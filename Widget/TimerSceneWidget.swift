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
        var entries = [TimerSceneEntry(date: now, burstStart: currentBurst(at: now))]
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
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                staticScene
                    .opacity(0.6)
                if let start = entry.burstStart, !luminanceReduced, !reduceMotion {
                    let end = start.addingTimeInterval(6)
                    Text(timerInterval: start...end,
                         pauseTime: end,
                         countsDown: true,
                         showsHours: false)
                        .font(.custom("WigySceneFrames-Regular", fixedSize: side))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        .frame(width: side, height: side, alignment: .trailing)
                        .clipped()
                        .accessibilityHidden(true)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            if !accessory { Color(red: 0.075, green: 0.085, blue: 0.11) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Anime rain scene, scheduled to move briefly twice an hour")
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
        .foregroundStyle(.primary)
    }
}

struct WigyTimerSceneWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WigyTimerScene", provider: TimerSceneProvider()) { entry in
            TimerSceneView(entry: entry)
        }
        .configurationDisplayName("Wigy Timer Test")
        .description("Tests two six-second scene bursts per hour using custom timer glyphs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}
