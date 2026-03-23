// SleepTrackingView.swift
// StepTracker
//
// Suivi du sommeil — affiche la durée de la nuit précédente lue depuis HealthKit.
// Même architecture que StepTrackingView : fond dégradé dynamique selon la progression
// par rapport à un objectif de sommeil configurable.

import SwiftUI
import WidgetKit

// MARK: - Vue principale

struct SleepTrackingView: View {

    @Binding var path: [AppPage]
    @AppStorage("defaultPage") private var defaultPage: String = ""

    // Objectif stocké dans l'App Group partagé (accessible par le widget)
    @State private var sleepGoalMinutes: Int = HealthKitManager.shared.sleepGoalMinutes

    @State private var sleepDuration: TimeInterval = 0
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    @Environment(\.horizontalSizeClass) private var sizeClass

    private let healthManager = HealthKitManager.shared

    private var isDefault: Bool { defaultPage == AppPage.sleep.rawValue }

    /// Durée en minutes
    private var sleepMinutes: Int { Int(sleepDuration / 60) }

    /// Ratio de progression (0.0 → 1.0+)
    private var progress: Double {
        sleepGoalMinutes > 0 ? Double(sleepMinutes) / Double(sleepGoalMinutes) : 0
    }

    /// Couleurs du dégradé de fond : violet sombre (0%) → bleu-violet → bleu ciel (100%)
    private var gradientColors: [Color] { sleepGradientColors(for: progress) }

    /// Couleur principale de l'anneau (bord haut du dégradé)
    private var progressColor: Color { gradientColors[0] }

    var body: some View {
        GeometryReader { geometry in
            let isRegular = sizeClass == .regular

            ZStack {
                if isRegular {
                    regularLayout(geometry: geometry)
                } else {
                    compactLayout(geometry: geometry)
                }
            }
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: progress)
            )
        }
        .ignoresSafeArea(.all)
        .task { await loadSleep() }
    }

    // MARK: - Layouts

    private func compactLayout(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                headerTitle
                moonSection(diameter: min(geometry.size.width * 0.58, 260))
                statsRow
                goalCard
                if let error = errorMessage { errorBanner(error) }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private func regularLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(spacing: 20) {
                headerTitle
                moonSection(diameter: min(geometry.size.width * 0.38, 300))
                statsRow
                if let error = errorMessage { errorBanner(error) }
            }
            .frame(maxWidth: .infinity)

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
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Text("Sommeil")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Button {
                defaultPage = isDefault ? "" : AppPage.sleep.rawValue
            } label: {
                Image(systemName: isDefault ? "house.fill" : "house")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    private func moonSection(diameter: CGFloat) -> some View {
        VStack(spacing: 12) {
            ZStack {
                // Anneau de fond
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 18)
                    .frame(width: diameter, height: diameter)

                // Arc de progression
                Circle()
                    .trim(from: 0, to: isLoading ? 0 : min(progress, 1.0))
                    .stroke(.white, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: diameter, height: diameter)
                    .opacity(isLoading ? 0.4 : 1)
                    .animation(.easeOut(duration: 0.8), value: progress)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: diameter * 0.12))
                            .foregroundColor(.white.opacity(0.85))

                        Text(formattedDuration(sleepDuration))
                            .font(.system(size: diameter * 0.18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.easeOut, value: sleepDuration)

                        Text("cette nuit")
                            .font(.system(size: diameter * 0.065, weight: .medium))
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
            SleepStatItem(
                value: isLoading ? "—" : formattedDuration(sleepDuration),
                label: "durée"
            )
            Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: 36)
            SleepStatItem(
                value: isLoading ? "—" : "\(Int(min(progress, 9.99) * 100))%",
                label: "objectif"
            )
            Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: 36)
            SleepStatItem(
                value: isLoading ? "—" : formattedRemainder,
                label: "restants"
            )
        }
        .padding(.vertical, 14)
        .background(.white.opacity(0.15))
        .cornerRadius(16)
    }

    /// Temps restant avant d'atteindre l'objectif, ou "Objectif !" si dépassé.
    private var formattedRemainder: String {
        let remaining = max(0, sleepGoalMinutes - sleepMinutes)
        if remaining == 0 { return "Objectif !" }
        let h = remaining / 60
        let m = remaining % 60
        return h > 0 ? "\(h)h\(m > 0 ? "\(m)m" : "")" : "\(m)m"
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Objectif de sommeil", systemImage: "bed.double.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Stepper(
                value: $sleepGoalMinutes,
                in: 240...720,   // 4h → 12h
                step: 15
            ) {
                Text(formattedGoal)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .tint(.white)
            .onChange(of: sleepGoalMinutes) { _, newValue in
                HealthKitManager.shared.sleepGoalMinutes = newValue
                WidgetCenter.shared.reloadAllTimelines()
            }

            // Raccourcis
            HStack(spacing: 8) {
                SleepGoalButton(label: "6h",  minutes: 360, current: $sleepGoalMinutes)
                SleepGoalButton(label: "7h",  minutes: 420, current: $sleepGoalMinutes)
                SleepGoalButton(label: "8h",  minutes: 480, current: $sleepGoalMinutes)
                SleepGoalButton(label: "9h",  minutes: 540, current: $sleepGoalMinutes)
            }
        }
        .padding(20)
        .background(.white.opacity(0.18))
        .cornerRadius(20)
    }

    private var formattedGoal: String {
        let h = sleepGoalMinutes / 60
        let m = sleepGoalMinutes % 60
        return m == 0 ? "\(h)h de sommeil" : "\(h)h \(m)m"
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

    private func loadSleep() async {
        guard healthManager.isAvailable else {
            errorMessage = "HealthKit n'est pas disponible sur cet appareil."
            isLoading = false
            return
        }
        do {
            try await healthManager.requestAuthorization()
            sleepDuration = try await healthManager.fetchLastNightSleep()
        } catch let error as NSError where error.domain == "com.apple.healthkit" && error.code == 5 {
            errorMessage = "HealthKit nécessite un iPhone physique."
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Couleur

    /// Interpolation violet sombre → bleu-violet → bleu ciel selon la progression.
    private func sleepGradientColors(for p: Double) -> [Color] {
        let t = min(max(p, 0), 1)
        // top  : violet sombre (0%) → indigo (50%) → bleu ciel (100%)
        let top = Color(
            red:   lerp(0.12, 0.20, 0.20, t),
            green: lerp(0.01, 0.25, 0.65, t),
            blue:  lerp(0.22, 0.75, 1.00, t)
        )
        // bottom : légèrement plus sombre / profond
        let bottom = Color(
            red:   lerp(0.06, 0.10, 0.10, t),
            green: lerp(0.00, 0.12, 0.40, t),
            blue:  lerp(0.12, 0.55, 0.80, t)
        )
        return [top, bottom]
    }

    /// Interpolation linéaire entre a (t=0), mid (t=0.5) et b (t=1).
    private func lerp(_ a: Double, _ mid: Double, _ b: Double, _ t: Double) -> Double {
        t < 0.5 ? a + (mid - a) * (t * 2) : mid + (b - mid) * ((t - 0.5) * 2)
    }

    // MARK: - Formatage

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h\(m)m"
    }
}

// MARK: - Cellule de stat

struct SleepStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bouton raccourci d'objectif

struct SleepGoalButton: View {
    let label: String
    let minutes: Int
    @Binding var current: Int

    var body: some View {
        Button {
            current = minutes
            HealthKitManager.shared.sleepGoalMinutes = minutes
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Text(label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(current == minutes ? Color.white : Color.white.opacity(0.2))
                .foregroundColor(current == minutes ? .black : .white)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    SleepTrackingView(path: .constant([.sleep]))
}
