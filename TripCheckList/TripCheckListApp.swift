//
//  TripCheckListApp.swift
//  TripCheckList
//
//  Created by Рома Котов on 02.10.2025.
//

import SwiftUI

@main
struct TripCheckListApp: App {
    @StateObject private var appState: AppState = {
        let state = StorageService.shared.load()
        return state
    }()
    @StateObject private var achievementService = AchievementService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(achievementService)
                .onChange(of: appState.trips) { _ in
                    StorageService.shared.save(appState)
                    achievementService.checkAchievements(for: appState)
                }
                .onChange(of: appState.settings) { _ in
                    StorageService.shared.save(appState)
                }
                .onChange(of: appState.categories) { _ in
                    StorageService.shared.save(appState)
                }
                .onAppear {
                    achievementService.checkAchievements(for: appState)
                }
        }
    }
}
