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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 1 — Déclarer l'identifiant unique et stable du widget
    // ═══════════════════════════════════════════════════════════════
    // "kind" est le nom interne qu'iOS utilise pour identifier ce widget.
    // Convention : on utilise le bundle identifier de l'app en sens inverse
    // (reverse-DNS) suivi d'un suffixe descriptif.
    //
    // ATTENTION : si tu changes cet identifiant, tous les widgets déjà
    // placés sur l'écran d'accueil des utilisateurs seront supprimés !
    // Il faut donc le choisir une fois pour toutes et ne plus le modifier.

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

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 2 — StaticConfiguration : widget sans paramètre interactif
        // ═══════════════════════════════════════════════════════════════
        // Il existe deux types de configuration de widget :
        //   - StaticConfiguration : l'utilisateur ne peut PAS configurer
        //     le widget depuis la galerie (c'est notre cas).
        //   - AppIntentConfiguration : l'utilisateur peut choisir des options
        //     (ex : "afficher les pas de quelle journée ?").
        // On choisit StaticConfiguration car l'objectif se règle dans l'app.
        StaticConfiguration(
            kind: kind,

            // ═══════════════════════════════════════════════════════════════
            // ÉTAPE 3 — Connecter le provider (source de données)
            // ═══════════════════════════════════════════════════════════════
            // StepWidgetProvider est le "cerveau" du widget : c'est lui qui
            // fournit les données (pas du jour, objectif) à la bonne heure.
            // iOS appelera ses méthodes selon le contexte (aperçu, production...).
            provider: StepWidgetProvider()
        ) { entry in
            // ═══════════════════════════════════════════════════════════════
            // ÉTAPE 4 — Connecter la vue et lui appliquer le fond dégradé
            // ═══════════════════════════════════════════════════════════════
            // "entry" est le paquet de données fourni par StepWidgetProvider
            // (il contient stepCount, stepGoal, et les couleurs calculées).
            // StepWidgetView reçoit ces données et les affiche.
            //
            // .containerBackground définit le fond du widget de façon moderne
            // (requis depuis iOS 17). On utilise un LinearGradient dynamique
            // dont les couleurs changent avec la progression (rouge → vert).
            StepWidgetView(entry: entry)
                .widgetURL(URL(string: "steptracker://steps"))
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: entry.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        // Nom affiché dans la galerie de widgets d'iOS
        .configurationDisplayName("Suivi de pas")
        // Description affichée sous le nom dans la galerie
        .description("Affiche vos pas du jour avec un dégradé de couleur selon votre objectif.")

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 5 — Déclarer les tailles de widget supportées
        // ═══════════════════════════════════════════════════════════════
        // iOS propose plusieurs tailles de widgets. On déclare ici lesquelles
        // notre widget supporte. L'utilisateur pourra choisir entre les deux
        // dans la galerie.
        //   .systemSmall  = carré 1×1 (coin de l'écran d'accueil)
        //   .systemMedium = rectangulaire 2×1 (deux colonnes de largeur)
        // Si on n'ajoute pas une taille ici, elle n'apparaît pas dans la galerie.
        .supportedFamilies([
            .systemSmall,   // Widget carré
            .systemMedium   // Widget rectangulaire
        ])
    }
}
