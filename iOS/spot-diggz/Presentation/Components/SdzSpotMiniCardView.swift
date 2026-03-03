import SwiftUI

struct SdzSpotMiniCardView: View {
    let spot: SdzSpot
    var distance: String?
    var onTapDetail: (() -> Void)?
    var onTapNav: (() -> Void)?

    var body: some View {
        VStack(spacing: SdzSpacing.sm) {
            HStack(spacing: SdzSpacing.md) {
                VStack(alignment: .leading, spacing: SdzSpacing.xs) {
                    Text(spot.name)
                        .font(SdzTypography.headline)
                        .foregroundColor(.sdzTextPrimary)
                        .lineLimit(1)
                    HStack(spacing: SdzSpacing.xs) {
                        Text(spot.sdzTypeLabel)
                            .font(SdzTypography.caption1)
                            .foregroundColor(.sdzTextSecondary)
                        if let distance {
                            Text("・")
                                .font(SdzTypography.caption1)
                                .foregroundColor(.sdzTextTertiary)
                            Text(distance)
                                .font(SdzTypography.caption1)
                                .foregroundColor(.sdzTextSecondary)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .font(SdzTypography.caption1)
                    .foregroundColor(.sdzTextTertiary)
            }

            if onTapDetail != nil || onTapNav != nil {
                HStack(spacing: SdzSpacing.sm) {
                    if let onTapNav {
                        Button(action: onTapNav) {
                            Label("ナビ", systemImage: "car")
                                .font(SdzTypography.caption1)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.sdzStreet)
                    }
                    if let onTapDetail {
                        Button(action: onTapDetail) {
                            Label("詳細を見る", systemImage: "info.circle")
                                .font(SdzTypography.caption1)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.sdzStreet)
                    }
                }
            }
        }
        .padding(.horizontal, SdzSpacing.md + 2)
        .padding(.vertical, SdzSpacing.sm + 2)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: SdzRadius.lg, style: .continuous))
    }
}
