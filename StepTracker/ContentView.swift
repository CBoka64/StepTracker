// ContentView.swift
// StepTracker (app principale)
//
// L'app principale a deux rôles essentiels :
//   1. Demander la permission HealthKit (le widget ne peut PAS afficher la pop-up)
//   2. Permettre à l'utilisateur de définir son objectif de pas
//
// IMPORTANT : L'utilisateur DOIT ouvrir l'app au moins une fois pour accorder
// l'accès HealthKit. Sans ça, le widget affichera toujours 0.

import SwiftUI
import WidgetKit

struct ContentView: View {

    @State private var stepCount: Int = 0
    @State private var stepGoal: Int = HealthKitManager.shared.stepGoal
    @State private var isAuthorized: Bool = false
    @State private var errorMessage: String?
    @State private var isLoading: Bool = true

    private let healthManager = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ---- Carte principale : pas du jour ----
                    stepCountCard

                    // ---- Réglage de l'objectif ----
                    goalSettingCard

                    // ---- Message d'erreur éventuel ----
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }

                    // ---- Note explicative ----
                    infoCard
                }
                .padding()
            }
            .navigationTitle("Mes Pas")
            .task {
                // .task se lance automatiquement quand la vue apparaît.
                // On demande l'autorisation HealthKit puis on charge les pas.
                await setupHealthKit()
            }
        }
    }

    // MARK: - Carte du nombre de pas

    private var stepCountCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundStyle(progressGradient)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Chargement...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(stepCount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(progressGradient)

                Text("pas aujourd'hui")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Barre de progression
                let progress = stepGoal > 0 ? Double(stepCount) / Double(stepGoal) : 0
                ProgressView(value: min(progress, 1.0))
                    .tint(colorForProgress(progress))
                    .scaleEffect(y: 2)
                    .padding(.horizontal, 32)

                Text("\(Int(progress * 100))% de l'objectif")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Réglage de l'objectif

    private var goalSettingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Objectif quotidien", systemImage: "target")
                .font(.headline)

            // Stepper pour ajuster l'objectif par tranches de 500
            Stepper(
                value: $stepGoal,
                in: 1000...50_000,
                step: 500
            ) {
                Text("\(stepGoal) pas")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
            .onChange(of: stepGoal) { _, newValue in
                // Quand l'utilisateur change l'objectif :
                // 1. On sauvegarde dans le App Group (partagé avec le widget)
                healthManager.stepGoal = newValue

                // 2. On force le widget à se rafraîchir immédiatement
                // Sans ça, il ne se mettrait à jour qu'au prochain cycle (15 min)
                WidgetCenter.shared.reloadAllTimelines()
            }

            // Raccourcis rapides pour les objectifs courants
            HStack(spacing: 8) {
                GoalButton(title: "5 000", goal: 5_000, currentGoal: $stepGoal)
                GoalButton(title: "8 000", goal: 8_000, currentGoal: $stepGoal)
                GoalButton(title: "10 000", goal: 10_000, currentGoal: $stepGoal)
                GoalButton(title: "15 000", goal: 15_000, currentGoal: $stepGoal)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Note d'information

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Comment ajouter le widget", systemImage: "info.circle")
                .font(.headline)

            Text("Restez appuyé sur l'écran d'accueil de votre iPhone, appuyez sur le bouton \"+\" en haut à gauche, puis cherchez \"StepTracker\" dans la liste des widgets.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Logique HealthKit

    /// Configure HealthKit : demande l'autorisation puis charge les pas.
    private func setupHealthKit() async {
        guard healthManager.isAvailable else {
            errorMessage = "HealthKit n'est pas disponible sur cet appareil."
            isLoading = false
            return
        }

        do {
            // Étape 1 : demander l'autorisation
            try await healthManager.requestAuthorization()
            isAuthorized = true

            // Étape 2 : charger les pas du jour
            stepCount = try await healthManager.fetchTodayStepCount()
            isLoading = false

        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Helpers visuels

    /// Retourne un dégradé selon la progression (mêmes paliers que le widget)
    private var progressGradient: LinearGradient {
        let progress = stepGoal > 0 ? Double(stepCount) / Double(stepGoal) : 0
        let color = colorForProgress(progress)
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Même logique de couleur que dans le widget
    private func colorForProgress(_ progress: Double) -> Color {
        let pct = progress * 100
        switch pct {
        case ..<11:  return .red
        case 11..<51: return .orange
        case 51..<81: return .yellow
        default:      return .green
        }
    }
}

// MARK: - Bouton raccourci d'objectif

/// Petit bouton réutilisable pour les objectifs prédéfinis (5000, 8000, etc.)
struct GoalButton: View {
    let title: String
    let goal: Int
    @Binding var currentGoal: Int

    var body: some View {
        Button {
            currentGoal = goal
            HealthKitManager.shared.stepGoal = goal
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Text(title)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    currentGoal == goal
                        ? Color.accentColor
                        : Color.secondary.opacity(0.2)
                )
                .foregroundColor(currentGoal == goal ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
