# Kanban — BagTrip Refactor Plan v2

> **Vision** : Transformer BagTrip en une app de voyage premium. Un seul flow de creation, une home contextuelle, un mode voyage immersif.
> **Philosophie** : Chaque sprint livre une experience utilisable. Le polish n'est pas une phase — c'est le produit.
> **Structure** : 6 sprints. Pas de sprint technique isole. Pas de sprint polish a la fin.

---

## Roadmap

| Sprint | Nom | Dependances | Status |
| ------ | --- | ----------- | ------ |
| **0** | Vision & Principes | — | [ ] |
| **1** | Assainissement Technique & Fondation | — | [ ] |
| **2** | Creation de Trip Unifiee | Sprint 1 | [ ] |
| **3** | Home Contextuelle & Trip Detail | Sprint 1, 2 | [ ] |
| **4** | Mode In-Trip & Notifications | Sprint 3 | [ ] |
| **5** | Completion, Edition & Partage | Sprint 3 | [ ] |
| **6** | Tests Complets, Polish Final & Cleanup | Tous | [ ] |

> Sprints 4 et 5 peuvent etre parallelises (pas de dependance entre eux).

---

## Graphe de dependances

```
Sprint 0 (Vision)
    |
Sprint 1 (Assainissement + Fondation)
    |
Sprint 2 (Creation Trip Unifiee)
    |
Sprint 3 (Home + Trip Detail)
   / \
  /   \
Sprint 4 (In-Trip)    Sprint 5 (Completion + Sharing)
  \   /
   \ /
Sprint 6 (Tests + Polish + Cleanup)
```

---

## Principes structurants (vs ancien kanban)

| Ancien kanban (10 sprints) | Nouveau kanban (6 sprints) |
| --- | --- |
| Foundation technique isolee | Assainissement = fixe les bugs d'audit AVANT de construire |
| Sprint API isole (Sprint 5) | Changements API integres dans chaque sprint qui en a besoin |
| Polish reporte au Sprint 9 | Animations, haptics, skeletons integres dans chaque sprint |
| Tests reports au Sprint 9 | Tests ecrits avec chaque feature |
| In-trip mode au Sprint 8 | In-trip mode au Sprint 4 (le differenciateur arrive tot) |
| Home redesignee 3 fois (S1, S2, S8) | Home designee une seule fois (Sprint 3) |
| 10 sprints, 19 semaines | 6 sprints, scope equivalent, zero gaspillage |

---

## Corrections techniques integrees (issues de l'audit)

| Probleme identifie | Sprint |
| --- | --- |
| `build.yaml` sans `field_rename: snake_case` (~100+ champs JSON) | Sprint 1 |
| `PaymentCard` / `RecentBooking` pas Freezed | Sprint 1 |
| `FlightSegment` sans `fromJson` | Sprint 1 |
| FCM StreamSubscriptions jamais cancel (memory leak) | Sprint 1 |
| `LocationService` / `AgentService` throw au lieu de Result<T> | Sprint 1 |
| 15 BLoCs sans `close()` override | Sprint 1 |
| 14 imports dead dans `service_locator.dart` | Sprint 1 |
| 2 fichiers avec legacy `EmptyState` | Sprint 1 |
| `Navigator.push()` bypass GoRouter | Sprint 1 |
| 78 `Colors.*` hardcodes dans les views | Sprint 1 |
| Erreurs silencieusement avalees dans services | Sprint 1 |
| `SettingsState` / `NavigationState` pas sealed | Sprint 1 |
| `CachedTripRepository` mauvais type d'erreur | Sprint 1 |
| Anti-pattern `add(LoadXxx())` reload complet | Sprint 1 |
| Couverture tests ~40% → objectif > 80% BLoCs | Sprint 6 |

---

## Fichiers sprint

- [Sprint 0 — Vision](./sprint-0-vision.md)
- [Sprint 1 — Assainissement & Fondation](./sprint-1-assainissement.md)
- [Sprint 2 — Creation Trip Unifiee](./sprint-2-creation-trip.md)
- [Sprint 3 — Home & Trip Detail](./sprint-3-home-trip-detail.md)
- [Sprint 4 — Mode In-Trip](./sprint-4-in-trip-mode.md)
- [Sprint 5 — Completion & Partage](./sprint-5-completion-sharing.md)
- [Sprint 6 — Tests, Polish & Cleanup](./sprint-6-tests-polish-cleanup.md)
