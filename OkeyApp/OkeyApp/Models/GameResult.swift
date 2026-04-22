import Foundation

struct GameResult: Codable {
    let tiles: [Tile]
    let totalScore: Int
    let isFinished: Bool
    let runs: [[Tile]]    // seriler
    let sets: [[Tile]]    // takımlar
    let message: String
}
