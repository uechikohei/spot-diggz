import Foundation
import Combine

/// Shared application state used across the entire app.
@MainActor
final class SdzAppState: ObservableObject {
    /// Flag indicating whether the user is authenticated.
    @Published var isAuthenticated: Bool = false

    /// Currently selected API environment.
    let environment: SdzEnvironment = .dev

    /// Placeholder for the authentication token (Firebase ID token).
    @Published var idToken: String?

    /// Current authenticated user info (from Firebase).
    @Published var authUserId: String?
    @Published var authEmail: String?
    @Published var authDisplayName: String?

    /// Indicates whether the auth session is loading.
    @Published var isAuthLoading: Bool = false

    /// Favorites stored locally (no backend yet).
    @Published private(set) var favoriteSpots: [SdzSpot] = []

    /// Profile image data stored locally.
    @Published var profileImageData: Data?

    init() {
        loadFavorites()
        loadProfileImage()
    }

    func restoreSession() async {
        isAuthLoading = true
        let session = await SdzAuthService.shared.currentSession()
        applySession(session)
        isAuthLoading = false
    }

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await SdzAuthService.shared.signInWithEmail(email: email, password: password)
        applySession(session)
    }

    func signUpWithEmail(email: String, password: String) async throws {
        let session = try await SdzAuthService.shared.signUpWithEmail(email: email, password: password)
        applySession(session)
    }

    func signInWithGoogle() async throws {
        let session = try await SdzAuthService.shared.signInWithGoogle()
        applySession(session)
    }

    func signOut() {
        do {
            try SdzAuthService.shared.signOut()
        } catch {
            // Keep state consistent even if sign-out fails.
        }
        applySession(nil)
    }

    func toggleFavorite(_ spot: SdzSpot) {
        if let index = favoriteSpots.firstIndex(where: { $0.spotId == spot.spotId }) {
            favoriteSpots.remove(at: index)
        } else {
            favoriteSpots.append(spot)
        }
        saveFavorites()
    }

    func isFavorite(_ spot: SdzSpot) -> Bool {
        favoriteSpots.contains(where: { $0.spotId == spot.spotId })
    }

    private func applySession(_ session: SdzAuthSession?) {
        if let session = session {
            idToken = session.idToken
            authUserId = session.userId
            authEmail = session.email
            authDisplayName = session.displayName
            isAuthenticated = true
        } else {
            idToken = nil
            authUserId = nil
            authEmail = nil
            authDisplayName = nil
            isAuthenticated = false
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: Self.favoritesKey) else {
            return
        }
        if let decoded = try? JSONDecoder().decode([SdzSpot].self, from: data) {
            favoriteSpots = decoded
        }
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favoriteSpots) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.favoritesKey)
    }

    private static let favoritesKey = "sdz.favoriteSpots"

    func setProfileImageData(_ data: Data?) {
        profileImageData = data
        saveProfileImage()
    }

    private func loadProfileImage() {
        profileImageData = UserDefaults.standard.data(forKey: Self.profileImageKey)
    }

    private func saveProfileImage() {
        if let data = profileImageData {
            UserDefaults.standard.set(data, forKey: Self.profileImageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.profileImageKey)
        }
    }

    private static let profileImageKey = "sdz.profileImage"
}
