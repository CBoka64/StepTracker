// HealthKitPermissionsView.swift
// StepTracker
//
// Gestion des permissions HealthKit.
// Affiche l'état actuel de l'autorisation et permet de la demander.
// Cette section n'a pas de bouton "page par défaut" (pas de sens pour une page de réglages).

import SwiftUI
import HealthKit
import UIKit

// MARK: - Vue des permissions

/// Vue de gestion de l'autorisation HealthKit.
///
/// Affiche l'état de l'accès (accordé / non déterminé) et propose
/// un bouton pour demander l'autorisation si elle n'a pas encore été accordée.
/// En cas de refus, redirige vers les Réglages iOS.
struct HealthKitPermissionsView: View {

    @Binding var path: [AppPage]

    /// `true` si HealthKit a retourné des données avec succès (proxy d'autorisation).
    @State private var isAuthorized = false
    /// `true` pendant la demande d'autorisation.
    @State private var isLoading = false
    /// Message d'erreur ou d'aide affiché sous le bouton.
    @State private var statusMessage = ""

    private let manager = HealthKitManager.shared

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
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // En-tête avec bouton retour
                sectionHeader(title: "Permissions HealthKit")

                Spacer()

                // Icône principale
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 24)

                // Description
                VStack(spacing: 10) {
                    Text("Accès à HealthKit")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("StepTracker lit uniquement vos données de pas depuis l'app Santé. Aucune donnée n'est écrite ni partagée.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)

                // Carte de permission
                HStack(spacing: 14) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Nombre de pas")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Lecture uniquement · Aujourd'hui")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: isAuthorized ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isAuthorized ? .green : .white.opacity(0.35))
                }
                .padding(18)
                .background(.white.opacity(0.13))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

                // Bouton d'action
                if !manager.isAvailable {
                    Text("HealthKit n'est pas disponible sur cet appareil.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Button {
                        Task { await requestAccess() }
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView().tint(.black).scaleEffect(0.9)
                            } else {
                                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "hand.raised.fill")
                                    .font(.system(size: 16))
                            }
                            Text(isAuthorized ? "Accès accordé" : "Autoriser l'accès")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isAuthorized ? Color.green.opacity(0.85) : Color.white)
                        .foregroundColor(isAuthorized ? .white : Color(red: 0.1, green: 0.1, blue: 0.2))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .disabled(isLoading || isAuthorized)

                    // Bouton vers les réglages iOS pour gérer/révoquer l'accès
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 14))
                            Text("Gérer dans Réglages Santé")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.top, 6)
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 10)
                    }
                }

                Spacer()
            }
        }
        .ignoresSafeArea(.all)
        .task { await checkStatus() }
    }

    // MARK: - Composants

    /// En-tête commun avec bouton retour, sans icône d'accueil par défaut.
    private func sectionHeader(title: String) -> some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            // Espace de symétrie (pas de bouton ⌂ pour les permissions)
            Image(systemName: "chevron.left").opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    // MARK: - HealthKit

    /// Vérifie l'état actuel de l'autorisation en tentant une lecture.
    private func checkStatus() async {
        guard manager.isAvailable else { return }
        do {
            _ = try await manager.fetchTodayStepCount()
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Demande l'autorisation HealthKit puis vérifie le résultat.
    private func requestAccess() async {
        isLoading = true
        statusMessage = ""
        defer { isLoading = false }

        do {
            try await manager.requestAuthorization()
            await checkStatus()
            if !isAuthorized {
                statusMessage = "Accès non accordé. Allez dans Réglages → Santé → Accès aux apps → StepTracker."
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    HealthKitPermissionsView(path: .constant([.permissions]))
}
