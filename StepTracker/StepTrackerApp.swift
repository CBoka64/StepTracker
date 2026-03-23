// StepTrackerApp.swift
// StepTracker
//
// Point d'entrée de l'application et routage au lancement.
// AppRootView lit la page par défaut choisie par l'utilisateur
// et navigue directement vers elle si elle est définie.

import SwiftUI

// MARK: - Pages de navigation

/// Identifie les 4 sections navigables de l'application.
///
/// Conforme à `Hashable` pour être utilisé avec `NavigationStack`.
/// La valeur `rawValue` (String) est persistée dans `@AppStorage`
/// pour mémoriser la page d'accueil choisie par l'utilisateur.
enum AppPage: String, Hashable {
    case permissions
    case steps
    case sleep
    case dashboard
}

// MARK: - Point d'entrée

@main
struct StepTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

// MARK: - Routage au lancement

/// Vue racine : gère le menu principal et la navigation vers chaque section.
///
/// Au premier lancement, si une page par défaut a été enregistrée
/// (via le bouton ⌂ dans chaque section), l'app navigue directement
/// vers cette section sans passer par le menu.
struct AppRootView: View {

    /// Page d'accueil persistée. Vide = afficher le menu.
    @AppStorage("defaultPage") private var defaultPage: String = ""

    /// Pile de navigation SwiftUI.
    @State private var path: [AppPage] = []

    /// Garde-fou pour n'appliquer la page par défaut qu'une seule fois par session.
    @State private var launched = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeMenuView()
                .navigationDestination(for: AppPage.self) { page in
                    switch page {
                    case .permissions:
                        HealthKitPermissionsView()
                    case .steps:
                        StepTrackingView()
                    case .sleep:
                        SleepTrackingView()
                    case .dashboard:
                        DashboardView()
                    }
                }
        }
        .onAppear {
            guard !launched else { return }
            launched = true
            // Naviguer directement vers la page par défaut si elle est définie
            if let page = AppPage(rawValue: defaultPage) {
                path = [page]
            }
        }
    }
}
