// HomeMenuView.swift
// StepTracker
//
// Menu principal de l'application.
// Affiché au lancement sauf si l'utilisateur a défini une page par défaut.
// Chaque carte navigue vers la section correspondante.

import SwiftUI

// MARK: - Menu principal

/// Vue d'accueil qui présente les 4 sections de l'application.
///
/// La page par défaut est indiquée par l'icône ⌂ sur la carte concernée.
/// Modifier la page par défaut se fait depuis chaque section.
struct HomeMenuView: View {

    /// Page définie comme accueil par l'utilisateur (empty = ce menu).
    @AppStorage("defaultPage") private var defaultPage: String = ""

    var body: some View {
        ZStack {
            // Fond dégradé bleu-indigo neutre pour le menu
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.65),
                    Color(red: 0.08, green: 0.12, blue: 0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
                        NavigationLink(value: AppPage.permissions) {
                            MenuItemCard(
                                icon: "hand.raised.fill",
                                title: "Permissions HealthKit",
                                subtitle: "Gérer l'accès aux données de santé",
                                isDefault: false
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: AppPage.steps) {
                            MenuItemCard(
                                icon: "figure.walk",
                                title: "Suivi des pas",
                                subtitle: "Pas du jour, objectif et progression",
                                isDefault: defaultPage == AppPage.steps.rawValue
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: AppPage.sleep) {
                            MenuItemCard(
                                icon: "moon.zzz.fill",
                                title: "Suivi du sommeil",
                                subtitle: "Durée et qualité de votre sommeil",
                                isDefault: defaultPage == AppPage.sleep.rawValue
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: AppPage.dashboard) {
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

                    // Indicateur de page par défaut active
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
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Carte de menu

/// Carte cliquable représentant une section de l'application.
///
/// L'icône ⌂ (`house.fill`) s'affiche quand cette section est définie
/// comme page d'accueil par défaut.
struct MenuItemCard: View {

    let icon: String
    let title: String
    let subtitle: String
    /// `true` si cette section est la page d'accueil par défaut.
    let isDefault: Bool

    var body: some View {
        HStack(spacing: 16) {

            // Icône dans badge
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.2))
                .cornerRadius(12)

            // Titre + sous-titre
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
    /// Nom lisible de la section, affiché dans le menu.
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
    HomeMenuView()
}
