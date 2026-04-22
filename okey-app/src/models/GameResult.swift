import Foundation

struct GameResult: Codable, Hashable {
    let tiles: [Tile]
    let totalScore: Int
    let canOpen: Bool
    let isFinished: Bool
    let runs: [[Tile]]
    let sets: [[Tile]]
    let remaining: [Tile]
    let groupsTotal: Int
    let message: String
}
