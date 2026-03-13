// StepTrackerApp.swift
// StepTracker
//
// Point d'entrée de l'application. Le modificateur @main indique à Swift
// que c'est ici que l'exécution commence. Cette structure crée une fenêtre
// et y injecte ContentView comme vue racine.

import SwiftUI

// MARK: - Point d'entrée de l'app

/// Point d'entrée de l'application StepTracker.
///
/// Annotée `@main`, cette structure est instanciée automatiquement par le
/// runtime Swift/SwiftUI au lancement de l'app. Elle déclare une `WindowGroup`
/// qui encapsule `ContentView` et gère nativement le multifenêtrage
/// sur iPad et Mac.
@main
struct StepTrackerApp: App {

    /// La scène racine de l'application : une `WindowGroup` contenant `ContentView`.
    ///
    /// `WindowGroup` crée autant de fenêtres que le système le permet
    /// (plusieurs fenêtres sur iPad ou macOS, une seule sur iPhone).
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
