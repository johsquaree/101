import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("101 Okey")
                    .font(.largeTitle)
                    .bold()

                // TODO: Günlük kalan hak göstergesi

                NavigationLink("Fotoğraf Çek / Seç") {
                    // CameraView()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Paketler") {
                    // PackagesView()
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("Ana Sayfa")
        }
    }
}
