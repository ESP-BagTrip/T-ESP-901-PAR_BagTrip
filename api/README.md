# API Python BagTrip

API Python migrée depuis TypeScript/Node.js, conservant les logiques Amadeus et la connexion à PostgreSQL.

## Installation

### Prérequis

- Python 3.14+
- uv (gestionnaire de packages Python)
- PostgreSQL

### Configuration

1. Installer les dépendances avec uv:

```bash
uv sync
```

2. Créer un fichier `.env` à partir de `.env.example`:

```bash
cp .env.example .env
```

3. Configurer les variables d'environnement dans `.env`:

```env
NODE_ENV=development
PORT=3000
REQUEST_TIMEOUT_MS=3000

DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres

AMADEUS_CLIENT_ID=your-amadeus-client-id
AMADEUS_CLIENT_SECRET=your-amadeus-client-secret
AMADEUS_BASE_URL=https://test.api.amadeus.com

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

## Utilisation

### Démarrer l'API

```bash
uv run python -m src.main
```

Ou avec uvicorn directement:

```bash
uv run uvicorn src.main:app --host 0.0.0.0 --port 3000 --reload
```

### Documentation API

Une fois l'API démarrée, la documentation Swagger est disponible à:

- Swagger UI: http://localhost:3000/docs
- ReDoc: http://localhost:3000/redoc

## Structure du projet

```
api-python/
├── src/
│   ├── main.py                 # Point d'entrée FastAPI
│   ├── config/
│   │   ├── env.py              # Configuration environnement
│   │   └── database.py         # Configuration SQLAlchemy
│   ├── integrations/
│   │   └── amadeus/            # Intégration Amadeus
│   │       ├── auth.py         # Authentification OAuth2
│   │       ├── client.py       # Client unifié
│   │       ├── locations.py    # Recherche locations
│   │       ├── flights.py      # Recherche vols
│   │       └── types.py        # Types Pydantic
│   ├── models/
│   │   └── user.py             # Modèle User SQLAlchemy
│   ├── api/
│   │   ├── auth/               # Routes authentification
│   │   └── travel/             # Routes travel
│   └── utils/
│       ├── logger.py           # Logger
│       └── errors.py           # Gestion erreurs
└── pyproject.toml              # Configuration uv
```

## Endpoints

### Authentification

- `POST /api/auth/signup` - Inscription
- `POST /api/auth/login` - Connexion
- `GET /api/auth/me` - Informations utilisateur (protégé)

### Travel

- `GET /api/travel/locations` - Recherche locations par mot-clé
- `GET /api/travel/locations/{id}` - Recherche location par ID
- `GET /api/travel/locations/nearest` - Recherche locations proches
- `GET /api/travel/flight/offers` - Recherche offres de vols
- `GET /api/travel/flight/destinations` - Recherche destinations inspirantes
- `GET /api/travel/flight/cheapest-dates` - Recherche dates les moins chères

## Base de données

Les tables sont créées automatiquement au démarrage de l'application via SQLAlchemy.

Pour créer manuellement la table User:

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR UNIQUE NOT NULL,
    password VARCHAR NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Technologies utilisées

- **FastAPI** - Framework web moderne et rapide
- **SQLAlchemy** - ORM pour PostgreSQL
- **Pydantic** - Validation de données
- **httpx** - Client HTTP async
- **python-jose** - JWT
- **bcrypt** - Hashage de mots de passe
- **uv** - Gestionnaire de packages

