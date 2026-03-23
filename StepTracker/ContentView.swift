// ContentView.swift
// StepTracker
//
// Design adaptatif : fond dégradé plein écran + anneau de progression circulaire.
// Sur iPhone (compact) : layout vertical.
// Sur iPad / Mac (regular) : layout deux colonnes côte à côte.

import SwiftUI
import WidgetKit

// MARK: - Vue principale

/// Vue racine de l'application StepTracker.
///
/// `ContentView` orchestre l'ensemble de l'interface utilisateur :
/// - Récupération et affichage des pas via `HealthKitManager`
/// - Fond dégradé plein écran qui change de couleur selon la progression
/// - Anneau de progression circulaire animé
/// - Réglage de l'objectif quotidien avec synchronisation immédiate du widget
///
/// La mise en page s'adapte automatiquement :
/// - **compact** (iPhone) → `compactLayout` (défilement vertical)
/// - **regular** (iPad/Mac) → `regularLayout` (deux colonnes côte à côte)
struct StepTrackingView: View {

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 1 — Déclarer les variables d'état (@State) de la vue
    // ═══════════════════════════════════════════════════════════════
    // @State est une annotation SwiftUI qui dit : "quand cette variable
    // change, recrée automatiquement l'affichage."
    // Ces 4 variables représentent l'état complet de la vue :

    /// Nombre de pas du jour, chargé depuis HealthKit au lancement de la vue.
    ///
    /// Initialisé à `0` et mis à jour après la résolution de la requête HealthKit.
    /// Déclenche une transition animée via `.contentTransition(.numericText())`.
    @State private var stepCount: Int = 0          // Commence à 0, mis à jour après lecture HealthKit

    /// Objectif quotidien en nombre de pas, lu depuis l'App Group partagé.
    ///
    /// Toute modification est immédiatement persistée dans `HealthKitManager.stepGoal`
    /// et déclenche un rechargement du widget via `WidgetCenter.shared.reloadAllTimelines()`.
    @State private var stepGoal: Int = HealthKitManager.shared.stepGoal  // Valeur sauvegardée (défaut 10 000)

    /// Indique si le chargement HealthKit est en cours.
    ///
    /// Pendant le chargement, l'anneau est atténué et un `ProgressView` est affiché
    /// au centre. Passe à `false` dès que la requête se termine (succès ou erreur).
    @State private var isLoading: Bool = true      // true = en train de charger

    /// Message d'erreur affiché dans `errorBanner` si HealthKit échoue.
    ///
    /// `nil` tant qu'aucune erreur ne s'est produite. Alimenté par le bloc `catch`
    /// de `setupHealthKit()` ou si HealthKit n'est pas disponible sur l'appareil.
    @State private var errorMessage: String?       // nil = pas d'erreur

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 2 — Lire la taille d'écran via @Environment
    // ═══════════════════════════════════════════════════════════════
    // @Environment permet de lire des informations du système.
    // horizontalSizeClass indique si l'écran est "compact" (iPhone)
    // ou "regular" (iPad plein écran, Mac). Cela permet d'adapter
    // automatiquement la mise en page sans écrire deux apps séparées.

    /// Taille horizontale de l'écran, injectée par SwiftUI.
    ///
    /// - `.compact` → iPhone (et iPad en split-view étroit) : `compactLayout`
    /// - `.regular` → iPad plein écran, Mac Catalyst : `regularLayout`
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Référence au singleton `HealthKitManager` pour l'autorisation et la lecture des pas.
    private let healthManager = HealthKitManager.shared

    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultPage") private var defaultPage: String = ""

    private var isDefault: Bool { defaultPage == AppPage.steps.rawValue }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 3 — Calculer le ratio de progression (pas / objectif)
    // ═══════════════════════════════════════════════════════════════
    // "progress" est une propriété calculée : elle est recalculée
    // automatiquement à chaque fois que stepCount ou stepGoal change.
    // Exemple : 6 500 pas / 10 000 objectif = 0.65 (soit 65%).
    // La protection "stepGoal > 0" évite une division par zéro.

    /// Ratio pas / objectif, entre 0.0 et 1.0+.
    ///
    /// Non plafonné à 1.0 pour permettre l'affichage de valeurs supérieures à 100 %.
    /// Retourne `0` si l'objectif est nul pour éviter une division par zéro.
    private var progress: Double {
        stepGoal > 0 ? Double(stepCount) / Double(stepGoal) : 0
    }

    /// Couleur principale calculée selon le palier de progression.
    ///
    /// Délègue à `colorForProgress(_:)`. Utilisée comme couleur de base
    /// du fond dégradé plein écran, animée lors des transitions.
    private var progressColor: Color { colorForProgress(progress) }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 4 — Construire l'interface dans "body"
    // ═══════════════════════════════════════════════════════════════
    // "body" est la propriété obligatoire de toute vue SwiftUI.
    // Elle décrit CE QUE l'utilisateur voit. SwiftUI recrée cette vue
    // automatiquement chaque fois qu'un @State change.
    // Le ZStack superpose le fond dégradé ET le contenu par-dessus.

    /// La vue SwiftUI rendue par ce composant.
    ///
    /// Compose un `ZStack` avec le contenu adaptatif (compact ou regular),
    /// et un fond dégradé animé via `.background(.ignoresSafeArea())`.
    ///
    /// > Note : Le dégradé est placé dans `.background` (et non en enfant du ZStack)
    /// > afin de couvrir toute la fenêtre — y compris la status bar et le home
    /// > indicator — sans affecter les safe area insets du contenu.
    var body: some View {
        // ═══════════════════════════════════════════════════════════════
        // ÉTAPE 5 — GeometryReader : lire la taille réelle de l'écran
        // ═══════════════════════════════════════════════════════════════
        // GeometryReader donne accès aux dimensions disponibles (width/height)
        // à l'exécution, sur le vrai appareil. On calcule le diamètre de
        // l'anneau en pourcentage de la largeur d'écran pour qu'il s'adapte
        // automatiquement : iPhone SE (375 pt), iPhone 15 Pro Max (430 pt), iPad, etc.
        GeometryReader { geometry in
            let isRegular = sizeClass == .regular
            let ringDiameter: CGFloat = isRegular
                ? min(geometry.size.width * 0.38, 300)   // iPad : 38 % de la largeur
                : min(geometry.size.width * 0.58, 260)   // iPhone : 58 % de la largeur

            ZStack {
                if isRegular {
                    regularLayout(ringDiameter: ringDiameter)
                } else {
                    compactLayout(ringDiameter: ringDiameter)
                }
            }
            .background(
                LinearGradient(
                    colors: [progressColor, progressColor.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: progressColor)
            )
        }
        .task { await setupHealthKit() }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Layout compact (iPhone)

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 7 — Layout iPhone : ScrollView + VStack vertical
    // ═══════════════════════════════════════════════════════════════
    // ScrollView permet de faire défiler le contenu si l'écran est
    // trop petit. VStack empile les éléments verticalement avec
    // un espacement de 28 points entre chaque bloc.

    /// Layout vertical pour iPhone et tailles d'écran compactes.
    ///
    /// Empile verticalement dans un `ScrollView` : titre, anneau,
    /// rangée de stats, carte d'objectif et (si besoin) bandeau d'erreur.
    /// `ringDiameter` est calculé depuis `GeometryReader` dans `body`.
    private func compactLayout(ringDiameter: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                headerTitle
                ringSection(diameter: ringDiameter)
                statsRow
                goalCard
                if let error = errorMessage { errorBanner(error) }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    // MARK: - Layout regular (iPad / Mac)

    /// Layout deux colonnes pour iPad plein écran et Mac Catalyst.
    ///
    /// Colonne gauche : titre + anneau + stats + bandeau d'erreur.
    /// Colonne droite : carte de réglage de l'objectif.
    /// `ringDiameter` est calculé depuis `GeometryReader` dans `body`.
    private func regularLayout(ringDiameter: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 40) {
            // Colonne gauche : anneau
            VStack(spacing: 20) {
                headerTitle
                ringSection(diameter: ringDiameter)
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

    /// En-tête avec bouton retour (←), titre centré et bouton page par défaut (⌂).
    private var headerTitle: some View {
        HStack {
            // Retour au menu
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Text("Mes Pas")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            // Définir / retirer comme page par défaut
            Button {
                defaultPage = isDefault ? "" : AppPage.steps.rawValue
            } label: {
                Image(systemName: isDefault ? "house.fill" : "house")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 8 — Afficher l'anneau de progression ou le spinner
    // ═══════════════════════════════════════════════════════════════
    // Pendant le chargement (isLoading == true), on montre un spinner
    // blanc et l'anneau est atténué (opacity 0.4).
    // Une fois les données arrivées, l'anneau se remplit avec une
    // animation (easeOut 0.8s) et le compteur numérique apparaît.
    // .contentTransition(.numericText()) anime le changement de chiffre.

    /// Anneau de progression circulaire centré avec le compteur de pas à l'intérieur.
    ///
    /// Pendant le chargement, affiche un `ProgressView` blanc et atténue l'anneau.
    /// Une fois chargé, anime le remplissage de l'arc et le compteur numérique.
    /// `diameter` est calculé dynamiquement depuis `GeometryReader` pour s'adapter
    /// à la taille réelle de l'écran (iPhone SE, iPhone 15 Pro Max, iPad…).
    private func ringSection(diameter: CGFloat) -> some View {
        VStack(spacing: 12) {
            ZStack {
                CircularProgressRing(
                    progress: isLoading ? 0 : progress,
                    color: .white
                )
                .frame(width: diameter, height: diameter)
                .opacity(isLoading ? 0.4 : 1)
                .animation(.easeOut(duration: 0.8), value: progress)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                } else {
                    VStack(spacing: 4) {
                        Text("\(stepCount)")
                            // Taille de police proportionnelle au diamètre (≈ 22 %)
                            // 220 pt × 0.22 ≈ 48 pt (valeur d'origine)
                            .font(.system(size: diameter * 0.22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.easeOut, value: stepCount)

                        Text("pas")
                            // Taille de police proportionnelle au diamètre (≈ 7 %)
                            // 220 pt × 0.07 ≈ 15 pt (valeur d'origine)
                            .font(.system(size: diameter * 0.07, weight: .medium))
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

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 9 — Afficher les 3 statistiques dans une rangée
    // ═══════════════════════════════════════════════════════════════
    // HStack place les éléments côte à côte horizontalement.
    // Les 3 cellules (StepStatItem) partagent l'espace équitablement.
    // Pendant le chargement, on affiche "—" à la place des chiffres
    // pour signaler que les données ne sont pas encore disponibles.

    /// Rangée de 3 statistiques : pas du jour, pourcentage, pas restants.
    ///
    /// Les cellules sont séparées par `divider` et affichent "—" pendant le chargement.
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

    /// Séparateur vertical semi-transparent entre les cellules de la rangée de stats.
    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.3))
            .frame(width: 1, height: 36)
    }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 10 — Carte de réglage de l'objectif avec Stepper
    // ═══════════════════════════════════════════════════════════════
    // Le Stepper permet d'augmenter/diminuer stepGoal par pas de 500,
    // avec un minimum de 1 000 et un maximum de 50 000 pas.
    // Les boutons GoalButton offrent des raccourcis vers les valeurs
    // les plus courantes (5 000, 8 000, 10 000, 15 000).

    /// Carte de réglage de l'objectif quotidien avec stepper et boutons raccourcis.
    ///
    /// Toute modification déclenche :
    /// 1. La persistance dans `HealthKitManager.stepGoal` (App Group)
    /// 2. Un rechargement du widget via `WidgetCenter.shared.reloadAllTimelines()`
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
            // ═══════════════════════════════════════════════════════════════
            // ÉTAPE 11 — Réagir au changement d'objectif et mettre à jour le widget
            // ═══════════════════════════════════════════════════════════════
            // .onChange(of:) est appelé automatiquement chaque fois que
            // stepGoal change (bouton + ou - du Stepper, ou bouton raccourci).
            // On fait deux choses :
            //   1. Sauvegarder la nouvelle valeur dans les UserDefaults partagés
            //      (HealthKitManager.stepGoal) pour que le widget puisse la lire.
            //   2. Demander à iOS de mettre à jour immédiatement le widget
            //      (WidgetCenter.shared.reloadAllTimelines()), sinon le widget
            //      n'afficherait le nouvel objectif qu'au prochain cycle de 15 min.
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

    /// Bandeau d'erreur affiché en bas de l'interface si HealthKit retourne une erreur.
    ///
    /// - Parameter message: Texte de l'erreur à afficher (typiquement `error.localizedDescription`).
    /// - Returns: Une vue `Label` stylisée sur fond semi-opaque.
    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundColor(.white)
            .padding(12)
            .background(.black.opacity(0.25))
            .cornerRadius(12)
    }

    // MARK: - HealthKit

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 12 — Demander l'autorisation HealthKit puis charger les pas
    // ═══════════════════════════════════════════════════════════════
    // Cette fonction est "async" : elle peut faire une pause (await)
    // sans bloquer l'interface. Le mot-clé "try" indique qu'elle peut
    // échouer et lancer une erreur, capturée par le bloc "catch".
    //
    // Ordre d'exécution :
    //   a) Vérifier si HealthKit est disponible sur cet appareil
    //   b) Demander la permission à l'utilisateur (pop-up système)
    //   c) Lire les pas du jour depuis l'app Santé
    //   d) Mettre fin au chargement (isLoading = false)

    /// Demande l'autorisation HealthKit puis charge les pas du jour.
    ///
    /// Appelée une seule fois via `.task { }` à l'apparition de la vue.
    /// Met à jour `stepCount`, `isLoading` et `errorMessage` selon le résultat.
    private func setupHealthKit() async {
        guard healthManager.isAvailable else {
            errorMessage = "HealthKit n'est pas disponible sur cet appareil."
            isLoading = false
            return
        }
        do {
            try await healthManager.requestAuthorization()
            stepCount = try await healthManager.fetchTodayStepCount()
        } catch let error as NSError where error.domain == "com.apple.healthkit" && error.code == 5 {
            // HealthKit non fonctionnel sur simulateur
            errorMessage = "HealthKit nécessite un iPhone physique."
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Couleur selon progression

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 13 — Choisir la couleur selon le niveau de progression
    // ═══════════════════════════════════════════════════════════════
    // Cette fonction reçoit le ratio (0.0 → 1.0+) et retourne une couleur.
    // La logique est simple : plus on avance vers l'objectif,
    // plus la couleur "chauffe" du rouge vers le vert.
    //   0 à 10%   → Rouge   (départ, motivation !)
    //   11 à 50%  → Orange  (en route)
    //   51 à 80%  → Jaune   (bonne progression)
    //   81%+      → Vert    (objectif quasi atteint ou dépassé)

    /// Retourne la couleur associée à un ratio de progression.
    ///
    /// | Plage (%) | Couleur               |
    /// |----------:|:----------------------|
    /// | 0 – 10    | Rouge                 |
    /// | 11 – 50   | Orange                |
    /// | 51 – 80   | Jaune lisible         |
    /// | 81 +      | Vert profond          |
    ///
    /// - Parameter p: Ratio de progression (0.0 = 0 %, 1.0 = 100 %).
    /// - Returns: Une `Color` SwiftUI correspondant au palier atteint.
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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 14 — Dessiner l'anneau circulaire avec Circle().trim()
// ═══════════════════════════════════════════════════════════════
// CircularProgressRing est un composant réutilisable (struct View séparée).
// Il dessine deux cercles superposés dans un ZStack :
//   1. Un cercle de fond semi-transparent (le "track" gris)
//   2. Un arc coloré par-dessus, dont la longueur = progress × 360°
//
// .trim(from: 0, to: progress) coupe le cercle à la valeur de progression.
// .rotationEffect(-90°) fait démarrer l'arc à 12h (au lieu de 3h par défaut).
// .lineCap: .round arrondit les extrémités de l'arc pour un effet soigné.

/// Anneau de progression circulaire réutilisable.
///
/// Affiche un arc coloré sur un fond circulaire semi-transparent.
/// L'arc commence à 12 h (`.rotationEffect(.degrees(-90))`) et tourne dans le sens
/// des aiguilles d'une montre. Les extrémités sont arrondies (`.lineCap: .round`).
struct CircularProgressRing: View {

    /// Ratio de remplissage entre 0.0 (vide) et 1.0 (plein).
    ///
    /// Les valeurs supérieures à 1.0 sont clampées à 1.0 visuellement.
    let progress: Double

    /// Couleur de l'arc et du fond semi-transparent.
    let color: Color

    /// Épaisseur du trait de l'anneau et du fond en points.
    private let lineWidth: CGFloat = 18

    /// La vue SwiftUI rendue par ce composant.
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

/// Cellule de statistique réutilisable affichant une valeur et son libellé.
///
/// Utilisée dans la rangée de stats de `ContentView` pour afficher
/// le nombre de pas, le pourcentage et les pas restants.
struct StepStatItem: View {

    /// Valeur numérique ou textuelle affichée en grand (ex : `"6 500"`, `"65%"`, `"—"`).
    let value: String

    /// Libellé descriptif affiché en petit sous la valeur (ex : `"pas"`, `"objectif"`).
    let label: String

    /// La vue SwiftUI rendue par ce composant.
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

// ═══════════════════════════════════════════════════════════════
// ÉTAPE 15 — Bouton raccourci avec @Binding pour modifier le parent
// ═══════════════════════════════════════════════════════════════
// @Binding est différent de @State : il ne crée PAS la variable,
// il reçoit un "lien" vers une variable qui existe dans la vue parente.
// Quand GoalButton modifie currentGoal, c'est DIRECTEMENT le stepGoal
// de ContentView qui est modifié — pas une copie locale.
// C'est le mécanisme de communication enfant → parent en SwiftUI.
//
// Visuellement : si goal == currentGoal, le bouton est blanc opaque
// (= sélectionné). Sinon il est semi-transparent.

/// Bouton de sélection rapide d'un objectif prédéfini.
///
/// S'affiche en blanc opaque lorsque `goal == currentGoal` (sélectionné),
/// ou en blanc semi-transparent sinon. Au tap, met à jour `currentGoal`,
/// persiste dans `HealthKitManager` et recharge le widget.
struct GoalButton: View {

    /// Texte affiché sur le bouton (ex : `"10 000"`).
    let title: String

    /// Valeur de l'objectif représentée par ce bouton (en nombre de pas).
    let goal: Int

    /// Objectif actuellement sélectionné dans la vue parente. Modifié au tap.
    @Binding var currentGoal: Int

    /// La vue SwiftUI rendue par ce composant.
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
    StepTrackingView()
}
