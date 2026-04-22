import StoreKit

// Ürün ID'leri — App Store Connect'te tanımlanacak
enum ProductID: String, CaseIterable {
    case smallPack    = "com.okeyapp.pack.small"    // 15 fotoğraf - 50₺
    case largePack    = "com.okeyapp.pack.large"    // 50 fotoğraf - 100₺
    case monthly      = "com.okeyapp.sub.monthly"  // Aylık abonelik - 500₺
}

class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    func loadProducts() async {
        // TODO: StoreKit 2 ile ürünleri yükle
    }

    func purchase(_ product: Product) async throws -> Bool {
        // TODO: satın alma akışı
        return false
    }

    func restorePurchases() async {
        // TODO: satın alma geri yükle
    }
}
