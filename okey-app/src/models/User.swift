import Foundation

struct User: Codable {
    let id: String
    let email: String?
    let token: String
    let dailyUsage: Int
    let dailyLimit: Int       // 1 ücretsiz, 25 abonelik
    let photosRemaining: Int  // paket hakkı
    let subscriptionActive: Bool
}
