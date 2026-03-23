# CLAUDE.md — Contexte projet pour Claude Code

Ce fichier donne à Claude Code le contexte nécessaire pour travailler sur StepTracker.

---

## Vue d'ensemble

**StepTracker** est une app iOS open source qui affiche le nombre de pas quotidiens via HealthKit, avec un widget WidgetKit dynamique dont le fond change de couleur selon la progression.

- **Langage** : Swift 5.9+
- **UI** : SwiftUI
- **Architecture** : MVVM
- **iOS minimum** : 17.0
- **Xcode minimum** : 16.0

---

## Structure du projet

```
StepTracker/
├── StepTracker/              # App principale
│   ├── StepTrackerApp.swift  # Point d'entrée (@main)
│   ├── ContentView.swift     # Vue principale (layout compact + regular)
│   └── HealthKitManager.swift # Singleton HealthKit + gestion objectif
│
├── StepWidget/               # Extension widget WidgetKit
│   ├── StepWidgetBundle.swift # Déclaration du bundle widget
│   ├── StepWidget.swift      # Configuration et entrée du widget
│   ├── StepWidgetProvider.swift # TimelineProvider (données + planning)
│   ├── StepWidgetView.swift  # Vues Small et Medium du widget
│   └── HealthKitManager.swift # Copie partagée (même App Group)
```

---

## Règles critiques

### App Group
- Identifiant : `group.com.bc046.stepttracker` (noter la double `t` dans `stepttracker`)
- Utilisé pour partager `stepGoal` entre l'app et le widget via `UserDefaults`
- Doit être configuré dans les entitlements des DEUX targets

### HealthKit
- Uniquement lecture (`toRead`) — on n'écrit jamais dans l'app Santé
- HealthKit ne fonctionne que sur iPhone physique, pas sur simulateur
- Le code gère l'erreur HealthKit code 5 (simulateur) explicitement

### Widget
- Rafraîchissement : toutes les 15 minutes via `Timeline`
- Rafraîchissement forcé : `WidgetCenter.shared.reloadAllTimelines()` quand l'objectif change
- Ne jamais modifier `StepWidgetProvider.swift` sans vérifier que `StepEntry` reste conforme à `TimelineEntry`

### SwiftUI
- Pas de UIKit sauf si absolument nécessaire
- `@State` pour l'état local, `@Binding` pour passer aux enfants
- `.task { }` pour les opérations async au chargement de la vue

---

## Commandes utiles

```bash
# Ouvrir le projet
open StepTracker.xcodeproj

# Vérifier le statut git
git status

# Builder depuis la ligne de commande (CI)
xcodebuild -project StepTracker.xcodeproj \
  -scheme StepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build CODE_SIGNING_ALLOWED=NO
```

---

## Paliers de couleur

| Progression | Couleur |
|:-----------:|:-------:|
| 0 – 10 %    | Rouge |
| 11 – 50 %   | Orange |
| 51 – 80 %   | Jaune (`Color(red: 0.8, green: 0.7, blue: 0.1)` dans l'app, `.yellow` dans le widget) |
| 81 %+       | Vert (`Color(red: 0.1, green: 0.7, blue: 0.35)` dans l'app, `.green` dans le widget) |

---

## Ce qu'il ne faut PAS faire

- Ne pas créer plusieurs instances de `HKHealthStore` (utiliser `HealthKitManager.shared`)
- Ne pas modifier l'App Group ID sans mettre à jour les entitlements des deux targets
- Ne pas utiliser UIKit pour les vues — SwiftUI uniquement
- Ne pas ajouter de dépendances CocoaPods (le projet utilise SPM ou zéro dépendance externe)
