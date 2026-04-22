import SwiftUI
import StoreKit

struct PackagesView: View {
    @StateObject private var store = StoreKitService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Daha Fazla Analiz")
                        .font(.title2.bold())
                    Text("İhtiyacınıza uygun paketi seçin")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                if store.products.isEmpty {
                    ProgressView("Yükleniyor...")
                        .padding(40)
                } else {
                    ForEach(store.products, id: \.id) { product in
                        ProductCard(product: product, isPurchasing: isPurchasing) {
                            Task { await buy(product) }
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let success = successMessage {
                    Text(success)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }

                Button("Satın Almaları Geri Yükle") {
                    Task { await store.restorePurchases() }
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Paketler")
        .task { await store.loadProducts() }
    }

    private func buy(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        successMessage = nil
        do {
            let ok = try await store.purchase(product)
            if ok { successMessage = "Satın alma başarılı! 🎉" }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}

struct ProductCard: View {
    let product: Product
    let isPurchasing: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onBuy) {
                Text(product.displayPrice)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .disabled(isPurchasing)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
