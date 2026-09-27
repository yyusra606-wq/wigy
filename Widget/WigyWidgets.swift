import SwiftUI
import WidgetKit

private struct LayerEntry: TimelineEntry {
    let date: Date
    let revision: Int
}

private struct LayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> LayerEntry {
        LayerEntry(date: .now, revision: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (LayerEntry) -> Void) {
        completion(LayerEntry(date: .now, revision: WidgetPoseStore.current))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LayerEntry>) -> Void) {
        let entry = LayerEntry(date: .now, revision: WidgetPoseStore.current)
        // Button intents cause WidgetKit to reload the timeline. There is no
        // background timer, paid push entitlement, or server dependency.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct LayerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var luminanceReduced
    let entry: LayerEntry

    private var canAnimate: Bool { !reduceMotion && !luminanceReduced }
    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    private var wind: Double {
        guard canAnimate else { return 0 }
        return [-1.0, 0, 1][entry.revision % 3]
    }

    var body: some View {
        Group {
            if family == .accessoryInline {
                Label("Wigy · Rain", systemImage: "cloud.rain")
            } else {
                Button(intent: MoveLayersIntent()) {
                    ZStack(alignment: .bottomTrailing) {
                        if isAccessory {
                            AccessoryLayerScene(wind: wind)
                                .padding(3)
                        } else {
                            LayerScene(wind: wind * 5,
                                       rainRevision: canAnimate ? entry.revision : 0)
                                .foregroundStyle(.white)
                            Label("Tap for wind", systemImage: "wind")
                                .font(.caption2.weight(.semibold))
                                .padding(8)
                                .foregroundStyle(.white)
                                .background(.black.opacity(0.65), in: Capsule())
                                .padding(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Move the hair, cloak, and rain")
                .animation(canAnimate ? .easeInOut(duration: 2) : nil, value: entry.revision)
            }
        }
        .containerBackground(for: .widget) {
            // No clear rectangle in the accessory's vibrant rendering tree.
            if !isAccessory { Color(red: 0.075, green: 0.085, blue: 0.11) }
        }
    }
}

/// Small pre-cropped transparent layers avoid oversized off-screen surfaces
/// in the Lock Screen renderer. All four images retain the same registration.
private struct AccessoryLayerScene: View {
    let wind: Double

    var body: some View {
        ZStack {
            layer(.character)
            layer(.cloak)
                .rotationEffect(.degrees(wind * 3), anchor: .top)
            layer(.hair)
                .offset(x: wind * 2)
            layer(.rain)
                .offset(y: wind * 5)
                .opacity(0.2)
        }
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(.primary)
        .accessibilityHidden(true)
    }

    private func layer(_ layer: SceneLayer) -> some View {
        Image("accessory_" + layer.rawValue)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
    }
}

private struct WigyLayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WigyLayers", provider: LayerProvider()) { entry in
            LayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Wigy Layers")
        .description("A transparent anime scene with separate hair, cloak, and rain.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

@main
struct WigyWidgetBundle: WidgetBundle {
    var body: some Widget { WigyLayerWidget() }
}
