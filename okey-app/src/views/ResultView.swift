import SwiftUI

struct ResultView: View {
    let result: GameResult

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScoreCard(result: result)

                if !result.runs.isEmpty {
                    GroupSection(title: "Seriler", groups: result.runs, accent: .blue)
                }

                if !result.sets.isEmpty {
                    GroupSection(title: "Takımlar", groups: result.sets, accent: .green)
                }

                if !result.remaining.isEmpty {
                    RemainingSection(tiles: result.remaining, score: result.totalScore)
                }
            }
            .padding()
        }
        .navigationTitle("Sonuç")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var shareText: String {
        result.isFinished
            ? "Elim tamam! \(result.groupsTotal) puan 🎉"
            : "\(result.totalScore) puan kaldı 🀄"
    }
}

// MARK: - Score card

struct ScoreCard: View {
    let result: GameResult

    var body: some View {
        VStack(spacing: 0) {
            // Ana durum
            HStack(spacing: 16) {
                Image(systemName: result.isFinished ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(result.isFinished ? .green : .red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.isFinished ? "El Tamam!" : "El Bitmedi")
                        .font(.title2.bold())

                    Text(result.isFinished ? "Tüm taşlar gruplanabildi" : "\(result.totalScore) puan elinizde kaldı")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()

            Divider()

            // Puan bilgileri
            HStack(spacing: 0) {
                statCell(
                    value: "\(result.groupsTotal)",
                    label: "Grup puanı",
                    color: .primary
                )

                Divider().frame(height: 44)

                statCell(
                    value: result.canOpen ? "✓" : "✗",
                    label: "El açma (101+)",
                    color: result.canOpen ? .green : .red
                )

                Divider().frame(height: 44)

                statCell(
                    value: result.isFinished ? "0" : "\(result.totalScore)",
                    label: "Kalan puan",
                    color: result.totalScore == 0 ? .secondary : .red
                )
            }
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Group section

struct GroupSection: View {
    let title: String
    let groups: [[Tile]]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accent)
                Spacer()
                Text("\(groups.count) grup · \(groupTotal) puan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(group) { tile in
                            TileView(tile: tile)
                        }

                        // Grup puanı
                        Text("\(group.compactMap(\.number).reduce(0, +))")
                            .font(.caption.bold())
                            .foregroundStyle(accent)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 2)
                }
                .padding(8)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var groupTotal: Int {
        groups.flatMap { $0 }.compactMap(\.number).reduce(0, +)
    }
}

// MARK: - Remaining section

struct RemainingSection: View {
    let tiles: [Tile]
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Kalan Taşlar")
                    .font(.headline)
                    .foregroundStyle(.red)
                Spacer()
                Text("\(score) puan ceza")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 46), spacing: 8)], spacing: 8) {
                ForEach(tiles) { tile in
                    TileView(tile: tile)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Tile view

struct TileView: View {
    let tile: Tile

    var body: some View {
        Text(tile.displayNumber)
            .font(.system(size: 16, weight: .bold))
            .frame(width: 44, height: 52)
            .background(tile.backgroundColor)
            .foregroundStyle(tile.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
    }
}
