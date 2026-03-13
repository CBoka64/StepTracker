// StepWidgetView.swift
// StepWidgetExtension
//
// C'est ici que tout le design visuel du widget est défini.
// On crée deux vues : une pour le format carré (small) et une pour le rectangulaire (medium).
// Le dégradé de couleur change dynamiquement selon la progression.

import SwiftUI
import WidgetKit

// MARK: - Vue principale du widget

/// Vue racine du widget, qui délègue le rendu à `SmallWidgetView` ou `MediumWidgetView`
/// selon la taille de widget choisie par l'utilisateur.
///
/// WidgetKit injecte automatiquement la famille via `@Environment(\.widgetFamily)`.
/// Toute nouvelle taille supportée (`.systemLarge`, etc.) doit être ajoutée
/// dans le `switch` de `body` ET dans `supportedFamilies` de `StepWidget`.
struct StepWidgetView: View {

    /// Données fournies par `StepWidgetProvider` pour cet instant de la timeline.
    let entry: StepEntry

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 1 — Détecter automatiquement la taille du widget
    // ═══════════════════════════════════════════════════════════════
    // @Environment(\.widgetFamily) est injecté automatiquement par WidgetKit.
    // Il indique la taille du widget choisie par l'utilisateur :
    //   - .systemSmall  → widget carré (petite taille)
    //   - .systemMedium → widget rectangulaire (taille moyenne)
    //   - .systemLarge  → widget tall (non supporté ici)
    // Cette valeur est lue à l'affichage, on ne peut pas la modifier.

    /// Taille du widget détectée automatiquement par WidgetKit.
    ///
    /// `.systemSmall` = carré · `.systemMedium` = rectangulaire.
    /// Modifiée par le système uniquement — ne pas assigner manuellement.
    @Environment(\.widgetFamily) var widgetFamily

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 2 — Router vers la bonne vue selon la taille du widget
    // ═══════════════════════════════════════════════════════════════
    // Le switch sur widgetFamily choisit quelle vue afficher.
    // C'est le seul rôle de StepWidgetView : servir de "routeur".
    // Chaque vue (SmallWidgetView, MediumWidgetView) s'occupe de
    // son propre design indépendamment.
    // Le cas "default" couvre les tailles non prévues (sécurité).

    /// La vue SwiftUI rendue par ce composant.
    ///
    /// Sélectionne la mise en page appropriée selon la taille du widget.
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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 3 — SmallWidgetView : layout carré en colonne verticale
// ═══════════════════════════════════════════════════════════════
// Le widget small est un carré compact. On empile les éléments
// verticalement (VStack) de haut en bas :
//   1. Icône de marche (SF Symbol)
//   2. Nombre de pas (gros chiffre)
//   3. Label "pas"
//   4. Barre de progression horizontale
//   5. Texte de l'objectif (petit)
//
// L'espace est limité, donc on garde uniquement l'essentiel.

/// Layout compact pour le widget carré (`.systemSmall`).
///
/// Affiche du haut vers le bas : icône de marche, nombre de pas,
/// libellé "pas", barre de progression, objectif en petit texte.
/// Le fond dégradé est défini dans `StepWidget.containerBackground`.
struct SmallWidgetView: View {

    /// Données fournies par le provider pour cet instant de la timeline.
    let entry: StepEntry

    /// La vue SwiftUI rendue par ce composant.
    var body: some View {
        VStack(spacing: 8) {
            // ═══════════════════════════════════════════════════════════════
            // ÉTAPE 4 — SF Symbol : icône native iOS sans asset custom
            // ═══════════════════════════════════════════════════════════════
            // Image(systemName:) utilise les SF Symbols d'Apple : une
            // bibliothèque de +6000 icônes vectorielles intégrées à iOS.
            // Avantages : pas de fichier image à gérer, s'adaptent aux
            // tailles de police, disponibles dans toutes les épaisseurs.
            // "figure.walk" = icône d'une personne qui marche.
            Image(systemName: "figure.walk")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            // Nombre de pas — le chiffre principal, bien visible
            // ═══════════════════════════════════════════════════════════════
            // ÉTAPE 5 — minimumScaleFactor : réduire la taille si nécessaire
            // ═══════════════════════════════════════════════════════════════
            // Si le nombre de pas est très grand (ex: "12 345"), il pourrait
            // ne pas rentrer dans le widget. .minimumScaleFactor(0.6) autorise
            // iOS à réduire la taille de la police jusqu'à 60% de l'original.
            // .lineLimit(1) force le texte à tenir sur une seule ligne.
            Text("\(entry.stepCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)  // Réduit la taille si le nombre est très grand
                .lineLimit(1)

            // Label "pas" sous le nombre
            Text("pas")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            // ═══════════════════════════════════════════════════════════════
            // ÉTAPE 6 — ProgressBarView : barre de progression réutilisable
            // ═══════════════════════════════════════════════════════════════
            // ProgressBarView est un composant séparé (défini plus bas)
            // qu'on réutilise dans les deux tailles de widget.
            // entry.progress = ratio entre 0.0 et 1.0 (calculé dans StepEntry).
            // .frame(height: 6) fixe la hauteur de la barre à 6 points.
            // .padding(.horizontal, 8) laisse un espace de 8 points sur les côtés.
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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 7 — MediumWidgetView : layout rectangulaire en deux colonnes
// ═══════════════════════════════════════════════════════════════
// Le widget medium est deux fois plus large que le small.
// On utilise un HStack pour diviser l'espace en deux colonnes :
//   Colonne gauche : icône dans cercle + grand nombre de pas
//   Colonne droite : pourcentage + barre + objectif + pas restants
//
// .frame(maxWidth: .infinity) sur chaque colonne les force à partager
// l'espace disponible en deux moitiés égales.

/// Layout élargi pour le widget rectangulaire (`.systemMedium`).
///
/// Divise l'espace en deux colonnes :
/// - **Gauche** : icône dans un cercle translucide + nombre de pas
/// - **Droite** : pourcentage, barre de progression, objectif, pas restants
struct MediumWidgetView: View {

    /// Données fournies par le provider pour cet instant de la timeline.
    let entry: StepEntry

    /// La vue SwiftUI rendue par ce composant.
    var body: some View {
        HStack(spacing: 16) {

            // ════════════════════════════════════════════════════════════
            // ÉTAPE 8 — Colonne gauche : icône dans cercle + nombre de pas
            // ════════════════════════════════════════════════════════════
            // ZStack superpose un cercle blanc translucide et l'icône par-dessus.
            // C'est une technique courante pour créer un "badge" d'icône.
            // Circle().fill(.white.opacity(0.2)) = fond circulaire semi-transparent.
            // L'icône figure.walk est centrée automatiquement par ZStack.
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

            // ════════════════════════════════════════════════════════════
            // ÉTAPE 9 — Colonne droite : détails de progression
            // ════════════════════════════════════════════════════════════
            // Cette colonne affiche 4 informations empilées verticalement :
            //   1. Pourcentage atteint (ex: "65%") avec icône cible
            //   2. Barre de progression horizontale (ProgressBarView)
            //   3. Objectif total avec icône drapeau
            //   4. Pas restants OU "Objectif atteint !" si 0 restants
            //
            // Pour les pas restants : max(0, ...) évite les valeurs négatives
            // si les pas dépassent l'objectif. L'opérateur ternaire "? :"
            // choisit le texte et l'icône selon si remaining == 0 ou non.
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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 10 — ProgressBarView : barre de progression avec GeometryReader
// ═══════════════════════════════════════════════════════════════
// Une barre de progression horizontale se compose de deux rectangles :
//   1. Le fond (semi-transparent, largeur 100%)
//   2. Le remplissage (blanc, largeur = progress × largeur totale)
//
// GeometryReader est nécessaire pour connaître la largeur disponible
// en points (geometry.size.width) et calculer la largeur du remplissage.
// ZStack(alignment: .leading) superpose les deux rectangles avec le
// remplissage aligné à gauche.
//
// min(progress, 1.0) plafonne visuellement la barre à 100% même si
// l'utilisateur a fait 120% de son objectif.

/// Barre de progression horizontale personnalisée avec coins arrondis.
///
/// Le remplissage est proportionnel à `progress` (plafonné à 100% visuellement
/// grâce à `min(progress, 1.0)`), sur un fond semi-transparent blanc.
/// Utilisée à la fois dans `SmallWidgetView` et `MediumWidgetView`.
struct ProgressBarView: View {

    /// Ratio de remplissage entre 0.0 (vide) et 1.0+ (plein).
    ///
    /// Les valeurs supérieures à 1.0 sont acceptées mais clampées visuellement
    /// à la largeur totale de la barre (l'arc ne déborde pas).
    let progress: Double

    /// La vue SwiftUI rendue par ce composant.
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

/// Ces previews permettent de voir le widget directement dans Xcode
/// sans avoir besoin de le compiler et le lancer sur un vrai iPhone.

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
