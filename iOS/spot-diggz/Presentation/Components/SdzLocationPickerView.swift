import SwiftUI
import MapKit
import Combine

/// Map-based location picker for selecting a spot coordinate.
struct SdzLocationPickerView: View {
    @Binding var selectedLocation: SdzSpotLocation?
    var height: CGFloat = 320

    @State private var cameraPosition: MapCameraPosition = .automatic
    @StateObject private var searchViewModel = SdzLocationSearchViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                if #available(iOS 17.0, *) {
                    MapReader { proxy in
                        Map(position: $cameraPosition) {
                            if let location = selectedLocation {
                                Marker(
                                    "選択位置",
                                    coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                                )
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
                                        updateSelection(with: coordinate)
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
            searchOverlay
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

    private func updateSelection(with coordinate: CLLocationCoordinate2D) {
        selectedLocation = SdzSpotLocation(lat: coordinate.latitude, lng: coordinate.longitude)
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    private var searchOverlay: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("場所を検索", text: $searchViewModel.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchViewModel.query.isEmpty {
                    Button {
                        searchViewModel.reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            if searchViewModel.shouldShowResults {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchViewModel.results, id: \.self) { completion in
                            Button {
                                searchViewModel.resolve(completion: completion) { coordinate in
                                    guard let coordinate = coordinate else {
                                        return
                                    }
                                    updateSelection(with: coordinate)
                                    searchViewModel.applySelection(completion)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            if completion != searchViewModel.results.last {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 180)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
        }
        .padding(8)
    }
}

final class SdzLocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query: String = "" {
        didSet {
            completer.queryFragment = query
            if query.isEmpty {
                results = []
            }
        }
    }
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    var shouldShowResults: Bool {
        !query.isEmpty && !results.isEmpty
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }

    func resolve(completion: MKLocalSearchCompletion, handler: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            let coordinate = response?.mapItems.first?.location.coordinate
            DispatchQueue.main.async {
                handler(coordinate)
            }
        }
    }

    func applySelection(_ completion: MKLocalSearchCompletion) {
        query = completion.title
        results = []
    }

    func reset() {
        query = ""
        results = []
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
