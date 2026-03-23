// SleepWidgetProvider.swift
// StepWidgetExtension
//
// Provider du widget sommeil — même architecture que StepWidgetProvider.
// Fournit les données de durée de sommeil au widget WidgetKit.

import WidgetKit
import SwiftUI

// MARK: - Modèle de données du widget sommeil

/// Paquet de données que le widget sommeil affiche à un instant précis.
struct SleepEntry: TimelineEntry {

    let date: Date
    /// Durée de sommeil en secondes.
    let sleepDuration: TimeInterval
    /// Objectif en minutes (stocké dans UserDefaults partagé).
    let sleepGoalMinutes: Int
    let state: WidgetLoadState

    /// Durée en minutes.
    var sleepMinutes: Int { Int(sleepDuration / 60) }

    /// Ratio de progression (0.0 → 1.0+).
    var progress: Double {
        sleepGoalMinutes > 0 ? Double(sleepMinutes) / Double(sleepGoalMinutes) : 0
    }

    /// Durée formatée (ex : "7h30").
    var formattedDuration: String {
        let h = sleepMinutes / 60
        let m = sleepMinutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h\(m)m"
    }

    /// Couleur principale (bord haut du dégradé) selon la progression.
    var progressColor: Color { gradientColors[0] }

    /// Couleurs du dégradé de fond : violet sombre (0%) → bleu ciel (100%).
    var gradientColors: [Color] {
        let t = min(max(progress, 0), 1)
        let top = Color(
            red:   lerp(0.12, 0.20, 0.20, t),
            green: lerp(0.01, 0.25, 0.65, t),
            blue:  lerp(0.22, 0.75, 1.00, t)
        )
        let bottom = Color(
            red:   lerp(0.06, 0.10, 0.10, t),
            green: lerp(0.00, 0.12, 0.40, t),
            blue:  lerp(0.12, 0.55, 0.80, t)
        )
        return [top, bottom]
    }

    private func lerp(_ a: Double, _ mid: Double, _ b: Double, _ t: Double) -> Double {
        t < 0.5 ? a + (mid - a) * (t * 2) : mid + (b - mid) * ((t - 0.5) * 2)
    }
}

// MARK: - Provider

/// Fournisseur de données pour le widget sommeil.
struct SleepWidgetProvider: TimelineProvider {

    private let healthManager = HealthKitManager.shared

    private var sleepGoalMinutes: Int {
        healthManager.sleepGoalMinutes
    }

    func placeholder(in context: Context) -> SleepEntry {
        SleepEntry(date: Date(), sleepDuration: 7 * 3600, sleepGoalMinutes: 480, state: .loaded)
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { completion(await buildEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepEntry>) -> Void) {
        Task {
            let entry = await buildEntry()

            let policy: TimelineReloadPolicy
            switch entry.state {
            case .loaded:
                // Rafraîchissement toutes les 30 minutes (le sommeil ne change pas en journée)
                let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                    ?? Date().addingTimeInterval(1800)
                policy = .after(next)
            case .unavailable:
                policy = .never
            case .unauthorized:
                policy = .after(Date().addingTimeInterval(3_600))
            }

            completion(Timeline(entries: [entry], policy: policy))
        }
    }

    private func buildEntry() async -> SleepEntry {
        guard healthManager.isAvailable else {
            return SleepEntry(date: Date(), sleepDuration: 0,
                              sleepGoalMinutes: sleepGoalMinutes, state: .unavailable)
        }
        do {
            let duration = try await healthManager.fetchLastNightSleep()
            return SleepEntry(date: Date(), sleepDuration: duration,
                              sleepGoalMinutes: sleepGoalMinutes, state: .loaded)
        } catch {
            return SleepEntry(date: Date(), sleepDuration: 0,
                              sleepGoalMinutes: sleepGoalMinutes, state: .unauthorized)
        }
    }
}


