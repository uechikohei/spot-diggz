import Foundation

struct SdzErrorResponse: Codable {
    let code: Int
    let errorCode: String
    let message: String
}

enum SdzApiError: LocalizedError {
    case invalidUrl
    case invalidResponse
    case api(statusCode: Int, error: SdzErrorResponse)
    case statusCode(Int)
    case decoding(Error)
    case network(Error)
    case authRequired

    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "APIのURLが不正です。"
        case .invalidResponse:
            return "APIのレスポンスが不正です。"
        case let .api(statusCode, error):
            return "\(error.message) (HTTP \(statusCode))"
        case let .statusCode(code):
            return "サーバーエラーが発生しました (HTTP \(code))"
        case let .decoding(error):
            return "レスポンスの解析に失敗しました: \(error.localizedDescription)"
        case let .network(error):
            return "通信に失敗しました: \(error.localizedDescription)"
        case .authRequired:
            return "ログインが必要です。"
        }
    }
}

/// API client for communicating with the SpotDiggz backend.
final class SdzApiClient {
    private let environment: SdzEnvironment
    private let urlSession: URLSession
    private let idToken: String?

    init(environment: SdzEnvironment, idToken: String? = nil, urlSession: URLSession = .shared) {
        self.environment = environment
        self.idToken = idToken
        self.urlSession = urlSession
    }

    /// Fetches all spots.
    func fetchSpots() async throws -> [SdzSpot] {
        try await request(path: "/sdz/spots")
    }

    /// Fetches a specific spot by ID.
    func fetchSpotDetail(id: String) async throws -> SdzSpot {
        try await request(path: "/sdz/spots/\(id)")
    }

    /// Creates a new spot.
    func createSpot(_ input: SdzCreateSpotInput) async throws -> SdzSpot {
        guard idToken != nil else {
            throw SdzApiError.authRequired
        }
        let body = try JSONEncoder().encode(input)
        return try await request(
            path: "/sdz/spots",
            method: "POST",
            body: body,
            requiresAuth: true,
            requiresMobileClient: true
        )
    }

    /// Fetches current user.
    func fetchCurrentUser() async throws -> SdzUser {
        guard idToken != nil else {
            throw SdzApiError.authRequired
        }
        return try await request(path: "/sdz/users/me", requiresAuth: true)
    }

    /// Requests a signed upload URL for spot images.
    func requestUploadUrl(contentType: String) async throws -> SdzUploadUrlResponse {
        guard idToken != nil else {
            throw SdzApiError.authRequired
        }
        let payload = SdzUploadUrlRequest(contentType: contentType)
        let body = try JSONEncoder().encode(payload)
        return try await request(
            path: "/sdz/spots/upload-url",
            method: "POST",
            body: body,
            requiresAuth: true,
            requiresMobileClient: true
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = false,
        requiresMobileClient: Bool = false
    ) async throws -> T {
        let request = try buildRequest(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth,
            requiresMobileClient: requiresMobileClient
        )

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw SdzApiError.invalidResponse
            }

            if (200...299).contains(http.statusCode) {
                do {
                    return try decoder().decode(T.self, from: data)
                } catch {
                    throw SdzApiError.decoding(error)
                }
            }

            if let apiError = try? decoder().decode(SdzErrorResponse.self, from: data) {
                throw SdzApiError.api(statusCode: http.statusCode, error: apiError)
            }

            throw SdzApiError.statusCode(http.statusCode)
        } catch let error as SdzApiError {
            throw error
        } catch {
            throw SdzApiError.network(error)
        }
    }

    private func buildRequest(
        path: String,
        method: String,
        body: Data?,
        requiresAuth: Bool,
        requiresMobileClient: Bool
    ) throws -> URLRequest {
        let url = buildUrl(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if requiresAuth {
            guard let token = idToken else {
                throw SdzApiError.authRequired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if requiresMobileClient {
            request.setValue("ios", forHTTPHeaderField: "X-SDZ-Client")
        }

        return request
    }

    private func buildUrl(path: String) -> URL {
        var normalized = path
        if normalized.hasPrefix("/") {
            normalized.removeFirst()
        }
        return environment.baseURL.appendingPathComponent(normalized)
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = SdzApiClient.iso8601WithFractional.date(from: value)
                ?? SdzApiClient.iso8601Plain.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(value)"
            )
        }
        return decoder
    }

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

struct SdzUploadUrlRequest: Codable {
    let contentType: String
}

struct SdzUploadUrlResponse: Codable {
    let uploadUrl: String
    let objectUrl: String
    let objectName: String
    let expiresAt: Date
}
