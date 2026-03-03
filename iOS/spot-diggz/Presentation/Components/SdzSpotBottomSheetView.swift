import SwiftUI
import MapKit

struct SdzSpotBottomSheetView: View {
    let spot: SdzSpot
    var distance: String?
    var onTapDetail: () -> Void
    var onTapNav: () -> Void

    @State private var showNavigationDialog: Bool = false

    var body: some View {
        VStack(spacing: SdzSpacing.md) {
            SdzSpotMiniCardView(
                spot: spot,
                distance: distance,
                onTapDetail: onTapDetail,
                onTapNav: {
                    showNavigationDialog = true
                }
            )
        }
        .padding(.horizontal, SdzSpacing.md)
        .padding(.vertical, SdzSpacing.sm)
        .confirmationDialog("ナビを開く", isPresented: $showNavigationDialog, titleVisibility: .visible) {
            Button("Google Mapsで開く") {
                guard let location = spot.location else { return }
                let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                SdzMapNavigator.openGoogleMaps(destination: coordinate, mode: .drive)
            }
            Button("Apple Mapsで開く") {
                guard let location = spot.location else { return }
                let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                SdzMapNavigator.openAppleMaps(destination: coordinate, mode: .drive)
            }
        }
    }
}
