import SwiftUI
import PhotosUI

@MainActor
class CameraService: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func setImage(_ image: UIImage) {
        selectedImage = image
        errorMessage = nil
    }

    func clearImage() {
        selectedImage = nil
        errorMessage = nil
    }

    func compressedImageData(quality: CGFloat = 0.8) -> Data? {
        selectedImage?.jpegData(compressionQuality: quality)
    }
}
