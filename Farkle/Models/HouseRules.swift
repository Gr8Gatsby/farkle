import Foundation

struct HouseRules: Codable, Equatable, Hashable {
    var threePair: Bool = true
    var straight: Bool = true
    var twoTriples: Bool = true
    var mustOpenWith: Int? = 500

    static let `default` = HouseRules()
}
