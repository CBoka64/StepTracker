// SleepWidget.swift
// StepWidgetExtension
//
// Déclaration du widget sommeil — même structure que StepWidget.

import WidgetKit
import SwiftUI

struct SleepWidget: Widget {

    let kind: String = "com.bc046.steptracker.sleepwidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepWidgetProvider()) { entry in
            SleepWidgetView(entry: entry)
                .widgetURL(URL(string: "steptracker://sleep"))
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: entry.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Suivi du sommeil")
        .description("Affiche votre durée de sommeil de la nuit avec un dégradé selon votre objectif.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
