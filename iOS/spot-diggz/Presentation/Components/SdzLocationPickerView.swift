import SwiftUI
import MapKit

/// Map-based location picker for selecting a spot coordinate.
struct SdzLocationPickerView: View {
    @Binding var selectedLocation: SdzSpotLocation?
    var height: CGFloat = 320

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 8) {
            if #available(iOS 17.0, *) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if let location = selectedLocation {
                            Marker("選択位置", coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng))
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if selectedLocation == nil {
                            Text("地図をタップして位置を選択")
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding(8)
                        }
                    }
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                if let coordinate = proxy.convert(value.location, from: .local) {
                                    selectedLocation = SdzSpotLocation(lat: coordinate.latitude, lng: coordinate.longitude)
                                    cameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    )
                                }
                            }
                    )
                }
            } else {
                Map(
                    coordinateRegion: .constant(defaultRegion),
                    annotationItems: selectedLocation.map { [$0] } ?? []
                ) { location in
                    MapMarker(
                        coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .onAppear {
            updateCameraPosition()
        }
        .onChangeCompat(of: selectedLocation) {
            updateCameraPosition()
        }
    }

    private var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    private func updateCameraPosition() {
        if let location = selectedLocation {
            let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        } else {
            cameraPosition = .region(defaultRegion)
        }
    }
}

private extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(of value: T, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) {
                action()
            }
        } else {
            self.onChange(of: value) { (_: T) in
                action()
            }
        }
    }
}

#if DEBUG
struct SdzLocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        SdzLocationPickerView(selectedLocation: .constant(SdzSpotLocation(lat: 35.6812, lng: 139.7671)))
    }
}
#endif
