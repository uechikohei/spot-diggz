import Foundation
import Combine
import CoreLocation

@MainActor
final class SdzLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var lastErrorMessage: String?

    private let manager: CLLocationManager

    override init() {
        manager = CLLocationManager()
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        lastErrorMessage = nil
        if authorizationStatus == .notDetermined {
            requestWhenInUseAuthorization()
        }
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentCoordinate = locations.first?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}
