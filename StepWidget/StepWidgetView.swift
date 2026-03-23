// StepWidgetView.swift
// StepWidgetExtension
//
// Design visuel du widget. Trois états possibles :
//   - .loaded      → affiche les vraies données (pas + objectif + barre)
//   - .unavailable → HealthKit absent sur cet appareil (certains iPad)
//   - .unauthorized → l'app principale doit être ouverte pour autoriser l'accès

import SwiftUI
import WidgetKit

// MARK: - Vue principale du widget

/// Vue racine du widget, qui délègue le rendu à `SmallWidgetView` ou `MediumWidgetView`
/// selon la taille de widget choisie par l'utilisateur.
///
/// `.widgetURL` est défini dans chaque vue enfant pour que le tap ouvre l'app principale.
struct StepWidgetView: View {

    let entry: StepEntry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Carré (Small)

/// Layout compact pour le widget carré (`.systemSmall`).
///
/// Affiche un contenu différent selon l'état du widget :
/// - `.loaded`       → icône + pas + barre de progression + objectif
/// - `.unavailable`  → message "HealthKit non disponible"
/// - `.unauthorized` → message "Ouvre l'app pour autoriser"
///
/// `.widgetURL` permet d'ouvrir l'app en tapant sur le widget.
struct SmallWidgetView: View {

    let entry: StepEntry

    var body: some View {
        Group {
            switch entry.state {
            case .loaded:
                loadedContent
            case .unavailable:
                stateContent(
                    icon: "heart.slash.fill",
                    message: "HealthKit\nnon disponible"
                )
            case .unauthorized:
                stateContent(
                    icon: "lock.shield.fill",
                    message: "Ouvre l'app\npour autoriser"
                )
            }
        }
        .padding(12)
        // Taper sur le widget ouvre l'app principale
        .widgetURL(URL(string: "steptracker://open"))
    }

    // MARK: - Contenu chargé

    /// Vue affichée quand les données HealthKit sont disponibles.
    private var loadedContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.walk")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            Text("\(entry.stepCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("pas")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            ProgressBarView(progress: entry.progress)
                .frame(height: 6)
                .padding(.horizontal, 8)

            Text("/ \(entry.stepGoal) pas")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Contenu d'état (erreur)

    /// Vue affichée en cas d'indisponibilité ou d'accès non accordé.
    ///
    /// - Parameters:
    ///   - icon: SF Symbol à afficher.
    ///   - message: Texte explicatif en deux lignes.
    private func stateContent(icon: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Rectangulaire (Medium)

/// Layout élargi pour le widget rectangulaire (`.systemMedium`).
///
/// Divise l'espace en deux colonnes :
/// - **Gauche** : icône dans un cercle translucide + nombre de pas
/// - **Droite**  : pourcentage, barre de progression, objectif, pas restants
///
/// En cas d'erreur, affiche un message centré sur toute la largeur.
struct MediumWidgetView: View {

    let entry: StepEntry

    var body: some View {
        Group {
            switch entry.state {
            case .loaded:
                loadedContent
            case .unavailable:
                stateContent(
                    icon: "heart.slash.fill",
                    message: "HealthKit non disponible sur cet appareil"
                )
            case .unauthorized:
                stateContent(
                    icon: "lock.shield.fill",
                    message: "Ouvre l'app StepTracker pour autoriser l'accès à Santé"
                )
            }
        }
        .padding(16)
        .widgetURL(URL(string: "steptracker://open"))
    }

    // MARK: - Contenu chargé (deux colonnes)

    private var loadedContent: some View {
        HStack(spacing: 16) {

            // Colonne gauche : icône + nombre de pas
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "figure.walk")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("\(entry.stepCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("pas aujourd'hui")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)

            // Colonne droite : progression détaillée
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(Int(min(entry.progress, 9.99) * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                ProgressBarView(progress: entry.progress)
                    .frame(height: 8)

                HStack {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Objectif : \(entry.stepGoal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                let remaining = max(0, entry.stepGoal - entry.stepCount)
                HStack {
                    Image(systemName: remaining == 0 ? "checkmark.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))

                    Text(remaining == 0 ? "Objectif atteint !" : "Encore \(remaining) pas")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Contenu d'état (erreur)

    private func stateContent(icon: String, message: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Barre de progression réutilisable

/// Barre de progression horizontale avec coins arrondis.
///
/// Le remplissage est proportionnel à `progress`, plafonné visuellement à 100 %
/// (`min(progress, 1.0)`). Le fond est semi-transparent, le remplissage est blanc.
struct ProgressBarView: View {

    /// Ratio de remplissage entre 0.0 (vide) et 1.0+ (plein).
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.3))

                RoundedRectangle(cornerRadius: 4)
                    .fill(.white)
                    .frame(width: geometry.size.width * min(progress, 1.0))
            }
        }
    }
}

// MARK: - Previews Xcode

#Preview("Small – Rouge (5%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 500, stepGoal: 10_000, state: .loaded)
}

#Preview("Small – Orange (35%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 3_500, stepGoal: 10_000, state: .loaded)
}

#Preview("Small – Jaune (65%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 6_500, stepGoal: 10_000, state: .loaded)
}

#Preview("Small – Vert (95%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 9_500, stepGoal: 10_000, state: .loaded)
}

#Preview("Small – Non autorisé", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 0, stepGoal: 10_000, state: .unauthorized)
}

#Preview("Medium – Orange", as: .systemMedium) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 4_200, stepGoal: 10_000, state: .loaded)
}

#Preview("Medium – Objectif atteint", as: .systemMedium) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 11_500, stepGoal: 10_000, state: .loaded)
}

#Preview("Medium – Non autorisé", as: .systemMedium) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 0, stepGoal: 10_000, state: .unauthorized)
}
