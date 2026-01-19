import Foundation

/// Transport mode for a saved route.
enum SdzRouteMode: String, Codable, CaseIterable, Identifiable {
    case walk
    case transit
    case drive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .walk:
            return "徒歩"
        case .transit:
            return "電車"
        case .drive:
            return "車"
        }
    }
}

/// A saved route consisting of multiple skate spots.
struct SdzRoute: Codable, Identifiable {
    let routeId: String
    let name: String
    let mode: SdzRouteMode
    let spots: [SdzSpot]
    let createdAt: Date

    var id: String { routeId }
}
