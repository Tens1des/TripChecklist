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
                    Label(LocalizedString.localized("tab.lists", language: appState.settings.language), systemImage: "checklist")
                }

            HistoryView()
                .tabItem {
                    Label(LocalizedString.localized("tab.history", language: appState.settings.language), systemImage: "clock")
                }

            AchievementsView()
                .tabItem {
                    Label(LocalizedString.localized("tab.awards", language: appState.settings.language), systemImage: "star")
                }

            SettingsView()
                .tabItem {
                    Label(LocalizedString.localized("tab.settings", language: appState.settings.language), systemImage: "gear")
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
