import Foundation
import SwiftUI

// MARK: - Achievement System

struct AchievementDefinition {
    let id: Int
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

extension AchievementDefinition {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: 1, title: "First Suitcase", description: "Create your first trip checklist", iconName: "suitcase", color: .blue),
        AchievementDefinition(id: 2, title: "Nothing Forgotten", description: "Check off all items in one trip", iconName: "checkmark.circle.fill", color: .green),
        AchievementDefinition(id: 3, title: "Light Backpack", description: "Create a checklist with < 5 items", iconName: "backpack", color: .yellow),
        AchievementDefinition(id: 4, title: "Packed the Whole House", description: "Create a checklist with > 30 items", iconName: "house.fill", color: .purple),
        AchievementDefinition(id: 5, title: "Weekend Traveler", description: "Complete a 1–2 day trip checklist", iconName: "calendar", color: .orange),
        AchievementDefinition(id: 6, title: "Packing Master", description: "Complete 5 different trips", iconName: "star.fill", color: .red),
        AchievementDefinition(id: 7, title: "Experienced Tourist", description: "Complete 10 different trips", iconName: "globe", color: .indigo),
        AchievementDefinition(id: 8, title: "Baggage Organizer", description: "Add notes to 10 items", iconName: "note.text", color: .pink),
        AchievementDefinition(id: 9, title: "Seasonal Traveler", description: "Create checklists for 4 seasons", iconName: "leaf", color: .mint),
        AchievementDefinition(id: 10, title: "No Panic", description: "Complete on the day of departure", iconName: "clock.fill", color: .red),
        AchievementDefinition(id: 11, title: "Everything Under Control", description: "Complete a week before departure", iconName: "calendar.badge.checkmark", color: .green),
        AchievementDefinition(id: 12, title: "Global Tourist", description: "Use the app in two languages", iconName: "character.cursor.ibeam", color: .blue),
        AchievementDefinition(id: 13, title: "Note Master", description: "Add your first note", iconName: "pencil", color: .orange),
        AchievementDefinition(id: 14, title: "Checklist Pro", description: "Create 20 trip checklists", iconName: "trophy.fill", color: .yellow),
        AchievementDefinition(id: 15, title: "Road Legend", description: "Complete 50 checklists", iconName: "crown.fill", color: .purple)
    ]
}

final class AchievementService: ObservableObject {
    @Published var unlockedAchievements: Set<Int> = []
    
    private let storageKey = "unlocked_achievements"
    
    init() {
        loadUnlockedAchievements()
    }
    
    func checkAchievements(for appState: AppState) {
        let newAchievements = calculateNewAchievements(for: appState)
        for achievementId in newAchievements {
            unlockAchievement(achievementId)
        }
    }
    
    private func calculateNewAchievements(for appState: AppState) -> [Int] {
        var newAchievements: [Int] = []
        
        // Achievement 1: First Suitcase
        if appState.trips.count >= 1 && !unlockedAchievements.contains(1) {
            newAchievements.append(1)
        }
        
        // Achievement 2: Nothing Forgotten
        for trip in appState.trips {
            if trip.totalItemCount > 0 && trip.completedItemCount == trip.totalItemCount && !unlockedAchievements.contains(2) {
                newAchievements.append(2)
                break
            }
        }
        
        // Achievement 3: Light Backpack
        for trip in appState.trips {
            if trip.totalItemCount < 5 && trip.totalItemCount > 0 && !unlockedAchievements.contains(3) {
                newAchievements.append(3)
                break
            }
        }
        
        // Achievement 4: Packed the Whole House
        for trip in appState.trips {
            if trip.totalItemCount > 30 && !unlockedAchievements.contains(4) {
                newAchievements.append(4)
                break
            }
        }
        
        // Achievement 5: Weekend Traveler (simplified - any completed trip)
        let completedTrips = appState.trips.filter { $0.completedItemCount == $0.totalItemCount && $0.totalItemCount > 0 }
        if completedTrips.count >= 1 && !unlockedAchievements.contains(5) {
            newAchievements.append(5)
        }
        
        // Achievement 6: Packing Master
        if completedTrips.count >= 5 && !unlockedAchievements.contains(6) {
            newAchievements.append(6)
        }
        
        // Achievement 7: Experienced Tourist
        if completedTrips.count >= 10 && !unlockedAchievements.contains(7) {
            newAchievements.append(7)
        }
        
        // Achievement 8: Baggage Organizer
        let itemsWithNotes = appState.trips.flatMap { $0.items }.filter { $0.note != nil && !$0.note!.isEmpty }
        if itemsWithNotes.count >= 10 && !unlockedAchievements.contains(8) {
            newAchievements.append(8)
        }
        
        // Achievement 13: Note Master
        if itemsWithNotes.count >= 1 && !unlockedAchievements.contains(13) {
            newAchievements.append(13)
        }
        
        // Achievement 14: Checklist Pro
        if appState.trips.count >= 20 && !unlockedAchievements.contains(14) {
            newAchievements.append(14)
        }
        
        // Achievement 15: Road Legend
        if completedTrips.count >= 50 && !unlockedAchievements.contains(15) {
            newAchievements.append(15)
        }
        
        return newAchievements
    }
    
    private func unlockAchievement(_ id: Int) {
        unlockedAchievements.insert(id)
        saveUnlockedAchievements()
    }
    
    private func loadUnlockedAchievements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let achievements = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            unlockedAchievements = achievements
        }
    }
    
    private func saveUnlockedAchievements() {
        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func getAchievementDefinition(for id: Int) -> AchievementDefinition? {
        return AchievementDefinition.all.first { $0.id == id }
    }
    
    func isUnlocked(_ id: Int) -> Bool {
        return unlockedAchievements.contains(id)
    }
}

