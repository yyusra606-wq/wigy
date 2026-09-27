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

    var body: some View {
        Group {
            if family == .accessoryInline {
                Label("Wigy · Rain", systemImage: "cloud.rain")
            } else if family == .accessoryCircular {
                Button(intent: MoveLayersIntent()) {
                    scene(framing: .portrait)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Move the hair, cloak, and rain")
            } else {
                ZStack(alignment: .bottomTrailing) {
                    scene(framing: family == .accessoryRectangular ? .portrait : .fullBody)
                    Button(intent: MoveLayersIntent()) {
                        Image(systemName: "wind")
                            .font(.system(size: isAccessory ? 12 : 16, weight: .semibold))
                            .padding(isAccessory ? 5 : 10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Move the hair, cloak, and rain")
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private func scene(framing: SceneFraming) -> some View {
        LayerScene(wind: canAnimate && !entry.revision.isMultiple(of: 2) ? 1 : 0,
                   rainRevision: canAnimate ? entry.revision : 0,
                   framing: framing)
            .foregroundStyle(.primary)
            .animation(canAnimate ? .easeInOut(duration: 2) : nil, value: entry.revision)
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
