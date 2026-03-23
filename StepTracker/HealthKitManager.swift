// HealthKitManager.swift
// Shared — utilisé par l'app principale ET le widget
//
// Ce fichier gère toute la communication avec HealthKit (l'app Santé d'Apple).
// Il demande l'autorisation de lire les pas, puis récupère le total du jour.
// L'objectif quotidien est stocké dans un App Group UserDefaults partagé,
// ce qui permet à l'app et au widget de lire/écrire la même valeur.

import Foundation
import HealthKit

// MARK: - Gestionnaire HealthKit

/// Classe responsable de toutes les interactions avec HealthKit et de la
/// persistance de l'objectif quotidien de pas.
///
/// `HealthKitManager` expose une interface `async/await` pour ne jamais
/// bloquer le thread principal. On l'utilise toujours via le singleton `shared`.
class HealthKitManager {

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 1 — Créer un singleton : une seule instance partagée
    // ═══════════════════════════════════════════════════════════════
    // Un "singleton" est un objet dont il n'existe qu'une seule copie
    // dans toute l'application. On y accède via "HealthKitManager.shared".
    // C'est la recommandation Apple pour HKHealthStore : créer plusieurs
    // instances serait un gaspillage de ressources.
    //
    // "static let" signifie que cette propriété appartient à la CLASSE
    // (pas à une instance), et qu'elle ne changera jamais (let = constante).

    /// Singleton partagé entre l'app et le widget.
    ///
    /// Utiliser `HealthKitManager.shared` garantit qu'une seule instance
    /// du `HKHealthStore` est créée, conformément aux recommandations Apple.
    static let shared = HealthKitManager()

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 2 — Créer le "coffre-fort" d'accès aux données Santé
    // ═══════════════════════════════════════════════════════════════
    // HKHealthStore est la porte d'entrée vers l'app Santé d'Apple.
    // Toutes les requêtes (lecture de pas, autorisation) passent par cet objet.
    // "private" = seul ce fichier peut l'utiliser, pas l'extérieur.

    /// Point d'accès unique aux données HealthKit.
    ///
    /// `HKHealthStore` est le "coffre-fort" de l'app Santé : toutes les requêtes
    /// de lecture et les demandes d'autorisation passent par cet objet.
    private let healthStore = HKHealthStore()

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 3 — Identifier le type de donnée qu'on veut lire : les pas
    // ═══════════════════════════════════════════════════════════════
    // HealthKit gère des dizaines de types de données (poids, fréquence
    // cardiaque, sommeil, pas...). On doit préciser exactement ce qu'on
    // veut lire avec un identifiant. ".stepCount" = nombre de pas.
    // Le "!" (force-unwrap) est sûr ici car .stepCount est un identifiant
    // connu d'Apple qui ne sera jamais nil.

    /// Type de donnée lu : le nombre de pas (`HKQuantityTypeIdentifier.stepCount`).
    ///
    /// Force-unwrap justifié : `.stepCount` est un identifiant connu et valide
    /// — cette valeur ne peut pas être `nil`.
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    /// Type de donnée lu pour le sommeil.
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

    // MARK: - Vérifier la disponibilité de HealthKit

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 4 — Vérifier si HealthKit est disponible sur l'appareil
    // ═══════════════════════════════════════════════════════════════
    // Tous les appareils Apple ne supportent pas HealthKit.
    // Exemple : certains anciens iPad ou Mac sans l'app Santé.
    // On DOIT vérifier AVANT d'utiliser HealthKit pour éviter un crash.
    // Cette propriété calculée retourne true ou false.

    /// Indique si HealthKit est disponible sur cet appareil.
    ///
    /// Tous les appareils Apple ne supportent pas HealthKit (certains iPad,
    /// certaines configurations Mac). On vérifie toujours avant d'utiliser le store.
    var isAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Demander l'autorisation

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 5 — Demander la permission à l'utilisateur de lire ses pas
    // ═══════════════════════════════════════════════════════════════
    // iOS affiche automatiquement une pop-up système demandant à l'utilisateur
    // s'il accepte de partager ses données de pas avec l'app.
    // Cette pop-up n'apparaît qu'UNE SEULE FOIS — iOS mémorise le choix.
    //
    // "async throws" signifie :
    //   - "async" : cette fonction peut faire une pause (elle attend la réponse
    //     de l'utilisateur) sans bloquer le reste de l'app.
    //   - "throws" : elle peut échouer et lancer une erreur (ex : HealthKit
    //     non disponible).
    //
    // On ne demande que la LECTURE (toRead), pas l'écriture (toShare vide).

    /// Demande à l'utilisateur la permission de lire ses données de pas.
    ///
    /// La pop-up système n'apparaît qu'une seule fois — iOS mémorise ensuite
    /// le choix de l'utilisateur. On demande uniquement la **lecture** (toRead) ;
    /// aucune donnée n'est écrite dans l'app Santé (toShare est vide).
    ///
    /// - Throws: `HealthKitError.notAvailable` si HealthKit n'est pas supporté
    ///   sur cet appareil.
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(
            toShare: [],
            read: [stepType, sleepType]   // On lit les pas ET le sommeil
        )
    }

    // MARK: - Récupérer les pas du jour

    /// Récupère le nombre total de pas depuis minuit jusqu'à maintenant.
    ///
    /// Utilise `HKStatisticsQueryDescriptor` avec l'option `.cumulativeSum`
    /// pour additionner les échantillons provenant de toutes les sources
    /// (Apple Watch, iPhone, etc.). HealthKit déduplique automatiquement.
    ///
    /// - Returns: Nombre entier de pas pour la journée en cours. Retourne `0`
    ///   si aucune donnée n'est encore disponible (ex : début de journée).
    /// - Throws: `HealthKitError.notAvailable` si HealthKit n'est pas supporté.
    func fetchTodayStepCount() async throws -> Int {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 6 — Définir la plage horaire : de minuit à maintenant
        // ═══════════════════════════════════════════════════════════════
        // On veut uniquement les pas d'aujourd'hui, donc on calcule :
        //   - startOfDay : minuit (00:00:00) du jour en cours
        //   - Date() : l'instant présent
        // "predicateForSamples" crée un filtre qui dit à HealthKit :
        // "ne me donne que les données dans cet intervalle de temps."
        // .strictStartDate = on exclut les données exactement à minuit
        // (bord gauche exclu) pour éviter les doublons avec la veille.
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 7 — Construire la requête HealthKit
        // ═══════════════════════════════════════════════════════════════
        // HKStatisticsQueryDescriptor est l'API moderne (iOS 15.4+) pour
        // faire des requêtes statistiques sur HealthKit avec async/await.
        // ".cumulativeSum" additionne tous les échantillons de la journée :
        //   - Pas enregistrés par l'iPhone (baromètre + accéléromètre)
        //   - Pas enregistrés par l'Apple Watch (si présente)
        //   - HealthKit déduplique automatiquement si les deux enregistrent
        //     la même marche.
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(
                type: stepType,
                predicate: predicate
            ),
            options: .cumulativeSum
        )

        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 8 — Exécuter la requête et attendre le résultat
        // ═══════════════════════════════════════════════════════════════
        // "try await" signifie :
        //   - "try" : cette ligne peut lancer une erreur (capturée par catch)
        //   - "await" : on fait une pause ici et on reprend quand iOS
        //     a fini d'interroger la base HealthKit (sans bloquer l'UI)
        let result = try await descriptor.result(for: healthStore)

        // Extrait la somme et la convertit en entier.
        // Retourne 0 si aucune donnée n'existe pour aujourd'hui.
        // "guard let" = si result est nil (pas de données), on retourne 0.
        guard let sum = result?.sumQuantity() else {
            return 0
        }

        // .count() = l'unité "nombre de pas" (sans dimension comme kg ou km)
        return Int(sum.doubleValue(for: .count()))
    }

    // MARK: - Récupérer le sommeil de la nuit dernière

    /// Récupère la durée totale de sommeil (phases asleep) de la nuit précédente.
    ///
    /// Plage analysée : 18h00 la veille → 12h00 aujourd'hui, pour couvrir
    /// toutes les heures de coucher sans capturer une sieste d'après-midi.
    ///
    /// - Returns: Durée en secondes. Retourne `0` si aucune donnée n'existe.
    /// - Throws: `HealthKitError.notAvailable` si HealthKit n'est pas supporté.
    func fetchLastNightSleep() async throws -> TimeInterval {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let calendar = Calendar.current
        let now = Date()

        // Fenêtre : 18h00 hier → 12h00 aujourd'hui
        let startOfToday = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .hour, value: -6, to: startOfToday),
              let windowEnd   = calendar.date(byAdding: .hour, value: 12, to: startOfToday)
        else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: windowStart,
            end: windowEnd,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: []
        )

        let samples = try await descriptor.result(for: healthStore)

        // On additionne uniquement les phases "endormi" (exclut "au lit" sans sommeil)
        let sleepSeconds = samples
            .compactMap { $0 as? HKCategorySample }
            .filter { sample in
                let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                return value == .asleepUnspecified
                    || value == .asleepCore
                    || value == .asleepDeep
                    || value == .asleepREM
            }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        return sleepSeconds
    }

    // MARK: - Gestion de l'objectif de pas

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 9 — Accéder aux UserDefaults partagés (App Group)
    // ═══════════════════════════════════════════════════════════════
    // Normalement, l'app et le widget ne peuvent pas partager de données
    // car iOS les isole dans des "sandbox" séparés.
    // L'App Group est une exception : c'est un espace commun autorisé
    // par Apple via les entitlements (fichier .entitlements).
    //
    // UserDefaults avec un "suiteName" (App Group ID) permet de stocker
    // de petites valeurs (nombres, textes) accessibles par les deux targets.
    // Si l'identifiant est incorrect → sharedDefaults retourne nil.

    /// UserDefaults du groupe d'apps, accessible par l'app ET le widget.
    ///
    /// L'App Group `group.com.bc046.stepttracker` doit être déclaré dans
    /// les entitlements des deux targets pour que cet accès fonctionne.
    /// Retourne `nil` si l'identifiant d'App Group est incorrect ou manquant.
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.bc046.stepttracker")
    }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 10 — Propriété stepGoal : lecture et écriture persistantes
    // ═══════════════════════════════════════════════════════════════
    // Cette propriété a un "getter" (lire) et un "setter" (écrire).
    //
    // GET : On lit la valeur depuis les UserDefaults partagés.
    //   - Si la valeur est 0 (jamais enregistrée), on retourne 10 000
    //     comme valeur par défaut (recommandation OMS).
    //
    // SET : On écrit la nouvelle valeur dans les UserDefaults partagés.
    //   - Le widget peut alors lire cette valeur au prochain rafraîchissement.
    //
    // "var" + "get/set" = propriété calculée avec persistance externalisée.

    /// Objectif quotidien de pas, lu et écrit dans l'App Group partagé.
    ///
    /// - Valeur par défaut : **10 000 pas** (recommandation OMS classique).
    /// - L'App Group garantit que l'app et le widget lisent toujours la même valeur.
    /// - Toute modification est immédiatement visible par le widget au prochain
    ///   rafraîchissement ou lors d'un appel à `WidgetCenter.shared.reloadAllTimelines()`.
    var stepGoal: Int {
        get {
            let goal = sharedDefaults?.integer(forKey: "stepGoal") ?? 0
            return goal > 0 ? goal : 10_000  // 10 000 par défaut
        }
        set {
            sharedDefaults?.set(newValue, forKey: "stepGoal")
        }
    }

    /// Objectif de sommeil en minutes, lu et écrit dans l'App Group partagé.
    ///
    /// - Valeur par défaut : **480 minutes** (8 heures).
    /// - L'App Group garantit que l'app et le widget lisent toujours la même valeur.
    var sleepGoalMinutes: Int {
        get {
            let goal = sharedDefaults?.integer(forKey: "sleepGoalMinutes") ?? 0
            return goal > 0 ? goal : 480  // 8h par défaut
        }
        set {
            sharedDefaults?.set(newValue, forKey: "sleepGoalMinutes")
        }
    }
}

// MARK: - Erreurs personnalisées

/// Erreurs possibles lors des opérations HealthKit.
enum HealthKitError: LocalizedError {

    /// HealthKit n'est pas disponible sur cet appareil (certains iPad, Mac sans Santé).
    case notAvailable

    /// Aucune donnée de pas trouvée (ne devrait normalement pas être levée :
    /// `fetchTodayStepCount` retourne `0` plutôt que de lancer cette erreur).
    case noData

    /// Message d'erreur localisé affiché à l'utilisateur via `error.localizedDescription`.
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit n'est pas disponible sur cet appareil."
        case .noData:
            return "Aucune donnée de pas trouvée pour aujourd'hui."
        }
    }
}
