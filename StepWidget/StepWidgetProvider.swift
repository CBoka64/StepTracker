// StepWidgetProvider.swift
// StepWidgetExtension
//
// Le "Provider" est le cerveau du widget. Il répond aux trois questions d'iOS :
//   1. placeholder()  — un aperçu générique pour la galerie
//   2. snapshot()     — un aperçu rapide (données réelles si possible)
//   3. timeline()     — les vraies données + la date du prochain rafraîchissement

import WidgetKit
import SwiftUI

// MARK: - État de chargement du widget

/// Décrit l'état des données du widget.
///
/// Permet à `StepWidgetView` d'afficher une interface adaptée à chaque situation :
/// données chargées, HealthKit non disponible sur l'appareil, ou accès non accordé.
enum WidgetLoadState {
    /// Données chargées avec succès depuis HealthKit.
    case loaded
    /// HealthKit n'est pas disponible sur cet appareil (certains iPad sans app Santé).
    case unavailable
    /// L'accès HealthKit n'a pas encore été accordé — l'app principale doit être ouverte.
    case unauthorized
}

// MARK: - Modèle de données du widget

/// Paquet de données que le widget affiche à un instant précis.
///
/// Conforme au protocole `TimelineEntry`, `StepEntry` encapsule les données nécessaires
/// au rendu du widget : date, nombre de pas, objectif et état de chargement.
/// Les propriétés calculées (`progress`, `progressColor`, `gradientColors`)
/// dérivent toutes de ces valeurs de base.
struct StepEntry: TimelineEntry {

    /// Date à laquelle cette entrée doit être affichée par le widget.
    let date: Date

    /// Nombre de pas enregistrés depuis minuit jusqu'au moment de la requête.
    let stepCount: Int

    /// Objectif quotidien défini par l'utilisateur, lu depuis l'App Group partagé.
    let stepGoal: Int

    /// État de chargement — détermine quelle interface est affichée dans le widget.
    let state: WidgetLoadState

    /// Ratio de progression entre 0.0 et 1.0+ (non plafonné à 1.0).
    ///
    /// Retourne `0` si `stepGoal` vaut 0 pour éviter une division par zéro.
    var progress: Double {
        guard stepGoal > 0 else { return 0 }
        return Double(stepCount) / Double(stepGoal)
    }

    /// Couleur principale selon le palier de progression.
    ///
    /// Utilise les mêmes paliers et couleurs que `ContentView` dans l'app principale
    /// pour garantir la cohérence visuelle.
    ///
    /// | Plage (%)  | Couleur               |
    /// |-----------:|:----------------------|
    /// | 0 – 10     | Rouge                 |
    /// | 11 – 50    | Orange                |
    /// | 51 – 80    | Jaune lisible         |
    /// | 81 +       | Vert profond          |
    var progressColor: Color {
        switch progress * 100 {
        case ..<11:
            return .red
        case 11..<51:
            return .orange
        case 51..<81:
            return Color(red: 0.85, green: 0.75, blue: 0.1) // jaune lisible (cohérent avec l'app)
        default:
            return Color(red: 0.1, green: 0.75, blue: 0.35) // vert profond (cohérent avec l'app)
        }
    }

    /// Dégradé dynamique utilisé comme fond du widget.
    ///
    /// Part de la couleur principale vers une version plus sombre,
    /// cohérent avec le fond dégradé de l'app principale.
    var gradientColors: [Color] {
        switch progress * 100 {
        case ..<11:
            return [.red, .red.opacity(0.6)]
        case 11..<51:
            return [.orange, .red.opacity(0.7)]
        case 51..<81:
            return [Color(red: 0.85, green: 0.75, blue: 0.1),
                    Color.orange.opacity(0.7)]
        default:
            return [Color(red: 0.1, green: 0.75, blue: 0.35),
                    Color(red: 0.05, green: 0.5, blue: 0.25)]
        }
    }
}

// MARK: - Provider

/// Fournisseur de données pour le widget de pas.
///
/// `StepWidgetProvider` implémente `TimelineProvider`. iOS appelle ses méthodes
/// selon le contexte pour obtenir les données à afficher et planifier les prochains
/// rafraîchissements.
///
/// La méthode clé `buildEntry()` centralise la logique de chargement HealthKit
/// et retourne toujours un `StepEntry` avec l'état approprié.
struct StepWidgetProvider: TimelineProvider {

    private let healthManager = HealthKitManager.shared

    // MARK: - Placeholder (galerie de widgets)

    /// Aperçu générique affiché dans la galerie de widgets d'iOS.
    ///
    /// Données fictives — aucun accès HealthKit requis. iOS peut appeler
    /// cette méthode de façon synchrone, sans délai.
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(date: Date(), stepCount: 6_500, stepGoal: 10_000, state: .loaded)
    }

    // MARK: - Snapshot (aperçu rapide)

    /// Aperçu rapide : données fictives en mode preview, données réelles en production.
    ///
    /// `context.isPreview` est `true` quand l'utilisateur parcourt la galerie de widgets.
    /// Dans ce cas, on retourne des données fictives immédiatement sans interroger HealthKit.
    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            completion(await buildEntry())
        }
    }

    // MARK: - Timeline (production)

    /// Construit la timeline et planifie le prochain rafraîchissement.
    ///
    /// Politique de rafraîchissement adaptative selon l'état :
    /// - **Chargé** : toutes les 15 minutes (données fraîches sans épuiser la batterie)
    /// - **Indisponible** : `.never` (HealthKit absent → inutile de réessayer)
    /// - **Non autorisé** : dans 1 heure (l'utilisateur aura peut-être ouvert l'app)
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        Task {
            let entry = await buildEntry()

            let policy: TimelineReloadPolicy
            switch entry.state {
            case .loaded:
                // Rafraîchissement toutes les 15 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
                    ?? Date().addingTimeInterval(900)
                policy = .after(nextUpdate)
            case .unavailable:
                // HealthKit non disponible sur cet appareil → ne jamais réessayer
                policy = .never
            case .unauthorized:
                // Réessayer dans 1 heure, au cas où l'utilisateur ait accordé l'accès entre-temps
                policy = .after(Date().addingTimeInterval(3_600))
            }

            completion(Timeline(entries: [entry], policy: policy))
        }
    }

    // MARK: - Construction de l'entrée

    /// Tente de lire les pas via HealthKit et construit le `StepEntry` correspondant.
    ///
    /// Cette méthode centralise toute la logique de chargement et de gestion d'erreur.
    /// Elle retourne toujours un `StepEntry` valide — jamais nil, jamais de crash.
    ///
    /// - Returns: Un `StepEntry` avec l'état `.loaded`, `.unavailable` ou `.unauthorized`.
    private func buildEntry() async -> StepEntry {
        // Étape 1 : vérifier que HealthKit est disponible sur cet appareil
        guard healthManager.isAvailable else {
            return StepEntry(
                date: Date(),
                stepCount: 0,
                stepGoal: healthManager.stepGoal,
                state: .unavailable
            )
        }

        // Étape 2 : tenter de récupérer les pas
        // Si l'autorisation n'a pas été accordée dans l'app, la requête lancera une erreur.
        do {
            let steps = try await healthManager.fetchTodayStepCount()
            return StepEntry(
                date: Date(),
                stepCount: steps,
                stepGoal: healthManager.stepGoal,
                state: .loaded
            )
        } catch {
            // Toute erreur ici signifie que HealthKit n'est pas accessible :
            // autorisation refusée, ou HealthKit non fonctionnel (simulateur iOS).
            return StepEntry(
                date: Date(),
                stepCount: 0,
                stepGoal: healthManager.stepGoal,
                state: .unauthorized
            )
        }
    }
}
