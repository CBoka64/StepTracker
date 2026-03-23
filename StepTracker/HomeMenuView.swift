// HomeMenuView.swift
// StepTracker
//
// Menu principal de l'application.
// Affiché au lancement sauf si l'utilisateur a défini une page par défaut.
// Chaque carte navigue vers la section correspondante.

import SwiftUI

// MARK: - Menu principal

struct HomeMenuView: View {

    @AppStorage("defaultPage") private var defaultPage: String = ""
    @Binding var path: [AppPage]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.65),
                    Color(red: 0.08, green: 0.12, blue: 0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 0) {

                    // En-tête
                    VStack(spacing: 10) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Text("StepTracker")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Que voulez-vous consulter ?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 40)

                    // Cartes de navigation
                    VStack(spacing: 14) {
                        Button { path.append(.permissions) } label: {
                            MenuItemCard(
                                icon: "hand.raised.fill",
                                title: "Permissions HealthKit",
                                subtitle: "Gérer l'accès aux données de santé",
                                isDefault: false
                            )
                        }
                        .buttonStyle(.plain)

                        Button { path.append(.steps) } label: {
                            MenuItemCard(
                                icon: "figure.walk",
                                title: "Suivi des pas",
                                subtitle: "Pas du jour, objectif et progression",
                                isDefault: defaultPage == AppPage.steps.rawValue
                            )
                        }
                        .buttonStyle(.plain)

                        Button { path.append(.sleep) } label: {
                            MenuItemCard(
                                icon: "moon.zzz.fill",
                                title: "Suivi du sommeil",
                                subtitle: "Durée et qualité de votre sommeil",
                                isDefault: defaultPage == AppPage.sleep.rawValue
                            )
                        }
                        .buttonStyle(.plain)

                        Button { path.append(.dashboard) } label: {
                            MenuItemCard(
                                icon: "chart.bar.fill",
                                title: "Dashboard",
                                subtitle: "Vue d'ensemble de votre activité",
                                isDefault: defaultPage == AppPage.dashboard.rawValue
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    if let page = AppPage(rawValue: defaultPage) {
                        Label("Accueil : \(page.displayName)", systemImage: "house.fill")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.top, 32)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Carte de menu

struct MenuItemCard: View {

    let icon: String
    let title: String
    let subtitle: String
    let isDefault: Bool

    var body: some View {
        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.2))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if isDefault {
                        Image(systemName: "house.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.white.opacity(0.13))
        .cornerRadius(16)
    }
}

// MARK: - Extension utilitaire

extension AppPage {
    var displayName: String {
        switch self {
        case .permissions: return "Permissions"
        case .steps:       return "Suivi des pas"
        case .sleep:       return "Suivi du sommeil"
        case .dashboard:   return "Dashboard"
        }
    }
}

// MARK: - Preview

#Preview {
    HomeMenuView(path: .constant([]))
}
