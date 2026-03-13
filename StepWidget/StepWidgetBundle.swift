// StepWidgetBundle.swift
// StepWidgetExtension
//
// Point d'entrée de l'extension widget. Le modificateur @main désigne ce bundle
// comme racine de l'extension. C'est ici qu'on liste tous les widgets disponibles
// dans l'application ; iOS les découvre via cette déclaration.

import WidgetKit
import SwiftUI

// MARK: - Bundle de l'extension widget

/// Bundle principal de l'extension widget, annoté `@main`.
///
/// Un `WidgetBundle` regroupe un ou plusieurs widgets sous une même extension.
/// iOS lit la propriété `body` pour découvrir quels widgets sont disponibles
/// et les afficher dans la galerie d'ajout de widgets.
///
/// > Note : Si vous créez de nouveaux widgets, ajoutez-les dans `body`.

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 1 — @main marque le point d'entrée de l'extension widget
// ═══════════════════════════════════════════════════════════════
// Tout comme l'app principale a son @main dans StepTrackerApp.swift,
// l'extension widget a son propre @main ici.
// iOS lance cette structure en premier quand il a besoin d'afficher
// ou de mettre à jour un widget de cette extension.
// IMPORTANT : il ne peut y avoir qu'UN SEUL @main par "target" (l'app
// principale et l'extension widget sont deux targets séparés).
@main

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 2 — WidgetBundle regroupe tous les widgets de l'extension
// ═══════════════════════════════════════════════════════════════
// Une extension widget peut contenir PLUSIEURS widgets différents.
// WidgetBundle est le conteneur qui les regroupe tous.
// iOS lit ce bundle pour savoir quels widgets proposer à l'utilisateur
// dans la galerie "Ajouter un widget".
struct StepWidgetBundle: WidgetBundle {

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 3 — body liste les widgets disponibles dans la galerie iOS
    // ═══════════════════════════════════════════════════════════════
    // Chaque widget listé ici apparaît comme une entrée distincte
    // dans la galerie de widgets iOS (appui long sur l'écran d'accueil
    // → "+" → rechercher "StepTracker").
    //
    // Pour ajouter un deuxième widget à l'avenir, il suffit d'ajouter
    // son nom ici, par exemple :
    //   StepWidget()
    //   MonNouveauWidget()

    /// Liste des widgets déclarés dans cette extension.
    ///
    /// Chaque widget retourné ici apparaît comme une entrée distincte
    /// dans la galerie de widgets d'iOS.
    var body: some Widget {
        StepWidget()
    }
}
