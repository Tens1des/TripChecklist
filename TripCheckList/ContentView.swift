//
//  ContentView.swift
//  TripCheckList
//
//  Created by Рома Котов on 02.10.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            TripsListView()
                .tabItem {
                    Label("Lists", systemImage: "checklist")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            AchievementsView()
                .tabItem {
                    Label("Awards", systemImage: "star")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environment(\.sizeCategory, sizeCategoryFromScale(appState.settings.textScale))
        .preferredColorScheme(colorSchemeFromTheme(appState.settings.theme))
        .background(Color(UIColor.systemBackground))
    }

    private func sizeCategoryFromScale(_ scale: Double) -> ContentSizeCategory {
        switch scale {
        case ..<0.95: return .small
        case 0.95..<1.05: return .medium
        case 1.05..<1.2: return .large
        default: return .extraLarge
        }
    }
    
    private func colorSchemeFromTheme(_ theme: UserSettings.Theme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    ContentView().environmentObject(AppState())
}
