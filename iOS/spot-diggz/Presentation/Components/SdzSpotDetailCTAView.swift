import SwiftUI
import MapKit

struct SdzSpotDetailCTAView: View {
    let spot: SdzSpot
    var distance: String?

    @State private var showNavigationDialog: Bool = false

    private var hasOfficialUrl: Bool {
        guard let officialUrl = spot.parkAttributes?.officialUrl,
              !officialUrl.isEmpty,
              isAllowedUrl(officialUrl) else {
            return false
        }
        return true
    }

    private func isAllowedUrl(_ urlString: String) -> Bool {
        urlString.sdzIsAllowedUrl
    }

    var body: some View {
        VStack(spacing: SdzSpacing.md) {
            instagramCTA
            if hasOfficialUrl {
                officialSiteCTA
            }
            navigationCTA
        }
        .confirmationDialog("ナビを開く", isPresented: $showNavigationDialog, titleVisibility: .visible) {
            Button("Google Mapsで開く") {
                openGoogleMaps()
            }
            Button("Apple Mapsで開く") {
                openAppleMaps()
            }
        }
    }

    private var instagramCTA: some View {
        Button(action: {
            SdzInstagramLauncher.searchOnInstagram(spotName: spot.name)
        }) {
            HStack {
                Image(systemName: "camera")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Instagramでこの場所を検索")
                        .font(.subheadline)
                    Text("実際の写真・動画をチェック")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(SdzSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var officialSiteCTA: some View {
        if let officialUrl = spot.parkAttributes?.officialUrl,
           !officialUrl.isEmpty,
           isAllowedUrl(officialUrl),
           let url = URL(string: officialUrl) {
            Link(destination: url) {
                HStack {
                    Image(systemName: "globe")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("公式サイトを見る")
                            .font(.subheadline)
                        Text("営業時間・料金を確認")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(SdzSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous)
                        .stroke(Color.sdzStreet.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    private var navigationCTA: some View {
        Button(action: {
            showNavigationDialog = true
        }) {
            HStack {
                Image(systemName: "car")
                VStack(alignment: .leading, spacing: 2) {
                    Text(hasOfficialUrl ? "ナビを起動" : "ナビを起動して行く")
                        .font(.subheadline)
                    if let distance {
                        Text("現在地から\(distance)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(SdzSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous)
                    .fill(hasOfficialUrl ? Color(.systemBackground) : Color.sdzStreet.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous)
                    .stroke(Color.sdzStreet.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(spot.location == nil)
    }

    private func openGoogleMaps() {
        guard let location = spot.location else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        SdzMapNavigator.openGoogleMaps(destination: coordinate, mode: .drive)
    }

    private func openAppleMaps() {
        guard let location = spot.location else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        SdzMapNavigator.openAppleMaps(destination: coordinate, mode: .drive)
    }
}

extension String {
    var sdzIsAllowedUrl: Bool {
        guard let url = URL(string: self),
              let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "https" || scheme == "http"
    }
}
