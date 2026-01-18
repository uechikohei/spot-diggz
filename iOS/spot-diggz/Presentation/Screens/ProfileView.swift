import SwiftUI
import UIKit

/// Displays the current user's profile, their posts, and favorites.
struct ProfileView: View {
    @EnvironmentObject var appState: SdzAppState

    @State private var user: SdzUser?
    @State private var mySpots: [SdzSpot] = []
    @State private var errorMessage: String?
    @State private var showAvatarPicker: Bool = false
    @State private var avatarImages: [UIImage] = []

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
                            avatarView
                            VStack(alignment: .leading) {
                                Text(resolvedDisplayName)
                                    .font(.headline)
                                if let email = resolvedEmail {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Button("ログアウト") {
                            appState.signOut()
                        }
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)

                        Button("アイコンを変更") {
                            showAvatarPicker = true
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
                    if appState.favoriteSpots.isEmpty {
                        Text("お気に入りはありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appState.favoriteSpots) { spot in
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
            .sheet(isPresented: $showAvatarPicker) {
                ImagePicker(images: $avatarImages)
            }
            .onChange(of: avatarImages) { _, newValue in
                guard let image = newValue.last else {
                    return
                }
                if let data = image.jpegData(compressionQuality: 0.85) {
                    appState.setProfileImageData(data)
                } else if let data = image.pngData() {
                    appState.setProfileImageData(data)
                }
            }
        }
    }

    private var avatarView: some View {
        Group {
            if let data = appState.profileImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
    }

    private var resolvedDisplayName: String {
        if let user = user {
            return user.displayName
        }
        if let displayName = appState.authDisplayName, !displayName.isEmpty {
            return displayName
        }
        if let email = appState.authEmail, !email.isEmpty {
            return email
        }
        return "ユーザー"
    }

    private var resolvedEmail: String? {
        if let user = user {
            return user.email
        }
        return appState.authEmail
    }

    private func loadData() {
        errorMessage = nil
        guard appState.idToken != nil else {
            errorMessage = "ログインが必要です。"
            return
        }
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
