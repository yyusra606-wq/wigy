import AppIntents
import Foundation
import WidgetKit

/// Extension-local test state: no shared App Group is needed. A fresh request
/// starts when the provider receives it, allowing for the reload's delivery delay.
enum TimerTestStore {
    private static let lock = NSLock()
    private static let prefix = "wigy.timerTest."

    static func request(at date: Date = .now) {
        lock.lock()
        defer { lock.unlock() }
        let defaults = UserDefaults.standard
        defaults.set(UUID().uuidString, forKey: prefix + "request")
        defaults.set(date.timeIntervalSince1970, forKey: prefix + "requestedAt")
    }

    static func start(at now: Date) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        let defaults = UserDefaults.standard
        guard let request = defaults.string(forKey: prefix + "request") else { return nil }
        if defaults.string(forKey: prefix + "consumed") == request {
            let start = Date(timeIntervalSince1970: defaults.double(forKey: prefix + "start"))
            return now < start.addingTimeInterval(6) ? start : nil
        }
        let age = now.timeIntervalSince1970 - defaults.double(forKey: prefix + "requestedAt")
        guard age >= 0, age < 60 else { return nil }
        let start = now.addingTimeInterval(2)
        defaults.set(start.timeIntervalSince1970, forKey: prefix + "start")
        defaults.set(request, forKey: prefix + "consumed")
        return start
    }
}

struct PlayTimerTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Test timer scene now"
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        TimerTestStore.request()
        WidgetCenter.shared.reloadTimelines(ofKind: "WigyTimerScene")
        return .result()
    }
}
