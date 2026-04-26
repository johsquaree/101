import SwiftUI

struct TileEditSheet: View {
    let tile: Tile
    let onSave: (Tile) -> Void
    let onCancel: () -> Void

    @State private var selectedColor: TileColor
    @State private var selectedNumber: Int
    @State private var isJoker: Bool

    init(tile: Tile, onSave: @escaping (Tile) -> Void, onCancel: @escaping () -> Void) {
        self.tile = tile
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedColor = State(initialValue: tile.color == .joker ? .black : tile.color)
        _selectedNumber = State(initialValue: tile.number ?? 1)
        _isJoker = State(initialValue: tile.color == .joker)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Önizleme
                let preview = isJoker
                    ? Tile(color: .joker, number: nil, isOkey: false)
                    : Tile(color: selectedColor, number: selectedNumber, isOkey: false)

                TileView(tile: preview)
                    .scaleEffect(2)
                    .frame(height: 80)
                    .padding(.top, 20)

                // Joker toggle
                Toggle("Joker taş", isOn: $isJoker)
                    .padding(.horizontal)

                if !isJoker {
                    // Renk seçimi
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Renk")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 16) {
                            ForEach([TileColor.red, .yellow, .blue, .black], id: \.self) { color in
                                ColorOption(color: color, isSelected: selectedColor == color) {
                                    selectedColor = color
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Sayı seçimi
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sayı")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                            ForEach(1...13, id: \.self) { num in
                                Button {
                                    selectedNumber = num
                                } label: {
                                    Text("\(num)")
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: 40, height: 40)
                                        .background(selectedNumber == num ? Color.accentColor : Color(.secondarySystemBackground))
                                        .foregroundStyle(selectedNumber == num ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Taşı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let updated = isJoker
                            ? Tile(color: .joker, number: nil, isOkey: false)
                            : Tile(color: selectedColor, number: selectedNumber, isOkey: false)
                        onSave(updated)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Color option button

struct ColorOption: View {
    let color: TileColor
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : .clear, radius: 6)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(checkColor)
                }
            }
        }
    }

    private var circleColor: Color {
        switch color {
        case .red:    return .red
        case .yellow: return .yellow
        case .blue:   return .blue
        case .black:  return .black
        default:      return .gray
        }
    }

    private var checkColor: Color {
        color == .yellow ? .black : .white
    }
}
