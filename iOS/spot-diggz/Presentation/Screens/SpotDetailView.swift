import SwiftUI
import MapKit

/// A screen displaying detailed information about a specific spot.
struct SpotDetailView: View {
    @EnvironmentObject var appState: SdzAppState
    let spot: SdzSpot

    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var cameraPosition: MapCameraPosition = .automatic

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
                        Text("信頼度: \(spot.trustLevel == .verified ? "verified" : "unverified")")
                            .font(.subheadline)
                            .foregroundColor(spot.trustLevel == .verified ? .green : .orange)
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
                            // TODO: Open external map
                        }) {
                            Label("ナビ", systemImage: "car")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)

                    if isOwnedByCurrentUser {
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

    private var isOwnedByCurrentUser: Bool {
        guard let currentUserId = appState.authUserId else {
            return false
        }
        return spot.userId == currentUserId
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
