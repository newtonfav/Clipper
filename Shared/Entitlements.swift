import Foundation

/// What each tier allows. Change the numbers here and nowhere else.
struct Limits: Sendable, Equatable {
    /// `nil` means unlimited.
    var maxPins: Int?
    var maxHistory: Int
    var insertVariants: Bool
    var kindActions: Bool

    static let free = Limits(maxPins: 5, maxHistory: 10, insertVariants: false, kindActions: false)
    static let pro = Limits(maxPins: nil, maxHistory: 50, insertVariants: true, kindActions: true)
}

/// The Pro flag, cached in the shared defaults so the keyboard and share extension can
/// read it without StoreKit. The app refreshes it from StoreKit on every launch.
enum Entitlements {
    private static let key = "isPro"

    static var isPro: Bool {
        get { AppGroup.defaults.bool(forKey: key) }
        set { AppGroup.defaults.set(newValue, forKey: key) }
    }

    static var limits: Limits { isPro ? .pro : .free }
}
