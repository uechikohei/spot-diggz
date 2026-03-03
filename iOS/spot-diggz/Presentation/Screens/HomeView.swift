import SwiftUI
import MapKit
import CoreLocation

/// Home screen showing a full-screen map with floating overlay.
struct HomeView: View {
    @EnvironmentObject var appState: SdzAppState
    @EnvironmentObject var locationManager: SdzLocationManager
    @State private var searchText: String = ""
    @State private var selectedSpotType: SdzSpotType?
    @State private var selectedTags: Set<String> = []
    @State private var isFilterExpanded: Bool = false
    @State private var spots: [SdzSpot] = []
    @State private var selectedSpot: SdzSpot?
    @State private var detailSpot: SdzSpot?
    @State private var focusedSpotId: String?
    @State private var expandedClusterSpotIds: Set<String> = []
    @State private var draftPinLocation: SdzSpotLocation?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var fetchTask: Task<Void, Never>?
    @State private var shouldApplySearchTextFilter: Bool = true
    @State private var showPostLocationAlert: Bool = false

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .top) {
            SdzFullScreenMapView(
                annotations: annotationItems,
                region: $region,
                focusedSpotId: focusedSpotId,
                expandedSpotIds: expandedClusterSpotIds,
                onTapCoordinate: { coordinate in
                    handleMapTap(coordinate)
                },
                onSelectSpot: { spot in
                    selectSpot(spot)
                },
                onSelectCluster: { spotIds in
                    expandedClusterSpotIds = Set(spotIds)
                    selectedSpot = nil
                    focusedSpotId = nil
                    draftPinLocation = nil
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                SdzMapOverlayView(
                    searchText: $searchText,
                    selectedSpotType: $selectedSpotType,
                    selectedTags: $selectedTags,
                    isFilterExpanded: $isFilterExpanded,
                    tagOptions: tagOptions
                )
                .padding(.top, 4)

                Spacer()

                HStack {
                    statusOverlay
                    Spacer()
                    VStack(spacing: SdzSpacing.md) {
                        Button(action: {
                            locationManager.requestCurrentLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .padding(SdzSpacing.md)
                                .foregroundColor(.white)
                                .background(Color.sdzStreet)
                                .clipShape(Circle())
                                .sdzShadow(.md)
                        }
                        .accessibilityLabel("現在地に移動")

                        Button(action: {
                            handleTapCreateSpotButton()
                        }) {
                            Image(systemName: "plus")
                                .font(SdzTypography.title2)
                                .foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(
                                    Circle()
                                        .fill(draftPinLocation == nil ? Color.sdzStreet : Color.sdzError)
                                )
                                .sdzShadow(.lg)
                        }
                        .accessibilityLabel("選択した位置で投稿")
                    }
                }
                .padding(.horizontal, SdzSpacing.lg)
                .padding(.bottom, SdzSpacing.md)
            }
        }
        .sheet(item: $selectedSpot) { spot in
            SdzSpotBottomSheetView(
                spot: spot,
                distance: distanceText(for: spot),
                onTapDetail: {
                    let target = spot
                    selectedSpot = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        detailSpot = target
                    }
                },
                onTapNav: {}
            )
            .presentationDetents([.fraction(0.18), .fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $detailSpot) { spot in
            if #available(iOS 16.0, *) {
                NavigationStack {
                    SpotDetailView(spot: spot)
                }
                .presentationDetents([.fraction(0.4), .fraction(0.9)])
                .presentationDragIndicator(.visible)
            } else {
                NavigationView {
                    SpotDetailView(spot: spot)
                }
            }
        }
        .onAppear {
            setInitialCameraPositionIfNeeded()
            fetchSpots(query: currentSearchQuery())
            applyPendingMapFocusIfNeeded()
        }
        .onReceive(locationManager.$currentCoordinate) { coordinate in
            guard let coordinate = coordinate else {
                return
            }
            let newRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            withAnimation(.easeInOut(duration: 0.24)) {
                region = newRegion
                if #available(iOS 17.0, *) {
                    cameraPosition = .region(newRegion)
                }
            }
        }
        .onChange(of: searchText) {
            scheduleSearch()
        }
        .onChange(of: selectedSpotType) {
            scheduleSearch()
        }
        .onChange(of: selectedTags) {
            scheduleSearch()
        }
        .onChange(of: appState.pendingMapFocusLocation) { _, _ in
            applyPendingMapFocusIfNeeded()
        }
        .alert("投稿位置を選択してください", isPresented: $showPostLocationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("地図をタップしてピンを置いてから、右下の＋ボタンを押してください。")
        }
    }

    // MARK: - Status Overlay

    @ViewBuilder
    private var statusOverlay: some View {
        if isLoading {
            statusBanner(title: "読み込み中...", tone: .secondary, actionTitle: nil, action: nil)
        } else if let errorMessage = errorMessage {
            statusBanner(title: errorMessage, tone: .error, actionTitle: "再読み込み") {
                fetchSpots(query: currentSearchQuery())
            }
        } else if filteredSpots.isEmpty {
            statusBanner(title: "スポットが見つかりません", tone: .secondary, actionTitle: "更新") {
                fetchSpots(query: currentSearchQuery())
            }
        }
    }

    private enum StatusTone {
        case secondary
        case error
    }

    private func statusBanner(title: String, tone: StatusTone, actionTitle: String?, action: (() -> Void)?) -> some View {
        HStack(spacing: SdzSpacing.md) {
            Text(title)
                .font(SdzTypography.caption1)
                .foregroundColor(tone == .error ? .sdzError : .sdzTextSecondary)
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, SdzSpacing.md + 2)
        .padding(.vertical, SdzSpacing.sm + 2)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: SdzRadius.md, style: .continuous))
    }

    // MARK: - Annotation Items

    private var annotationItems: [SdzMapAnnotationItem] {
        var items: [SdzMapAnnotationItem] = filteredSpots.compactMap { spot in
            if let location = spot.location {
                return SdzMapAnnotationItem(
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
                SdzMapAnnotationItem(
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
        let typeTags = Set(SdzSpotType.allCases.map(\.tagValue))
        let tags = spots
            .flatMap(\.tags)
            .filter { !$0.isEmpty && !typeTags.contains($0) }
        return Array(Set(tags)).sorted()
    }

    private var filteredSpots: [SdzSpot] {
        spots
    }

    // MARK: - Distance

    private func distanceText(for spot: SdzSpot) -> String? {
        guard let location = spot.location,
              let meters = locationManager.distanceTo(location) else {
            return nil
        }
        return SdzDistanceCalculator.formattedDistance(meters: meters)
    }

    // MARK: - Actions

    private func selectSpot(_ spot: SdzSpot) {
        focusedSpotId = spot.spotId
        draftPinLocation = nil
        selectedSpot = spot
        expandedClusterSpotIds = []
    }

    private func focusOnCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        region = newRegion
        if #available(iOS 17.0, *) {
            cameraPosition = .region(newRegion)
        }
    }

    private func applyPendingMapFocusIfNeeded() {
        guard let location = appState.pendingMapFocusLocation else {
            return
        }
        draftPinLocation = location
        focusOnCoordinate(CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng))
        appState.pendingMapFocusLocation = nil
        appState.pendingMapFocusName = nil
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
        selectedSpot = nil
        focusedSpotId = nil
        expandedClusterSpotIds = []
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
        appState.selectedTab = .map
        appState.isPostComposerPresented = true
        draftPinLocation = nil
    }

    private func handleTapCreateSpotButton() {
        guard let draftPinLocation else {
            showPostLocationAlert = true
            return
        }
        openPostForDraftPin(draftPinLocation)
    }

    // MARK: - Data

    private func fetchSpots(query: SdzSpotSearchQuery?, forceRefresh: Bool = false) {
        fetchTask?.cancel()
        isLoading = true
        errorMessage = nil
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        fetchTask = Task {
            if !forceRefresh, let cached = await SdzSpotCache.shared.cachedSpots(for: query) {
                await MainActor.run {
                    self.spots = cached
                    let validSpotIds = Set(cached.map(\.spotId))
                    self.expandedClusterSpotIds = self.expandedClusterSpotIds.intersection(validSpotIds)
                    self.isLoading = false
                }
                return
            }
            do {
                var result = try await apiClient.fetchSpots(query: query, includeAuth: true)
                #if DEBUG
                if !result.contains(where: { $0.approvalStatus == .approved }) {
                    result.append(
                        SdzSpot(
                            spotId: "debug-approved-park",
                            name: "承認済みパーク（デバッグ）",
                            description: nil,
                            location: SdzSpotLocation(lat: 35.6812, lng: 139.7671),
                            tags: ["パーク"],
                            images: [],
                            approvalStatus: .approved,
                            parkAttributes: SdzSpotParkAttributes(
                                officialUrl: nil,
                                businessHours: nil,
                                accessInfo: nil,
                                phoneNumber: nil
                            ),
                            streetAttributes: nil,
                            userId: "debug",
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    )
                }
                if !result.contains(where: { $0.approvalStatus != .approved }) {
                    result.append(
                        SdzSpot(
                            spotId: "debug-pending-street",
                            name: "未承認ストリート（デバッグ）",
                            description: nil,
                            location: SdzSpotLocation(lat: 35.6762, lng: 139.7649),
                            tags: ["ストリート"],
                            images: [],
                            approvalStatus: .pending,
                            parkAttributes: nil,
                            streetAttributes: SdzStreetAttributes(
                                surfaceMaterial: nil,
                                surfaceCondition: nil,
                                sections: nil,
                                difficulty: nil,
                                notes: nil
                            ),
                            userId: "debug",
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    )
                }
                #endif
                await SdzSpotCache.shared.store(spots: result, for: query)
                await MainActor.run {
                    self.spots = result
                    let validSpotIds = Set(result.map(\.spotId))
                    self.expandedClusterSpotIds = self.expandedClusterSpotIds.intersection(validSpotIds)
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

    private func scheduleSearch() {
        searchTask?.cancel()
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchRegion = region
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else {
                return
            }
            var searchedCoordinate: CLLocationCoordinate2D?
            if !trimmedSearchText.isEmpty {
                searchedCoordinate = await resolveSearchCoordinate(
                    keyword: trimmedSearchText,
                    preferredRegion: searchRegion
                )
            }
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                if trimmedSearchText.isEmpty {
                    shouldApplySearchTextFilter = true
                } else if let searchedCoordinate {
                    shouldApplySearchTextFilter = false
                    selectedSpot = nil
                    focusedSpotId = nil
                    focusOnCoordinate(searchedCoordinate)
                } else {
                    shouldApplySearchTextFilter = true
                }
                fetchSpots(query: currentSearchQuery())
            }
        }
    }

    private func currentSearchQuery() -> SdzSpotSearchQuery? {
        let query = SdzSpotSearchQuery(
            text: shouldApplySearchTextFilter ? searchText : nil,
            spotType: selectedSpotType?.rawValue,
            tags: Array(selectedTags)
        )
        return query.isEmpty ? nil : query
    }

    private func resolveSearchCoordinate(
        keyword: String,
        preferredRegion: MKCoordinateRegion
    ) async -> CLLocationCoordinate2D? {
        if let coordinate = await performLocationSearch(
            keyword: keyword,
            region: preferredRegion
        ) {
            return coordinate
        }
        let worldRegion = MKCoordinateRegion(MKMapRect.world)
        return await performLocationSearch(
            keyword: keyword,
            region: worldRegion
        )
    }

    private func performLocationSearch(
        keyword: String,
        region: MKCoordinateRegion
    ) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = keyword
            request.resultTypes = [.address, .pointOfInterest]
            request.pointOfInterestFilter = .includingAll
            request.region = region
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                continuation.resume(returning: response?.mapItems.first?.placemark.coordinate)
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SdzAppState())
            .environmentObject(SdzLocationManager())
    }
}
#endif
