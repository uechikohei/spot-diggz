import SwiftUI

/// The entry point for the SpotDiggz application.
@main
struct SdzApp: App {
    /// Global application state.
    @StateObject private var appState = SdzAppState()

    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                RootTabView()
                    .environmentObject(appState)
            } else {
                // Present login/signup when unauthenticated.
                AuthView()
                    .environmentObject(appState)
            }
        }
    }
}