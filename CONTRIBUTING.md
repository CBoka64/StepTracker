# Guide de contribution — StepTracker

Merci de vouloir contribuer à StepTracker ! Ce document explique comment participer au projet.

---

## Table des matières

- [Code de conduite](#code-de-conduite)
- [Comment contribuer](#comment-contribuer)
- [Configurer l'environnement de développement](#configurer-lenvironnement-de-développement)
- [Processus de Pull Request](#processus-de-pull-request)
- [Conventions de code Swift](#conventions-de-code-swift)
- [Signaler un bug](#signaler-un-bug)
- [Proposer une fonctionnalité](#proposer-une-fonctionnalité)

---

## Code de conduite

Ce projet respecte le [Contributor Covenant](CODE_OF_CONDUCT.md). En participant, vous vous engagez à maintenir un environnement respectueux et inclusif.

---

## Comment contribuer

1. **Fork** le repository
2. Crée une branche depuis `main` : `git checkout -b feat/ma-fonctionnalité`
3. Fais tes modifications
4. Lance le build (`Cmd+B`) et vérifie qu'il n'y a aucune erreur
5. Commit avec un message conventionnel (voir ci-dessous)
6. Ouvre une **Pull Request** vers `main`

---

## Configurer l'environnement de développement

### Prérequis

- **Xcode 16+**
- **iOS 17+** comme cible de déploiement
- Un **iPhone physique** pour tester HealthKit

### Étapes

```bash
# Cloner le repo
git clone https://github.com/CBoka64/StepTracker.git
cd StepTracker

# Ouvrir dans Xcode
open StepTracker.xcodeproj
```

### Points importants

- **App Group** : l'identifiant `group.com.bc046.stepttracker` doit être configuré dans les entitlements des deux targets (StepTracker et StepWidgetExtension)
- **HealthKit** : les tests nécessitent un iPhone physique — le simulateur ne fournit pas de vraies données de pas
- **Code signing** : utilise ton propre Team ID dans les réglages de signing

---

## Processus de Pull Request

- Une PR = une fonctionnalité ou un correctif
- Le titre doit suivre le format **Conventional Commits** (voir ci-dessous)
- Remplis le template de PR
- Les CI checks (build + tests) doivent passer

### Conventional Commits

```
feat: ajouter la taille large du widget
fix: corriger l'objectif qui se réinitialise au redémarrage
docs: mettre à jour le README avec des screenshots
refactor: extraire ColorTheme dans un fichier séparé
test: ajouter des tests pour HealthKitManager
chore: mettre à jour les dépendances SPM
```

---

## Conventions de code Swift

- **SwiftUI** pour toutes les vues
- **Architecture MVVM** — la logique métier dans les ViewModels, pas dans les vues
- **async/await** pour les opérations asynchrones (pas de callbacks)
- **Commentaires en français** (ce projet est documenté en français)
- Les structs et classes en **UpperCamelCase**, les propriétés et fonctions en **lowerCamelCase**

---

## Signaler un bug

Utilise le [template d'issue Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) et fournis :

- Version iOS et modèle d'iPhone
- Étapes pour reproduire
- Comportement attendu vs observé
- Captures d'écran si pertinent

---

## Proposer une fonctionnalité

Utilise le [template d'issue Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) et décris :

- Le problème que ça résout
- La solution que tu proposes
- Des alternatives que tu as envisagées
