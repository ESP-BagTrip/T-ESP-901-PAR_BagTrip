# Partage et Permissions

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La feature de partage permet au proprietaire d'un voyage d'inviter d'autres utilisateurs BagTrip a consulter son trip. Le systeme repose sur un modele OWNER/VIEWER avec invitation par email, notification push a l'invite, quotas de partage lies au plan de l'utilisateur et revocation. Les viewers ont un acces en lecture seule avec masquage des informations sensibles (prix, references de reservation).

---

## Architecture mobile (Flutter)

### BLoC

`TripShareBloc` (`bagtrip/lib/trips/bloc/trip_share_bloc.dart`) gere le CRUD des partages via `TripShareRepository`.

| Event | Action |
|-------|--------|
| `LoadShares` | Charge la liste des partages pour un trip |
| `CreateShare` | Invite un utilisateur par email (avec message optionnel). Gere le quota depasse via `TripShareQuotaExceeded` |
| `DeleteShare` | Revoque un partage existant |

### Etats

| State | Description |
|-------|-------------|
| `TripShareInitial` | Etat initial |
| `TripShareLoading` | Operation en cours |
| `TripShareLoaded` | Liste de `TripShare` disponible |
| `TripShareError` | Erreur avec `AppError` |
| `TripShareQuotaExceeded` | Quota de partage depasse (lie au plan) |

### Modele Freezed

`TripShare` (`bagtrip/lib/models/trip_share.dart`) :
- `id` (obligatoire)
- `tripId` (obligatoire)
- `userId` (obligatoire)
- `role` (defaut `'VIEWER'`)
- `invitedAt` (DateTime?)
- `userEmail` (obligatoire)
- `userFullName` (optionnel)

### Vues et pages

| Fichier | Role |
|---------|------|
| `bagtrip/lib/pages/trip_shares_page.dart` | Page de gestion des partages (cree le BlocProvider) |
| `bagtrip/lib/trips/view/trip_shares_view.dart` | UI de la liste des partages avec formulaire d'invitation |

### Flux d'invitation

1. L'owner ouvre la page de partage
2. Il saisit l'email de l'utilisateur a inviter + un message optionnel
3. L'event `CreateShare` est fire
4. En cas de succes, les shares sont recharges (`LoadShares`)
5. En cas de quota depasse, l'etat `TripShareQuotaExceeded` est emis

### Flux de revocation

1. L'owner voit la liste des partages avec email et nom
2. Il declenche `DeleteShare(tripId, shareId)`
3. Les shares sont recharges apres suppression

---

## Architecture backend (FastAPI)

### Endpoints partages

- `POST /v1/trips/{tripId}/shares` — Invite un utilisateur. Body : `email` (EmailStr, obligatoire), `message?` (String). Owner only. Retourne 201.

- `GET /v1/trips/{tripId}/shares` — Liste tous les partages du trip. Owner only. Retourne pour chaque share : id, tripId, userId, role, invitedAt, userEmail, userFullName.

- `DELETE /v1/trips/{tripId}/shares/{shareId}` — Revoque un partage. Owner only. Retourne 204.

### Service `TripShareService` (`api/src/services/trip_share_service.py`)

#### `create_share(db, trip_id, owner_user_id, email, message?)`

Flux complet de creation :

1. **Verification trip** : le trip ne doit pas etre au statut COMPLETED (`_check_trip_not_completed`)
2. **Resolution utilisateur** : recherche par email dans la table `users`. Erreur `USER_NOT_FOUND` (404) si l'email n'est pas enregistre
3. **Pas d'auto-partage** : erreur `SELF_SHARING` (400) si l'owner essaie de partager avec lui-meme
4. **Pas de doublon** : erreur `ALREADY_SHARED` (409) si un share existe deja pour ce user/trip
5. **Verification quota** : via `PlanService.get_share_limit(owner)`. Erreur `SHARE_QUOTA_EXCEEDED` (402) si la limite est atteinte
6. **Creation** : insertion d'un `TripShare` avec role `VIEWER` (seul role disponible)
7. **Notification push** : envoie une notification `TRIP_SHARED` a l'invite via `NotificationService.create_and_send()` avec :
   - Titre : "Nouveau voyage partage !"
   - Body : "{nom_owner} vous a invite a 'nom_du_trip'" ou avec le message personnalise
   - Data : `{screen: "tripHome", tripId: ...}` pour le deep-link

#### `get_shares_by_trip(db, trip_id)`

Jointure `TripShare` + `User` pour enrichir avec `user_email` et `user_full_name`.

#### `delete_share(db, share_id, trip_id)`

Verification que le trip n'est pas COMPLETED + existence du share, puis suppression.

### Modele SQLAlchemy

`TripShare` (`api/src/models/trip_share.py`) :
- `id` (UUID, PK, auto-genere)
- `trip_id` (UUID, FK vers trips, index)
- `user_id` (UUID, FK vers users, index)
- `role` (String, defaut "VIEWER")
- `invited_at` (DateTime with timezone, server_default now())
- Contrainte unique : `uq_trip_shares_trip_user` (trip_id, user_id)
- Relations : `trip` (backref `shares`), `user`

### Roles et permissions

Le systeme `TripAccess` (`api/src/api/auth/trip_access.py`) resout l'acces en deux etapes :

```
1. L'utilisateur est-il l'owner du trip ? → TripRole.OWNER
2. Existe-t-il un TripShare pour cet user ? → TripRole(share.role) (= VIEWER)
3. Sinon → 404 (pour ne pas reveler l'existence du trip)
```

Deux dependencies FastAPI :
- `get_trip_access` : accepte OWNER + VIEWER (routes en lecture)
- `get_trip_owner_access` : OWNER uniquement (routes en ecriture), renvoie 403 si VIEWER

### Matrice des permissions par feature

| Feature | Owner | Viewer |
|---------|-------|--------|
| Vols — recherche | Acces complet | Acces complet |
| Vols — offres/prix | Voir tout | Prix masques |
| Vols — orders | paymentId visible | paymentId masque |
| Vols — CRUD manuel | CRUD complet | Lecture seule |
| Hebergements — liste | Voir tout | pricePerNight, currency, bookingReference masques |
| Hebergements — CRUD | CRUD complet | Lecture seule |
| Bagages — liste | Voir tout | Voir tout |
| Bagages — CRUD | CRUD complet | Lecture seule |
| Bagages — IA suggest | Autorise | Non autorise |
| Budget — items | CRUD complet | Liste vide |
| Budget — summary | Complet | totalSpent=0, remaining=0, by_category={}, percentConsumed visible |
| Budget — detail item | Autorise | 403 Forbidden |
| Partages — CRUD | CRUD complet | Pas d'acces aux routes |
| Activites — CRUD | CRUD complet | Lecture seule |

### Enum des roles

```python
class ShareRole(StrEnum):
    VIEWER = "VIEWER"
```

Actuellement, seul le role `VIEWER` est defini. Il n'y a pas de role EDITOR ou COLLABORATOR.

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Role EDITOR/COLLABORATOR | Seul le role VIEWER existe. Pas de role intermediaire permettant d'editer certaines parties du trip (ex: ajouter des activites mais pas modifier le budget). L'enum `ShareRole` ne contient que `VIEWER`. (`api/src/enums.py:48-49`) | P1 |
| Invitation par lien | L'invitation ne fonctionne que par email d'un utilisateur deja enregistre. Pas de lien d'invitation generique (token + URL) pour inviter des non-inscrits. Erreur `USER_NOT_FOUND` si l'email n'est pas dans la base. (`api/src/services/trip_share_service.py:33-35`) | P1 |
| Notification de revocation | Quand un share est supprime (`delete_share`), l'utilisateur revoque ne recoit pas de notification. Seule l'invitation envoie une notification push. (`api/src/services/trip_share_service.py:120-133`) | P2 |
| Acceptation/refus d'invitation | Le partage est immediat — pas de flux d'acceptation/refus par l'invite. Le share est cree directement avec le role VIEWER. | P2 |
| Badge de role dans l'UI | Le modele `TripShare` contient un champ `role` mais il n'y a pas d'affichage de badge/chip dans l'UI Flutter pour distinguer visuellement le role. | P2 |
| Gestion des permissions granulaires | Le masquage des donnees est fait manuellement dans chaque route (ex: `if access.role == TripRole.VIEWER`). Pas de middleware centralise de filtrage par role. | P2 |
| Tests E2E partage | Des tests unitaires existent (`trip_share_bloc_test.dart`, `trip_share_repository_test.dart`, `trip_share_model_test.dart`) mais pas de test E2E couvrant le flux invitation -> acces viewer -> masquage donnees. | P2 |
| Listing des trips partages avec moi | Cote mobile, pas de vue dediee "Trips partages avec moi" distincte de "Mes trips". Les trips partages apparaissent dans la liste principale. | P2 |
