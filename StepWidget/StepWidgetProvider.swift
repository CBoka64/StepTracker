// StepWidgetProvider.swift
// StepWidgetExtension
//
// Le "Provider" est le cerveau du widget. C'est lui qui répond à iOS quand
// le système demande : "Qu'est-ce que je dois afficher, et quand dois-je
// revenir te demander ?"
//
// Il fournit 3 choses :
//   1. placeholder()  — un aperçu générique (affiché dans la galerie de widgets)
//   2. snapshot()     — un aperçu rapide avec des vraies ou fausses données
//   3. timeline()     — les vraies données + la prochaine date de rafraîchissement

import WidgetKit
import SwiftUI

// MARK: - Le modèle de données du widget

/// TimelineEntry est le "paquet de données" que le widget affiche à un instant T.
/// Chaque entrée contient : la date, le nombre de pas, et l'objectif.
struct StepEntry: TimelineEntry {
    let date: Date
    let stepCount: Int
    let stepGoal: Int

    /// Calcule le pourcentage de progression (entre 0.0 et 1.0+).
    /// On ne plafonne PAS à 1.0 pour pouvoir afficher "120%" si dépassé.
    var progress: Double {
        guard stepGoal > 0 else { return 0 }
        return Double(stepCount) / Double(stepGoal)
    }

    /// Retourne la couleur du dégradé selon les paliers définis :
    ///   - Rouge  : 0% à 10%
    ///   - Orange : 11% à 50%
    ///   - Jaune  : 51% à 80%
    ///   - Vert   : 81% et plus
    var progressColor: Color {
        let percentage = progress * 100
        switch percentage {
        case ..<11:
            return .red
        case 11..<51:
            return .orange
        case 51..<81:
            return .yellow
        default:
            return .green
        }
    }

    /// Dégradé dynamique : part de la couleur de progression vers une version plus sombre.
    /// Ça donne un effet visuel beaucoup plus "pro" qu'une couleur plate.
    var gradientColors: [Color] {
        switch progress * 100 {
        case ..<11:
            return [Color.red, Color.red.opacity(0.6)]
        case 11..<51:
            return [Color.orange, Color.red.opacity(0.7)]
        case 51..<81:
            return [Color.yellow, Color.orange.opacity(0.7)]
        default:
            return [Color.green, Color.green.opacity(0.6)]
        }
    }
}

// MARK: - Le Provider

struct StepWidgetProvider: TimelineProvider {

    private let healthManager = HealthKitManager.shared

    // MARK: placeholder
    /// Affiché dans la galerie de widgets quand l'utilisateur choisit quel widget ajouter.
    /// On utilise des données fictives — c'est juste un aperçu de la mise en page.
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(
            date: Date(),
            stepCount: 6500,    // Données fictives pour l'aperçu
            stepGoal: 10_000
        )
    }

    // MARK: snapshot
    /// Appelé quand iOS veut un aperçu rapide (ex: en mode transitoire).
    /// On essaie de charger les vraies données, sinon on utilise le placeholder.
    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        if context.isPreview {
            // En mode preview (galerie), données fictives
            completion(placeholder(in: context))
            return
        }

        // Sinon, on charge les vraies données
        Task {
            do {
                let steps = try await healthManager.fetchTodayStepCount()
                let entry = StepEntry(
                    date: Date(),
                    stepCount: steps,
                    stepGoal: healthManager.stepGoal
                )
                completion(entry)
            } catch {
                // En cas d'erreur, on affiche 0 pas
                completion(StepEntry(date: Date(), stepCount: 0, stepGoal: healthManager.stepGoal))
            }
        }
    }

    // MARK: timeline
    /// C'est LA fonction clé. Elle dit à iOS :
    ///   - "Voici les données actuelles"
    ///   - "Reviens me demander dans 15 minutes"
    ///
    /// Pourquoi 15 minutes ? C'est un bon compromis entre fraîcheur des données
    /// et économie de batterie. iOS peut aussi décider de rafraîchir plus tard
    /// si l'appareil est en mode économie d'énergie.
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        Task {
            do {
                let steps = try await healthManager.fetchTodayStepCount()
                let entry = StepEntry(
                    date: Date(),
                    stepCount: steps,
                    stepGoal: healthManager.stepGoal
                )

                // On demande un rafraîchissement dans 15 minutes.
                // .after signifie : "après cette date, redemande-moi une timeline"
                let nextUpdate = Calendar.current.date(
                    byAdding: .minute,
                    value: 15,
                    to: Date()
                ) ?? Date().addingTimeInterval(900)

                let timeline = Timeline(
                    entries: [entry],
                    policy: .after(nextUpdate)
                )
                completion(timeline)

            } catch {
                // En cas d'erreur, on affiche 0 et on réessaie dans 15 min
                let entry = StepEntry(
                    date: Date(),
                    stepCount: 0,
                    stepGoal: healthManager.stepGoal
                )
                let nextUpdate = Date().addingTimeInterval(900)
                let timeline = Timeline(
                    entries: [entry],
                    policy: .after(nextUpdate)
                )
                completion(timeline)
            }
        }
    }
}
