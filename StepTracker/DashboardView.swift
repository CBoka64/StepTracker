// DashboardView.swift
// StepTracker
//
// Section dashboard — à implémenter dans une prochaine version.
// Affiche un placeholder avec le bouton de page par défaut.

import SwiftUI

struct DashboardView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultPage") private var defaultPage: String = ""

    private var isDefault: Bool { defaultPage == AppPage.dashboard.rawValue }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.35, blue: 0.28),
                    Color(red: 0.04, green: 0.18, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // En-tête
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Text("Dashboard")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))

                    Spacer()

                    // Bouton page par défaut
                    Button {
                        defaultPage = isDefault ? "" : AppPage.dashboard.rawValue
                    } label: {
                        Image(systemName: isDefault ? "house.fill" : "house")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)

                Spacer()

                // Contenu placeholder
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.55))

                    Text("Bientôt disponible")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Le dashboard sera disponible dans une prochaine version.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }

                Spacer()

                // Indication si page par défaut
                if isDefault {
                    Label("Page d'accueil définie", systemImage: "house.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.bottom, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    DashboardView()
}
