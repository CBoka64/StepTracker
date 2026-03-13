# StepTracker 🦶

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue.svg)](https://developer.apple.com/xcode/)
[![WidgetKit](https://img.shields.io/badge/WidgetKit-✓-green.svg)](https://developer.apple.com/documentation/widgetkit)
[![HealthKit](https://img.shields.io/badge/HealthKit-✓-red.svg)](https://developer.apple.com/documentation/healthkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Application iOS de suivi de pas avec widget dynamique. Le widget change de couleur en temps réel selon votre progression vers l'objectif quotidien.

---

## Aperçu

| Progression | Couleur du widget |
|:-----------:|:-----------------:|
| 0 – 10 %    | 🔴 Rouge           |
| 11 – 50 %   | 🟠 Orange          |
| 51 – 80 %   | 🟡 Jaune           |
| 81 %+       | 🟢 Vert            |

Le widget est disponible en deux tailles :
- **Small** (carré) — icône + nombre de pas + barre de progression
- **Medium** (rectangulaire) — détails complets avec pourcentage et pas restants

---

## Fonctionnalités

- **Comptage de pas en temps réel** via HealthKit
- **Widget dynamique** avec dégradé de couleur selon l'objectif
- **Objectif personnalisable** (stepper + raccourcis 5 000 / 8 000 / 10 000 / 15 000)
- **Synchronisation app ↔ widget** via App Group (UserDefaults partagé)
- **Rafraîchissement automatique** toutes les 15 minutes
- **Rafraîchissement instantané** quand l'objectif change dans l'app

---

## Prérequis

- **Xcode 16** ou plus récent
- **iOS 17+** comme cible de déploiement
- Un **iPhone physique** pour tester HealthKit (le simulateur ne fournit pas de vraies données de pas)
- Un **compte développeur Apple** (compte gratuit suffisant pour tester sur votre propre appareil)

---

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/CBoka64/StepTracker.git
cd StepTracker
open StepTracker.xcodeproj
```

### 2. Configurer la signature (Signing)

1. Dans Xcode, cliquez sur le projet (icône bleue)
2. Pour chaque target (**StepTracker** et **StepWidgetExtension**) :
   - Onglet **Signing & Capabilities**
   - Sélectionnez votre **Team** dans le menu déroulant

### 3. Configurer l'App Group

L'App Group permet à l'app et au widget de partager l'objectif de pas.

1. Pour chaque target, onglet **Signing & Capabilities → App Groups**
2. Remplacez l'identifiant existant par le vôtre : `group.com.VOTRENOM.steptracker`
3. Mettez à jour le même identifiant dans `StepTracker/HealthKitManager.swift` et `StepWidget/HealthKitManager.swift` :

```swift
// Ligne ~78 dans HealthKitManager.swift
return UserDefaults(suiteName: "group.com.VOTRENOM.steptracker")
```

> ⚠️ Les deux targets doivent avoir **exactement le même** App Group ID.

### 4. Compiler et lancer

1. Connectez votre iPhone
2. Sélectionnez-le comme destination en haut de Xcode
3. Scheme : **StepTracker** (pas StepWidgetExtension)
4. **Run** (⌘R)
5. Acceptez l'accès HealthKit au premier lancement

### 5. Ajouter le widget

Appui long sur l'écran d'accueil → **+** → cherchez **StepTracker** → choisissez la taille.

---

## Architecture

```
StepTracker/
├── ContentView.swift          → Interface : affiche les pas, gère l'objectif
├── HealthKitManager.swift     → Lit les pas via HealthKit, stocke l'objectif
└── StepTrackerApp.swift       → Point d'entrée de l'app

StepWidget/
├── StepWidget.swift           → Déclaration du widget (tailles, metadata)
├── StepWidgetBundle.swift     → Point d'entrée de l'extension
├── StepWidgetProvider.swift   → Fournit les données à iOS (timeline + StepEntry)
└── StepWidgetView.swift       → Design visuel (Small, Medium, ProgressBarView)

StepWidgetExtension.entitlements  → Capabilities widget (HealthKit + App Group)
StepTracker/StepTracker.entitlements  → Capabilities app (HealthKit + App Group)
```

### Flux de données

```
App (ContentView)
    │  requestAuthorization()
    ▼
HealthKitManager ──── fetchTodayStepCount() ──── HealthKit
    │  stepGoal (UserDefaults App Group)
    ▼
Widget (StepWidgetProvider)
    │  getTimeline() → StepEntry
    ▼
StepWidgetView (Small / Medium)
```

---

## Personnalisation

| Ce que vous voulez changer | Où modifier |
|---|---|
| Couleurs des dégradés | `StepEntry.gradientColors` dans `StepWidgetProvider.swift` |
| Objectif par défaut (10 000) | `HealthKitManager.stepGoal` getter |
| Fréquence de rafraîchissement (15 min) | `getTimeline()` dans `StepWidgetProvider.swift` |
| Tailles de widget supportées | `supportedFamilies` dans `StepWidget.swift` |
| Paliers de couleur | `progressColor` / `gradientColors` dans `StepEntry` |

---

## Dépannage

| Problème | Solution |
|---|---|
| Widget affiche toujours 0 | Ouvrez l'app au moins une fois pour autoriser HealthKit |
| La pop-up HealthKit n'apparaît pas | Vérifiez que la capability HealthKit est bien ajoutée aux deux targets |
| L'objectif ne se synchronise pas | Vérifiez que l'App Group ID est **identique** dans les deux targets et dans `HealthKitManager.swift` |
| Widget ne se rafraîchit pas | iOS limite les rafraîchissements — patientez, ou forcez via l'app en modifiant l'objectif |
| Erreur `No such module 'HealthKit'` | Vérifiez que HealthKit est activé dans Signing & Capabilities |

---

## Contribution

Les contributions sont les bienvenues !

1. Forkez le projet
2. Créez une branche : `git checkout -b feature/ma-fonctionnalite`
3. Commitez vos changements : `git commit -m 'Ajoute ma fonctionnalité'`
4. Pushez : `git push origin feature/ma-fonctionnalite`
5. Ouvrez une Pull Request

Quelques idées d'améliorations possibles :
- Widget Large avec historique de la semaine
- Support macOS (app Santé sur Mac)
- Suivi de distance ou de calories en plus des pas
- Notifications quand l'objectif est atteint
- Thème sombre/clair personnalisable

---

## Licence

Ce projet est distribué sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus d'informations.

---

*Développé avec SwiftUI, WidgetKit et HealthKit.*
