import SwiftUI
import PhotosUI

class CameraService: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isLoading = false

    // Kamera veya galeriden fotoğraf seç
    // TODO: AVFoundation kamera entegrasyonu
    // TODO: PhotosUI galeri seçici
}
