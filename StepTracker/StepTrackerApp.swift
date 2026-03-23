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
                .preferredColorScheme(.dark)
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
        ZStack {
            // Fond de secours qui couvre toute la fenêtre, y compris les zones hors safe area
            Color(red: 0.08, green: 0.12, blue: 0.40)
                .ignoresSafeArea(.all)

            switch path.last {
            case .permissions:
                HealthKitPermissionsView(path: $path)
            case .steps:
                StepTrackingView(path: $path)
            case .sleep:
                SleepTrackingView(path: $path)
            case .dashboard:
                DashboardView(path: $path)
            case .none:
                HomeMenuView(path: $path)
            }
        }
        .onAppear {
            guard !launched else { return }
            launched = true
            if let page = AppPage(rawValue: defaultPage) {
                path = [page]
            }
        }
        .onOpenURL { url in
            // Deep link depuis un widget : steptracker://steps  ou  steptracker://sleep
            guard url.scheme == "steptracker",
                  let page = AppPage(rawValue: url.host ?? "") else { return }
            path = [page]
        }
    }
}
