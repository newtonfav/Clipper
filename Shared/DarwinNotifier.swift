import Foundation

/// Thin wrapper over the Darwin notify center, the only cross-process broadcast
/// available to app extensions. No payload; receivers simply reload from disk.
enum DarwinNotifier {
    static func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }

    /// Starts observing. Keep the returned token alive; dropping it stops observation.
    static func observe(_ name: String, handler: @escaping @Sendable @MainActor () -> Void) -> DarwinObservation {
        DarwinObservation(name: name, handler: handler)
    }
}

final class DarwinObservation: Sendable {
    fileprivate final class Box: Sendable {
        let handler: @Sendable @MainActor () -> Void
        init(handler: @escaping @Sendable @MainActor () -> Void) { self.handler = handler }
    }

    private let name: String
    private let box: Box

    fileprivate init(name: String, handler: @escaping @Sendable @MainActor () -> Void) {
        self.name = name
        self.box = Box(handler: handler)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(box).toOpaque(),
            darwinCallback,
            name as CFString,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(box).toOpaque(),
            CFNotificationName(name as CFString),
            nil
        )
    }
}

private let darwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
    guard let observer else { return }
    let box = Unmanaged<DarwinObservation.Box>.fromOpaque(observer).takeUnretainedValue()
    Task { @MainActor in box.handler() }
}
