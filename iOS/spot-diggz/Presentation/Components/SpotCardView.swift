import SwiftUI

/// A card representing a single skate spot in the list.
struct SpotCardView: View {
    let spot: SdzSpot

    var body: some View {
        HStack(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.headline)
                if let description = spot.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                if !spot.tags.isEmpty {
                    Text(spot.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(spot.trustLevel == .verified ? "✓" : "？")
                .font(.headline)
                .foregroundColor(spot.trustLevel == .verified ? .green : .orange)
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct SpotCardView_Previews: PreviewProvider {
    static var previews: some View {
        SpotCardView(spot: SdzSpot.sample(id: "sample", name: "サンプルスポット"))
            .previewLayout(.sizeThatFits)
    }
}
#endif