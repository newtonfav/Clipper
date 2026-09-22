import Foundation

/// Identifiers and keys shared by the app, the keyboard and the share extension.
/// Change `identifier` together with the entitlement entries in `project.yml`.
enum AppGroup {
    static let identifier = "group.com.newtonfav.clip"
    static let clipsFileName = "clips.json"
    static let storeDidChangeNotification = "com.newtonfav.clip.storeDidChange"

    enum DefaultsKey {
        static let lastSeenChangeCount = "lastSeenChangeCount"
        static let autoReturnAfterInsert = "autoReturnAfterInsert"
        static let captureOnKeyboardOpen = "captureOnKeyboardOpen"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    /// Shared defaults. Falls back to standard defaults if the group is misconfigured
    /// so that nothing crashes; data simply stops being shared.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

/// Typed access to the handful of user settings kept in the shared defaults.
enum AppSettings {
    /// After inserting a clip, switch back to the next keyboard automatically. Default on.
    static var autoReturnAfterInsert: Bool {
        get { boolWithDefault(AppGroup.DefaultsKey.autoReturnAfterInsert, default: true) }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.DefaultsKey.autoReturnAfterInsert) }
    }

    /// Read the clipboard every time the keyboard opens. Default on.
    static var captureOnKeyboardOpen: Bool {
        get { boolWithDefault(AppGroup.DefaultsKey.captureOnKeyboardOpen, default: true) }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.DefaultsKey.captureOnKeyboardOpen) }
    }

    static var hasSeenOnboarding: Bool {
        get { boolWithDefault(AppGroup.DefaultsKey.hasSeenOnboarding, default: false) }
        set { AppGroup.defaults.set(newValue, forKey: AppGroup.DefaultsKey.hasSeenOnboarding) }
    }

    private static func boolWithDefault(_ key: String, default fallback: Bool) -> Bool {
        let defaults = AppGroup.defaults
        return defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }
}
