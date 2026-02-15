import SwiftUI

/// User preference for color scheme.
enum SdzColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:
            return "システム"
        case .light:
            return "ライト"
        case .dark:
            return "ダーク"
        }
    }

    var iconName: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

/// Manages color scheme preference with persistence via AppStorage.
final class SdzThemeManager: ObservableObject {
    @AppStorage("sdz_color_scheme") var preference: SdzColorSchemePreference = .system

    /// Resolved color scheme for `.preferredColorScheme()`.
    /// Returns `nil` for system (follows device setting).
    var resolvedColorScheme: ColorScheme? {
        switch preference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
