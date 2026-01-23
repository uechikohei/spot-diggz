import SwiftUI

/// A card representing a single skate spot in the list.
struct SpotCardView: View {
    let spot: SdzSpot

    var body: some View {
        HStack(alignment: .top) {
            if let firstUrl = spot.images.first, let url = URL(string: firstUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }

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
            approvalStatusView
        }
        .padding(.vertical, 8)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 80)
            .cornerRadius(8)
    }

    @ViewBuilder
    private var approvalStatusView: some View {
        switch spot.approvalStatus {
        case .approved:
            Text("✓")
                .font(.headline)
                .foregroundColor(.green)
        case .pending:
            Text("審査中")
                .font(.caption)
                .foregroundColor(.orange)
        case .rejected:
            Text("差戻し")
                .font(.caption)
                .foregroundColor(.red)
        case .none:
            Text("未申請")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
