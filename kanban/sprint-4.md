# Sprint 4 — Hébergements : Recherche Amadeus + Suggestions IA Quartier

> **Durée estimée** : ~1 semaine
> **Objectif** : Offrir une expérience d'hébergement complète — l'IA recommande un type/quartier, Amadeus fournit les résultats réels, l'utilisateur peut aussi saisir manuellement.
> **Prérequis** : Sprint 1 (layout), Sprint 3 (IA contextuelle en place)

---

## Tâches

### Backend — Amadeus Hotel API

| # | Tâche | Statut | Réf backlog |
|---|-------|--------|-------------|
| 1 | Intégrer Amadeus Hotel List API dans `AmadeusClient` (recherche hôtels par ville/coordonnées) | [ ] | 6.1 |
| 2 | Intégrer Amadeus Hotel Search API (disponibilités + prix par hôtel) | [ ] | 6.2 |
| 3 | Créer endpoint `GET /v1/travel/hotels` (recherche par cityCode ou lat/lng) | [ ] | 6.3 |
| 4 | Créer endpoint `GET /v1/travel/hotels/{hotelId}/offers` (disponibilités + prix) | [ ] | 6.4 |
| 5 | Créer schemas Pydantic pour les réponses Hotel List et Hotel Search | [ ] | — |

### Backend — IA Suggestions Hébergement

| # | Tâche | Statut | Réf backlog |
|---|-------|--------|-------------|
| 6 | Créer service `AccommodationAiService` | [ ] | — |
| 7 | Créer endpoint `POST /v1/trips/{tripId}/accommodations/suggest` | [ ] | 6.5 |
| 8 | Prompt : profil + destination + dates + budget + voyageurs + activités prévues | [ ] | 6.6 |
| 9 | Réponse : 3-5 suggestions (type hébergement, quartier, fourchette prix/nuit, raison) | [ ] | — |

### Backend — Budget Auto (Hébergements)

| # | Tâche | Statut | Réf backlog |
|---|-------|--------|-------------|
| 10 | À la création/MAJ d'un hébergement avec prix → auto-créer/MAJ BudgetItem (source_type=ACCOMMODATION) | [ ] | 6.7 |
| 11 | Calcul automatique : prix_par_nuit × nombre_de_nuits → montant du BudgetItem | [ ] | 6.7 |
| 12 | À la suppression d'un hébergement → auto-supprimer le BudgetItem lié | [ ] | — |

### Frontend — Section Hébergements

| # | Tâche | Statut | Réf backlog |
|---|-------|--------|-------------|
| 13 | Bouton "Suggestions IA" → affiche recommandations type/quartier | [ ] | 6.10 |
| 14 | Depuis une suggestion IA → lancer recherche Amadeus filtrée sur ce quartier/zone | [ ] | 6.11 |
| 15 | Formulaire d'ajout avec recherche auto-complétion Amadeus (nom d'hôtel, adresse) | [ ] | 6.8 |
| 16 | Conserver le formulaire d'ajout manuel (Airbnb, Booking, etc.) | [ ] | 6.9 |
| 17 | Afficher prix total calculé (prix/nuit × nuits) sur chaque hébergement | [ ] | — |

---

## Critères de validation

- [ ] L'IA recommande des types d'hébergement et quartiers adaptés au profil et aux activités
- [ ] L'utilisateur peut chercher des hôtels réels via Amadeus
- [ ] L'utilisateur peut ajouter manuellement un hébergement
- [ ] Le coût total (prix/nuit × nuits) alimente automatiquement le budget
- [ ] La suppression met à jour le budget

---

## Dépendances

- Amadeus Hotel API : vérifier les clés API et l'accès (même compte que Flights)
- Sprint 3 : IA contextuelle (même pattern de prompt enrichi)
