// SleepTrackingView.swift
// StepTracker
//
// Section suivi du sommeil — à implémenter dans une prochaine version.
// Affiche un placeholder avec le bouton de page par défaut.

import SwiftUI

struct SleepTrackingView: View {

    @Binding var path: [AppPage]
    @AppStorage("defaultPage") private var defaultPage: String = ""

    private var isDefault: Bool { defaultPage == AppPage.sleep.rawValue }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.45),
                    Color(red: 0.05, green: 0.06, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 0) {

                // En-tête
                HStack {
                    Button { path.removeLast() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Text("Suivi du sommeil")
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
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 32)

                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.55))

                    Text("Bientôt disponible")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Le suivi du sommeil sera disponible dans une prochaine version.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }

                Spacer()

                if isDefault {
                    Label("Page d'accueil définie", systemImage: "house.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    SleepTrackingView(path: .constant([.sleep]))
}
