import Foundation

enum TileColor: String, Codable {
    case red = "red"
    case yellow = "yellow"
    case blue = "blue"
    case black = "black"
    case joker = "joker"
}

struct Tile: Codable, Identifiable {
    let id = UUID()
    let color: TileColor
    let number: Int?   // joker için nil
    let isOkey: Bool

    enum CodingKeys: String, CodingKey {
        case color, number, isOkey
    }
}
