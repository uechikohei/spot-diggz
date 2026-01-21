import SwiftUI
import MapKit

/// Detail view for a saved route.
struct RouteDetailView: View {
    let route: SdzRoute
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var showNavigationDialog: Bool = false

    var body: some View {
        List {
            if let mapRegion = mapRegion {
                Section {
                    mapView(region: mapRegion)
                        .frame(height: 220)
                        .cornerRadius(12)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section(header: Text("ルート情報")) {
                LabeledContent("移動手段", value: route.mode.label)
                LabeledContent("スポット数", value: "\(route.spots.count)")
            }

            Section(header: Text("ナビ")) {
                Button {
                    showNavigationDialog = true
                } label: {
                    Label("ナビを開く", systemImage: "arrow.triangle.turn.up.right.circle")
                }
                .disabled(routeCoordinates.isEmpty)
                Text("Google Maps/Apple Mapsでルートを開始できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("スポット一覧")) {
                ForEach(route.spots) { spot in
                    NavigationLink(destination: SpotDetailView(spot: spot)) {
                        SpotCardView(spot: spot)
                    }
                }
            }
        }
        .navigationTitle(route.name)
        .onAppear {
            if let mapRegion = mapRegion {
                region = mapRegion
            }
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

    private var mapRegion: MKCoordinateRegion? {
        guard let firstLocation = route.spots.first?.location else {
            return nil
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: firstLocation.lat, longitude: firstLocation.lng),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        route.spots.compactMap { spot in
            guard let location = spot.location else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        }
    }

    private func openGoogleMaps() {
        guard let destination = routeCoordinates.last else {
            return
        }
        let waypoints = Array(routeCoordinates.dropLast())
        SdzMapNavigator.openGoogleMaps(
            destination: destination,
            waypoints: waypoints,
            mode: route.mode.navigationMode
        )
    }

    private func openAppleMaps() {
        guard let destination = routeCoordinates.last else {
            return
        }
        SdzMapNavigator.openAppleMaps(
            destination: destination,
            mode: route.mode.navigationMode
        )
    }

    @ViewBuilder
    private func mapView(region: MKCoordinateRegion) -> some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .region(region)) {
                ForEach(route.spots.compactMap { $0.location }, id: \.id) { location in
                    Marker("スポット", coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng))
                }
            }
        } else {
            Map(
                coordinateRegion: $region,
                annotationItems: route.spots.compactMap { $0.location }
            ) { location in
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng))
            }
        }
    }
}

#if DEBUG
struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RouteDetailView(route: SdzRoute(
                routeId: "sample",
                name: "サンプルルート",
                mode: .walk,
                spots: [SdzSpot.sample(id: "sample", name: "サンプル")],
                createdAt: Date()
            ))
        }
    }
}
#endif
