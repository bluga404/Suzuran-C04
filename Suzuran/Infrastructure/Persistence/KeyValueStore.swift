import Foundation

protocol KeyValueStore {
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func set(_ value: Bool, forKey key: String)
    func set(_ value: String, forKey key: String)
}
