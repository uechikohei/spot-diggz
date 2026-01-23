import SwiftUI

/// A horizontally scrollable card for showcasing a spot on the map screen.
struct SpotCarouselCardView: View {
    let spot: SdzSpot
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                coverImage
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.headline)
                    .lineLimit(1)
                if let description = spot.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if !spot.tags.isEmpty {
                    Text(spot.tags.joined(separator: " / "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private var coverImage: some View {
        Group {
            if let firstUrl = spot.images.first, let url = URL(string: firstUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 170)
        .clipped()
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.white.opacity(0.8))
            )
    }
}

#if DEBUG
struct SpotCarouselCardView_Previews: PreviewProvider {
    static var previews: some View {
        SpotCarouselCardView(spot: SdzSpot.sample(id: "sample", name: "サンプルスポット"), isFavorite: true)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
