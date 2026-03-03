import SwiftUI
import MapKit

struct SdzMapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let spot: SdzSpot?
    let isDraft: Bool
}

struct SdzFullScreenMapView: UIViewRepresentable {
    let annotations: [SdzMapAnnotationItem]
    @Binding var region: MKCoordinateRegion
    let focusedSpotId: String?
    let expandedSpotIds: Set<String>
    let onTapCoordinate: (CLLocationCoordinate2D) -> Void
    let onSelectSpot: (SdzSpot) -> Void
    let onSelectCluster: ([String]) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        mapView.addGestureRecognizer(tap)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !context.coordinator.isRegionChangeFromMap {
            if !context.coordinator.isSimilarRegion(lhs: mapView.region, rhs: region) {
                mapView.setRegion(region, animated: true)
            }
        }
        context.coordinator.isRegionChangeFromMap = false
        context.coordinator.focusedSpotId = focusedSpotId
        context.coordinator.expandedSpotIds = expandedSpotIds
        context.coordinator.updateAnnotations(annotations, in: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        private let parent: SdzFullScreenMapView
        private var annotationStore: [String: SdzSpotAnnotation] = [:]
        private var clusterStore: [String: SdzClusterAnnotation] = [:]
        fileprivate var focusedSpotId: String?
        fileprivate var expandedSpotIds: Set<String> = []
        fileprivate var isRegionChangeFromMap = false
        private var lastFocusedSpotId: String?
        private var isRegionChanging = false

        init(parent: SdzFullScreenMapView) {
            self.parent = parent
            self.focusedSpotId = parent.focusedSpotId
            self.expandedSpotIds = parent.expandedSpotIds
        }

        func updateAnnotations(_ items: [SdzMapAnnotationItem], in mapView: MKMapView) {
            let previousFocusId = lastFocusedSpotId
            let currentFocusId = focusedSpotId
            lastFocusedSpotId = currentFocusId
            let region = parent.region
            let gridSizePoints = clusterGridSizePoints(for: region)

            var nextIds = Set<String>()
            for item in items {
                nextIds.insert(item.id)
                if let existing = annotationStore[item.id] {
                    existing.coordinate = item.coordinate
                    existing.spot = item.spot
                    existing.isDraft = item.isDraft
                } else {
                    let annotation = SdzSpotAnnotation(
                        id: item.id,
                        coordinate: item.coordinate,
                        spot: item.spot,
                        isDraft: item.isDraft
                    )
                    annotationStore[item.id] = annotation
                }
            }
            let removed = annotationStore.keys.filter { !nextIds.contains($0) }
            for id in removed {
                if let annotation = annotationStore.removeValue(forKey: id) {
                    mapView.removeAnnotation(annotation)
                }
            }

            var displaySpotIds = Set<String>()
            var displayClusterIds = Set<String>()
            var clusterGroups: [ClusterKey: [SdzSpotAnnotation]] = [:]

            for item in items where !item.isDraft {
                guard let annotation = annotationStore[item.id], let spot = item.spot else { continue }
                if item.id == focusedSpotId || expandedSpotIds.contains(item.id) {
                    displaySpotIds.insert(item.id)
                    continue
                }
                let mapPoint = MKMapPoint(item.coordinate)
                let key = ClusterKey(
                    type: clusterTypeKey(for: spot),
                    x: Int(floor(mapPoint.x / gridSizePoints)),
                    y: Int(floor(mapPoint.y / gridSizePoints))
                )
                clusterGroups[key, default: []].append(annotation)
            }

            for (key, annotations) in clusterGroups {
                if annotations.count == 1, let annotation = annotations.first {
                    displaySpotIds.insert(annotation.id)
                } else if !annotations.isEmpty {
                    let clusterId = "\(key.type)-\(key.x)-\(key.y)"
                    let cluster = clusterStore[clusterId] ?? SdzClusterAnnotation(
                        id: clusterId,
                        coordinate: annotations[0].coordinate,
                        count: annotations.count,
                        isPark: key.type == "park",
                        memberMapRect: MKMapRect.null,
                        memberSpotIds: []
                    )
                    updateCluster(cluster, with: annotations)
                    clusterStore[clusterId] = cluster
                    displayClusterIds.insert(clusterId)
                }
            }

            let removedClusters = clusterStore.keys.filter { !displayClusterIds.contains($0) }
            for id in removedClusters {
                if let cluster = clusterStore.removeValue(forKey: id) {
                    mapView.removeAnnotation(cluster)
                }
            }

            for (id, annotation) in annotationStore {
                let shouldDisplay = annotation.isDraft || displaySpotIds.contains(id)
                setAnnotation(annotation, visible: shouldDisplay, in: mapView)
            }

            for (id, cluster) in clusterStore {
                let shouldDisplay = displayClusterIds.contains(id)
                setAnnotation(cluster, visible: shouldDisplay, in: mapView)
            }

            mapView.annotations.forEach { annotation in
                if let view = mapView.view(for: annotation) as? SdzSpotAnnotationView,
                   let spotAnnotation = annotation as? SdzSpotAnnotation,
                   let spot = spotAnnotation.spot {
                    view.update(spot: spot, isFocused: focusedSpotId == spot.spotId)
                }
            }

            if previousFocusId != currentFocusId, !isRegionChanging {
                let idsToRefresh = [previousFocusId, currentFocusId].compactMap { $0 }
                for id in idsToRefresh {
                    refreshAnnotation(id: id, in: mapView)
                }
            } else if previousFocusId != currentFocusId {
                let idsToRefresh = [previousFocusId, currentFocusId].compactMap { $0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak mapView] in
                    guard let self, let mapView else { return }
                    for id in idsToRefresh {
                        self.refreshAnnotation(id: id, in: mapView)
                    }
                }
            }
        }

        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onTapCoordinate(coordinate)
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            isRegionChangeFromMap = true
            parent.region = mapView.region
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isRegionChanging = true
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isRegionChanging = false
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            if let cluster = annotation as? SdzClusterAnnotation {
                let identifier = "SdzClusterAnnotationView"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SdzClusterAnnotationView
                    ?? SdzClusterAnnotationView(annotation: cluster, reuseIdentifier: identifier)
                view.annotation = cluster
                view.canShowCallout = false
                view.update(
                    count: cluster.count,
                    tintColor: clusterTintColor(for: cluster)
                )
                view.displayPriority = .required
                return view
            }
            guard let spotAnnotation = annotation as? SdzSpotAnnotation else {
                return nil
            }
            if spotAnnotation.isDraft {
                let identifier = "SdzDraftAnnotationView"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: spotAnnotation, reuseIdentifier: identifier)
                view.annotation = spotAnnotation
                view.image = UIImage(systemName: "plus.circle.fill")
                view.displayPriority = .required
                view.clusteringIdentifier = nil
                return view
            }
            let identifier = "SdzSpotAnnotationView"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SdzSpotAnnotationView
                ?? SdzSpotAnnotationView(annotation: spotAnnotation, reuseIdentifier: identifier)
            view.annotation = spotAnnotation
            if let spot = spotAnnotation.spot {
                view.update(spot: spot, isFocused: focusedSpotId == spot.spotId)
            }
            view.clusteringIdentifier = nil
            view.displayPriority = .required
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? SdzClusterAnnotation {
                parent.onSelectCluster(cluster.memberSpotIds)
                zoomToCluster(cluster, in: mapView)
                return
            }
            guard let annotation = view.annotation as? SdzSpotAnnotation,
                  let spot = annotation.spot,
                  !annotation.isDraft else { return }
            focusedSpotId = spot.spotId
            if let spotView = view as? SdzSpotAnnotationView {
                spotView.update(spot: spot, isFocused: true)
            }
            parent.onSelectSpot(spot)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if let view = touch.view, isAnnotationSubview(view) {
                return false
            }
            return true
        }

        private func isAnnotationSubview(_ view: UIView) -> Bool {
            var current: UIView? = view
            while let node = current {
                if node is MKAnnotationView {
                    return true
                }
                current = node.superview
            }
            return false
        }

        private func clusterTintColor(for cluster: SdzClusterAnnotation) -> UIColor {
            UIColor(cluster.isPark ? Color.sdzPark : Color.sdzStreet)
        }

        private func zoomToCluster(_ cluster: SdzClusterAnnotation, in mapView: MKMapView) {
            guard !cluster.memberMapRect.isNull else { return }
            let padding = UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80)
            mapView.setVisibleMapRect(cluster.memberMapRect, edgePadding: padding, animated: true)
        }

        private func refreshAnnotation(id: String, in mapView: MKMapView) {
            guard let annotation = annotationStore[id] else { return }
            mapView.removeAnnotation(annotation)
            mapView.addAnnotation(annotation)
        }

        private func setAnnotation(_ annotation: MKAnnotation, visible: Bool, in mapView: MKMapView) {
            let exists = mapView.annotations.contains { $0 === annotation }
            if visible && !exists {
                mapView.addAnnotation(annotation)
            } else if !visible && exists {
                mapView.removeAnnotation(annotation)
            }
        }

        private func clusterGridSizePoints(for region: MKCoordinateRegion) -> Double {
            let radiusMeters = clusterRadiusMeters(for: region.span.latitudeDelta)
            let metersPerPoint = MKMetersPerMapPointAtLatitude(region.center.latitude)
            return max(1, radiusMeters / metersPerPoint)
        }

        private func clusterRadiusMeters(for latitudeDelta: CLLocationDegrees) -> Double {
            switch latitudeDelta {
            case ..<0.05:
                return 500
            case ..<0.5:
                return 5_000
            case ..<2.0:
                return 10_000
            case ..<8.0:
                return 100_000
            default:
                return 300_000
            }
        }

        private func clusterTypeKey(for spot: SdzSpot) -> String {
            spot.sdzIsPark ? "park" : "street"
        }

        private func updateCluster(_ cluster: SdzClusterAnnotation, with annotations: [SdzSpotAnnotation]) {
            guard !annotations.isEmpty else { return }
            var rect = MKMapRect.null
            var sumX = 0.0
            var sumY = 0.0
            for annotation in annotations {
                let point = MKMapPoint(annotation.coordinate)
                sumX += point.x
                sumY += point.y
                let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.01, height: 0.01)
                rect = rect.isNull ? pointRect : rect.union(pointRect)
            }
            let count = Double(annotations.count)
            let centerPoint = MKMapPoint(x: sumX / count, y: sumY / count)
            cluster.coordinate = centerPoint.coordinate
            cluster.count = annotations.count
            if let spot = annotations.first?.spot {
                cluster.isPark = spot.sdzIsPark
            }
            cluster.memberMapRect = rect
            cluster.memberSpotIds = annotations.compactMap { $0.spot?.spotId }
        }

        private struct ClusterKey: Hashable {
            let type: String
            let x: Int
            let y: Int
        }

        fileprivate func isSimilarRegion(lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
            let delta = abs(lhs.center.latitude - rhs.center.latitude)
                + abs(lhs.center.longitude - rhs.center.longitude)
                + abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta)
                + abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta)
            return delta < 0.0001
        }
    }
}

// MARK: - Annotation Models

final class SdzSpotAnnotation: NSObject, MKAnnotation {
    let id: String
    dynamic var coordinate: CLLocationCoordinate2D
    var spot: SdzSpot?
    var isDraft: Bool

    init(id: String, coordinate: CLLocationCoordinate2D, spot: SdzSpot?, isDraft: Bool) {
        self.id = id
        self.coordinate = coordinate
        self.spot = spot
        self.isDraft = isDraft
    }
}

final class SdzClusterAnnotation: NSObject, MKAnnotation {
    let id: String
    dynamic var coordinate: CLLocationCoordinate2D
    var count: Int
    var isPark: Bool
    var memberMapRect: MKMapRect
    var memberSpotIds: [String]

    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        count: Int,
        isPark: Bool,
        memberMapRect: MKMapRect,
        memberSpotIds: [String]
    ) {
        self.id = id
        self.coordinate = coordinate
        self.count = count
        self.isPark = isPark
        self.memberMapRect = memberMapRect
        self.memberSpotIds = memberSpotIds
    }
}

// MARK: - Annotation Views

final class SdzSpotAnnotationView: MKAnnotationView {
    private var hostingController: UIHostingController<AnyView>?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        canShowCallout = false
        backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        backgroundColor = .clear
        annotation = nil
    }

    func update(spot: SdzSpot, isFocused: Bool) {
        let view = AnyView(
            SdzMapPinView(spot: spot, isFocused: isFocused)
        )
        if let hostingController = hostingController {
            hostingController.rootView = view
        } else {
            let controller = UIHostingController(rootView: view)
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = true
            hostingController = controller
            addSubview(controller.view)
        }
        layoutHostingView()
    }

    private func layoutHostingView() {
        guard let hostingController = hostingController else { return }
        let hostedView = hostingController.view!
        let size = hostingController.sizeThatFits(in: CGSize(width: 240, height: 240))
        frame = CGRect(origin: .zero, size: size)
        hostedView.frame = bounds
        centerOffset = CGPoint(x: 0, y: -size.height * 0.5)
    }
}

final class SdzClusterAnnotationView: MKAnnotationView {
    private var hostingController: UIHostingController<AnyView>?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        canShowCallout = false
        backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        backgroundColor = .clear
        annotation = nil
    }

    func update(count: Int, tintColor: UIColor) {
        let view = AnyView(
            SdzClusterBubble(count: count, color: Color(tintColor))
        )
        if let hostingController = hostingController {
            hostingController.rootView = view
        } else {
            let controller = UIHostingController(rootView: view)
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = true
            hostingController = controller
            addSubview(controller.view)
        }
        layoutHostingView()
    }

    private func layoutHostingView() {
        guard let hostingController = hostingController else { return }
        let hostedView = hostingController.view!
        let size = hostingController.sizeThatFits(in: CGSize(width: 120, height: 120))
        frame = CGRect(origin: .zero, size: size)
        hostedView.frame = bounds
        centerOffset = CGPoint(x: 0, y: -size.height * 0.5)
    }
}
