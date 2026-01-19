import Foundation

/// Location information for a spot.
struct SdzSpotLocation: Codable, Identifiable, Equatable {
    let lat: Double
    let lng: Double

    // Use a stable identifier derived from coordinates.
    var id: String { "\(lat),\(lng)" }
}

/// Approval status for a spot.
enum SdzSpotApprovalStatus: String, Codable {
    case pending
    case approved
    case rejected
}

/// Represents a skate spot posted by a user.
struct SdzSpot: Codable, Identifiable {
    let spotId: String
    let name: String
    let description: String?
    let location: SdzSpotLocation?
    let tags: [String]
    let images: [String]
    let approvalStatus: SdzSpotApprovalStatus?
    let userId: String
    let createdAt: Date
    let updatedAt: Date

    var id: String { spotId }
}

extension SdzSpot {
    /// Creates a sample spot for preview and development.
    static func sample(id: String, name: String) -> SdzSpot {
        return SdzSpot(
            spotId: id,
            name: name,
            description: "説明が入ります。このスポットは楽しい場所です。",
            location: SdzSpotLocation(lat: 34.67, lng: 135.5),
            tags: ["パーク", "ストリート"],
            images: [],
            approvalStatus: nil,
            userId: "user",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
