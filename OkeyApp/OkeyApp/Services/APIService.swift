import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://your-backend-url.railway.app" // deploy sonrası değişecek

    // Fotoğrafı backend'e gönder, taşları al
    func recognizeTiles(imageData: Data) async throws -> [Tile] {
        // TODO: implement
        return []
    }

    // Taşları değerlendir, puan hesapla
    func evaluateHand(tiles: [Tile]) async throws -> GameResult {
        // TODO: implement
        fatalError("Not implemented")
    }

    // Günlük kullanım kontrolü
    func checkUsage(token: String) async throws -> (used: Int, limit: Int) {
        // TODO: implement
        return (0, 1)
    }
}
