import Foundation

struct UserDefaultsKeyValueStore: KeyValueStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }

    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func set(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func set(_ value: Data, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}
