import Foundation
import SwiftUI

enum TileColor: String, Codable, Hashable {
    case red = "red"
    case yellow = "yellow"
    case blue = "blue"
    case black = "black"
    case joker = "joker"
}

struct Tile: Codable, Identifiable, Hashable {
    let id: UUID
    let color: TileColor
    let number: Int?
    let isOkey: Bool

    init(color: TileColor, number: Int?, isOkey: Bool) {
        self.id = UUID()
        self.color = color
        self.number = number
        self.isOkey = isOkey
    }

    enum CodingKeys: String, CodingKey {
        case color, number, isOkey
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.color = try c.decode(TileColor.self, forKey: .color)
        self.number = try c.decodeIfPresent(Int.self, forKey: .number)
        self.isOkey = try c.decodeIfPresent(Bool.self, forKey: .isOkey) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encodeIfPresent(number, forKey: .number)
        try c.encode(isOkey, forKey: .isOkey)
    }
}

extension Tile {
    var backgroundColor: Color {
        switch color {
        case .red:    return .red
        case .yellow: return .yellow
        case .blue:   return .blue
        case .black:  return .black
        case .joker:  return .purple
        }
    }

    var foregroundColor: Color {
        switch color {
        case .yellow: return .black
        default:      return .white
        }
    }

    var displayNumber: String {
        if isOkey { return "★" }
        if let n = number { return "\(n)" }
        return "J"
    }
}
