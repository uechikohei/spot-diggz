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

                Section(header: Text("アカウント情報"), footer: Text(emailChangeNote)) {
                    LabeledContent("ユーザーID", value: resolvedUserId)
                    LabeledContent("ログイン方法", value: providerLabel)
                    LabeledContent("表示名", value: resolvedDisplayName)
                    if let email = resolvedEmail {
                        LabeledContent("メール", value: email)
                    }
                }

                Section(header: Text("自分の投稿")) {
                    if mySpots.isEmpty {
                        Text("投稿がありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(mySpots) { spot in
                            NavigationLink(destination: SpotDetailView(spot: spot)) {
                                SpotCardView(spot: spot)
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
                                SpotCardView(spot: spot)
                            }
                        }
                    }
                }
            }
            .navigationTitle("設定")
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

    private var resolvedUserId: String {
        user?.userId ?? appState.authUserId ?? "-"
    }

    private var resolvedDisplayName: String {
        if let user = user, !user.displayName.isEmpty, user.displayName != "unknown" {
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
        if let user = user, let email = user.email, !email.isEmpty {
            return email
        }
        return appState.authEmail
    }

    private var providerLabel: String {
        let providers = Set(appState.authProviderIds)
        var labels: [String] = []
        if providers.contains("google.com") {
            labels.append("Google")
        }
        if providers.contains("apple.com") {
            labels.append("Apple")
        }
        if providers.contains("password") {
            labels.append("メール/パスワード")
        }
        return labels.isEmpty ? "不明" : labels.joined(separator: " / ")
    }

    private var emailChangeNote: String {
        if appState.authProviderIds.contains("google.com") || appState.authProviderIds.contains("apple.com") {
            return "Google/Appleログインのメール変更は各アカウント側で行います。アプリ内での変更には未対応です。"
        }
        return "メール変更は今後対応予定です。"
    }

    private func loadData() {
        errorMessage = nil
        guard appState.idToken != nil else {
            errorMessage = "ログインが必要です。"
            return
        }
        let apiClient = SdzApiClient(environment: appState.environment, idToken: appState.idToken)

        Task {
            async let spots = apiClient.fetchSpots(includeAuth: true)
            async let currentUser = apiClient.fetchCurrentUser()

            let spotsResponse: Result<[SdzSpot], Error>
            do {
                spotsResponse = .success(try await spots)
            } catch {
                spotsResponse = .failure(error)
            }

            let userResponse: Result<SdzUser, Error>
            do {
                userResponse = .success(try await currentUser)
            } catch {
                userResponse = .failure(error)
            }

            await MainActor.run {
                switch userResponse {
                case .success(let currentUser):
                    self.user = currentUser
                case .failure(let error):
                    if let message = resolveErrorMessage(error) {
                        self.errorMessage = message
                    }
                }

                switch spotsResponse {
                case .success(let spots):
                    let currentUserId = self.user?.userId ?? appState.authUserId
                    if let currentUserId = currentUserId {
                        self.mySpots = spots.filter { $0.userId == currentUserId }
                    } else {
                        self.mySpots = []
                    }
                case .failure(let error):
                    if let message = resolveErrorMessage(error) {
                        self.errorMessage = message
                    }
                    self.mySpots = []
                }
            }
        }
    }

    private func resolveErrorMessage(_ error: Error) -> String? {
        if let apiError = error as? SdzApiError {
            switch apiError {
            case let .api(statusCode, _) where statusCode == 401:
                return nil
            case let .statusCode(statusCode) where statusCode == 401:
                return nil
            case .authRequired:
                return "ログインが必要です。"
            default:
                return apiError.errorDescription ?? "読み込みに失敗しました。"
            }
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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
