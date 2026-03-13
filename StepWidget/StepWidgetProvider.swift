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

/// Paquet de données que le widget affiche à un instant précis.
///
/// Conforme au protocole `TimelineEntry`, `StepEntry` encapsule les trois
/// valeurs nécessaires au rendu du widget : la date d'affichage, le nombre
/// de pas et l'objectif. Les propriétés calculées (`progress`, `progressColor`,
/// `gradientColors`) dérivent toutes de ces trois valeurs de base.
struct StepEntry: TimelineEntry {

    /// Date à laquelle cette entrée doit être affichée par le widget.
    ///
    /// WidgetKit utilise ce champ pour planifier les transitions de la timeline.
    let date: Date

    /// Nombre de pas enregistrés depuis minuit jusqu'au moment de la requête.
    let stepCount: Int

    /// Objectif quotidien défini par l'utilisateur, lu depuis l'App Group partagé.
    let stepGoal: Int

    /// Ratio de progression entre 0.0 et 1.0+ (non plafonné à 1.0).
    ///
    /// Retourner une valeur supérieure à 1.0 permet d'afficher
    /// un pourcentage comme "120%" lorsque l'objectif est dépassé.
    /// Retourne `0` si `stepGoal` vaut 0 pour éviter une division par zéro.
    var progress: Double {
        guard stepGoal > 0 else { return 0 }
        return Double(stepCount) / Double(stepGoal)
    }

    /// Retourne la couleur principale selon les paliers de progression :
    ///   - **Rouge**  : 0 % à 10 %
    ///   - **Orange** : 11 % à 50 %
    ///   - **Jaune**  : 51 % à 80 %
    ///   - **Vert**   : 81 % et plus
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

    /// Dégradé dynamique utilisé comme fond du widget.
    ///
    /// Part de la couleur principale vers une version plus sombre/transparente,
    /// créant un effet visuel plus professionnel qu'une couleur plate.
    /// Les couleurs correspondent aux mêmes paliers que `progressColor`.
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

/// Fournisseur de données pour le widget de pas.
///
/// `StepWidgetProvider` implémente le protocole `TimelineProvider` qui définit
/// le cycle de vie des données du widget. iOS appelle ses méthodes selon le contexte :
/// - `placeholder` pour la galerie de widgets
/// - `getSnapshot` pour l'aperçu rapide
/// - `getTimeline` pour les données en production
struct StepWidgetProvider: TimelineProvider {

    /// Accès au singleton HealthKit pour récupérer le nombre de pas du jour.
    private let healthManager = HealthKitManager.shared

    // MARK: - placeholder

    /// Retourne un aperçu générique affiché dans la galerie de widgets.
    ///
    /// Les données sont fictives — il s'agit uniquement de montrer la mise en page.
    /// iOS peut appeler cette méthode de façon synchrone, sans accès réseau.
    ///
    /// - Parameter context: Contexte d'affichage fourni par WidgetKit.
    /// - Returns: Une entrée avec 6 500 pas fictifs sur un objectif de 10 000.
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(
            date: Date(),
            stepCount: 6500,    // Données fictives pour l'aperçu
            stepGoal: 10_000
        )
    }

    // MARK: - snapshot

    /// Retourne un aperçu rapide, de préférence avec les vraies données.
    ///
    /// Appelé lorsqu'iOS a besoin d'un aperçu sans délai (ex : vue de transition).
    /// En mode preview (galerie), on utilise des données fictives pour la rapidité.
    /// En production, on tente de lire HealthKit ; en cas d'erreur, on retourne 0.
    ///
    /// - Parameters:
    ///   - context: Contexte d'affichage fourni par WidgetKit.
    ///   - completion: Bloc appelé avec l'entrée à afficher.
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

    // MARK: - timeline

    /// Construit la timeline du widget et planifie son prochain rafraîchissement.
    ///
    /// C'est la méthode principale en production. Elle lit les vrais pas via HealthKit
    /// et demande à iOS de la rappeler dans 15 minutes (`.after`), ce qui est un bon
    /// compromis entre fraîcheur des données et économie de batterie.
    ///
    /// > Note : iOS peut retarder le rafraîchissement en mode économie d'énergie
    /// > ou si le budget de rafraîchissement de l'app est épuisé.
    ///
    /// - Parameters:
    ///   - context: Contexte d'affichage fourni par WidgetKit.
    ///   - completion: Bloc appelé avec la `Timeline` à enregistrer.
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        Task {
            do {
                let steps = try await healthManager.fetchTodayStepCount()
                let entry = StepEntry(
                    date: Date(),
                    stepCount: steps,
                    stepGoal: healthManager.stepGoal
                )

                // Rafraîchissement demandé dans 15 minutes.
                // .after signifie : "après cette date, redemande-moi une timeline".
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
