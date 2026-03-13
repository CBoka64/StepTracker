// StepWidgetView.swift
// StepWidgetExtension
//
// C'est ici que tout le design visuel du widget est défini.
// On crée deux vues : une pour le format carré (small) et une pour le rectangulaire (medium).
// Le dégradé de couleur change dynamiquement selon la progression.

import SwiftUI
import WidgetKit

// MARK: - Vue principale du widget

/// Cette vue s'adapte automatiquement à la taille du widget (carré ou rectangulaire).
/// Elle détecte la famille de widget via @Environment et choisit le bon layout.
struct StepWidgetView: View {

    let entry: StepEntry

    // WidgetKit injecte automatiquement la taille du widget ici.
    // .systemSmall = carré, .systemMedium = rectangulaire
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

/// Layout compact : icône de pied en haut, nombre de pas au centre,
/// barre de progression en bas. Le tout sur un fond dégradé.
struct SmallWidgetView: View {
    let entry: StepEntry

    var body: some View {
        VStack(spacing: 8) {
            // Icône de pied
            // On utilise le SF Symbol "figure.walk" qui est natif iOS.
            // Pas besoin d'importer d'image custom !
            Image(systemName: "figure.walk")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            // Nombre de pas — le chiffre principal, bien visible
            Text("\(entry.stepCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)  // Réduit la taille si le nombre est très grand
                .lineLimit(1)

            // Label "pas" sous le nombre
            Text("pas")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            // Barre de progression horizontale
            ProgressBarView(progress: entry.progress)
                .frame(height: 6)
                .padding(.horizontal, 8)

            // Objectif en petit texte
            Text("Objectif : \(entry.stepGoal)")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
    }
}

// MARK: - Widget Rectangulaire (Medium)

/// Layout élargi : icône + texte à gauche, stats détaillées à droite.
/// Plus d'espace = plus d'informations affichées.
struct MediumWidgetView: View {
    let entry: StepEntry

    var body: some View {
        HStack(spacing: 16) {

            // ---- Côté gauche : icône + nombre de pas ----
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

            // ---- Côté droit : détails de progression ----
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(Int(entry.progress * 100))%")
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
        .padding(16)
    }
}

// MARK: - Barre de progression réutilisable

/// Une barre de progression personnalisée avec coins arrondis.
/// Le remplissage est proportionnel au ratio steps/goal (plafonné à 100% visuellement).
struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fond de la barre (semi-transparent)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.3))

                // Remplissage (plafonné à 100% pour ne pas déborder)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white)
                    .frame(
                        width: geometry.size.width * min(progress, 1.0)
                    )
            }
        }
    }
}

// MARK: - Preview pour Xcode

/// Ces previews te permettent de voir le widget directement dans Xcode
/// sans avoir besoin de le compiler et le lancer sur un vrai iPhone.
/// Super pratique pour itérer rapidement sur le design !

#Preview("Small - Rouge (5%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 500, stepGoal: 10_000)
}

#Preview("Small - Orange (35%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 3500, stepGoal: 10_000)
}

#Preview("Small - Jaune (65%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 6500, stepGoal: 10_000)
}

#Preview("Small - Vert (95%)", as: .systemSmall) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 9500, stepGoal: 10_000)
}

#Preview("Medium - Orange", as: .systemMedium) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 4200, stepGoal: 10_000)
}

#Preview("Medium - Objectif atteint", as: .systemMedium) {
    StepWidget()
} timeline: {
    StepEntry(date: Date(), stepCount: 11_500, stepGoal: 10_000)
}
