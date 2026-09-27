import SwiftUI

/// All images share a 1024 x 1024 transparent canvas. Never trim individual
/// images to their visible bounds: that would change their registration.
enum SceneLayer: String, CaseIterable, Identifiable {
    case character = "character_base"
    case cloak
    case hair
    case rain

    var id: String { rawValue }
    var title: String {
        switch self {
        case .character: return "Character"
        case .cloak: return "Cloak"
        case .hair: return "Hair"
        case .rain: return "Rain"
        }
    }
}

enum SceneFraming {
    case fullBody, portrait

    var crop: CGRect {
        switch self {
        case .fullBody: return CGRect(x: 0, y: 0, width: 1024, height: 1024)
        case .portrait: return CGRect(x: 170, y: 92, width: 420, height: 380)
        }
    }
}

/// The same actual PNG layers render in both the app and widget extension.
/// This view deliberately adds no background image, material, or card.
struct LayerScene: View {
    var visibleLayers: Set<SceneLayer> = Set(SceneLayer.allCases)
    var wind: Double = 0
    var rainPhase: Double = 0
    /// Widgets use an identity transition when a new revision is delivered.
    /// The app leaves this nil and supplies a continuous rainPhase instead.
    var rainRevision: Int? = nil
    var framing: SceneFraming = .fullBody

    var body: some View {
        GeometryReader { geometry in
            let crop = framing.crop
            let scale = min(geometry.size.width / crop.width, geometry.size.height / crop.height)
            let width = 1024 * scale
            let height = 1024 * scale

            ZStack {
                if visibleLayers.contains(.character) {
                    artwork(.character, width: width, height: height)
                }
                if visibleLayers.contains(.cloak) {
                    artwork(.cloak, width: width, height: height)
                        .scaleEffect(x: CGFloat(1 + wind * 0.012), y: 1, anchor: UnitPoint(x: 0.37, y: 0.27))
                        .rotationEffect(.degrees(wind * 0.65), anchor: UnitPoint(x: 0.37, y: 0.27))
                }
                if visibleLayers.contains(.hair) {
                    artwork(.hair, width: width, height: height)
                        .rotationEffect(.degrees(wind * 0.35), anchor: UnitPoint(x: 0.3125, y: 0.17))
                        .offset(x: CGFloat(wind * 2.5) * scale, y: CGFloat(abs(wind) * 1.2) * scale)
                }
                if visibleLayers.contains(.rain) {
                    ZStack {
                        if let revision = rainRevision {
                            artwork(.rain, width: width, height: height)
                                .id(revision)
                                .transition(.asymmetric(insertion: .offset(y: -height),
                                                        removal: .offset(y: height)))
                        } else {
                            artwork(.rain, width: width, height: height)
                                .offset(y: CGFloat(rainPhase) * height)
                            artwork(.rain, width: width, height: height)
                                .offset(y: CGFloat(rainPhase - 1) * height)
                        }
                    }
                    .frame(width: width, height: height)
                    .clipped()
                    .opacity(0.24)
                }
            }
            .frame(width: width, height: height)
            .position(x: (geometry.size.width - crop.width * scale) / 2 + (512 - crop.minX) * scale,
                      y: (geometry.size.height - crop.height * scale) / 2 + (512 - crop.minY) * scale)
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Anime character with independent hair, cloak, and rain layers")
    }

    private func artwork(_ layer: SceneLayer, width: CGFloat, height: CGFloat) -> some View {
        Image(layer.rawValue)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: height)
    }
}
