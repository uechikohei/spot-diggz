import Foundation

/// A simple API client for communicating with the SpotDiggz backend.
/// This class demonstrates how to structure network calls; replace stubs with real implementation.
final class SdzApiClient {
    private let environment: SdzEnvironment
    private let urlSession: URLSession

    init(environment: SdzEnvironment, urlSession: URLSession = .shared) {
        self.environment = environment
        self.urlSession = urlSession
    }

    /// Fetches all spots.
    func fetchSpots() async throws -> [SdzSpot] {
        // TODO: Implement network call: GET /sdz/spots
        return [
            SdzSpot.sample(id: "1", name: "パークA"),
            SdzSpot.sample(id: "2", name: "ストリートB")
        ]
    }

    /// Fetches a specific spot by ID.
    func fetchSpotDetail(id: String) async throws -> SdzSpot {
        // TODO: Implement network call: GET /sdz/spots/{spot_id}
        return SdzSpot.sample(id: id, name: "詳細スポット")
    }

    /// Creates a new spot.
    func createSpot(_ input: SdzCreateSpotInput) async throws {
        // TODO: Implement network call: POST /sdz/spots
    }

    /// Fetches current user.
    func fetchCurrentUser() async throws -> SdzUser {
        // TODO: Implement network call: GET /sdz/users/me
        return SdzUser(userId: "u1", displayName: "Sample User", email: "sample@example.com")
    }
}