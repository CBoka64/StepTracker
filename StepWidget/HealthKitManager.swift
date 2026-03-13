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

    /// Singleton partagé entre l'app et le widget.
    ///
    /// Utiliser `HealthKitManager.shared` garantit qu'une seule instance
    /// du `HKHealthStore` est créée, conformément aux recommandations Apple.
    static let shared = HealthKitManager()

    /// Point d'accès unique aux données HealthKit.
    ///
    /// `HKHealthStore` est le "coffre-fort" de l'app Santé : toutes les requêtes
    /// de lecture et les demandes d'autorisation passent par cet objet.
    private let healthStore = HKHealthStore()

    /// Type de donnée lu : le nombre de pas (`HKQuantityTypeIdentifier.stepCount`).
    ///
    /// Force-unwrap justifié : `.stepCount` est un identifiant connu et valide
    /// — cette valeur ne peut pas être `nil`.
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    // MARK: - Vérifier la disponibilité de HealthKit

    /// Indique si HealthKit est disponible sur cet appareil.
    ///
    /// Tous les appareils Apple ne supportent pas HealthKit (certains iPad,
    /// certaines configurations Mac). On vérifie toujours avant d'utiliser le store.
    var isAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Demander l'autorisation

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
            toShare: [],          // On n'écrit rien dans Santé
            read: [stepType]      // On lit uniquement les pas
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

        // Predicate : uniquement les données entre minuit et maintenant.
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        // API async/await de HealthKit (iOS 15.4+).
        // .cumulativeSum additionne tous les échantillons de la journée.
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(
                type: stepType,
                predicate: predicate
            ),
            options: .cumulativeSum
        )

        let result = try await descriptor.result(for: healthStore)

        // Extrait la somme et la convertit en entier.
        // Retourne 0 si aucune donnée n'existe pour aujourd'hui.
        guard let sum = result?.sumQuantity() else {
            return 0
        }

        return Int(sum.doubleValue(for: .count()))
    }

    // MARK: - Gestion de l'objectif de pas

    /// UserDefaults du groupe d'apps, accessible par l'app ET le widget.
    ///
    /// L'App Group `group.com.bc046.stepttracker` doit être déclaré dans
    /// les entitlements des deux targets pour que cet accès fonctionne.
    /// Retourne `nil` si l'identifiant d'App Group est incorrect ou manquant.
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.bc046.stepttracker")
    }

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
