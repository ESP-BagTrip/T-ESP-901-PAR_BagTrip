# Spécifications Fonctionnelles — Assistant de Voyage IA (V4)

## 1. Vision & Objectif

L'application accompagne l'utilisateur à travers **quatre phases** : l'**Inspiration** (génération IA d'un voyage), la **Planification** (construction complète du trip), le **Voyage en cours** (notifications et suivi temps réel) et le **Post-voyage** (feedback et suggestions).

L'objectif produit est de couvrir le cycle de vie complet d'un voyage, de l'idée initiale au retour.

---

## 2. Modèle de Données (Entités & Relations)

### 2.1 Trip

Entité centrale. Un voyage appartient à un unique **owner** (le créateur).

| Champ           | Type          | Description                                      |
| --------------- | ------------- | ------------------------------------------------ |
| `id`            | UUID          | Identifiant unique                                |
| `owner_id`      | UUID (FK)     | Créateur du voyage                                |
| `title`         | string        | Nom du voyage                                     |
| `destination`   | string        | Destination principale                            |
| `start_date`    | date          | Date de début                                     |
| `end_date`      | date          | Date de fin                                       |
| `status`        | enum          | `DRAFT` → `PLANNED` → `ONGOING` → `COMPLETED`   |
| `budget_total`  | decimal       | Budget global alloué (en devise de référence)     |
| `origin`        | enum          | `AI` / `MANUAL` — tunnel de création utilisé      |
| `created_at`    | datetime      |                                                   |
| `updated_at`    | datetime      |                                                   |

**Machine à états du Trip :**

```
DRAFT ──→ PLANNED ──→ ONGOING ──→ COMPLETED
  │                                    ▲
  └──────────── (suppression) ─────────┘ (seul DRAFT peut être supprimé)
```

- `DRAFT` : Trip créé (via IA ou manuellement), en cours de complétion.
- `PLANNED` : Trip considéré comme prêt par l'owner. Les partages view-only sont actifs.
- `ONGOING` : La `start_date` est atteinte. Notifications actives.
- `COMPLETED` : La `end_date` est dépassée ou clôture manuelle. Feedback possible.

**Règles de transition :**

| Transition            | Déclencheur                                | Condition                        |
| --------------------- | ------------------------------------------ | -------------------------------- |
| DRAFT → PLANNED       | Action manuelle de l'owner                 | Au moins une destination et des dates définies |
| PLANNED → ONGOING     | Automatique quand `start_date` est atteinte | —                                |
| ONGOING → COMPLETED   | Automatique quand `end_date` est dépassée, ou clôture manuelle | —                                |
| DRAFT → supprimé      | Action manuelle de l'owner                 | Statut = DRAFT uniquement        |

### 2.2 Activity

Une activité est un élément du planning jour par jour.

| Champ         | Type      | Description                              |
| ------------- | --------- | ---------------------------------------- |
| `id`          | UUID      |                                          |
| `trip_id`     | UUID (FK) |                                          |
| `title`       | string    | Nom de l'activité                        |
| `description` | text      | Détail / notes                           |
| `date`        | date      | Jour de l'activité                       |
| `start_time`  | time      | Heure de début (optionnel)               |
| `end_time`    | time      | Heure de fin (optionnel)                 |
| `location`    | string    | Lieu / adresse (optionnel)               |
| `category`    | enum      | `VISIT`, `RESTAURANT`, `TRANSPORT`, `LEISURE`, `OTHER` |
| `estimated_cost` | decimal | Coût estimé                             |
| `is_booked`   | boolean   | Réservation confirmée ou non             |

### 2.3 Flight

Un vol réservé via l'application (Amadeus + Stripe).

| Champ              | Type      | Description                          |
| ------------------ | --------- | ------------------------------------ |
| `id`               | UUID      |                                      |
| `trip_id`          | UUID (FK) |                                      |
| `airline`          | string    | Compagnie aérienne                   |
| `flight_number`    | string    |                                      |
| `departure_city`   | string    |                                      |
| `arrival_city`     | string    |                                      |
| `departure_at`     | datetime  |                                      |
| `arrival_at`       | datetime  |                                      |
| `booking_ref`      | string    | Référence de réservation Amadeus     |
| `payment_id`       | string    | ID de transaction Stripe             |
| `ticket_url`       | string    | URL du billet numérique stocké       |
| `price`            | decimal   |                                      |
| `status`           | enum      | `CONFIRMED`, `CANCELLED`             |

**Règle :** Un vol `CONFIRMED` ne peut pas être modifié via l'app. Seule l'annulation est possible (si supportée par Amadeus).

### 2.4 Accommodation

| Champ          | Type      | Description                  |
| -------------- | --------- | ---------------------------- |
| `id`           | UUID      |                              |
| `trip_id`      | UUID (FK) |                              |
| `name`         | string    | Nom de l'hébergement         |
| `address`      | string    |                              |
| `check_in`     | date      |                              |
| `check_out`    | date      |                              |
| `price_per_night` | decimal |                             |
| `notes`        | text      | Infos complémentaires        |

### 2.5 BudgetItem

Suivi granulaire des dépenses.

| Champ      | Type      | Description                                     |
| ---------- | --------- | ----------------------------------------------- |
| `id`       | UUID      |                                                 |
| `trip_id`  | UUID (FK) |                                                 |
| `label`    | string    | Description de la dépense                       |
| `amount`   | decimal   | Montant                                         |
| `category` | enum      | `FLIGHT`, `ACCOMMODATION`, `FOOD`, `ACTIVITY`, `TRANSPORT`, `OTHER` |
| `date`     | date      | Date de la dépense                              |
| `is_planned` | boolean | Dépense prévue vs dépense réelle               |

**Règles budget :**
- `budget_total` est défini sur le Trip. La somme des `BudgetItem` donne le budget consommé.
- Alerte quand `sum(BudgetItem.amount) >= 80%` de `budget_total`.
- Alerte quand `sum(BudgetItem.amount) > budget_total` (dépassement).

### 2.6 BaggageItem

Check-list de bagages.

| Champ      | Type      | Description              |
| ---------- | --------- | ------------------------ |
| `id`       | UUID      |                          |
| `trip_id`  | UUID (FK) |                          |
| `name`     | string    | Nom de l'objet           |
| `quantity` | int       | Nombre                   |
| `is_packed`| boolean   | Coché / pas coché        |
| `category` | enum      | `CLOTHES`, `ELECTRONICS`, `DOCUMENTS`, `HYGIENE`, `OTHER` |

### 2.7 TripShare

Gestion du partage view-only.

| Champ       | Type      | Description                             |
| ----------- | --------- | --------------------------------------- |
| `id`        | UUID      |                                         |
| `trip_id`   | UUID (FK) |                                         |
| `user_id`   | UUID (FK) | Utilisateur invité                      |
| `role`      | enum      | `VIEWER` (seule valeur pour l'instant)  |
| `invited_at`| datetime  |                                         |

**Règles de partage :**
- Seul l'**owner** peut inviter/révoquer des viewers.
- Un viewer voit : planning, activités, hébergements, vols (horaires uniquement, pas les prix), budget global (pas le détail), bagages.
- Un viewer **ne peut pas** modifier quoi que ce soit.
- Un viewer **reçoit** les notifications du voyage quand le trip est `ONGOING`.

### 2.8 Feedback

Retour post-voyage.

| Champ          | Type      | Description                                      |
| -------------- | --------- | ------------------------------------------------ |
| `id`           | UUID      |                                                  |
| `trip_id`      | UUID (FK) |                                                  |
| `user_id`      | UUID (FK) | Auteur du feedback (owner ou viewer)             |
| `overall_rating` | int (1-5) | Note globale                                   |
| `highlights`   | text      | Points positifs (texte libre)                    |
| `lowlights`    | text      | Points négatifs (texte libre)                    |
| `would_recommend` | boolean | Recommanderait cette destination                |
| `created_at`   | datetime  |                                                  |

**Règle :** Un seul feedback par user par trip. Le feedback est possible uniquement quand le trip est `COMPLETED`.

---

## 3. Parcours par Phase

### Phase 1 — Inspiration

**Objectif :** Générer une idée de voyage personnalisée via l'IA.

**Flux :**
1. L'utilisateur lance le tunnel IA.
2. Il répond à un questionnaire de préférences :
   - Type de voyage (détente, aventure, culture, gastronomie, mixte)
   - Climat préféré
   - Fourchette de budget
   - Durée souhaitée
   - Contraintes (dates fixes, destinations exclues)
3. L'IA génère une suggestion de voyage comprenant :
   - Destination recommandée
   - Durée suggérée
   - Estimation budgétaire
   - Aperçu des activités possibles (liste non exhaustive)
4. L'utilisateur peut :
   - **Accepter** → Un Trip est créé en statut `DRAFT` avec les données IA pré-remplies.
   - **Relancer** → Nouvelle suggestion avec les mêmes préférences ou des ajustements.
   - **Abandonner** → Retour à l'accueil.

**Alternative — Tunnel Direct :**
L'utilisateur crée un Trip manuellement (destination, dates, budget) sans passer par l'IA. Le Trip est créé directement en statut `DRAFT`.

**Acceptance Criteria :**
- [ ] AC-1.1 : Le questionnaire IA contient au minimum les 5 champs listés ci-dessus.
- [ ] AC-1.2 : La suggestion IA retourne une destination, une durée, un budget estimé et au moins 3 activités.
- [ ] AC-1.3 : L'acceptation d'une suggestion crée un Trip `DRAFT` avec `origin = AI` et les champs pré-remplis.
- [ ] AC-1.4 : Le tunnel direct crée un Trip `DRAFT` avec `origin = MANUAL` sans appel IA.
- [ ] AC-1.5 : L'utilisateur peut relancer la génération IA sans limite (soumis au quota Free/Premium).

---

### Phase 2 — Planification

**Objectif :** Construire le voyage complet. L'utilisateur enrichit son Trip `DRAFT` avec tous les éléments nécessaires.

#### 2a. Gestion du Planning (Activités)

- L'owner ajoute/modifie/supprime des activités jour par jour.
- Chaque activité a un jour, un créneau horaire optionnel, une catégorie et un coût estimé.
- L'IA peut suggérer des activités sur demande (basé sur la destination et les préférences).

**Acceptance Criteria :**
- [ ] AC-2a.1 : L'owner peut créer une activité avec au minimum un titre et une date.
- [ ] AC-2a.2 : Les activités sont affichées groupées par jour, triées par `start_time`.
- [ ] AC-2a.3 : L'owner peut modifier et supprimer toute activité tant que le trip n'est pas `COMPLETED`.
- [ ] AC-2a.4 : L'IA peut générer des suggestions d'activités pour une date donnée.

#### 2b. Réservation de Vols

- Recherche de vols via **Amadeus** (aller, retour, ou aller-retour).
- Sélection d'un vol → Paiement via **Stripe**.
- Après paiement confirmé : le Flight est créé avec `status = CONFIRMED`, le billet numérique est stocké, un BudgetItem `FLIGHT` est automatiquement créé.

**Acceptance Criteria :**
- [ ] AC-2b.1 : La recherche retourne des vols avec prix, horaires et compagnies.
- [ ] AC-2b.2 : Le paiement Stripe génère un `payment_id` associé au Flight.
- [ ] AC-2b.3 : Le billet numérique est accessible via `ticket_url` après confirmation.
- [ ] AC-2b.4 : Un BudgetItem de catégorie `FLIGHT` est créé automatiquement au montant du vol.
- [ ] AC-2b.5 : Un vol confirmé ne peut pas être modifié (seulement annulé si supporté).

#### 2c. Hébergements

- L'owner ajoute manuellement ses hébergements (nom, adresse, dates, prix/nuit).
- Pas de réservation in-app pour les hébergements (hors scope V4).

**Acceptance Criteria :**
- [ ] AC-2c.1 : L'owner peut ajouter un hébergement avec nom, check-in et check-out.
- [ ] AC-2c.2 : Un BudgetItem `ACCOMMODATION` est automatiquement créé à l'ajout (prix/nuit × nombre de nuits).

#### 2d. Budget

- L'owner définit un `budget_total` sur le Trip.
- Il peut ajouter des dépenses prévues (`is_planned = true`) et les transformer en dépenses réelles.
- Vue synthétique : budget total, budget consommé, budget restant, répartition par catégorie.

**Acceptance Criteria :**
- [ ] AC-2d.1 : Le budget consommé = somme de tous les BudgetItems du trip.
- [ ] AC-2d.2 : Une alerte visuelle s'affiche à 80% du budget.
- [ ] AC-2d.3 : Une alerte de dépassement s'affiche quand le budget est dépassé.
- [ ] AC-2d.4 : Les BudgetItems créés automatiquement (vols, hébergements) sont inclus dans le calcul.

#### 2e. Bagages

- Check-list de bagages.
- L'owner ajoute des objets, les catégorise et les coche comme "packed".
- L'IA peut suggérer une liste de base en fonction de la destination et de la durée.

**Acceptance Criteria :**
- [ ] AC-2e.1 : L'owner peut ajouter un item avec nom, quantité et catégorie.
- [ ] AC-2e.2 : L'owner peut cocher/décocher un item (`is_packed`).
- [ ] AC-2e.3 : L'IA peut générer une suggestion de liste de bagages pour le trip.

#### 2f. Partage View-Only

- L'owner peut inviter des utilisateurs existants en tant que `VIEWER`.
- Le partage est possible dès le statut `DRAFT`.
- Le viewer accède au trip en lecture seule (cf. règles TripShare §2.7).

**Acceptance Criteria :**
- [ ] AC-2f.1 : L'owner peut inviter un utilisateur par son identifiant (email ou user ID).
- [ ] AC-2f.2 : Le viewer voit le planning, les activités, les hébergements et les horaires de vol.
- [ ] AC-2f.3 : Le viewer ne voit pas le détail des prix (vols, budget items) — uniquement le budget global et le % consommé.
- [ ] AC-2f.4 : Le viewer ne peut effectuer aucune action de modification.
- [ ] AC-2f.5 : L'owner peut révoquer un partage à tout moment.

#### 2g. Passage en PLANNED

- L'owner marque le trip comme "prêt" → transition `DRAFT → PLANNED`.
- Le système vérifie les conditions minimales (destination + dates).

**Acceptance Criteria :**
- [ ] AC-2g.1 : La transition échoue si `destination`, `start_date` ou `end_date` est manquant.
- [ ] AC-2g.2 : Le trip `PLANNED` reste modifiable par l'owner (ajout/modif d'activités, bagages, budget, hébergements).

---

### Phase 3 — Voyage en Cours

**Objectif :** Accompagner l'owner et les viewers pendant le voyage avec des notifications aux moments clefs.

**Déclenchement :** Transition automatique `PLANNED → ONGOING` quand `start_date` est atteinte (job planifié quotidien à 00:00 UTC).

#### 3a. Notifications

Tous les utilisateurs du trip (owner + viewers) reçoivent les notifications.

**Matrice de notifications :**

| Moment               | Déclencheur                                  | Contenu                                           | Destinataires     |
| -------------------- | -------------------------------------------- | ------------------------------------------------- | ----------------- |
| J-1 avant départ     | `start_date - 1 jour`, 09:00 local          | Rappel préparation + statut check-list bagages     | Owner + Viewers   |
| H-4 avant vol        | `flight.departure_at - 4h`                   | Alerte départ vol + lien billet numérique          | Owner + Viewers   |
| H-1 avant vol        | `flight.departure_at - 1h`                   | Rappel imminent + infos porte (si dispo)           | Owner + Viewers   |
| Chaque matin         | 08:00 heure locale, chaque jour du trip      | Résumé des activités du jour                       | Owner + Viewers   |
| H-1 avant activité   | `activity.start_time - 1h` (si horaire défini)| Rappel activité + lieu                            | Owner + Viewers   |
| Alerte budget        | À chaque ajout de BudgetItem si seuil atteint | Notification 80% ou dépassement                   | Owner uniquement  |
| Fin de voyage        | `end_date` atteinte                           | Résumé du voyage + invitation feedback             | Owner + Viewers   |

#### 3b. Modifications pendant le voyage

- L'**owner** peut modifier le trip pendant le voyage : ajouter/modifier des activités, mettre à jour les hébergements, ajouter des dépenses, cocher des bagages.
- **Exception :** Les vols `CONFIRMED` ne sont **pas modifiables**.
- Les viewers restent en **lecture seule**.
- Les modifications nécessitent une **connexion internet** (pas de modification offline).

**Acceptance Criteria :**
- [ ] AC-3.1 : La transition `PLANNED → ONGOING` se fait automatiquement à `start_date`.
- [ ] AC-3.2 : Les notifications J-1, H-4, H-1 vol, matin, et H-1 activité sont envoyées aux horaires définis.
- [ ] AC-3.3 : Les notifications sont reçues par tous les users du trip (owner + viewers).
- [ ] AC-3.4 : L'owner peut ajouter/modifier/supprimer des activités pendant le voyage.
- [ ] AC-3.5 : L'owner peut ajouter des BudgetItems pendant le voyage.
- [ ] AC-3.6 : Un vol `CONFIRMED` ne peut être ni modifié ni supprimé pendant le voyage.
- [ ] AC-3.7 : Toute modification requiert une connexion internet active.
- [ ] AC-3.8 : L'alerte budget est envoyée uniquement à l'owner.

---

### Phase 4 — Post-Voyage

**Objectif :** Clôturer le voyage, collecter les retours et alimenter les futures suggestions IA.

**Déclenchement :** Transition automatique `ONGOING → COMPLETED` quand `end_date` est dépassée (job planifié quotidien), ou clôture manuelle par l'owner.

#### 4a. Feedback

- À la clôture, l'owner ET les viewers sont invités à laisser un feedback.
- Le feedback est structuré : note globale (1-5), points positifs, points négatifs, recommandation.
- **Un seul feedback par utilisateur par trip.**
- Les feedbacks sont **persistés en base** et associés au trip et à l'utilisateur.

#### 4b. Suggestions IA post-voyage

- Après soumission d'un feedback, l'IA peut proposer un nouveau voyage basé sur :
  - Les préférences historiques de l'utilisateur (feedbacks précédents).
  - Les highlights/lowlights du voyage terminé.
- La suggestion suit le même format que la Phase 1 (destination, durée, budget, activités).

**Acceptance Criteria :**
- [ ] AC-4.1 : La transition `ONGOING → COMPLETED` se fait automatiquement à `end_date + 1 jour`.
- [ ] AC-4.2 : L'owner peut clôturer manuellement un trip `ONGOING`.
- [ ] AC-4.3 : Une notification de fin de voyage invite owner + viewers à laisser un feedback.
- [ ] AC-4.4 : Le feedback est créé en base avec `trip_id`, `user_id`, `overall_rating`, `highlights`, `lowlights`, `would_recommend`.
- [ ] AC-4.5 : Un user ne peut soumettre qu'un seul feedback par trip (contrainte d'unicité `trip_id + user_id`).
- [ ] AC-4.6 : Un trip `COMPLETED` ne peut plus être modifié (lecture seule totale).
- [ ] AC-4.7 : L'IA peut générer une suggestion post-voyage basée sur l'historique des feedbacks de l'utilisateur.

---

## 4. Règles Transverses

### 4.1 Gestion des Documents

- L'application ne gère **pas** l'upload de documents externes.
- Seuls les documents générés par les réservations **intra-app** sont stockés (billets de vol Amadeus).
- Les documents sont accessibles via l'entité Flight (`ticket_url`).

### 4.2 Connectivité & Synchronisation

- Toute **modification** (création, update, suppression) nécessite une connexion internet.
- La **consultation** en mode hors-ligne est réservée aux utilisateurs Premium (données synchronisées localement avant le départ).

### 4.3 Droits & Permissions

| Action                     | Owner | Viewer |
| -------------------------- | ----- | ------ |
| Créer / modifier le trip    | ✅    | ❌     |
| Ajouter des activités       | ✅    | ❌     |
| Réserver un vol             | ✅    | ❌     |
| Gérer le budget             | ✅    | ❌     |
| Gérer les bagages           | ✅    | ❌     |
| Inviter / révoquer viewers  | ✅    | ❌     |
| Consulter le trip           | ✅    | ✅     |
| Recevoir les notifications  | ✅    | ✅     |
| Laisser un feedback         | ✅    | ✅     |

### 4.4 Suppression

- Un trip `DRAFT` peut être supprimé par l'owner. Les entités liées (activités, bagages, budget items, hébergements, partages) sont supprimées en cascade.
- Un trip `PLANNED`, `ONGOING` ou `COMPLETED` ne peut **pas** être supprimé (archivage uniquement, hors scope V4).
- Un vol `CONFIRMED` avec paiement Stripe ne peut pas être supprimé sans annulation préalable.

---

## 5. Segmentation Free / Premium

> Cette section est une **annexe commerciale**. Elle ne modifie pas les règles fonctionnelles ci-dessus mais restreint l'accès à certaines fonctionnalités.

| Fonctionnalité                  | Free                | Premium             |
| ------------------------------- | ------------------- | ------------------- |
| Création de trip (tunnel direct)| ✅ Illimitée        | ✅ Illimitée        |
| Génération IA (inspiration)     | 3 générations / mois | Illimitée          |
| Réservation de vols             | ✅                  | ✅                  |
| Partage view-only               | 2 viewers max / trip | 10 viewers max / trip |
| Notifications                   | Push (connexion requise) | Push + locales (hors-ligne) |
| Mode hors-ligne                 | ❌                  | ✅ Sync avant départ |
| Suggestions IA post-voyage      | ❌                  | ✅                  |

---

## 6. Hors Scope (V4)

Les éléments suivants sont explicitement **exclus** de cette version :

- Réservation d'hébergements in-app.
- Réservation d'activités in-app.
- Upload de documents externes (passeports, assurances, etc.).
- Chat ou messagerie entre owner et viewers.
- Rôle `EDITOR` (modification collaborative).
- Multi-devises (un seul référentiel monétaire par trip).
- Intégration calendrier externe (Google Calendar, Apple Calendar).
- Modification de vols réservés (seule l'annulation est envisagée, si API Amadeus le supporte).
