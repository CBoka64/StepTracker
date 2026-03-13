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
@main
struct StepWidgetBundle: WidgetBundle {

    /// Liste des widgets déclarés dans cette extension.
    ///
    /// Chaque widget retourné ici apparaît comme une entrée distincte
    /// dans la galerie de widgets d'iOS.
    var body: some Widget {
        StepWidget()
    }
}
