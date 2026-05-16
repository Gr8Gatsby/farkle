import Foundation

/// One-shot migrations for `UserDefaults`-backed app preferences.
/// Keep this in sync with the `default.rulesVersion` reader in NewGameView.
enum DefaultsMigrator {
    private static let rulesVersionKey = "default.rulesVersion"
    private static let rulesDataKey = "default.rulesData"

    static func runIfNeeded() {
        let store = UserDefaults.standard
        let version = store.integer(forKey: rulesVersionKey)

        if version < 1 {
            var rules: HouseRules = .default
            if let data = store.data(forKey: rulesDataKey),
               let decoded = try? JSONDecoder().decode(HouseRules.self, from: data) {
                rules = decoded
            }
            rules.twoTriples = true
            if let encoded = try? JSONEncoder().encode(rules) {
                store.set(encoded, forKey: rulesDataKey)
            }
            store.set(1, forKey: rulesVersionKey)
        }
    }
}
