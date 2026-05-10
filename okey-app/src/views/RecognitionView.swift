import SwiftUI

// MARK: - Manual group

struct TileGroup: Identifiable {
    let id = UUID()
    var tiles: [Tile]
    var type: GroupType
    var isValid: Bool

    enum GroupType { case run, set }

    var label: String { type == .run ? "Seri" : "Takım" }
    var total: Int { tiles.compactMap(\.number).reduce(0, +) }
}

// MARK: - RecognitionView

struct RecognitionView: View {
    let archiveId: Int?
    @State var tiles: [Tile]

    @State private var splitIndex: Int = 0
    @State private var selectedIndices: Set<Int> = []

    @State private var editingTile: Tile?
    @State private var editingIndex: Int?
    @State private var showGosterge = false
    @State private var gostergeColor: TileColor = .black
    @State private var gostergeNumber: Int = 1
    @State private var gostergeSet = false

    @State private var groups: [TileGroup] = []
    @State private var groupedIndices: Set<Int> = []
    @State private var groupError: String?

    var topTiles: [Tile] { Array(tiles.prefix(splitIndex)) }
    var bottomTiles: [Tile] { Array(tiles.dropFirst(splitIndex)) }

    var okeyTile: OkeyTileRequest? {
        guard gostergeSet else { return nil }
        let okeyNum = gostergeNumber == 13 ? 1 : gostergeNumber + 1
        return OkeyTileRequest(color: gostergeColor.rawValue, number: okeyNum)
    }

    var okeyNumber: Int {
        gostergeNumber == 13 ? 1 : gostergeNumber + 1
    }

    var ungroupedTiles: [Tile] {
        tiles.indices.filter { !groupedIndices.contains($0) }.map { tiles[$0] }
    }

    var remainingScore: Int {
        ungroupedTiles.compactMap(\.number).reduce(0, +)
    }

    var groupsTotal: Int {
        groups.filter(\.isValid).reduce(0) { $0 + $1.total }
    }

    var canOpen: Bool { groupsTotal >= 101 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                gostergeCard
                tileSection
                groupActionBar
                groupsList
                scoreCard
            }
            .padding(.vertical)
        }
        .navigationTitle("El Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTile) { tile in
            TileEditSheet(tile: tile) { updated in
                if let idx = editingIndex { tiles[idx] = updated }
                editingTile = nil; editingIndex = nil
            } onCancel: { editingTile = nil; editingIndex = nil }
        }
        .onAppear { splitIndex = tiles.count / 2 }
    }

    // MARK: - Gösterge card

    private var gostergeCard: some View {
        VStack(spacing: 0) {
            // Başlık + özet
            Button {
                withAnimation { showGosterge.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gösterge & Okey").font(.subheadline.weight(.semibold))
                        Text(gostergeSet
                             ? "\(colorTR(gostergeColor)) \(gostergeNumber) → Okey: \(colorTR(gostergeColor)) \(okeyNumber)"
                             : "Göstergeyi seç")
                            .font(.caption)
                            .foregroundStyle(gostergeSet ? Color.secondary : Color.blue)
                    }
                    Spacer()
                    if gostergeSet {
                        HStack(spacing: 6) {
                            TileView(tile: Tile(color: gostergeColor, number: gostergeNumber, isOkey: false))
                                .frame(width: 36, height: 44)
                            Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
                            TileView(tile: Tile(color: gostergeColor, number: okeyNumber, isOkey: true))
                                .frame(width: 36, height: 44)
                        }
                    }
                    Image(systemName: showGosterge ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
            }
            .foregroundStyle(.primary)

            // Inline seçici
            if showGosterge {
                Divider()
                VStack(spacing: 12) {
                    // Renk
                    HStack(spacing: 12) {
                        ForEach([TileColor.red, .yellow, .blue, .black], id: \.self) { c in
                            Button {
                                gostergeColor = c
                                gostergeSet = true
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tileColor(c))
                                    .frame(width: 52, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(gostergeColor == c ? Color.white : Color.clear, lineWidth: 2.5)
                                    )
                                    .shadow(color: gostergeColor == c ? .black.opacity(0.3) : .clear, radius: 4)
                            }
                        }
                    }

                    // Sayı
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(1...13, id: \.self) { n in
                            Button {
                                gostergeNumber = n
                                gostergeSet = true
                            } label: {
                                Text("\(n)")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(width: 36, height: 36)
                                    .background(gostergeNumber == n && gostergeSet
                                                ? tileColor(gostergeColor)
                                                : Color(.tertiarySystemBackground))
                                    .foregroundStyle(gostergeNumber == n && gostergeSet
                                                     ? (gostergeColor == .yellow ? Color.black : .white)
                                                     : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func colorTR(_ c: TileColor) -> String {
        switch c {
        case .red: return "Kırmızı"
        case .yellow: return "Sarı"
        case .blue: return "Mavi"
        case .black: return "Siyah"
        case .joker: return "Joker"
        }
    }

    private func tileColor(_ c: TileColor) -> Color {
        switch c {
        case .red: return .red
        case .yellow: return .yellow
        case .blue: return .blue
        case .black: return .black
        default: return .gray
        }
    }

    // MARK: - Tile section

    private var tileSection: some View {
        VStack(spacing: 12) {
            tileRow(label: "Üst Sıra", rowTiles: topTiles, offset: 0)
            Divider().padding(.horizontal)
            tileRow(label: "Alt Sıra", rowTiles: bottomTiles, offset: splitIndex)

            // Bölme slider
            HStack {
                Text("Üst: \(splitIndex)  Alt: \(tiles.count - splitIndex)")
                    .font(.caption2).foregroundStyle(.tertiary)
                Slider(value: Binding(
                    get: { Double(splitIndex) },
                    set: { splitIndex = Int($0) }
                ), in: 0...Double(max(1, tiles.count)), step: 1)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func tileRow(label: String, rowTiles: [Tile], offset: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.horizontal)
                Spacer()
                Button {
                    let t = Tile(color: .black, number: 1, isOkey: false)
                    if offset == 0 { tiles.insert(t, at: splitIndex); splitIndex += 1 }
                    else { tiles.append(t) }
                    let idx = offset == 0 ? splitIndex - 1 : tiles.count - 1
                    editingIndex = idx; editingTile = t
                } label: {
                    Image(systemName: "plus.circle").foregroundStyle(.blue).padding(.trailing)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(rowTiles.enumerated()), id: \.offset) { localIdx, tile in
                        let globalIdx = offset + localIdx
                        let isGrouped = groupedIndices.contains(globalIdx)
                        let isSelected = selectedIndices.contains(globalIdx)
                        let isOkeyMatch = isOkeyMatch(tile)

                        ZStack(alignment: .topTrailing) {
                            Button {
                                if isGrouped { return }
                                if selectedIndices.contains(globalIdx) {
                                    selectedIndices.remove(globalIdx)
                                } else {
                                    selectedIndices.insert(globalIdx)
                                }
                                groupError = nil
                            } label: {
                                VStack(spacing: 2) {
                                    TileView(tile: tile)
                                        .frame(width: 52, height: 60)
                                        .opacity(isGrouped ? 0.3 : 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? Color.blue : .clear, lineWidth: 3)
                                        )
                                    if isOkeyMatch {
                                        Text("OKEY").font(.system(size: 7, weight: .black)).foregroundStyle(.orange)
                                    } else {
                                        Text(" ").font(.system(size: 7))
                                    }
                                }
                            }
                            .disabled(isGrouped)

                            if !isGrouped {
                                // Uzun bas → düzenle
                                Button {
                                    editingIndex = globalIdx
                                    editingTile = tile
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white)
                                        .background(Color.gray.clipShape(Circle()))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Action bar

    private var groupActionBar: some View {
        HStack(spacing: 10) {
            Button {
                makeGroup(type: .run)
            } label: {
                Label("Seri Yap", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedIndices.count >= 3 ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundStyle(selectedIndices.count >= 3 ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(selectedIndices.count < 3)

            Button {
                makeGroup(type: .set)
            } label: {
                Label("Takım Yap", systemImage: "square.grid.2x2.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedIndices.count >= 3 ? Color.green : Color.gray.opacity(0.3))
                    .foregroundStyle(selectedIndices.count >= 3 ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(selectedIndices.count < 3)

            if !selectedIndices.isEmpty {
                Button {
                    selectedIndices.removeAll()
                    groupError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .overlay(alignment: .bottom) {
            if let err = groupError {
                Text(err).font(.caption).foregroundStyle(.red).offset(y: 20)
            }
        }
    }

    // MARK: - Groups list

    private var groupsList: some View {
        VStack(spacing: 8) {
            ForEach(groups) { group in
                HStack(spacing: 8) {
                    Text(group.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(group.isValid ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(group.isValid ? .green : .red)
                        .clipShape(Capsule())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(group.tiles) { tile in
                                TileView(tile: tile).frame(width: 36, height: 44)
                            }
                        }
                    }

                    Text("\(group.total)p").font(.caption.bold()).foregroundStyle(.secondary)

                    Button {
                        removeGroup(group)
                    } label: {
                        Image(systemName: "trash").font(.caption).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Score card

    private var scoreCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(value: "\(groupsTotal)", label: "Grup puanı", color: .primary)
                Divider().frame(height: 40)
                statCell(value: canOpen ? "✓" : "✗", label: "El açma (101+)", color: canOpen ? .green : .red)
                Divider().frame(height: 40)
                statCell(value: "\(remainingScore)", label: "Kalan ceza", color: remainingScore == 0 ? .green : .red)
            }
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Group logic

    private func makeGroup(type: TileGroup.GroupType) {
        let indices = selectedIndices.sorted()
        let selected = indices.map { tiles[$0] }
        guard selected.count >= 3 else { return }

        let valid = type == .run ? validateRun(selected) : validateSet(selected)
        if !valid {
            groupError = type == .run
                ? "Geçersiz seri — aynı renk, ardışık sayılar olmalı (min 3)"
                : "Geçersiz takım — aynı sayı, farklı renkler olmalı (min 3, max 4)"
            return
        }

        let group = TileGroup(tiles: selected, type: type, isValid: true)
        groups.append(group)
        groupedIndices.formUnion(indices)
        selectedIndices.removeAll()
        groupError = nil
    }

    private func removeGroup(_ group: TileGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        let removedTiles = groups[idx].tiles
        // groupedIndices'ten kaldır
        for i in tiles.indices {
            if removedTiles.contains(where: { $0.id == tiles[i].id }) {
                groupedIndices.remove(i)
            }
        }
        groups.remove(at: idx)
    }

    private func validateRun(_ selected: [Tile]) -> Bool {
        let normals = selected.filter { $0.color != .joker && !isOkeyMatch($0) }
        let wildCount = selected.count - normals.count
        guard let color = normals.first?.color, normals.allSatisfy({ $0.color == color }) else {
            return wildCount == selected.count // tamamen joker ise geçersiz
        }
        let nums = normals.compactMap(\.number).sorted()
        guard let minN = nums.first, let maxN = nums.last else { return false }
        let span = maxN - minN + 1
        let unique = Set(nums).count == nums.count
        return unique && span <= selected.count && (span - nums.count) <= wildCount
    }

    private func validateSet(_ selected: [Tile]) -> Bool {
        guard selected.count >= 3, selected.count <= 4 else { return false }
        let normals = selected.filter { $0.color != .joker && !isOkeyMatch($0) }
        let wildCount = selected.count - normals.count
        guard let num = normals.first?.number, normals.allSatisfy({ $0.number == num }) else {
            return false
        }
        let colors = normals.map(\.color)
        return Set(colors).count == colors.count && (colors.count + wildCount) == selected.count
    }

    private func isOkeyMatch(_ tile: Tile) -> Bool {
        guard gostergeSet else { return tile.color == .joker }
        return (tile.color == gostergeColor && tile.number == okeyNumber) || tile.color == .joker
    }

    // MARK: - Helpers

    private func dashedBox(label: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
            .frame(width: 44, height: 52)
            .overlay(Text(label).font(.caption2).foregroundStyle(.secondary))
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
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
                TileView(tile: tile).frame(width: 52, height: 60)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16)).foregroundStyle(.red)
                    .background(Color(.systemBackground).clipShape(Circle()))
            }
            .offset(x: 6, y: -6)
        }
    }
}
