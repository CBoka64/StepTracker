// StepWidget.swift
// StepWidgetExtension
//
// C'est le point d'entrée du widget — le fichier qui "enregistre" le widget
// auprès d'iOS. C'est ici qu'on déclare :
//   - Quel Provider utiliser (StepWidgetProvider)
//   - Quelle vue afficher (StepWidgetView)
//   - Quelles tailles supporter (small + medium)
//   - Les métadonnées (nom, description)

import WidgetKit
import SwiftUI

// MARK: - Déclaration du widget

/// Widget de suivi de pas, disponible en tailles small (carré) et medium (rectangulaire).
///
/// `StepWidget` orchestre les trois composants fondamentaux d'un widget WidgetKit :
/// - **Provider** (`StepWidgetProvider`) — fournit les données au bon moment
/// - **Vue** (`StepWidgetView`) — dessine l'interface
/// - **Fond** — un dégradé dynamique calculé depuis `StepEntry.gradientColors`
///
/// > Note : Ce fichier ne contient pas `@main` ; c'est `StepWidgetBundle`
/// > qui joue ce rôle de point d'entrée de l'extension.
struct StepWidget: Widget {

    /// Identifiant unique du widget, utilisé par iOS pour le référencer et le retrouver.
    ///
    /// Convention : bundle identifier inversé de l'app + suffixe descriptif.
    /// Doit être stable dans le temps — changer cet ID supprime les widgets
    /// déjà ajoutés sur l'écran d'accueil de l'utilisateur.
    let kind: String = "com.bc046.steptracker.widget"

    /// Configuration déclarative du widget : tailles supportées, provider de données,
    /// fond dégradé dynamique et métadonnées affichées dans la galerie.
    ///
    /// On utilise `StaticConfiguration` (pas de configuration utilisateur interactive).
    /// Si l'on voulait permettre à l'utilisateur de choisir son objectif directement
    /// depuis la galerie, on utiliserait `AppIntentConfiguration` à la place.
    var body: some WidgetConfiguration {

        // StaticConfiguration = widget sans configuration utilisateur interactive.
        StaticConfiguration(
            kind: kind,
            provider: StepWidgetProvider()
        ) { entry in
            StepWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: entry.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Suivi de pas")
        .description("Affiche vos pas du jour avec un dégradé de couleur selon votre objectif.")
        .supportedFamilies([
            .systemSmall,   // Widget carré
            .systemMedium   // Widget rectangulaire
        ])
    }
}
