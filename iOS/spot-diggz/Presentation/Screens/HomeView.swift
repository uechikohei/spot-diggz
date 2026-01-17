import SwiftUI

/// Home screen displaying a list of skate spots with search functionality.
struct HomeView: View {
    @EnvironmentObject var appState: SdzAppState
    @State private var searchText: String = ""
    @State private var spots: [SdzSpot] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("スポット名を検索", text: $searchText)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("再読み込み") {
                            fetchSpots()
                        }
                        .padding(.top, 4)
                    }
                } else if spots.isEmpty {
                    VStack {
                        Text("スポットが見つかりません")
                            .foregroundColor(.secondary)
                        Button("更新") {
                            fetchSpots()
                        }
                        .padding(.top, 4)
                    }
                } else {
                    List {
                        ForEach(filteredSpots) { spot in
                            NavigationLink(destination: SpotDetailView(spot: spot)) {
                                SpotCardView(spot: spot)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ホーム")
            .onAppear(perform: fetchSpots)
        }
    }

    /// Filters spots based on the search text.
    private var filteredSpots: [SdzSpot] {
        if searchText.isEmpty {
            return spots
        }
        return spots.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    /// Loads the list of spots from the API.
    private func fetchSpots() {
        isLoading = true
        errorMessage = nil
        let apiClient = SdzApiClient(environment: appState.environment)
        Task {
            do {
                let result = try await apiClient.fetchSpots()
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
