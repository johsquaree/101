import SwiftUI
import PhotosUI

struct CameraView: View {
    @StateObject private var camera = CameraService()
    @State private var pickerItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var result: GameResult?

    var body: some View {
        VStack(spacing: 20) {
            if let image = camera.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                Button {
                    Task { await analyze() }
                } label: {
                    Group {
                        if isAnalyzing {
                            ProgressView().tint(.white)
                        } else {
                            Label("Analiz Et", systemImage: "sparkles")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnalyzing)
                .padding(.horizontal)

                Button("Fotoğrafı Değiştir") { camera.clearImage() }
                    .foregroundStyle(.secondary)

            } else {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)

                    Text("Taşlarının fotoğrafını seç")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Galeriden Seç", systemImage: "photo.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    NavigationLink {
                        CameraCapture(onCapture: { camera.setImage($0) })
                    } label: {
                        Label("Kamera", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Fotoğraf Çek")
        .navigationDestination(item: $result) { r in
            ResultView(result: r)
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    camera.setImage(img)
                }
            }
        }
    }

    private func analyze() async {
        guard let imageData = camera.compressedImageData() else { return }
        isAnalyzing = true
        errorMessage = nil
        do {
            let recognize = try await APIService.shared.recognizeTiles(imageData: imageData)
            let gameResult = try await APIService.shared.evaluateHand(tiles: recognize.tiles)
            result = gameResult
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }
}

struct CameraCapture: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCapture
        init(_ parent: CameraCapture) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onCapture(img) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) { parent.dismiss() }
    }
}
