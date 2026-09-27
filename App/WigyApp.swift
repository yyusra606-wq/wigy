import SwiftUI

@main
struct WigyApp: App {
    var body: some Scene {
        WindowGroup { LayerLabView() }
    }
}

private struct LayerLabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var visibleLayers = Set(SceneLayer.allCases)
    @State private var playing = false
    @State private var loops = false
    @State private var checkerboard = true
    @State private var monochrome = true
    @State private var playbackStart = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Four layers. One scene.")
                        .font(.title2.bold())
                    Text("Hide a layer to inspect the cutout. Play a two-second motion to check the seams.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TimelineView(.animation(minimumInterval: 1.0 / 30.0,
                                            paused: !playing || reduceMotion || scenePhase != .active)) { context in
                        let elapsed = max(0, context.date.timeIntervalSince(playbackStart))
                        let active = playing && !reduceMotion && scenePhase == .active
                        let progress = active ? (loops ? elapsed.truncatingRemainder(dividingBy: 2) / 2 : min(elapsed / 2, 1)) : 0
                        LayerScene(visibleLayers: visibleLayers,
                                   wind: sin(progress * 2 * .pi), rainPhase: progress)
                            .foregroundStyle(monochrome ? Color.white : Color(red: 0.65, green: 0.84, blue: 1))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background {
                                if checkerboard { Checkerboard() }
                                else { Color(red: 0.075, green: 0.085, blue: 0.11) }
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .task(id: playing) {
                        guard playing else { return }
                        do {
                            try await Task.sleep(for: .seconds(2))
                            if !loops { playing = false }
                        } catch { /* Stop/replay cancels the pending completion. */ }
                    }
                    .onChange(of: loops) { _, _ in playing = false }
                    .onChange(of: scenePhase) { _, phase in
                        if phase != .active { playing = false }
                    }
                    .onChange(of: reduceMotion) { _, enabled in
                        if enabled { playing = false }
                    }

                    HStack {
                        Button {
                            if playing { playing = false }
                            else { playbackStart = .now; playing = true }
                        } label: {
                            Label(playing ? "Stop" : "Play 2 seconds",
                                  systemImage: playing ? "stop.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(reduceMotion)
                        Button("Reset") {
                            playing = false
                            visibleLayers = Set(SceneLayer.allCases)
                        }
                        .buttonStyle(.bordered)
                    }

                    GroupBox("Preview") {
                        VStack(spacing: 12) {
                            Toggle("Loop in app", isOn: $loops)
                            Toggle("Transparency checkerboard", isOn: $checkerboard)
                            Toggle("Monochrome material preview", isOn: $monochrome)
                        }
                    }
                    GroupBox("Visible layers") {
                        VStack(spacing: 12) {
                            ForEach(SceneLayer.allCases) { layer in
                                Toggle(layer.title, isOn: Binding(
                                    get: { visibleLayers.contains(layer) },
                                    set: { enabled in
                                        if enabled { visibleLayers.insert(layer) }
                                        else { visibleLayers.remove(layer) }
                                    }))
                            }
                        }
                    }
                    Text("Add Wigy from the widget gallery, then tap the wind button for a short update. These preview switches affect the app only. iOS controls widget animation and may suppress it in Always On or Reduce Motion.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if reduceMotion {
                        Label("Reduce Motion is enabled", systemImage: "accessibility")
                            .font(.footnote)
                    }
                }
                .padding(20)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Wigy · Layer Lab")
            .preferredColorScheme(.dark)
        }
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let tile: CGFloat = 16
            for row in 0..<Int(ceil(size.height / tile)) {
                for column in 0..<Int(ceil(size.width / tile)) {
                    let shade = (row + column).isMultiple(of: 2) ? 0.10 : 0.14
                    context.fill(Path(CGRect(x: CGFloat(column) * tile, y: CGFloat(row) * tile,
                                             width: tile, height: tile)), with: .color(Color(white: shade)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
