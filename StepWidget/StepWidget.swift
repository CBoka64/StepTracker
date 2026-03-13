// StepWidget.swift
// StepWidgetExtension
//
// C'est le point d'entrée du widget — le fichier qui "enregistre" ton widget
// auprès d'iOS. C'est ici qu'on déclare :
//   - Quel Provider utiliser (StepWidgetProvider)
//   - Quelle vue afficher (StepWidgetView)
//   - Quelles tailles supporter (small + medium)
//   - Les métadonnées (nom, description)

import WidgetKit
import SwiftUI

struct StepWidget: Widget {

    // Cet identifiant doit être UNIQUE parmi tous tes widgets.
    // Convention : utilise le bundle identifier inversé.
    let kind: String = "com.bc046.steptracker.widget"

    var body: some WidgetConfiguration {

        // StaticConfiguration = widget sans configuration utilisateur interactive.
        // (Si tu voulais un widget configurable — ex: choisir entre pas et calories —
        // tu utiliserais IntentConfiguration à la place.)
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
