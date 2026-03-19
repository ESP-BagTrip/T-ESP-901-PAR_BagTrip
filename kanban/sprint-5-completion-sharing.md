# Sprint 5 — Completion, Edition & Partage

> **Objectif** : Permettre a l'utilisateur de completer son voyage apres creation — affiner les dates, booker des vols, gerer hebergements, bagages, activites, budget, et partager le trip.
> **Dependances** : Sprint 3 (Trip Detail Page avec toutes les sections)
> **Ref design** : Tripsy trip editing, Wanderlog collaborative, TripIt sharing

> Ce sprint est parallelisable avec le Sprint 4 (pas de dependance mutuelle).

---

## 5.1 — Edition des informations de base

### Taches

- [ ] **EB1 — Inline editing du titre**
  - Tap titre dans le hero → `AdaptiveEditDialog` avec valeur pre-remplie
  - Appel `PATCH /v1/trips/{id}` au save
  - OWNER only
  - **Test** : Tap ouvre dialog, save appelle API, UI se met a jour

- [ ] **EB2 — Edition des dates**
  - Tap dates → bottom sheet range picker
  - Validation : `start <= end`, pas dans le passe
  - Alert si activites hors range : "X activites seront supprimees"
  - Appel `PATCH /v1/trips/{id}`
  - **Decoration** : transparent bg + rounded top + handle bar
  - **Test** : Validation, detection activites, confirmation dialog

- [ ] **EB3 — Edition du nombre de voyageurs**
  - Stepper dans la section sharing
  - Impact : recalcul du budget estime
  - **Test** : Stepper, appel API, recalcul budget

- [ ] **EB4 — Gestion du statut**
  - Bouton "Finaliser" quand DRAFT → PLANNED (conditions : destination + dates)
  - **Test** : Conditions, transition de statut

---

## 5.2 — Flight Booking & Manual Entry

### Taches

- [ ] **FB1 — Recherche de vols depuis trip detail**
  - Bouton "Rechercher un vol" dans la section flights
  - Pre-remplit `origin_iata`, `destination_iata`, dates depuis le trip
  - Navigue vers `FlightSearchRoute`
  - **Test** : Pre-remplissage, navigation

- [ ] **FB2 — Refactorer le formulaire vol manuel**
  - Groupement logique : (1) Depart, (2) Arrivee, (3) Compagnie, (4) Type
  - Validation : aeroports differents, arrivee >= depart
  - **Decoration** : bottom sheet standard (transparent + rounded + handle)
  - **Test** : Validation, soumission, pre-remplissage

- [ ] **FB3 — Lier un vol au trip**
  - Apres booking/selection → retour trip detail
  - Vol apparait dans la section flights
  - Mise a jour optimiste du state (pas de re-fetch complet)
  - **Test** : Search → select → trip detail affiche le vol

---

## 5.3 — Accommodation Management

### Taches

- [ ] **AM1 — Formulaire d'hebergement ameliore**
  - Bottom sheet : nom, adresse, check-in/out dates (pre-remplies), heures, prix, confirmation #, notes
  - Mode creation + edition
  - **Decoration** : transparent + rounded + handle bar
  - **Test** : Creation, edition, validation

- [ ] **AM2 — Suggestions d'hotels depuis Amadeus**
  - Bouton "Rechercher un hotel"
  - Utilise `destination_iata` + dates du trip
  - Resultats : prix, etoiles, distance
  - "Selectionner" cree un accommodation
  - **Test** : Resultats affiches, selection cree

- [ ] **AM3 — Card d'hebergement enrichie**
  - Nom, adresse (tappable → Maps), dates, prix, confirmation #
  - Actions (OWNER) : Edit, Delete
  - Badge : "Reserve" ou "Planifie"
  - **Test** : Avec/sans confirmation, role-gating

---

## 5.4 — Baggage Management

### Taches

- [ ] **BM1 — Gestion complete de la checklist**
  - Check/uncheck avec spring animation
  - Swipe delete
  - Drag-and-drop reorder (long press)
  - Items coches descendent en bas
  - **Haptic** : `AppHaptics.light()` sur check, `AppHaptics.medium()` sur swipe delete
  - **Test** : Check animation, reorder, delete

- [ ] **BM2 — Ajout d'items bagages**
  - Bottom sheet : nom, quantite (stepper, default 1), categorie (chips : Clothes/Electronics/Documents/Hygiene/Other)
  - Validation : nom non vide
  - **Test** : Form, validation, soumission

- [ ] **BM3 — Suggestions IA de bagages supplementaires**
  - Bouton "Suggestions IA"
  - Appel `POST /v1/baggage/{tripId}/suggestions`
  - Liste 5-10 suggestions avec bouton "Ajouter" par item
  - Deduplication avec items existants
  - **Test** : Suggestions affichees, dedup, ajout

- [ ] **BM4 — Celebration a 100%**
  - Quand tous les items sont coches :
    - Confetti/checkmark animation
    - `AppHaptics.success()`
    - Message "Tout est pret !"
  - **Test** : Animation declenchee a 100%

---

## 5.5 — Activity Management

### Taches

- [ ] **ACT1 — Valider/Rejeter en batch**
  - Si activites SUGGESTED existent : compteur "X a valider" + "Valider tout" + "Revoir une par une"
  - Batch update API
  - **Haptic** : `AppHaptics.success()` sur "Valider tout"
  - **Test** : Compteur, batch API, boutons

- [ ] **ACT2 — Ajout manuel d'activite**
  - Bottom sheet : titre, date (picker pre-rempli au jour selectionne), start/end times, lieu, categorie (8 chips), cout, notes
  - Creee comme MANUAL
  - **Decoration** : transparent + rounded + handle
  - **Test** : Form, validation, soumission

- [ ] **ACT3 — Edition d'activite**
  - Tap activite → edit sheet (meme form, pre-rempli)
  - Tous les champs editables sauf ID
  - **Test** : Pre-remplissage, save

- [ ] **ACT4 — Drag and drop d'activites entre jours**
  - Long press → drag mode
  - Drop sur un autre jour → update date de l'activite
  - Highlight visuel du jour cible
  - Appel `PATCH /v1/activities/{id}`
  - **Haptic** : `AppHaptics.medium()` au drop
  - **Test** : Drag initie, drop met a jour

- [ ] **ACT5 — Suggestion IA pour jours vides**
  - Jour vide → CTA "Obtenir des suggestions"
  - Appel API pour 2-3 activites
  - Ajoutees comme SUGGESTED (validables)
  - **Test** : Appel API, activites ajoutees avec status SUGGESTED

---

## 5.6 — Trip Sharing

### Taches

- [ ] **TS1 — Invite par email ameliore**
  - Bottom sheet : champ email + message optionnel
  - Validation format email
  - Erreurs specifiques :
    - "L'utilisateur doit d'abord creer un compte"
    - "Deja partage avec cet utilisateur"
  - **Test** : Validation, erreurs specifiques

- [ ] **TS2 — Revocation de partage**
  - Swipe ou bouton "X" sur un viewer → dialog confirmation
  - "Retirer l'acces de X ?"
  - Apres : viewer ne peut plus acceder
  - **Haptic** : `AppHaptics.medium()` sur swipe
  - **Test** : Confirmation, revocation effective

- [ ] **TS3 — Indicateur de role dans l'app**
  - VIEWER voit badge "Lecture seule" dans l'AppBar du trip detail
  - Tous les boutons d'edition desactives
  - **Test** : Badge visible, boutons disabled

---

## 5.7 — Budget Tracking Improvements

### Taches

- [ ] **BT1 — Ajout de depense depuis le trip detail**
  - Bottom sheet : montant, categorie, date, note
  - Ajout dans la section budget
  - Mise a jour optimiste du total
  - **Test** : Form, soumission, total mis a jour

- [ ] **BT2 — Alert budget depasse**
  - Si `totalSpent > totalBudget` → banner warning dans la section budget
  - Texte : "Budget depasse de X EUR"
  - **Test** : Banner affiché au bon moment

---

## Tests Sprint 5

### Tests unitaires

| Test | Module | Scenarios |
| --- | --- | --- |
| `date_editing_test.dart` | Trip date editing | Validation, activites hors range |
| `flight_prefill_test.dart` | Flight search | Pre-remplissage IATA + dates |
| `batch_validation_test.dart` | Activity batch | Compteur, batch API call |
| `baggage_completion_test.dart` | Baggage checklist | 0-100%, celebration trigger |
| `drag_drop_activity_test.dart` | Activity drag | Date update, API call |

### Tests widgets

| Test | Widget | Scenarios |
| --- | --- | --- |
| `inline_edit_title_test.dart` | TripHeroHeader | Tap opens dialog, save updates |
| `date_edit_test.dart` | Date bottom sheet | Validation, hors range alert |
| `manual_flight_form_test.dart` | Flight form | Validation, soumission |
| `accommodation_form_test.dart` | Accommodation form | Creation, edition |
| `baggage_management_test.dart` | Baggage section | Check, reorder, delete, add |
| `activity_form_test.dart` | Activity form | Fields, validation, soumission |
| `share_invite_test.dart` | Share invite | Validation email, erreurs specifiques |

### Tests integration

| Test | Scenario |
| --- | --- |
| `trip_completion_flow_test.dart` | Add flight + accommodation + validate activities → completion progresses |
| `viewer_readonly_test.dart` | Login viewer → voir trip partage → lecture seule |

---

## Criteres d'acceptation Sprint 5

- [ ] Titre editable inline (OWNER only)
- [ ] Dates editables avec detection d'activites hors range
- [ ] Flight search pre-remplit IATA codes + dates du trip
- [ ] Formulaire vol manuel valide et smooth
- [ ] Accommodation add (manuel + Amadeus search) fonctionne
- [ ] Baggage checklist : check/reorder/delete/add
- [ ] Celebration a 100% bagages coches (confetti + haptic)
- [ ] Activites AI validables individuellement + en batch
- [ ] Ajout manuel d'activite fonctionne
- [ ] Drag-and-drop activites entre jours
- [ ] Suggestions IA pour jours vides
- [ ] Invite par email avec erreurs specifiques
- [ ] Revocation de partage avec confirmation
- [ ] VIEWER voit badge "Lecture seule", ne peut pas editer
- [ ] Budget : ajout depense + alert si depasse
- [ ] Toutes les bottom sheets : transparent bg + rounded + handle bar
- [ ] Dark mode fonctionne
- [ ] `flutter analyze` = 0 issues
- [ ] Tous les tests passent
- [ ] i18n EN + FR
