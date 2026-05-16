import Foundation

/// One-shot migrations for `UserDefaults`-backed app preferences.
/// Keep this in sync with the `default.rulesVersion` reader in NewGameView.
enum DefaultsMigrator {
    private static let rulesVersionKey = "default.rulesVersion"
    private static let rulesDataKey = "default.rulesData"

    static func runIfNeeded() {
        let store = UserDefaults.standard
        let version = store.integer(forKey: rulesVersionKey)

        if version < 2 {
            var rules: HouseRules = .default
            if let data = store.data(forKey: rulesDataKey),
               let decoded = try? JSONDecoder().decode(HouseRules.self, from: data) {
                rules = decoded
            }
            // v1: Two-triples on by default
            rules.twoTriples = true
            // v2: 4-of-a-kind-with-a-pair on by default
            rules.fourOfAKindWithPair = true
            if let encoded = try? JSONEncoder().encode(rules) {
                store.set(encoded, forKey: rulesDataKey)
            }
            store.set(2, forKey: rulesVersionKey)
        }
    }
}
