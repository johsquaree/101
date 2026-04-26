import SwiftUI

struct RecognitionView: View {
    let archiveId: Int?
    @State var tiles: [Tile]

    @State private var editingTile: Tile?
    @State private var editingIndex: Int?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var result: GameResult?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Açıklama
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(.blue)
                    Text("Hatalı taşlara dokun ve düzelt")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(tiles.count) taş")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Taş grid'i
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 10)], spacing: 10) {
                    ForEach(Array(tiles.enumerated()), id: \.offset) { index, tile in
                        TileEditCell(tile: tile) {
                            editingIndex = index
                            editingTile = tile
                        } onDelete: {
                            tiles.remove(at: index)
                        }
                    }

                    // Taş ekle butonu
                    Button {
                        let newTile = Tile(color: .black, number: 1, isOkey: false)
                        tiles.append(newTile)
                        editingIndex = tiles.count - 1
                        editingTile = newTile
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                            Text("Ekle")
                                .font(.caption2)
                        }
                        .frame(width: 52, height: 60)
                        .background(Color(.tertiarySystemBackground))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                // Analiz Et butonu
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
                    .background(tiles.isEmpty ? Color.gray : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnalyzing || tiles.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Taşları Kontrol Et")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $result) { r in
            ResultView(result: r)
        }
        .sheet(item: $editingTile) { tile in
            TileEditSheet(tile: tile) { updated in
                if let idx = editingIndex {
                    tiles[idx] = updated
                }
                editingTile = nil
                editingIndex = nil
            } onCancel: {
                editingTile = nil
                editingIndex = nil
            }
        }
    }

    private func analyze() async {
        isAnalyzing = true
        errorMessage = nil

        // Düzeltmeleri kaydet (AI eğitimi için)
        if let id = archiveId {
            try? await APIService.shared.saveCorrection(archiveId: id, tiles: tiles)
        }

        do {
            let gameResult = try await APIService.shared.evaluateHand(tiles: tiles)
            result = gameResult
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }
}

// MARK: - Tile cell with edit/delete

struct TileEditCell: View {
    let tile: Tile
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onEdit) {
                TileView(tile: tile)
                    .frame(width: 52, height: 60)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                    .background(Color(.systemBackground).clipShape(Circle()))
            }
            .offset(x: 6, y: -6)
        }
    }
}
