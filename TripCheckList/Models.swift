import Foundation

// MARK: - Core Models

struct Trip: Identifiable, Codable, Equatable {
    enum Status: String, Codable, CaseIterable {
        case new = "new"
        case inProgress = "inProgress"
        case ready = "ready"
        
        var displayName: String {
            switch self {
            case .new: return "New"
            case .inProgress: return "In progress"
            case .ready: return "Ready"
            }
        }
        
        var color: String {
            switch self {
            case .new: return "green"
            case .inProgress: return "blue"
            case .ready: return "green"
            }
        }
    }
    
    var id: UUID
    var title: String
    var startDate: Date?
    var endDate: Date?
    var items: [TripItem]
    var isArchived: Bool
    var status: Status
    var iconName: String?

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        items: [TripItem] = [],
        isArchived: Bool = false,
        status: Status = .new,
        iconName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.items = items
        self.isArchived = isArchived
        self.status = status
        self.iconName = iconName
    }

    var completedItemCount: Int {
        items.reduce(0) { $0 + ($1.isChecked ? 1 : 0) }
    }

    var totalItemCount: Int { items.count }

    var totalWeightKg: Double {
        items.reduce(0) { $0 + (($1.weightKg ?? 0) * Double(max(1, $1.quantity))) }
    }

    var packedWeightKg: Double {
        items.filter { $0.isChecked }.reduce(0) { $0 + (($1.weightKg ?? 0) * Double(max(1, $1.quantity))) }
    }
    
    var categoryCount: Int {
        Set(items.map { $0.category.id }).count
    }
    
    mutating func updateStatus() {
        if completedItemCount == totalItemCount && totalItemCount > 0 {
            status = .ready
        } else if completedItemCount > 0 {
            status = .inProgress
        } else {
            status = .new
        }
    }
}

struct TripItem: Identifiable, Codable, Equatable {
    enum Importance: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    var id: UUID
    var title: String
    var note: String?
    var category: TripCategory
    var importance: Importance
    var weightKg: Double?
    var quantity: Int
    var isChecked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        category: TripCategory,
        importance: Importance = .medium,
        weightKg: Double? = nil,
        quantity: Int = 1,
        isChecked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.category = category
        self.importance = importance
        self.weightKg = weightKg
        self.quantity = max(1, quantity)
        self.isChecked = isChecked
    }
}

struct TripCategory: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var system: Bool
    var iconName: String

    init(id: UUID = UUID(), name: String, system: Bool = false, iconName: String) {
        self.id = id
        self.name = name
        self.system = system
        self.iconName = iconName
    }

    static let documents = TripCategory(name: "Documents", system: true, iconName: "doc.text")
    static let clothes = TripCategory(name: "Clothes", system: true, iconName: "tshirt")
    static let hygiene = TripCategory(name: "Hygiene", system: true, iconName: "sparkles")
    static let electronics = TripCategory(name: "Electronics", system: true, iconName: "bolt")
    
    func localizedName(language: UserSettings.AppLanguage) -> String {
        switch self.name {
        case "Documents": return LocalizedString.localized("category.documents", language: language)
        case "Clothes": return LocalizedString.localized("category.clothes", language: language)
        case "Hygiene": return LocalizedString.localized("category.hygiene", language: language)
        case "Electronics": return LocalizedString.localized("category.electronics", language: language)
        case "Medication": return LocalizedString.localized("category.medication", language: language)
        case "Other": return LocalizedString.localized("category.other", language: language)
        default: return self.name
        }
    }
}

struct UserSettings: Codable, Equatable {
    enum Theme: String, Codable, CaseIterable {
        case system
        case light
        case dark
    }

    enum AppLanguage: String, Codable, CaseIterable {
        case english = "en"
        case russian = "ru"
        case spanish = "es"
    }

    var displayName: String
    var avatarSymbolName: String
    var theme: Theme
    var language: AppLanguage
    var textScale: Double // 0.9...1.3

    static let `default` = UserSettings(
        displayName: "",
        avatarSymbolName: "luggage",
        theme: .light,
        language: .russian,
        textScale: 1.0
    )
}

struct Achievement: Identifiable, Codable, Equatable {
    var id: Int
    var title: String
    var description: String
    var isUnlocked: Bool
}

// MARK: - App State

final class AppState: ObservableObject {
    @Published var trips: [Trip]
    @Published var categories: [TripCategory]
    @Published var settings: UserSettings

    init(
        trips: [Trip] = [],
        categories: [TripCategory] = [
            .documents, .clothes, .hygiene, .electronics
        ],
        settings: UserSettings = .default
    ) {
        self.trips = trips
        self.categories = categories
        self.settings = settings
    }
    
    func addCustomCategory(_ category: TripCategory) {
        if !categories.contains(where: { $0.id == category.id }) {
            categories.append(category)
        }
    }
    
    func deleteCategory(_ category: TripCategory) {
        // Don't delete system categories
        guard !category.system else { return }
        categories.removeAll { $0.id == category.id }
    }
}


