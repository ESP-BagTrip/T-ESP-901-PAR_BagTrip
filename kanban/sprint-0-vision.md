# Sprint 0 — Vision Produit & Principes

> **Objectif** : Aligner la direction produit avant de coder une ligne.
> **Ref design** : Tripsy, Airbnb, Hopper, Apple Wallet, Wanderlog

---

## Principes directeurs

### 1. "One screen, one decision"

Chaque ecran pose **une seule question** a l'utilisateur. Pas de formulaires denses, pas de scroll infini de champs. Progressive disclosure partout.

### 2. "AI as copilot, not autopilot"

L'IA propose, l'utilisateur dispose. Toute suggestion IA est : opt-in, clairement identifiee (badge sparkle), modifiable, et dismissable. Jamais imposee.

### 3. "Context-aware, not config-heavy"

L'app s'adapte au contexte (avant/pendant/apres le voyage) sans que l'utilisateur configure quoi que ce soit. L'interface se transforme automatiquement.

### 4. "Native first"

Chaque interaction doit sembler native a la plateforme. Haptics iOS, spring animations, context menus, large titles. Pas de compromis "cross-platform".

### 5. "Zero cognitive load"

L'utilisateur ne doit jamais se demander "qu'est-ce que je suis cense faire ici ?". Chaque action suivante est evidente. Les etats vides guident. Les erreurs proposent une resolution.

### 6. "Polish is the product" (NOUVEAU)

Les animations, haptics, et skeleton loading ne sont pas une couche finale. Ils sont integres des le premier sprint de chaque feature. Un ecran sans transition est un ecran incomplet.

---

## Architecture des ecrans

```
App Launch
  |
  +-- Auth check (splash)
  |     |-- Not logged in --> Login/Register
  |     +-- Logged in -----> Home
  |
  +-- Home (context-aware)
  |     |-- No trips ---------> Onboarding View (welcome + CTA "Planifier")
  |     |-- Trip ongoing -----> Active Trip Hero (today's schedule, countdown)
  |     +-- Trips planned ----> Trip Management (upcoming cards + past carousel)
  |
  +-- Trip Creation (single fluid wizard)
  |     Step 1: Dates (exact picker OR flexible estimation)
  |     Step 2: Travelers + Budget (counter + preset chips)
  |     Step 3: Destination (AI suggestions OR manual search)
  |     Step 4: Visualize & Select (carousel des propositions)
  |     Step 5: AI Generation (SSE streaming des donnees manquantes)
  |     Step 6: Review & Validate (ou retour pour explorer les alternatives)
  |
  +-- Trip Detail (post-creation, progressive completion)
  |     |-- Overview (hero card + completion progress)
  |     |-- Timeline (day-by-day, morning/afternoon/evening blocks)
  |     |-- Flights (book via Amadeus OU saisie manuelle)
  |     |-- Accommodations (Amadeus suggestions OU saisie manuelle)
  |     |-- Activities (AI-suggested + manual, validate/reject/add)
  |     |-- Baggage (smart checklist, AI-suggested, progress bar)
  |     |-- Budget (dashboard + expense tracking)
  |     +-- Sharing (link-based, view-only)
  |
  +-- In-Trip Mode (auto-switch quand start_date <= today)
  |     |-- Today View (next activity countdown, mini-map, weather)
  |     |-- Quick Actions (navigate, log expense, take photo)
  |     +-- Daily Summary (notifications)
  |
  +-- Post-Trip
        |-- Completed view (memories, stats, feedback prompt)
        +-- AI suggestions for next trip
```

---

## Nouveau flow de creation — Detail fonctionnel

### Philosophie

**Un seul formulaire, techniquement complexe, mais percu comme une conversation naturelle.** L'utilisateur ne remplit pas un formulaire — il "discute" avec l'app pour planifier son voyage.

Chaque etape est un ecran plein, avec une transition fluide (slide + spring curve). Le header compact montre un resume des reponses precedentes (expandable).

### Flow detaille

```
[Dates] --> [Travelers + Budget] --> [Destination] --> [AI Proposals / Manual] --> [Generation] --> [Review]
```

**Pourquoi cet ordre ?**
- Les dates et le budget **conditionnent** les suggestions de l'IA (saisonnalite, prix vols)
- Les preferences voyageur **affinent** les suggestions (couple vs famille vs solo)
- La destination arrive en **dernier** car c'est la decision la plus complexe — l'IA peut aider ici
- L'IA a toutes les donnees en main quand on arrive a l'etape destination

---

## Mapping ancien flow vs nouveau flow

| Ancien flow | Nouveau flow |
| --- | --- |
| 2 parcours separes (manuel vs AI) | 1 seul parcours unifie |
| Destination en premier | Dates en premier |
| AI = bouton cache dans step 1 | AI = option naturelle a step 3 |
| Pas de budget collecte | Budget = step 2 (chips presets) |
| 4 etapes manuelles | 6 etapes fluides (dont 2 AI) |
| AI genere tout from scratch | AI complete les donnees manquantes |
| Redirect inconsistant post-creation | Toujours vers TripDetailPage |
| nb_travelers default inconsistant | Harmonise a 1 partout |
| Pas de validation API | Validation stricte dates + destination |
| Items bagages hardcodes francais | Items bagages IA + i18n |
| Destination auto-selectionnee (1ere) | L'utilisateur choisit parmi les propositions |

---

## KPIs qualite attendus

| Metrique | Cible |
| --- | --- |
| Temps creation voyage (manuel) | < 90 secondes |
| Temps creation voyage (avec AI) | < 120 secondes |
| Taux d'abandon du wizard | < 15% |
| `flutter analyze` issues | 0 |
| Couverture tests unitaires (BLoCs) | > 80% |
| Couverture tests widgets | > 60% |
| Performance (FPS scroll) | 60fps constant |
| Home loading time | < 1.5s |
| Taille APK / IPA | Pas de regression > 5% |
