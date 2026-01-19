import SwiftUI
import MapKit
import CoreLocation

/// Home screen showing a map with spot cards and lightweight filtering.
struct HomeView: View {
    @EnvironmentObject var appState: SdzAppState
    @State private var searchText: String = ""
    @State private var selectedTag: String?
    @State private var spots: [SdzSpot] = []
    @State private var selectedSpot: SdzSpot?
    @State private var focusedSpotId: String?
    @State private var draftPinLocation: SdzSpotLocation?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    homeContent
                }
            } else {
                NavigationView {
                    homeContent
                }
            }
        }
        .sheet(item: $selectedSpot) { spot in
            if #available(iOS 16.0, *) {
                NavigationStack {
                    SpotDetailView(spot: spot)
                }
            } else {
                NavigationView {
                    SpotDetailView(spot: spot)
                }
            }
        }
    }

    private var homeContent: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                mapContent
                    .ignoresSafeArea()
                topOverlay
            }
            .safeAreaInset(edge: .bottom) {
                bottomOverlay(height: proxy.size.height * 0.33)
            }
        }
        .onAppear {
            setInitialCameraPositionIfNeeded()
            fetchSpots()
        }
        .navigationTitle("スポット")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Map Content
    @ViewBuilder
    private var mapContent: some View {
        if #available(iOS 17.0, *) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(annotationItems) { annotation in
                        Annotation("", coordinate: annotation.coordinate) {
                            if annotation.isDraft {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            } else if let spot = annotation.spot {
                                Button(action: {
                                    selectSpot(spot)
                                }) {
                                    Image(systemName: focusedSpotId == spot.spotId
                                          ? "mappin.circle.fill" : "mappin.circle")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            if let coordinate = proxy.convert(value.location, from: .local) {
                                handleMapTap(coordinate)
                            }
                        }
                )
            }
        } else {
            Map(coordinateRegion: $region, annotationItems: annotationItems) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    if annotation.isDraft {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else if let spot = annotation.spot {
                        Button(action: {
                            selectSpot(spot)
                        }) {
                            Image(systemName: focusedSpotId == spot.spotId
                                  ? "mappin.circle.fill" : "mappin.circle")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .onTapGesture {
                handleMapTap(region.center)
            }
        }
    }

    private var topOverlay: some View {
        VStack(spacing: 10) {
            searchField
            if !tagOptions.isEmpty {
                tagChips
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func bottomOverlay(height: CGFloat) -> some View {
        VStack(spacing: 12) {
            if let draftPinLocation = draftPinLocation {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.blue)
                    Text("選択した位置から投稿できます")
                        .font(.caption)
                    Spacer()
                    Button("投稿へ") {
                        openPostForDraftPin(draftPinLocation)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("クリア") {
                        clearDraftPin()
                    }
                    .buttonStyle(.bordered)
                }
            }
            if isLoading {
                ProgressView("読み込み中...")
                    .padding(.vertical, 12)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("再読み込み") {
                        fetchSpots()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 12)
            } else if filteredSpots.isEmpty {
                VStack(spacing: 8) {
                    Text("スポットが見つかりません")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("更新") {
                        fetchSpots()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(filteredSpots) { spot in
                            SpotCarouselCardView(
                                spot: spot,
                                isFavorite: appState.isFavorite(spot)
                            )
                            .onTapGesture {
                                selectSpot(spot)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("スポットを検索", text: $searchText)
                .textInputAutocapitalization(.never)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "すべて",
                    isSelected: selectedTag == nil
                ) {
                    selectedTag = nil
                }
                ForEach(tagOptions, id: \.self) { tag in
                    FilterChip(
                        title: tag,
                        isSelected: selectedTag == tag
                    ) {
                        selectedTag = tag
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private struct FilterChip: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.accentColor : Color(.systemBackground).opacity(0.85))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private struct AnnotationItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let spot: SdzSpot?
        let isDraft: Bool
    }

    private var annotationItems: [AnnotationItem] {
        var items: [AnnotationItem] = filteredSpots.compactMap { spot in
            if let location = spot.location {
                return AnnotationItem(
                    id: spot.spotId,
                    coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng),
                    spot: spot,
                    isDraft: false
                )
            }
            return nil
        }
        if let draftPinLocation = draftPinLocation {
            items.append(
                AnnotationItem(
                    id: "draft-pin",
                    coordinate: CLLocationCoordinate2D(latitude: draftPinLocation.lat, longitude: draftPinLocation.lng),
                    spot: nil,
                    isDraft: true
                )
            )
        }
        return items
    }

    private var tagOptions: [String] {
        let tags = spots.flatMap(\.tags).filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }

    /// Filters spots based on the search text and selected tag.
    private var filteredSpots: [SdzSpot] {
        spots.filter { spot in
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let target = searchText.lowercased()
                matchesSearch =
                    spot.name.lowercased().contains(target)
                    || (spot.description?.lowercased().contains(target) ?? false)
                    || spot.tags.contains(where: { $0.lowercased().contains(target) })
            }

            let matchesTag: Bool
            if let selectedTag = selectedTag {
                matchesTag = spot.tags.contains(selectedTag)
            } else {
                matchesTag = true
            }

            return matchesSearch && matchesTag
        }
    }

    private func selectSpot(_ spot: SdzSpot) {
        focusedSpotId = spot.spotId
        draftPinLocation = nil
        focusOnSpot(spot)
        selectedSpot = spot
    }

    private func focusOnSpot(_ spot: SdzSpot) {
        guard let location = spot.location else {
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        region = newRegion
        if #available(iOS 17.0, *) {
            cameraPosition = .region(newRegion)
        }
    }

    private func setInitialCameraPositionIfNeeded() {
        if #available(iOS 17.0, *) {
            if case .automatic = cameraPosition {
                cameraPosition = .region(region)
            }
        }
    }

    private func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        if let spot = nearestSpot(to: coordinate, within: 60) {
            selectSpot(spot)
            return
        }
        draftPinLocation = SdzSpotLocation(lat: coordinate.latitude, lng: coordinate.longitude)
    }

    private func nearestSpot(to coordinate: CLLocationCoordinate2D, within meters: CLLocationDistance) -> SdzSpot? {
        let tapLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return filteredSpots.first { spot in
            guard let location = spot.location else {
                return false
            }
            let spotLocation = CLLocation(latitude: location.lat, longitude: location.lng)
            return tapLocation.distance(from: spotLocation) <= meters
        }
    }

    private func openPostForDraftPin(_ location: SdzSpotLocation) {
        appState.draftPostLocation = location
        appState.selectedTab = .post
        draftPinLocation = nil
    }

    private func clearDraftPin() {
        draftPinLocation = nil
    }

    /// Loads the list of spots from the API.
    private func fetchSpots() {
        isLoading = true
        errorMessage = nil
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        Task {
            do {
                let result = try await apiClient.fetchSpots(includeAuth: true)
                await MainActor.run {
                    self.spots = result
                    self.isLoading = false
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.errorMessage = message
                    self.isLoading = false
                }
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SdzAppState())
    }
}
#endif
