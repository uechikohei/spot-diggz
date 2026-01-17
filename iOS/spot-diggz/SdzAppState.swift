import Foundation
import Combine

/// Shared application state used across the entire app.
final class SdzAppState: ObservableObject {
    /// Flag indicating whether the user is authenticated.
    @Published var isAuthenticated: Bool = false

    /// Currently selected API environment.
    let environment: SdzEnvironment = .dev

    /// Placeholder for the authentication token (Firebase ID token).
    @Published var idToken: String?

    init() {
        // TODO: Load initial auth state and token here.
    }
}
