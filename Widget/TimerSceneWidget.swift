import SwiftUI
import WidgetKit

/// An experimental clock-driven scene. A countdown changes the custom font's
/// artwork glyph once per second; the timer stops after six seconds. WidgetKit
/// decides when scheduled timeline entries actually become visible.
private struct TimerSceneEntry: TimelineEntry {
    let date: Date
    let burstStart: Date?
}

private struct TimerSceneProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerSceneEntry {
        TimerSceneEntry(date: .now, burstStart: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerSceneEntry) -> Void) {
        completion(TimerSceneEntry(date: .now, burstStart: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerSceneEntry>) -> Void) {
        let now = Date()
        var entries = [TimerSceneEntry(date: now, burstStart: TimerTestStore.start(at: now) ?? currentBurst(at: now))]
        var cursor = now
        let calendar = Calendar.current
        // Precompute a full day so the extension does not need to wake for
        // every burst. Entries are thirty minutes apart, except the initial one.
        for _ in 0..<48 {
            guard let hour = calendar.nextDate(after: cursor,
                                               matching: DateComponents(minute: 0, second: 0),
                                               matchingPolicy: .nextTime),
                  let halfHour = calendar.nextDate(after: cursor,
                                                   matching: DateComponents(minute: 30, second: 0),
                                                   matchingPolicy: .nextTime) else { break }
            let start = min(hour, halfHour)
            entries.append(TimerSceneEntry(date: start, burstStart: start))
            cursor = start.addingTimeInterval(1)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentBurst(at now: Date) -> Date? {
        let calendar = Calendar.current
        guard let hourStart = calendar.dateInterval(of: .hour, for: now)?.start else { return nil }
        let start = now.timeIntervalSince(hourStart) >= 1800
            ? hourStart.addingTimeInterval(1800) : hourStart
        return now.timeIntervalSince(start) < 6 ? start : nil
    }
}

private struct TimerSceneView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.isLuminanceReduced) private var luminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let entry: TimerSceneEntry

    private var accessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular
    }

    var body: some View {
        Group {
            if accessory {
                Button(intent: PlayTimerTestIntent()) {
                    scene
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Run six-second timer scene test")
            } else {
                VStack(spacing: 4) {
                    HStack {
                        Text("Timer test · 0.2.1").font(.caption2)
                        Spacer(minLength: 0)
                        Text("6")
                            .font(.custom("WigySceneFrames-Regular", fixedSize: 22))
                            .frame(width: 22, height: 22)
                            .accessibilityLabel("Static artwork font sample")
                    }
                    scene
                    HStack(spacing: 6) {
                        if reduceMotion || luminanceReduced {
                            Text("Motion off").font(.caption2)
                        } else if let start = entry.burstStart {
                            Text(timerInterval: start...start.addingTimeInterval(6),
                                 countsDown: true, showsHours: false)
                                .font(.caption.monospacedDigit())
                                .multilineTextAlignment(.trailing)
                                .frame(width: 46)
                        } else {
                            Text("Ready").font(.caption2)
                        }
                        Spacer(minLength: 0)
                        Button(intent: PlayTimerTestIntent()) {
                            Label("Test now", systemImage: "play.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .foregroundStyle(accessory ? Color.primary : Color.white)
        .containerBackground(for: .widget) {
            if !accessory { Color(red: 0.075, green: 0.085, blue: 0.11) }
        }
    }

    private var scene: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                staticScene.opacity(0.6)
                if let start = entry.burstStart, !luminanceReduced, !reduceMotion {
                    // Use a bounded, running timer. Do not supply a pause date
                    // or fix its intrinsic width: WidgetKit archives its layout.
                    Text(timerInterval: start...start.addingTimeInterval(6),
                         countsDown: true, showsHours: false)
                        .font(.custom("WigySceneFrames-Regular", fixedSize: side))
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .frame(width: side, height: side, alignment: .trailing)
                        .clipped()
                        .accessibilityHidden(true)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var staticScene: some View {
        ZStack {
            ForEach(SceneLayer.allCases) { layer in
                Image("accessory_" + layer.rawValue)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .opacity(layer == .rain ? 0.25 : 1)
            }
        }
    }
}

struct WigyTimerSceneWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WigyTimerScene", provider: TimerSceneProvider()) { entry in
            TimerSceneView(entry: entry)
        }
        .configurationDisplayName("Wigy Timer Test")
        .description("Tap Test now to compare the artwork font with a visible six-second countdown. Also scheduled at :00 and :30.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}
