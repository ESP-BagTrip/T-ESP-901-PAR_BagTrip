# Partage et Travelers

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le module sharing couvre deux primitives distinctes mais liees au meme trip :

- **Shares** — invitation d'un autre utilisateur BagTrip a voir ou editer un voyage, avec roles `OWNER` / `EDITOR` / `VIEWER`, invitation differee via token quand l'invite n'est pas encore inscrit, et quota par plan (`viewers_per_trip`).
- **Travelers** — passagers physiques rattaches au voyage (identite, date de naissance, documents, contact). Sert au booking de vol Amadeus (payload `traveler.raw`) et a la repartition du budget. N'est pas une autorisation : un traveler n'a aucun compte BagTrip lie.

Cote API, l'autorisation passe par la dependency `TripAccess` qui resout `OWNER` / `EDITOR` / `VIEWER` a chaque requete. Cote mobile, le `TripDetailState` expose `isOwner` / `isEditor` / `isViewer` / `canEdit` que toutes les UI consomment pour conditionner CTA, swipe actions, formulaires et redaction visuelle.

---

## Cote Backend

### Modeles

| Modele | Fichier | Role |
|---|---|---|
| `TripShare` | `api/src/models/trip_share.py` | Lien `(trip_id, user_id, role)` actif. Unique `(trip_id, user_id)`. Role par defaut `VIEWER`. |
| `PendingInvite` | `api/src/models/pending_invite.py` | Invitation par email pour un utilisateur non inscrit. Champs `token`, `role`, `message`, `invited_by`, `expires_at` (7 jours). Unique `(trip_id, email)`. |
| `TripTraveler` | `api/src/models/traveler.py` | Passager du voyage. `amadeus_traveler_ref`, `traveler_type` (ADULT/CHILD), identite, `documents` JSON, `contacts` JSON, `raw` JSON (payload Amadeus complet). |

Enum `ShareRole` (`api/src/enums.py`) : `VIEWER`, `EDITOR`. Le role `OWNER` n'est pas stocke dans `TripShare` — il est deduit par `Trip.user_id`.

### Endpoints shares (`api/src/api/shares/routes.py`)

Prefix `/v1/trips/{tripId}/shares`. Toutes les routes sauf `GET` exigent `get_trip_owner_access`.

| Methode | Path | Acces | Comportement |
|---|---|---|---|
| `POST` | `/{tripId}/shares` | OWNER | Body `{ email, role?, message? }`. Cree un `TripShare` si l'email est connu, sinon un `PendingInvite` avec token. Retourne 201 + `{ status: "active" \| "pending", inviteToken? }`. |
| `GET` | `/{tripId}/shares` | OWNER + EDITOR + VIEWER | Liste `items` (shares actifs avec `userEmail`/`userFullName`) + `pendingInvites` (uniquement si OWNER). |
| `DELETE` | `/{tripId}/shares/{shareId}` | OWNER | Revoque un share existant. 204. |
| `DELETE` | `/{tripId}/pending-invites/{inviteId}` | OWNER | Annule une invitation en attente. 204. |

### Endpoint invites (`api/src/api/invites/routes.py`)

| Methode | Path | Acces | Comportement |
|---|---|---|---|
| `POST` | `/v1/invites/{token}/accept` | Authentifie | Resoud le `PendingInvite` par token, verifie non expiration, cree le `TripShare` correspondant et supprime l'invite. Retourne le `ShareResponse`. |

### Endpoints travelers (`api/src/api/travelers/routes.py`)

Prefix `/v1/trips/{tripId}/travelers`. Toutes les ecritures passent par `get_trip_editor_access` (OWNER ou EDITOR).

| Methode | Path | Acces | Comportement |
|---|---|---|---|
| `POST` | `/{tripId}/travelers` | OWNER + EDITOR | Cree un traveler. 201. |
| `GET` | `/{tripId}/travelers` | OWNER + EDITOR + VIEWER | Liste des travelers. |
| `PATCH` | `/{tripId}/travelers/{travelerId}` | OWNER + EDITOR | Mise a jour partielle. |
| `DELETE` | `/{tripId}/travelers/{travelerId}` | OWNER + EDITOR | Suppression. 204. |

`TravelersService.traveler_to_amadeus_payload()` mappe vers le format Amadeus (split country calling code, documents avec `validityCountry`, payload stocke dans `traveler.raw`). Sert au booking de vol.

### Service `TripShareService` (`api/src/services/trip_share_service.py`)

Flux `create_share(db, trip_id, owner_user_id, email, message?, role)` :

1. `_check_trip_not_completed` — refuse si trip `COMPLETED` (403 `TRIP_COMPLETED`).
2. Resolution user par email :
   - **User existe** : refuse self-share (`SELF_SHARING` 400), refuse doublon (`ALREADY_SHARED` 409), verifie quota plan (`SHARE_QUOTA_EXCEEDED` 402), insere `TripShare`, envoie notification localisee `TRIP_SHARED` (clef `TRIP_SHARED_WITH_MESSAGE` si message) avec deep-link `tripHome`.
   - **User n'existe pas** : refuse self-share par email, refuse pending duplique, verifie quota cumule (shares + pending), genere un token UUID4, insere `PendingInvite` avec `expires_at = now + 7d`.

Autres methodes :

- `get_shares_by_trip` — join `TripShare` x `User` pour exposer `user_email`/`user_full_name`.
- `get_pending_invites_by_trip` — filtre `expires_at > now`.
- `delete_share` / `delete_pending_invite` — verifient trip non completed + existence.
- `accept_invite(token, user_id)` — resoud le pending, verifie expiration (410 `INVITE_EXPIRED`), refuse doublon, cree le share et supprime l'invite.
- `claim_pending_invites(email, user_id)` — appele par `UserCreationService` a l'inscription : transforme automatiquement tous les `PendingInvite` non expires correspondant a l'email en `TripShare`.

### Guard `TripAccess` (`api/src/api/auth/trip_access.py`)

Resolution en trois etapes :

```
1. trip.user_id == current_user.id  -> TripRole.OWNER
2. TripShare(trip_id, user_id) existe -> TripRole(share.role)  # VIEWER ou EDITOR
3. Sinon -> AppError("TRIP_NOT_FOUND", 404)  # ne pas leaker l'existence
```

Trois dependencies exposees :

| Dependency | Roles autorises | Usage |
|---|---|---|
| `get_trip_access` | OWNER + EDITOR + VIEWER | Lectures (GET) |
| `get_trip_editor_access` | OWNER + EDITOR | Mutations partagees (activites, vols, hebergements, bagages, budget, travelers) |
| `get_trip_owner_access` | OWNER seul | Operations sensibles (shares CRUD, delete trip) |

Toutes les routes mutations passent par ces dependencies, jamais de check inline `trip.user_id == user_id`.

### Plan limits (`api/src/config/plans.py`)

`PlanService.get_share_limit(user)` lit `PLAN_LIMITS[plan]["viewers_per_trip"]`. Le compteur inclut `TripShare` actifs + `PendingInvite` non expires (`_check_quota`). Depasse -> `SHARE_QUOTA_EXCEEDED` (402, paywall cote mobile).

---

## Cote Mobile

### `TripDetailBloc` — source de verite des roles

L'etat `TripDetailLoaded` (`bagtrip/lib/trip_detail/bloc/trip_detail_state.dart`) expose :

```dart
bool get isOwner  => userRole == 'OWNER';
bool get isEditor => userRole == 'EDITOR';
bool get isViewer => userRole == 'VIEWER';
bool get canEdit  => (isOwner || isEditor) && !isCompleted;
```

`canEdit` est passe a chaque panneau (`activities`, `flights`, `accommodations`, `baggage`, `budget`, `shares`) pour conditionner les CTA, swipe actions, formulaires d'edition, FAB et bottom sheets. Un trip `COMPLETED` retombe en read-only meme pour l'owner.

### Panneau Shares (`bagtrip/lib/trip_detail/view/panels/shares_panel.dart`)

Visible uniquement pour OWNER. Couvre :

- Empty state `TripPanelEmptyState` avec CTA `emptySharesAddNow`.
- Bouton `panelInviteCollaborator` en tete de liste.
- Liste des shares avec avatar (initiales email), nom/email, chip role en pill.
- Swipe-to-revoke (`Dismissible` endToStart) + context menu adaptatif `shareRevokeAccess`.
- Tap row -> `QuickPreviewSheet` avec actions `shareCopyLink` (primary) et `shareRevokeAccess` (destructive).

L'invitation passe par `showItemFormSheet` + `ShareInviteSheet` (`bagtrip/lib/trips/widgets/share_invite_sheet.dart`) :

- Champ email valide par regex.
- `PillSegmentedControl` Viewer / Editor.
- Champ message optionnel.
- Submit -> `CreateShareFromDetail(email, role, message)` dispatche sur le `TripDetailBloc`.

### `TripShareBloc` legacy (`bagtrip/lib/trips/bloc/trip_share_bloc.dart`)

Reste utilise par les flows hors trip-detail (ex: ecrans dedies). Trois events :

| Event | Action |
|---|---|
| `LoadShares` | Charge la liste via `TripShareRepository.getSharesByTrip` |
| `CreateShare` | Invite via `createShare(email, role, message)`. Si `status == 'pending'`, emet `TripShareInvitePending(inviteToken)` -> copie automatique dans le presse-papier. Sur `QuotaExceededError`, emet `TripShareQuotaExceeded` -> ouverture `PremiumPaywall`. |
| `DeleteShare` | Revoque + reload |

### Repository (`bagtrip/lib/repositories/trip_share_repository.dart`)

Interface minimale, implementee dans `lib/service/`. Retourne `Future<Result<T>>`, pattern matching obligatoire cote bloc, mapping `DioException` -> `AppError` (`NotFoundError`, `ValidationError`, `QuotaExceededError`) par l'`ApiClient`.

### Mode viewer — restrictions UI

Quand `state.isViewer == true` :

- Aucun FAB, aucun bouton add sur les panneaux.
- Tap sur un item n'expose que l'`QuickPreviewSheet` en mode lecture (pas de `Edit` / `Delete`).
- Le panneau `Shares` n'est pas accessible (tab cache, l'API renvoie 403 sur les mutations).
- Le panneau `Travelers` reste lisible (lecture autorisee) mais sans CTA add/edit/delete.
- Le bouton de suppression du trip est masque.
- La redaction cote API masque deja les prix vol/hebergement, references de booking, `total_spent` budget, `paymentId`. L'UI affiche un placeholder neutre.

---

## Roles et permissions

| Role | Lecture trip | Mutation contenu (activites, vols, hotels, bagages, budget, travelers) | Delete trip | Shares mgmt (invite / revoke) |
|---|---|---|---|---|
| OWNER | oui | oui | oui | oui |
| EDITOR | oui | oui | non | non |
| VIEWER | oui (avec redaction) | non | non | non |

Hors-trip : tout utilisateur authentifie peut appeler `POST /v1/invites/{token}/accept` pour reclamer une invitation. Les `PendingInvite` correspondant a son email sont aussi reclames automatiquement a l'inscription (`UserCreationService._claim_pending_invites`).

---

## Plan limits

`viewers_per_trip` borne le nombre total `TripShare` + `PendingInvite` non expires sur un meme trip.

| Plan | `viewers_per_trip` | `ai_generations_per_month` | `post_voyage_ai` |
|---|---|---|---|
| FREE | 2 | 3 | non |
| PREMIUM | 10 | illimite | oui |
| ADMIN | illimite | illimite | oui |

Depassement -> `AppError("SHARE_QUOTA_EXCEEDED", 402)` -> cote mobile, le bloc emet `TripShareQuotaExceeded` et la sheet d'invitation se ferme pour ouvrir `PremiumPaywall`.

---

## Flux

### Invite -> accept (user inscrit)

1. Owner ouvre `SharesPanel`, tap `panelInviteCollaborator`, saisit email + role.
2. `TripDetailBloc` dispatche `CreateShareFromDetail` -> `POST /v1/trips/{id}/shares`.
3. Service trouve l'user, cree `TripShare(role)`, envoie notification push localisee `TRIP_SHARED` avec `data.tripId` pour deep-link.
4. L'invite ouvre la notification -> deep-link `tripHome` -> `TripAccess` resoud `EDITOR` ou `VIEWER` -> trip visible dans la liste home.

### Invite -> accept (user non inscrit)

1. Meme POST, service ne trouve pas l'user -> cree `PendingInvite` avec token UUID4 + `expires_at = now + 7d`.
2. Reponse `{ status: "pending", inviteToken }` -> cote mobile, le token est copie dans le presse-papier et un snackbar affiche `shareInvitePendingMessage`.
3. **Variante A** : l'invite s'inscrit avec le meme email -> `UserCreationService._claim_pending_invites` convertit automatiquement tous les pending en `TripShare`.
4. **Variante B** : l'invite recoit le lien manuellement et appelle `POST /v1/invites/{token}/accept` -> service verifie expiration, cree le `TripShare`, supprime l'invite.

### Revoke

1. Owner swipe ou tap `shareRevokeAccess` sur un row.
2. `TripDetailBloc` dispatche `DeleteShareFromDetail(shareId)` -> `DELETE /v1/trips/{id}/shares/{shareId}`.
3. Service verifie trip non completed + existence, supprime le `TripShare`.
4. L'ex-invite perd l'acces : prochaine requete `TripAccess` -> 404. Aucune notification de revocation n'est envoyee.

### Travelers (booking vol)

1. Owner ou Editor ouvre le tab Travelers, ajoute un passager (identite + document + contact).
2. `POST /v1/trips/{id}/travelers` cree le `TripTraveler`.
3. Au moment du booking Amadeus, `TravelersService.traveler_to_amadeus_payload` reformate vers le schema Amadeus (split phone code, `validityCountry` fallback) et stocke le payload dans `traveler.raw`.

---

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Email transactionnel | Aucun email n'est envoye lors de la creation d'un `PendingInvite`. Seul le token est renvoye dans la reponse API et copie dans le presse-papier mobile. Pas de mail avec lien magique. | P1 |
| Notification de revocation | `delete_share` ne notifie pas l'ex-invite. La perte d'acces est silencieuse cote client (decouvert au prochain refresh). | P2 |
| Refus explicite d'invitation | Pas de flux `POST /v1/invites/{token}/decline`. L'invite peut ignorer mais pas refuser proprement, et l'owner ne sait pas si l'invitation a ete vue. | P2 |
| Audit log shares | Pas d'historique des invitations / revocations / changements de role. Utile pour le debug support et la conformite. | P2 |
| Modification de role apres invite | Une fois cree, le role d'un `TripShare` n'est pas modifiable via l'API (pas de `PATCH /shares/{id}`). Il faut revoke + reinviter. | P3 |
| Liaison traveler <-> user | Un `TripTraveler` est purement declaratif. Pas de lien optionnel vers un `User` BagTrip qui permettrait de pre-remplir les documents depuis le profil. | P3 |
| Vue dediee "Trips partages avec moi" | Cote mobile, pas de section distincte sur le home pour separer trips owned et trips ou je suis EDITOR/VIEWER. | P3 |
