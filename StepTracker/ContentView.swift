// ContentView.swift
// StepTracker
//
// Design adaptatif : fond dégradé plein écran + anneau de progression circulaire.
// Sur iPhone (compact) : layout vertical.
// Sur iPad / Mac (regular) : layout deux colonnes côte à côte.

import SwiftUI
import WidgetKit

// MARK: - Vue principale

struct ContentView: View {

    @State private var stepCount: Int = 0
    @State private var stepGoal: Int = HealthKitManager.shared.stepGoal
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    @Environment(\.horizontalSizeClass) private var sizeClass

    private let healthManager = HealthKitManager.shared

    private var progress: Double {
        stepGoal > 0 ? Double(stepCount) / Double(stepGoal) : 0
    }

    private var progressColor: Color { colorForProgress(progress) }

    var body: some View {
        ZStack {
            // Fond dégradé plein écran — change de couleur avec la progression
            LinearGradient(
                colors: [progressColor, progressColor.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: progressColor)

            // Contenu — adaptatif selon la taille d'écran
            if sizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .task { await setupHealthKit() }
    }

    // MARK: - Layout compact (iPhone)

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerTitle
                ringSection
                statsRow
                goalCard
                if let error = errorMessage { errorBanner(error) }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    // MARK: - Layout regular (iPad / Mac)

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: 40) {
            // Colonne gauche : anneau
            VStack(spacing: 20) {
                headerTitle
                ringSection
                statsRow
                if let error = errorMessage { errorBanner(error) }
            }
            .frame(maxWidth: .infinity)

            // Colonne droite : objectif
            VStack {
                goalCard
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(40)
    }

    // MARK: - Composants

    private var headerTitle: some View {
        Text("Mes Pas")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ringSection: some View {
        VStack(spacing: 12) {
            ZStack {
                CircularProgressRing(
                    progress: isLoading ? 0 : progress,
                    color: .white
                )
                .frame(width: 220, height: 220)
                .opacity(isLoading ? 0.4 : 1)
                .animation(.easeOut(duration: 0.8), value: progress)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                } else {
                    VStack(spacing: 4) {
                        Text("\(stepCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.easeOut, value: stepCount)

                        Text("pas")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }

            Text(isLoading ? " " : "\(Int(min(progress, 9.99) * 100))% de l'objectif")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .animation(.easeOut, value: isLoading)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            StepStatItem(
                value: isLoading ? "—" : "\(stepCount)",
                label: "pas"
            )
            divider
            StepStatItem(
                value: isLoading ? "—" : "\(Int(min(progress, 9.99) * 100))%",
                label: "objectif"
            )
            divider
            StepStatItem(
                value: isLoading ? "—" : "\(max(0, stepGoal - stepCount))",
                label: "restants"
            )
        }
        .padding(.vertical, 14)
        .background(.white.opacity(0.15))
        .cornerRadius(16)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.3))
            .frame(width: 1, height: 36)
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Objectif quotidien", systemImage: "target")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Stepper(
                value: $stepGoal,
                in: 1_000...50_000,
                step: 500
            ) {
                Text("\(stepGoal) pas")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .tint(.white)
            .onChange(of: stepGoal) { _, newValue in
                healthManager.stepGoal = newValue
                WidgetCenter.shared.reloadAllTimelines()
            }

            // Raccourcis
            HStack(spacing: 8) {
                GoalButton(title: "5 000",  goal: 5_000,  currentGoal: $stepGoal)
                GoalButton(title: "8 000",  goal: 8_000,  currentGoal: $stepGoal)
                GoalButton(title: "10 000", goal: 10_000, currentGoal: $stepGoal)
                GoalButton(title: "15 000", goal: 15_000, currentGoal: $stepGoal)
            }
        }
        .padding(20)
        .background(.white.opacity(0.18))
        .cornerRadius(20)
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundColor(.white)
            .padding(12)
            .background(.black.opacity(0.25))
            .cornerRadius(12)
    }

    // MARK: - HealthKit

    private func setupHealthKit() async {
        guard healthManager.isAvailable else {
            errorMessage = "HealthKit n'est pas disponible sur cet appareil."
            isLoading = false
            return
        }
        do {
            try await healthManager.requestAuthorization()
            stepCount = try await healthManager.fetchTodayStepCount()
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Couleur selon progression

    private func colorForProgress(_ p: Double) -> Color {
        switch p * 100 {
        case ..<11:   return .red
        case 11..<51: return .orange
        case 51..<81: return Color(red: 0.8, green: 0.7, blue: 0.1)  // jaune lisible
        default:      return Color(red: 0.1, green: 0.7, blue: 0.35) // vert profond
        }
    }
}

// MARK: - Anneau de progression circulaire

struct CircularProgressRing: View {
    let progress: Double
    let color: Color
    private let lineWidth: CGFloat = 18

    var body: some View {
        ZStack {
            // Track (fond de l'anneau)
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Arc de progression
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Cellule de statistique

struct StepStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bouton raccourci d'objectif

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
                .background(currentGoal == goal ? Color.white : Color.white.opacity(0.2))
                .foregroundColor(currentGoal == goal ? .black : .white)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview("Jaune – 65%") {
    ContentView()
}
