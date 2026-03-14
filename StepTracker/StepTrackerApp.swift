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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 1 — Swift repère @main et démarre l'application ici
// ═══════════════════════════════════════════════════════════════
// L'annotation @main dit au compilateur Swift :
// "C'est cette structure qui est le point de départ de l'application."
// Sans elle, l'app ne saurait pas par où commencer. Une seule structure
// peut porter @main dans tout le projet.
@main
struct StepTrackerApp: App {

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 2 — On déclare le type de l'application via le protocole App
    // ═══════════════════════════════════════════════════════════════
    // Le protocole App oblige à définir une propriété "body" de type Scene.
    // C'est SwiftUI qui appelle automatiquement ce body au démarrage
    // pour construire l'interface de l'app.

    /// La scène racine de l'application : une `WindowGroup` contenant `ContentView`.
    ///
    /// `WindowGroup` crée autant de fenêtres que le système le permet
    /// (plusieurs fenêtres sur iPad ou macOS, une seule sur iPhone).
    var body: some Scene {

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 3 — WindowGroup crée la fenêtre et affiche ContentView
        // ═══════════════════════════════════════════════════════════════
        // WindowGroup est le conteneur de fenêtre standard SwiftUI.
        // Sur iPhone : une seule fenêtre est créée.
        // Sur iPad/Mac : plusieurs fenêtres peuvent exister en même temps.
        // ContentView est la première vue que l'utilisateur voit à l'écran.
        WindowGroup {
            ContentView()
        }
    }
}
