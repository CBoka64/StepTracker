# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet respecte le [Versionnement Sémantique](https://semver.org/lang/fr/).

---

## [Non publié]

### À venir
- Taille Large du widget
- Historique des pas sur 7 jours
- Notifications de rappel personnalisables

---

## [1.0.0] — 2026-03-23

### Ajouté
- Application iOS de suivi de pas via HealthKit
- Widget dynamique en tailles Small et Medium
- Fond dégradé adaptatif selon la progression (rouge → orange → jaune → vert)
- Objectif quotidien personnalisable (stepper + raccourcis 5 000 / 8 000 / 10 000 / 15 000)
- Synchronisation app ↔ widget via App Group (UserDefaults partagé)
- Rafraîchissement automatique du widget toutes les 15 minutes
- Rafraîchissement instantané du widget lors d'un changement d'objectif
- Layout adaptatif : vertical sur iPhone, deux colonnes sur iPad
- Anneau de progression circulaire animé
- Rangée de 3 statistiques : pas, pourcentage, pas restants
- Support iOS 17+ et Xcode 16+
- Licence MIT

[Non publié]: https://github.com/CBoka64/StepTracker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/CBoka64/StepTracker/releases/tag/v1.0.0
