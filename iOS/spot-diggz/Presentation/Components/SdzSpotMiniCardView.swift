import SwiftUI

struct SdzSpotMiniCardView: View {
    let spot: SdzSpot

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let typeLabel = spotTypeLabel {
                    Text(typeLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.up")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var spotTypeLabel: String? {
        if spot.parkAttributes != nil {
            return "スケートパーク"
        }
        if spot.tags.contains("パーク") {
            return "スケートパーク"
        }
        if spot.tags.contains("ストリート") {
            return "ストリート"
        }
        return nil
    }
}
