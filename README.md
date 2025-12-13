# Bag_Trip
Student Project

## 🚀 Quick Start

### Prerequisites (Manual Installation Required)

Before running `make install`, ensure you have the following installed:

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

2. **Run the automatic installation:**
   ```bash
   make install
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

## 🛠️ Available Commands

### Global Commands

```bash
make help          # Show all available commands
make install       # Install all dependencies and set up development environment
make db            # Start PostgreSQL database container
make api           # Start the Python API (FastAPI)
make ai-studio     # Start the AI Studio (LangGraph)
make admin         # Start the Admin Panel (Next.js)
make mobile        # Start the Mobile App (Flutter)
```

## 🏗️ Project Structure

```
Bag_Trip/
├── api/                    # Backend API (Python + FastAPI)
├── admin-panel/            # Frontend Admin Panel (Next.js + TypeScript)
├── bagtrip/               # Mobile App (Flutter)
├── scripts/                # Setup scripts
├── compose.yml             # Docker Compose configuration
├── .pre-commit-config.yaml # Pre-commit hooks configuration
└── Makefile                # Development automation
```

## 📝 Code Quality

The project uses automated code quality tools:

- **Ruff**: Python linting and formatting
- **ESLint + Prettier**: JavaScript/TypeScript linting and formatting
- **Dart/Flutter Lints**: Dart code analysis
- **Pre-commit**: Automated quality checks before commit

All tools are automatically configured during `make install`.
