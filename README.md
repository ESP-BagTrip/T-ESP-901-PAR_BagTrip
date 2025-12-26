# Bag_Trip
Student Project

## 🚀 Quick Start

### Prerequisites (Manual Installation Required)

Before running `make init`, ensure you have the following installed:

1. **Node.js and npm** - [Install Node.js](https://nodejs.org/)
2. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
3. **Docker and Docker Compose** - [Install Docker](https://docs.docker.com/get-docker/)

> **Note:** Python 3.14+ will be automatically installed via `uv` if not present.

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Bag_Trip
   ```

2. **Initialize the project (recommended):**
   ```bash
   make init
   make init
   ```

   This will automatically:
   - Install `uv` (Python package manager)
   - Install Python 3.14+ if needed
   - Install all project dependencies (API, Admin Panel, Mobile App)
   - Set up pre-commit hooks
   - Configure linters and formatters
   - Create `.env` file from `.env.example`

3. **Configure environment variables:**

   Edit `.env` file and fill in the required API keys:
   - `AMADEUS_CLIENT_ID`
   - `AMADEUS_CLIENT_SECRET`
   - `GOOGLE_API_KEY`
   - Other configuration values as needed

4. **Start the database:**
   ```bash
   make db
   ```

## 🛠️ Development

### Pre-commit Hooks

The project uses pre-commit hooks that automatically run on every commit:

- ✅ **Large file check** - Prevents files >500KB from being committed
- ✅ **Code formatting** - Runs Prettier on both API and Admin Panel
- ✅ **Code linting** - Runs ESLint on both packages with auto-fix

### Available Commands

```bash
# View all available make targets
make help

# Install only pre-commit hooks
make install-pre-commit

# Install only dependencies
make install-deps

# Complete initialization
make init
```

## 🏗️ Project Structure

```
Bag_Trip/
├── api/                 # Backend API (Node.js + Express + Prisma)
├── admin-panel/         # Frontend (React + TypeScript + Vite)
├── compose.yml          # Docker Compose configuration
├── .pre-commit-config.yaml  # Pre-commit hooks configuration
└── Makefile            # Development automation
```

## 🐳 Docker Development

Start the development environment:

```bash
docker-compose up
```

This will start:
- PostgreSQL database on port 5432
- API server on port 3000
- Admin Panel on port 5173

## 📝 Code Quality

- **ESLint**: Code linting with auto-fix
- **Prettier**: Code formatting
- **Pre-commit**: Automated quality checks before commit
- **TypeScript**: Type safety for both API and Admin Panel
