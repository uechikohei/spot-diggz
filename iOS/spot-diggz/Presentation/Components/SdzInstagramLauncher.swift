import UIKit

@MainActor
enum SdzInstagramLauncher {
    private static let sdzMaxSpotNameLength = 200

    static var isInstagramInstalled: Bool {
        guard let url = URL(string: "instagram://") else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }

    static func searchOnInstagram(spotName: String) {
        let truncated = String(spotName.prefix(sdzMaxSpotNameLength))
        guard let url = sdzBuildSearchURL(spotName: truncated) else { return }
        UIApplication.shared.open(url)
    }

    private static func sdzBuildSearchURL(spotName: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: "site:instagram.com \(spotName)")
        ]
        return components.url
    }
}
