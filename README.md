# Bag_Trip
Student Project

## 🚀 Quick Start

### For New Collaborators

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Bag_Trip
   ```

2. **Initialize the project (recommended):**
   ```bash
   make init
   ```
   
   This will:
   - Install pre-commit hooks
   - Install all project dependencies (API + Admin Panel)
   - Set up git hooks for code quality

### Manual Setup (Alternative)

If you prefer manual setup or the Makefile doesn't work:

1. **Install pre-commit:**
   ```bash
   # Option 1: Using pipx (recommended)
   pipx install pre-commit
   
   # Option 2: Using pip
   pip install pre-commit
   
   # Option 3: Using Homebrew (macOS)
   brew install pre-commit
   ```

2. **Install git hooks:**
   ```bash
   pre-commit install --install-hooks
   ```

3. **Install dependencies:**
   ```bash
   # API dependencies
   cd api && npm install
   
   # Admin Panel dependencies
   cd admin-panel && npm install
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
