import Foundation

class APIService {
    static let shared = APIService()

    private let baseURL = "https://gracious-benevolence-production.up.railway.app"

    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    // MARK: - Generic request

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        if !(200..<300).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "Sunucu hatası"
            throw APIError.serverError(http.statusCode, msg)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth

    func signInWithApple(identityToken: String) async throws {
        let body = try JSONEncoder().encode(AppleAuthRequest(identityToken: identityToken))
        let res: AuthResponse = try await request("/api/auth/apple", method: "POST", body: body)
        authToken = res.token
    }

    func checkUsage() async throws -> UsageResponse {
        try await request("/api/auth/usage")
    }

    func verifyPurchase(productId: String, transactionId: String) async throws {
        let body = try JSONEncoder().encode(PurchaseRequest(productId: productId, transactionId: transactionId))
        let _: EmptyResponse = try await request("/api/auth/verify-purchase", method: "POST", body: body)
    }

    var isLoggedIn: Bool { authToken != nil }

    #if DEBUG
    func devLogin() async throws {
        let res: AuthResponse = try await request("/api/auth/dev-login", method: "POST")
        authToken = res.token
    }
    #endif

    func logout() { authToken = nil }

    // MARK: - Core features

    func recognizeTiles(imageData: Data) async throws -> RecognizeResponse {
        guard let url = URL(string: baseURL + "/api/recognize") else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        if !(200..<300).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "Tanıma hatası"
            throw APIError.serverError(http.statusCode, msg)
        }

        return try JSONDecoder().decode(RecognizeResponse.self, from: data)
    }

    func saveCorrection(archiveId: Int, tiles: [Tile]) async throws {
        let body = try JSONEncoder().encode(CorrectionRequest(archiveId: archiveId, correctedTiles: tiles))
        let _: EmptyResponse = try await request("/api/recognize/correct", method: "POST", body: body)
    }

    func evaluateHand(tiles: [Tile], okeyTile: OkeyTileRequest? = nil) async throws -> GameResult {
        let body = try JSONEncoder().encode(EvaluateRequest(tiles: tiles, okeyTile: okeyTile))
        return try await request("/api/evaluate", method: "POST", body: body)
    }
}

// MARK: - Request / Response models

struct AppleAuthRequest: Encodable { let identityToken: String }
struct AuthResponse: Decodable { let token: String; let userId: String }

struct UsageResponse: Decodable {
    let used: Int
    let limit: Int
    let remaining: Int
    let photosRemaining: Int
    let subscriptionActive: Bool
    let type: String
}

struct RecognizeResponse: Decodable {
    let tiles: [Tile]
    let archiveId: Int?
    let usage: UsageInfo?
}

struct UsageInfo: Decodable {
    let type: String
    let used: Int?
    let limit: Int?
    let remaining: Int?
}

struct OkeyTileRequest: Encodable {
    let color: String
    let number: Int
}

struct EvaluateRequest: Encodable {
    let tiles: [Tile]
    let okeyTile: OkeyTileRequest?
}

struct CorrectionRequest: Encodable { let archiveId: Int; let correctedTiles: [Tile] }
struct PurchaseRequest: Encodable { let productId: String; let transactionId: String }
struct EmptyResponse: Decodable {}
struct ErrorBody: Decodable { let error: String }

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Geçersiz URL"
        case .invalidResponse:         return "Geçersiz yanıt"
        case .serverError(_, let msg): return msg
        }
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) { append(d) }
    }
}
