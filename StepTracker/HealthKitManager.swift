// HealthKitManager.swift
// Shared — utilisé par l'app principale ET le widget
//
// Ce fichier gère toute la communication avec HealthKit (l'app Santé d'Apple).
// Il demande l'autorisation de lire les pas, puis récupère le total du jour.

import Foundation
import HealthKit

class HealthKitManager {

    // Le "store" est le point d'entrée unique vers les données Santé.
    // On le crée une seule fois et on le réutilise partout.
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    // Le type de donnée qu'on veut lire : le nombre de pas.
    // HealthKit utilise des "identifiers" pour chaque type de donnée (pas, calories, etc.)
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    // MARK: - Vérifier la disponibilité de HealthKit

    /// Tous les appareils Apple ne supportent pas HealthKit (ex: certains iPad).
    /// On vérifie toujours avant d'essayer de l'utiliser.
    var isAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Demander l'autorisation

    /// Demande à l'utilisateur la permission de lire ses pas.
    /// Cette pop-up n'apparaît qu'une seule fois — iOS s'en souvient ensuite.
    /// Important : on ne demande que la LECTURE (toRead), pas l'écriture (toShare est vide).
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

    /// Récupère le nombre total de pas depuis minuit aujourd'hui.
    /// C'est la fonction principale que le widget appellera.
    func fetchTodayStepCount() async throws -> Int {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // On construit un "predicate" qui filtre les données :
        // uniquement celles entre minuit (début du jour) et maintenant.
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        // On utilise la nouvelle API async/await de HealthKit (iOS 15.4+).
        // Le "cumulativeSum" additionne tous les échantillons de pas de la journée
        // (montre, téléphone, etc. — HealthKit gère les doublons automatiquement).
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(
                type: stepType,
                predicate: predicate
            ),
            options: .cumulativeSum
        )

        let result = try await descriptor.result(for: healthStore)

        // On extrait la somme et on la convertit en nombre entier de pas.
        // Si aucune donnée n'existe (pas encore marché aujourd'hui), on retourne 0.
        guard let sum = result?.sumQuantity() else {
            return 0
        }

        return Int(sum.doubleValue(for: .count()))
    }

    // MARK: - Gestion de l'objectif de pas

    /// L'objectif est stocké dans UserDefaults via App Group,
    /// pour être accessible à la fois par l'app et par le widget.
    /// Par défaut : 10 000 pas (recommandation OMS classique).

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.bc046.stepttracker")
    }

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

enum HealthKitError: LocalizedError {
    case notAvailable
    case noData

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit n'est pas disponible sur cet appareil."
        case .noData:
            return "Aucune donnée de pas trouvée pour aujourd'hui."
        }
    }
}
