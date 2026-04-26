import Foundation
import AuthenticationServices

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?

    private let tokenKey = "authToken"

    override init() {
        super.init()
        isLoggedIn = UserDefaults.standard.string(forKey: tokenKey) != nil
    }

    // Apple Sign In sonucunu işle
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil

        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple kimlik bilgisi alınamadı"
                return
            }

            do {
                try await APIService.shared.signInWithApple(identityToken: identityToken)
                isLoggedIn = true
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            let err = error as? ASAuthorizationError
            if err?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        isLoggedIn = false
    }

    #if DEBUG
    func devLogin() async {
        errorMessage = nil
        do {
            try await APIService.shared.devLogin()
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif
}
