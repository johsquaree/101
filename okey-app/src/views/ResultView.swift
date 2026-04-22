import SwiftUI

struct ResultView: View {
    let result: GameResult

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScoreHeader(result: result)

                if result.canOpen && !result.isFinished {
                    OpenBanner(groupsTotal: result.groupsTotal)
                }

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
            ? "Elim tamam! Açabilirim 🎉"
            : "\(result.totalScore) puan kaldı, açamıyorum henüz 🀄"
    }
}

struct ScoreHeader: View {
    let result: GameResult

    var body: some View {
        VStack(spacing: 12) {
            if result.isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("El Tamam!")
                    .font(.title.bold())
                Text("Açabilirsiniz!")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)
                Text("\(result.totalScore)")
                    .font(.system(size: 52, weight: .bold))
                Text("puan kaldı")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct OpenBanner: View {
    let groupsTotal: Int

    var body: some View {
        HStack {
            Image(systemName: "hand.thumbsup.fill")
            Text("El açabilirsin! Grupların toplamı: \(groupsTotal) puan")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct GroupSection: View {
    let title: String
    let groups: [[Tile]]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(accent)

            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                HStack(spacing: 6) {
                    ForEach(group) { tile in
                        TileView(tile: tile)
                    }
                }
                .padding(8)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct RemainingSection: View {
    let tiles: [Tile]
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Gruplanamayan Taşlar")
                    .font(.headline)
                    .foregroundStyle(.red)
                Spacer()
                Text("\(score) puan")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                ForEach(tiles) { tile in
                    TileView(tile: tile)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TileView: View {
    let tile: Tile

    var body: some View {
        VStack(spacing: 2) {
            Text(tile.displayNumber)
                .font(.system(size: 15, weight: .bold))
        }
        .frame(width: 40, height: 48)
        .background(tile.backgroundColor)
        .foregroundStyle(tile.foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}
