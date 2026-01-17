import SwiftUI

/// Displays the current user's profile, their posts, and favorites.
struct ProfileView: View {
    @EnvironmentObject var appState: SdzAppState

    @State private var user: SdzUser = SdzUser(userId: "u1", displayName: "Sample User", email: "sample@example.com")
    @State private var mySpots: [SdzSpot] = []
    @State private var favorites: [SdzSpot] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Placeholder avatar
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                if let email = user.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Button("ログアウト") {
                            // TODO: Implement sign out.
                            appState.isAuthenticated = false
                        }
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("自分の投稿")) {
                    if mySpots.isEmpty {
                        Text("投稿がありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(mySpots) { spot in
                            NavigationLink(destination: SpotDetailView(spot: spot)) {
                                Text(spot.name)
                            }
                        }
                    }
                }

                Section(header: Text("お気に入り")) {
                    if favorites.isEmpty {
                        Text("お気に入りはありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favorites) { spot in
                            NavigationLink(destination: SpotDetailView(spot: spot)) {
                                Text(spot.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        errorMessage = nil
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)

        Task {
            do {
                let currentUser = try await apiClient.fetchCurrentUser()
                await MainActor.run {
                    self.user = currentUser
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.errorMessage = message
                }
            }
        }

        // TODO: Fetch my spots and favorites from API once endpoints are available.
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SdzAppState())
    }
}
#endif
