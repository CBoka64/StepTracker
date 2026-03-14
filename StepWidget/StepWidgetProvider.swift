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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 1 — StepEntry : le "paquet de données" du widget
// ═══════════════════════════════════════════════════════════════
// Un widget WidgetKit fonctionne comme un diaporama : iOS prépare
// à l'avance des "entrées" (StepEntry) avec les données et les dates
// d'affichage, puis les affiche automatiquement au bon moment.
//
// StepEntry doit être conforme au protocole TimelineEntry, qui exige
// une propriété "date: Date" (l'instant d'affichage de cette entrée).
// On y ajoute nos données métier : stepCount et stepGoal.

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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 2 — Calculer le ratio de progression (protection division/0)
    // ═══════════════════════════════════════════════════════════════
    // progress est une propriété calculée (pas stockée) : Swift recalcule
    // sa valeur chaque fois qu'on y accède.
    // "guard stepGoal > 0" évite la division par zéro si stepGoal est 0.
    // Une valeur > 1.0 est possible (ex: 1.2 = 120% si l'objectif est dépassé).

    /// Ratio de progression entre 0.0 et 1.0+ (non plafonné à 1.0).
    ///
    /// Retourner une valeur supérieure à 1.0 permet d'afficher
    /// un pourcentage comme "120%" lorsque l'objectif est dépassé.
    /// Retourne `0` si `stepGoal` vaut 0 pour éviter une division par zéro.
    var progress: Double {
        guard stepGoal > 0 else { return 0 }
        return Double(stepCount) / Double(stepGoal)
    }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 3 — Choisir la couleur principale selon le palier atteint
    // ═══════════════════════════════════════════════════════════════
    // Le "switch" sur un intervalle de valeurs est une fonctionnalité
    // puissante de Swift. Chaque "case" couvre une plage de pourcentages.
    // La couleur change progressivement pour motiver l'utilisateur :
    //   Rouge → Orange → Jaune → Vert

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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 4 — Définir le dégradé dynamique du fond du widget
    // ═══════════════════════════════════════════════════════════════
    // gradientColors retourne un tableau de 2 couleurs qui forment
    // le dégradé du fond du widget.
    // Ce tableau est utilisé dans StepWidget.swift dans containerBackground.
    // Chaque palier a ses propres teintes pour un effet visuel distinct.

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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 5 — placeholder() : aperçu générique pour la galerie iOS
    // ═══════════════════════════════════════════════════════════════
    // Quand l'utilisateur ouvre la galerie "Ajouter un widget",
    // iOS a besoin d'afficher un aperçu IMMÉDIATEMENT, sans attendre
    // de données réelles. On retourne donc des données fictives.
    // iOS peut appeler cette méthode de façon synchrone (sans async),
    // donc pas question de lire HealthKit ici (trop lent).
    //
    // Les données fictives doivent être "réalistes" pour que l'aperçu
    // soit représentatif de ce que verra l'utilisateur.

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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 6 — getSnapshot() : aperçu rapide, données réelles si possible
    // ═══════════════════════════════════════════════════════════════
    // getSnapshot est appelé dans deux situations :
    //   a) Mode preview (galerie) → on retourne des données fictives rapidement
    //   b) Mode production (widget ajouté) → on tente de lire HealthKit
    //
    // "context.isPreview" permet de distinguer les deux cas.
    // En mode production, on utilise Task {} pour lancer une opération
    // async depuis une fonction non-async (getSnapshot n'est pas async).

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

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 7 — Task {} : lancer du code async depuis du code synchrone
        // ═══════════════════════════════════════════════════════════════
        // getSnapshot n'est pas une fonction "async", mais on a besoin
        // de lire HealthKit de façon asynchrone. Task {} crée une "coroutine"
        // (un bloc de code qui peut faire des pauses avec await).
        // Une fois les données prêtes, on appelle completion() pour
        // signaler à iOS que l'entrée est disponible.
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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 8 — getTimeline() : la méthode principale en production
    // ═══════════════════════════════════════════════════════════════
    // C'est la méthode la plus importante : iOS l'appelle régulièrement
    // pour savoir quelles données afficher ET quand se réveiller
    // pour les mettre à jour.
    //
    // Elle construit une "Timeline" = une liste d'entrées planifiées
    // + une politique de rafraîchissement.
    //
    // Notre timeline ne contient qu'UNE entrée (les données actuelles)
    // car les pas changent en temps réel. On demande un rafraîchissement
    // toutes les 15 minutes, ce qui est un bon compromis entre fraîcheur
    // et économie de batterie.

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

                // ═══════════════════════════════════════════════════════════════
                // ÉTAPE 9 — Construire l'entrée avec les vraies données
                // ═══════════════════════════════════════════════════════════════
                // On crée un StepEntry avec :
                //   - date: Date() = maintenant (afficher immédiatement)
                //   - stepCount: les vrais pas lus depuis HealthKit
                //   - stepGoal: l'objectif lu depuis les UserDefaults partagés
                let entry = StepEntry(
                    date: Date(),
                    stepCount: steps,
                    stepGoal: healthManager.stepGoal
                )

                // ═══════════════════════════════════════════════════════════════
                // ÉTAPE 10 — Calculer la date du prochain rafraîchissement
                // ═══════════════════════════════════════════════════════════════
                // On dit à iOS : "Reviens me voir dans 15 minutes pour de
                // nouvelles données." 15 minutes = 900 secondes.
                // Le fallback "?? Date().addingTimeInterval(900)" s'applique
                // si Calendar.current.date() retourne nil (très rare).
                let nextUpdate = Calendar.current.date(
                    byAdding: .minute,
                    value: 15,
                    to: Date()
                ) ?? Date().addingTimeInterval(900)

                // ═══════════════════════════════════════════════════════════════
                // ÉTAPE 11 — Créer et soumettre la Timeline à iOS
                // ═══════════════════════════════════════════════════════════════
                // Timeline(entries:policy:) :
                //   - entries: la liste de StepEntry à afficher (une seule ici)
                //   - policy: .after(nextUpdate) = demander un nouveau refresh
                //     après la date nextUpdate.
                //
                // Autres politiques possibles :
                //   - .atEnd : refresh après la dernière entrée de la liste
                //   - .never : ne jamais rafraîchir automatiquement
                let timeline = Timeline(
                    entries: [entry],
                    policy: .after(nextUpdate)
                )
                completion(timeline)

            } catch {
                // ═══════════════════════════════════════════════════════════════
                // ÉTAPE 12 — Gérer l'erreur : afficher 0 pas et réessayer dans 15 min
                // ═══════════════════════════════════════════════════════════════
                // Si HealthKit échoue (permission refusée, appareil non compatible...),
                // on affiche 0 pas plutôt que de crasher.
                // On planifie quand même un refresh dans 15 min pour que le widget
                // réessaie automatiquement (l'utilisateur aura peut-être accordé
                // les permissions entre-temps).
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
