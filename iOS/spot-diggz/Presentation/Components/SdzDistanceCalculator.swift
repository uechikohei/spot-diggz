import Foundation
import CoreLocation

enum SdzDistanceCalculator {
    static func distance(
        from coordinate: CLLocationCoordinate2D,
        to location: SdzSpotLocation
    ) -> CLLocationDistance {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let destination = CLLocation(latitude: location.lat, longitude: location.lng)
        return origin.distance(from: destination)
    }

    static func formattedDistance(meters: CLLocationDistance) -> String {
        if meters >= 1_000 {
            let km = meters / 1_000
            return String(format: "%.1fkm先", km)
        }
        return "\(Int(meters))m先"
    }
}
