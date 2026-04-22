import StoreKit
import Foundation

enum ProductID: String, CaseIterable {
    case smallPack = "com.okeyapp.pack.small"
    case largePack = "com.okeyapp.pack.large"
    case monthly   = "com.okeyapp.sub.monthly"
}

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var products: [Product] = []
    @Published var purchasedIDs: Set<String> = []

    private var listener: Task<Void, Error>?

    init() {
        listener = listenForTransactions()
    }

    deinit { listener?.cancel() }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            print("Ürünler yüklenemedi:", error)
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateEntitlements()
            try? await APIService.shared.verifyPurchase(
                productId: product.id,
                transactionId: "\(transaction.id)"
            )
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateEntitlements()
    }

    private func updateEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil {
                active.insert(t.productID)
            }
        }
        purchasedIDs = active
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        guard case .verified(let value) = result else { throw StoreError.failedVerification }
        return value
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let t) = result {
                    await self.updateEntitlements()
                    await t.finish()
                }
            }
        }
    }
}

enum StoreError: Error { case failedVerification }
