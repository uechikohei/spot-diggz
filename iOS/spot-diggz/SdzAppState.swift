import Foundation
import Combine

enum SdzTab: Hashable {
    case spots
    case favorites
    case routes
    case post
    case settings
}

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
    @Published var authProviderIds: [String] = []

    /// Indicates whether the auth session is loading.
    @Published var isAuthLoading: Bool = false

    /// Favorites synced with backend (cached locally).
    @Published private(set) var favoriteSpots: [SdzSpot] = []
    @Published var isFavoritesLoading: Bool = false
    @Published var favoritesErrorMessage: String?

    /// Draft route stops for quick planning.
    @Published private(set) var routeDraftSpots: [SdzSpot] = []

    /// Saved routes stored locally.
    @Published private(set) var savedRoutes: [SdzRoute] = []

    /// Profile image data stored locally.
    @Published var profileImageData: Data?

    /// Currently selected tab.
    @Published var selectedTab: SdzTab = .spots

    /// Draft location passed from map to the post flow.
    @Published var draftPostLocation: SdzSpotLocation?

    init() {
        loadFavorites()
        loadRoutes()
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

    func toggleFavorite(_ spot: SdzSpot) async {
        guard let idToken = idToken else {
            favoritesErrorMessage = "ログインが必要です。"
            return
        }
        favoritesErrorMessage = nil
        let isAdding = !isFavorite(spot)
        if isAdding {
            favoriteSpots.insert(spot, at: 0)
        } else {
            favoriteSpots.removeAll { $0.spotId == spot.spotId }
        }
        saveFavorites()

        let apiClient = SdzApiClient(environment: environment, idToken: idToken)
        do {
            if isAdding {
                _ = try await apiClient.addToMyList(spotId: spot.spotId)
            } else {
                _ = try await apiClient.removeFromMyList(spotId: spot.spotId)
            }
        } catch {
            // Revert on failure to keep state consistent.
            if isAdding {
                favoriteSpots.removeAll { $0.spotId == spot.spotId }
            } else {
                favoriteSpots.insert(spot, at: 0)
            }
            favoritesErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            saveFavorites()
        }
    }

    func isFavorite(_ spot: SdzSpot) -> Bool {
        favoriteSpots.contains(where: { $0.spotId == spot.spotId })
    }

    func addSpotToRouteDraft(_ spot: SdzSpot) {
        guard !routeDraftSpots.contains(where: { $0.spotId == spot.spotId }) else {
            return
        }
        routeDraftSpots.append(spot)
    }

    func removeSpotFromRouteDraft(_ spot: SdzSpot) {
        routeDraftSpots.removeAll { $0.spotId == spot.spotId }
    }

    func clearRouteDraft() {
        routeDraftSpots.removeAll()
    }

    func saveRoute(name: String, mode: SdzRouteMode, spots: [SdzSpot]) {
        let route = SdzRoute(
            routeId: UUID().uuidString,
            name: name,
            mode: mode,
            spots: spots,
            createdAt: Date()
        )
        savedRoutes.insert(route, at: 0)
        saveRoutes()
    }

    func deleteRoute(_ route: SdzRoute) {
        savedRoutes.removeAll { $0.routeId == route.routeId }
        saveRoutes()
    }

    private func applySession(_ session: SdzAuthSession?) {
        if let session = session {
            idToken = session.idToken
            authUserId = session.userId
            authEmail = session.email
            authDisplayName = session.displayName
            authProviderIds = session.providerIds
            isAuthenticated = true
            Task {
                await refreshFavorites()
            }
        } else {
            idToken = nil
            authUserId = nil
            authEmail = nil
            authDisplayName = nil
            authProviderIds = []
            isAuthenticated = false
            favoriteSpots = []
            favoritesErrorMessage = nil
            saveFavorites()
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

    func refreshFavorites() async {
        guard let idToken = idToken else {
            favoriteSpots = []
            favoritesErrorMessage = "ログインが必要です。"
            saveFavorites()
            return
        }
        isFavoritesLoading = true
        favoritesErrorMessage = nil
        let apiClient = SdzApiClient(environment: environment, idToken: idToken)
        do {
            let spots = try await apiClient.fetchMyList()
            favoriteSpots = spots
            saveFavorites()
        } catch {
            favoritesErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isFavoritesLoading = false
    }

    private func loadRoutes() {
        guard let data = UserDefaults.standard.data(forKey: Self.routesKey) else {
            return
        }
        if let decoded = try? JSONDecoder().decode([SdzRoute].self, from: data) {
            savedRoutes = decoded
        }
    }

    private func saveRoutes() {
        guard let data = try? JSONEncoder().encode(savedRoutes) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.routesKey)
    }

    private static let routesKey = "sdz.savedRoutes"

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
