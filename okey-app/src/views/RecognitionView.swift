import SwiftUI

struct RecognitionView: View {
    let archiveId: Int?
    @State var tiles: [Tile]

    // Taşları iki satıra böl — üst: ilk yarı, alt: kalan
    @State private var splitIndex: Int = 0

    // Düzenleme
    @State private var editingTile: Tile?
    @State private var editingIndex: Int?
    @State private var editingRow: RowTarget = .top

    // Gösterge
    @State private var showGostergePicker = false
    @State private var gosterge: Tile?

    // Analiz
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var result: GameResult?

    enum RowTarget { case top, bottom }

    var topTiles: [Tile] { Array(tiles.prefix(splitIndex)) }
    var bottomTiles: [Tile] { Array(tiles.dropFirst(splitIndex)) }

    // Göstergeden okey taşını hesapla
    var okeyTile: OkeyTileRequest? {
        guard let g = gosterge, g.color != .joker, let num = g.number else { return nil }
        let okeyNum = num == 13 ? 1 : num + 1
        return OkeyTileRequest(color: g.color.rawValue, number: okeyNum)
    }

    var okeyDescription: String {
        guard let g = gosterge, g.color != .joker, let num = g.number else { return "Seçilmedi" }
        let okeyNum = num == 13 ? 1 : num + 1
        let colorName = colorTR(g.color)
        return "\(colorName) \(okeyNum)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Gösterge / Okey bilgisi
                gostergeCard

                // Üst sıra
                tileRow(title: "Üst Sıra", tiles: topTiles, row: .top)

                // Alt sıra
                tileRow(title: "Alt Sıra", tiles: bottomTiles, row: .bottom)

                // Sıra bölme ayarı
                splitSlider

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Analiz Et
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
                applyEdit(updated)
            } onCancel: {
                editingTile = nil
            }
        }
        .sheet(isPresented: $showGostergePicker) {
            let placeholder = gosterge ?? Tile(color: .black, number: 1, isOkey: false)
            TileEditSheet(tile: placeholder) { selected in
                gosterge = selected
                showGostergePicker = false
            } onCancel: {
                showGostergePicker = false
            }
        }
        .onAppear {
            splitIndex = tiles.count / 2
        }
    }

    // MARK: - Gösterge card

    private var gostergeCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gösterge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    showGostergePicker = true
                } label: {
                    if let g = gosterge, g.color != .joker {
                        TileView(tile: g)
                            .frame(width: 44, height: 52)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .frame(width: 44, height: 52)
                            .overlay(
                                Text("Seç")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
            }

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Okey")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let okey = okeyTile {
                    TileView(tile: Tile(
                        color: TileColor(rawValue: okey.color) ?? .black,
                        number: okey.number,
                        isOkey: true
                    ))
                    .frame(width: 44, height: 52)
                } else {
                    Text("—")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 52)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(tiles.count) taş")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Dokunarak düzelt")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Tile row

    private func tileRow(title: String, tiles rowTiles: [Tile], row: RowTarget) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                // Taş ekle
                Button {
                    let newTile = Tile(color: .black, number: 1, isOkey: false)
                    addTile(newTile, to: row)
                    let idx = globalIndex(of: newTile, in: row, localIndex: rowTiles.count)
                    editingIndex = idx
                    editingRow = row
                    editingTile = newTile
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(rowTiles.enumerated()), id: \.offset) { localIdx, tile in
                        TileEditCell(tile: tile, isOkey: isOkeyTile(tile)) {
                            let gIdx = startIndex(for: row) + localIdx
                            editingIndex = gIdx
                            editingRow = row
                            editingTile = tile
                        } onDelete: {
                            let gIdx = startIndex(for: row) + localIdx
                            self.tiles.remove(at: gIdx)
                            splitIndex = max(0, min(splitIndex, self.tiles.count))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Split slider

    private var splitSlider: some View {
        VStack(spacing: 6) {
            Text("Satır bölme: üst \(splitIndex) — alt \(tiles.count - splitIndex)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: Binding(
                get: { Double(splitIndex) },
                set: { splitIndex = Int($0) }
            ), in: 0...Double(max(1, tiles.count)), step: 1)
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func startIndex(for row: RowTarget) -> Int {
        row == .top ? 0 : splitIndex
    }

    private func addTile(_ tile: Tile, to row: RowTarget) {
        if row == .top {
            tiles.insert(tile, at: splitIndex)
            splitIndex += 1
        } else {
            tiles.append(tile)
        }
    }

    private func globalIndex(of tile: Tile, in row: RowTarget, localIndex: Int) -> Int {
        startIndex(for: row) + localIndex
    }

    private func isOkeyTile(_ tile: Tile) -> Bool {
        guard let okey = okeyTile else { return tile.color == .joker }
        return tile.color != .joker &&
               tile.color.rawValue == okey.color &&
               tile.number == okey.number
    }

    private func applyEdit(_ updated: Tile) {
        if let idx = editingIndex {
            tiles[idx] = updated
        }
        editingTile = nil
        editingIndex = nil
    }

    private func colorTR(_ color: TileColor) -> String {
        switch color {
        case .red:    return "Kırmızı"
        case .yellow: return "Sarı"
        case .blue:   return "Mavi"
        case .black:  return "Siyah"
        case .joker:  return "Joker"
        }
    }

    // MARK: - Analyze

    private func analyze() async {
        isAnalyzing = true
        errorMessage = nil

        if let id = archiveId {
            try? await APIService.shared.saveCorrection(archiveId: id, tiles: tiles)
        }

        do {
            let gameResult = try await APIService.shared.evaluateHand(tiles: tiles, okeyTile: okeyTile)
            result = gameResult
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }
}

// MARK: - Tile cell

struct TileEditCell: View {
    let tile: Tile
    var isOkey: Bool = false
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onEdit) {
                VStack(spacing: 2) {
                    TileView(tile: tile)
                        .frame(width: 52, height: 60)
                    if isOkey {
                        Text("OKEY")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
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
