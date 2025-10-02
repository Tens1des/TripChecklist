import Foundation

// Simple file-based storage. Works fully offline.
final class StorageService {
    static let shared = StorageService()

    private let stateURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.stateURL = directory.appendingPathComponent("app_state.json")
    }

    func load() -> AppState {
        do {
            let data = try Data(contentsOf: stateURL)
            let decoded = try JSONDecoder().decode(PersistedState.self, from: data)
            return decoded.toAppState()
        } catch {
            return AppState()
        }
    }

    func save(_ state: AppState) {
        let persisted = PersistedState(from: state)
        do {
            let data = try JSONEncoder().encode(persisted)
            try data.write(to: stateURL, options: [.atomic])
        } catch {
            // For offline app, fail silently; could add logging later
        }
    }
}

// Wrap for future migrations
private struct PersistedState: Codable {
    var trips: [Trip]
    var categories: [TripCategory]
    var settings: UserSettings

    init(from state: AppState) {
        self.trips = state.trips
        self.categories = state.categories
        self.settings = state.settings
    }

    func toAppState() -> AppState {
        AppState(trips: trips, categories: categories, settings: settings)
    }
}



