import AppIntents
import Foundation
import WidgetKit

/// This file belongs ONLY to the widget extension. Keeping the intent there
/// makes its defaults and the timeline provider use the same sandbox, without
/// an App Group entitlement that would complicate personal sideload signing.
enum WidgetPoseStore {
    private static let key = "wigy.layerRevision"
    static var current: Int { UserDefaults.standard.integer(forKey: key) }

    @MainActor static func advance() {
        let value = current
        UserDefaults.standard.set(value >= 1_000_000 ? 0 : value + 1, forKey: key)
    }
}

struct MoveLayersIntent: AppIntent {
    static var title: LocalizedStringResource = "Move scene layers"
    static var description = IntentDescription("Change the hair, cloak, and rain pose in the widget.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        WidgetPoseStore.advance()
        WidgetCenter.shared.reloadTimelines(ofKind: "WigyLayers")
        return .result()
    }
}
