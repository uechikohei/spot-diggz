import SwiftUI

/// The entry point for the SpotDiggz application.
@main
struct SdzApp: App {
    /// Global application state.
    @StateObject private var appState = SdzAppState()

    init() {
        _ = SdzAuthService.shared.configureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isAuthLoading {
                    ProgressView("認証中...")
                } else if appState.isAuthenticated {
                    RootTabView()
                } else {
                    // Present login/signup when unauthenticated.
                    AuthView()
                }
            }
            .environmentObject(appState)
        }
        .task {
            await appState.restoreSession()
        }
        .onOpenURL { url in
            _ = SdzAuthService.shared.handleOpenUrl(url)
        }
    }
}
