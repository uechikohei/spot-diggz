import Foundation

actor SdzSpotCache {
    static let shared = SdzSpotCache()

    private var entries: [SdzSpotSearchQuery?: (spots: [SdzSpot], fetchedAt: Date)] = [:]
    private let ttl: TimeInterval = 300

    func cachedSpots(for query: SdzSpotSearchQuery?) -> [SdzSpot]? {
        guard let entry = entries[query] else { return nil }
        if Date().timeIntervalSince(entry.fetchedAt) > ttl {
            return nil
        }
        return entry.spots
    }

    func store(spots: [SdzSpot], for query: SdzSpotSearchQuery?) {
        entries[query] = (spots: spots, fetchedAt: Date())
    }

    func invalidate() {
        entries.removeAll()
    }
}
