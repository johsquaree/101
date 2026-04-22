import SwiftUI

struct HomeView: View {
    @State private var usage: UsageResponse?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 6) {
                    Text("101 Okey")
                        .font(.system(size: 42, weight: .bold))
                    Text("El Analizi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let usage {
                    UsageCard(usage: usage)
                        .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink { CameraView() } label: {
                        Label("Fotoğraf Çek / Seç", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    NavigationLink { PackagesView() } label: {
                        Label("Paketler", systemImage: "bag.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Ana Sayfa")
            .task { await loadUsage() }
        }
    }

    private func loadUsage() async {
        guard !isLoading, APIService.shared.isLoggedIn else { return }
        isLoading = true
        usage = try? await APIService.shared.checkUsage()
        isLoading = false
    }
}

struct UsageCard: View {
    let usage: UsageResponse

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(badge)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15))
                        .foregroundStyle(color)
                        .clipShape(Capsule())
                    Text(main)
                        .font(.title2.bold())
                }
                Spacer()
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
            }

            if usage.type != "pack" {
                ProgressView(value: Double(usage.used), total: Double(max(usage.limit, 1)))
                    .tint(color)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var badge: String {
        switch usage.type {
        case "subscription": return "Abonelik"
        case "pack":         return "Paket"
        default:             return "Ücretsiz"
        }
    }

    private var main: String {
        usage.type == "pack"
            ? "\(usage.photosRemaining) fotoğraf hakkı"
            : "\(usage.remaining) / \(usage.limit) kaldı"
    }

    private var icon: String {
        switch usage.type {
        case "subscription": return "star.fill"
        case "pack":         return "photo.fill"
        default:             return "gift.fill"
        }
    }

    private var color: Color {
        switch usage.type {
        case "subscription": return .yellow
        case "pack":         return .blue
        default:             return .green
        }
    }
}
