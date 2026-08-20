import Foundation

enum AppSettings {
    private enum Key {
        static let readAloud = "readAloudEnabled"
        static let cheerSounds = "cheerSoundsEnabled"
    }

    static var readAloudEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.readAloud) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.readAloud)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.readAloud) }
    }

    static var cheerSoundsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.cheerSounds) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.cheerSounds)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.cheerSounds) }
    }
}
