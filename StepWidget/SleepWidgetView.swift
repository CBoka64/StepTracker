// SleepWidgetView.swift
// StepWidgetExtension
//
// Vue du widget sommeil — même structure que StepWidgetView.
// Affiche la durée de sommeil et la progression vers l'objectif.

import SwiftUI
import WidgetKit

// MARK: - Vue principale

struct SleepWidgetView: View {

    let entry: SleepEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallSleepWidgetView(entry: entry)
        case .systemMedium:
            MediumSleepWidgetView(entry: entry)
        default:
            SmallSleepWidgetView(entry: entry)
        }
    }
}

// MARK: - Small

struct SmallSleepWidgetView: View {

    let entry: SleepEntry

    var body: some View {
        Group {
            switch entry.state {
            case .loaded:
                loadedContent
            case .unavailable:
                stateContent(icon: "heart.slash.fill", message: "HealthKit\nnon disponible")
            case .unauthorized:
                stateContent(icon: "lock.shield.fill", message: "Ouvre l'app\npour autoriser")
            }
        }
        .padding(12)
        .widgetURL(URL(string: "steptracker://sleep"))
    }

    private var loadedContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            Text(entry.formattedDuration)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("cette nuit")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            ProgressBarView(progress: entry.progress)
                .frame(height: 6)
                .padding(.horizontal, 8)

            Text("/ \(entry.sleepGoalMinutes / 60)h objectif")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func stateContent(icon: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium

struct MediumSleepWidgetView: View {

    let entry: SleepEntry

    var body: some View {
        Group {
            switch entry.state {
            case .loaded:
                loadedContent
            case .unavailable:
                stateContent(icon: "heart.slash.fill",
                             message: "HealthKit non disponible sur cet appareil")
            case .unauthorized:
                stateContent(icon: "lock.shield.fill",
                             message: "Ouvre l'app StepTracker pour autoriser l'accès à Santé")
            }
        }
        .padding(16)
        .widgetURL(URL(string: "steptracker://sleep"))
    }

    private var loadedContent: some View {
        HStack(spacing: 16) {

            // Colonne gauche : icône + durée
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(entry.formattedDuration)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("cette nuit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)

            // Colonne droite : progression
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                    Text("\(Int(min(entry.progress, 9.99) * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                ProgressBarView(progress: entry.progress)
                    .frame(height: 8)

                HStack {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                    let goalH = entry.sleepGoalMinutes / 60
                    let goalM = entry.sleepGoalMinutes % 60
                    Text("Objectif : \(goalM == 0 ? "\(goalH)h" : "\(goalH)h\(goalM)m")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                let remaining = max(0, entry.sleepGoalMinutes - entry.sleepMinutes)
                HStack {
                    Image(systemName: remaining == 0 ? "checkmark.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                    let rH = remaining / 60
                    let rM = remaining % 60
                    let remainingText = remaining == 0 ? "Objectif atteint !" :
                        (rH > 0 ? "Encore \(rH)h\(rM > 0 ? "\(rM)m" : "")" : "Encore \(rM)m")
                    Text(remainingText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func stateContent(icon: String, message: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Small – Vert (90%)", as: .systemSmall) {
    SleepWidget()
} timeline: {
    SleepEntry(date: Date(), sleepDuration: 7.5 * 3600, sleepGoalMinutes: 480, state: .loaded)
}

#Preview("Small – Orange (55%)", as: .systemSmall) {
    SleepWidget()
} timeline: {
    SleepEntry(date: Date(), sleepDuration: 4.5 * 3600, sleepGoalMinutes: 480, state: .loaded)
}

#Preview("Small – Non autorisé", as: .systemSmall) {
    SleepWidget()
} timeline: {
    SleepEntry(date: Date(), sleepDuration: 0, sleepGoalMinutes: 480, state: .unauthorized)
}

#Preview("Medium – Vert", as: .systemMedium) {
    SleepWidget()
} timeline: {
    SleepEntry(date: Date(), sleepDuration: 8 * 3600, sleepGoalMinutes: 480, state: .loaded)
}

#Preview("Medium – Rouge", as: .systemMedium) {
    SleepWidget()
} timeline: {
    SleepEntry(date: Date(), sleepDuration: 2 * 3600, sleepGoalMinutes: 480, state: .loaded)
}
