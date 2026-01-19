import SwiftUI
import MapKit

/// A screen displaying detailed information about a specific spot.
struct SpotDetailView: View {
    @EnvironmentObject var appState: SdzAppState
    @State private var spot: SdzSpot

    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var approvalMessage: String?
    @State private var routeMessage: String?
    @State private var isRequestingApproval: Bool = false
    @State private var showRouteBuilder: Bool = false

    init(spot: SdzSpot) {
        _spot = State(initialValue: spot)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if spot.images.isEmpty {
                    placeholderImage
                } else {
                    TabView {
                        ForEach(spot.images, id: \.self) { urlString in
                            if let url = URL(string: urlString) {
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
                    }
                    .frame(height: 220)
                    .tabViewStyle(.page)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(spot.name)
                        .font(.title)
                        .bold()
                    HStack {
                        Text("公開ステータス: \(approvalStatusText)")
                            .font(.subheadline)
                            .foregroundColor(approvalStatusColor)
                        Spacer()
                    }
                    if !spot.tags.isEmpty {
                        Text(spot.tags.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let description = spot.description {
                        Text(description)
                            .padding(.top, 8)
                    }
                    // Map preview
                    if let location = spot.location {
                        let coord = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                        if #available(iOS 17.0, *) {
                            Map(initialPosition: .region(MKCoordinateRegion(center: coord,
                                                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                                Marker(spot.name, coordinate: coord)
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                        } else {
                            Map(coordinateRegion: $region, annotationItems: [location]) { loc in
                                MapMarker(coordinate: CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.lng))
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                            .onAppear {
                                region = MKCoordinateRegion(
                                    center: coord,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        }
                    }
                    // Actions
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: {
                                appState.toggleFavorite(spot)
                            }) {
                                Label(
                                    isFavorite ? "お気に入り解除" : "お気に入りに追加",
                                    systemImage: isFavorite ? "heart.fill" : "heart"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            Button(action: {
                                toggleRouteDraft()
                            }) {
                                Label(
                                    isInRouteDraft ? "ルートから外す" : "ルートに追加",
                                    systemImage: isInRouteDraft ? "bookmark.fill" : "bookmark"
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        HStack {
                            Button(action: {
                                // TODO: Open external map
                            }) {
                                Label("ナビ", systemImage: "car")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        if isInRouteDraft {
                            Button("ルート作成へ") {
                                showRouteBuilder = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                    if let routeMessage = routeMessage {
                        Text(routeMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isOwnedByCurrentUser {
                        if let approvalMessage = approvalMessage {
                            Text(approvalMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if canRequestApproval {
                            Button(isRequestingApproval ? "申請中..." : "承認を申請") {
                                requestApproval()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isRequestingApproval)
                        }
                        NavigationLink("投稿を編集") {
                            EditSpotView(spot: spot)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("スポット詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRouteBuilder) {
            RouteBuilderView()
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 200)
            .overlay(
                Text("画像")
                    .foregroundColor(.white)
            )
    }

    private var isFavorite: Bool {
        appState.isFavorite(spot)
    }

    private var isInRouteDraft: Bool {
        appState.routeDraftSpots.contains(where: { $0.spotId == spot.spotId })
    }

    private var isOwnedByCurrentUser: Bool {
        guard let currentUserId = appState.authUserId else {
            return false
        }
        return spot.userId == currentUserId
    }

    private var approvalStatusText: String {
        switch spot.approvalStatus {
        case .approved:
            return "承認済"
        case .pending:
            return "審査中"
        case .rejected:
            return "差戻し"
        case .none:
            return "未申請"
        }
    }

    private var approvalStatusColor: Color {
        switch spot.approvalStatus {
        case .approved:
            return .green
        case .pending:
            return .orange
        case .rejected:
            return .red
        case .none:
            return .secondary
        }
    }

    private var canRequestApproval: Bool {
        guard isOwnedByCurrentUser else {
            return false
        }
        switch spot.approvalStatus {
        case .none, .rejected:
            return true
        default:
            return false
        }
    }

    private func requestApproval() {
        guard appState.idToken != nil else {
            approvalMessage = "ログインが必要です。"
            return
        }
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)
        isRequestingApproval = true
        approvalMessage = nil
        Task {
            do {
                let input = SdzUpdateSpotInput(
                    name: spot.name,
                    description: nil,
                    location: nil,
                    tags: nil,
                    images: nil,
                    approvalStatus: .pending
                )
                let updated = try await apiClient.updateSpot(id: spot.spotId, input: input)
                await MainActor.run {
                    self.spot = updated
                    self.isRequestingApproval = false
                    self.approvalMessage = "承認申請を送信しました。"
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.isRequestingApproval = false
                    self.approvalMessage = message
                }
            }
        }
    }

    private func toggleRouteDraft() {
        if isInRouteDraft {
            appState.removeSpotFromRouteDraft(spot)
            routeMessage = "ルート下書きから外しました。"
        } else {
            appState.addSpotToRouteDraft(spot)
            routeMessage = "ルート下書きに追加しました。"
        }
    }
}

#if DEBUG
struct SpotDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpotDetailView(spot: SdzSpot.sample(id: "preview", name: "プレビュー"))
                .environmentObject(SdzAppState())
        }
    }
}
#endif
