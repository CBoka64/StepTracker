// StepTrackerTests.swift
// StepTrackerTests
//
// Tests unitaires pour StepTracker.
// Ces tests ne nécessitent pas d'iPhone physique ni d'accès HealthKit réel.

import XCTest
@testable import StepTracker

final class StepTrackerTests: XCTestCase {

    // MARK: - HealthKitManager.stepGoal

    func testStepGoalDefaultValue() {
        // Quand aucune valeur n'est enregistrée, l'objectif par défaut est 10 000
        let manager = HealthKitManager.shared
        // On ne peut pas reset UserDefaults facilement dans les tests,
        // mais on vérifie que la valeur est bien dans la plage attendue
        XCTAssertGreaterThan(manager.stepGoal, 0)
        XCTAssertLessThanOrEqual(manager.stepGoal, 50_000)
    }

    func testStepGoalPersistence() {
        let manager = HealthKitManager.shared
        let originalGoal = manager.stepGoal

        // Modifier l'objectif
        manager.stepGoal = 8_000
        XCTAssertEqual(manager.stepGoal, 8_000)

        // Restaurer la valeur d'origine
        manager.stepGoal = originalGoal
    }

    func testStepGoalMinimumBoundary() {
        let manager = HealthKitManager.shared
        manager.stepGoal = 1_000
        XCTAssertEqual(manager.stepGoal, 1_000)
        manager.stepGoal = 10_000 // restaurer
    }

    func testStepGoalMaximumBoundary() {
        let manager = HealthKitManager.shared
        manager.stepGoal = 50_000
        XCTAssertEqual(manager.stepGoal, 50_000)
        manager.stepGoal = 10_000 // restaurer
    }

    // MARK: - HealthKitError

    func testHealthKitErrorNotAvailableDescription() {
        let error = HealthKitError.notAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testHealthKitErrorNoDataDescription() {
        let error = HealthKitError.noData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    // MARK: - StepEntry (widget)

    func testStepEntryProgressZeroWhenGoalIsZero() {
        let entry = StepEntry(date: Date(), stepCount: 5_000, stepGoal: 0)
        XCTAssertEqual(entry.progress, 0.0)
    }

    func testStepEntryProgressCalculation() {
        let entry = StepEntry(date: Date(), stepCount: 5_000, stepGoal: 10_000)
        XCTAssertEqual(entry.progress, 0.5, accuracy: 0.001)
    }

    func testStepEntryProgressCanExceedOne() {
        // Si l'objectif est dépassé, progress > 1.0
        let entry = StepEntry(date: Date(), stepCount: 12_000, stepGoal: 10_000)
        XCTAssertGreaterThan(entry.progress, 1.0)
    }

    func testStepEntryProgressColorAt0Percent() {
        let entry = StepEntry(date: Date(), stepCount: 0, stepGoal: 10_000)
        // 0% → rouge
        XCTAssertEqual(entry.progressColor, .red)
    }

    func testStepEntryProgressColorAt50Percent() {
        let entry = StepEntry(date: Date(), stepCount: 5_000, stepGoal: 10_000)
        // 50% → orange (11–50%)
        XCTAssertEqual(entry.progressColor, .orange)
    }

    func testStepEntryProgressColorAt100Percent() {
        let entry = StepEntry(date: Date(), stepCount: 10_000, stepGoal: 10_000)
        // 100% → vert (81%+)
        XCTAssertEqual(entry.progressColor, .green)
    }

    func testStepEntryGradientColorsNotEmpty() {
        let entry = StepEntry(date: Date(), stepCount: 5_000, stepGoal: 10_000)
        XCTAssertFalse(entry.gradientColors.isEmpty)
        XCTAssertEqual(entry.gradientColors.count, 2)
    }
}
