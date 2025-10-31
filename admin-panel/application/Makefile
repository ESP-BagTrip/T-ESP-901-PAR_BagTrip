# BagTrip Admin - Makefile
# Commandes utiles pour le développement

.PHONY: help install dev build start lint lint-fix type-check format format-check check-all test-e2e test-e2e-open cypress-open cypress-run clean

# Variables
NODE_VERSION := $(shell node --version 2>/dev/null || echo "non installé")
NPM_VERSION := $(shell npm --version 2>/dev/null || echo "non installé")

# Commandes d'aide
help: ## Affiche l'aide
	@echo "BagTrip Admin - Commandes disponibles:"
	@echo ""
	@echo "🔧 ENVIRONNEMENT:"
	@echo "  Node.js: $(NODE_VERSION)"
	@echo "  npm: $(NPM_VERSION)"
	@echo ""
	@echo "📦 INSTALLATION & SETUP:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(install|init|setup)"
	@echo ""
	@echo "🚀 DÉVELOPPEMENT:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(dev|build|start)"
	@echo ""
	@echo "✅ QUALITÉ DE CODE:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(lint|type|format|check)"
	@echo ""
	@echo "🧪 TESTS:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(test|cypress)"
	@echo ""
	@echo "🛠️ UTILITAIRES:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(clean|logs)"

# Installation et setup
install: ## Installe les dépendances npm
	@echo "📦 Installation des dépendances..."
	npm install

init: install ## Initialise le projet (install + setup)
	@echo "🎯 Initialisation du projet..."
	@echo "✅ Copie du fichier d'environnement..."
	@if [ ! -f .env.local ]; then cp .env.example .env.local && echo "📝 Configurez vos variables dans .env.local"; else echo "⚠️  .env.local existe déjà"; fi
	@echo "✅ Projet initialisé avec succès!"

# Développement
dev: ## Lance le serveur de développement
	@echo "🚀 Lancement du serveur de développement..."
	npm run dev

build: ## Construit l'application pour la production
	@echo "🏗️  Construction de l'application..."
	npm run build

start: ## Démarre l'application en mode production
	@echo "▶️  Démarrage de l'application..."
	npm run start

# Qualité de code
lint: ## Vérifie la qualité du code avec ESLint
	@echo "🔍 Vérification ESLint..."
	npm run lint

lint-fix: ## Corrige automatiquement les erreurs ESLint
	@echo "🔧 Correction automatique ESLint..."
	npm run lint:fix

type-check: ## Vérifie les types TypeScript
	@echo "🎯 Vérification des types TypeScript..."
	npm run type-check

format: ## Formate le code avec Prettier
	@echo "💅 Formatage du code avec Prettier..."
	npm run format

format-check: ## Vérifie le formatage du code
	@echo "👀 Vérification du formatage..."
	npm run format:check

check-all: ## Lance tous les contrôles qualité (types + lint + format)
	@echo "🔍 Lancement de tous les contrôles qualité..."
	npm run check-all

# Tests
test-e2e: ## Lance les tests E2E Cypress en mode headless
	@echo "🧪 Lancement des tests E2E..."
	npm run test:e2e

test-e2e-open: ## Lance les tests E2E avec interface graphique
	@echo "🧪 Ouverture des tests E2E..."
	npm run test:e2e:open

cypress-open: ## Ouvre l'interface Cypress
	@echo "🎯 Ouverture de Cypress..."
	npm run cypress:open

cypress-run: ## Lance Cypress en mode headless
	@echo "🏃 Lancement de Cypress..."
	npm run cypress:run

# Utilitaires
clean: ## Nettoie les fichiers temporaires et node_modules
	@echo "🧹 Nettoyage des fichiers temporaires..."
	rm -rf node_modules
	rm -rf .next
	rm -rf dist
	rm -rf coverage
	rm -rf cypress/screenshots
	rm -rf cypress/videos
	@echo "✅ Nettoyage terminé!"

logs: ## Affiche les logs de l'application
	@echo "📋 Logs de l'application:"
	@if [ -f .next/server/server.log ]; then tail -f .next/server/server.log; else echo "Aucun log trouvé"; fi

# Commandes de développement avancées
dev-https: ## Lance le serveur en HTTPS (dev)
	@echo "🔒 Lancement en HTTPS..."
	npm run dev -- --experimental-https

analyze: ## Analyse le bundle de l'application
	@echo "📊 Analyse du bundle..."
	ANALYZE=true npm run build

# CI/CD helpers
ci-install: ## Installation pour CI/CD (cache optimisé)
	@echo "⚡ Installation CI/CD..."
	npm ci

ci-test: check-all test-e2e ## Lance tous les tests pour CI/CD
	@echo "✅ Tous les tests CI/CD passés!"

# Commandes Git helpers
git-hooks: ## Configure les hooks Git
	@echo "🪝 Configuration des hooks Git..."
	@if [ -d .git ]; then \
		echo "#!/bin/sh\nmake check-all" > .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "✅ Hook pre-commit configuré"; \
	else \
		echo "❌ Pas un dépôt Git"; \
	fi

# Status du projet
status: ## Affiche le statut du projet
	@echo "📊 Statut du projet BagTrip Admin:"
	@echo ""
	@echo "📁 Fichiers importants:"
	@ls -la package.json tsconfig.json next.config.ts 2>/dev/null || true
	@echo ""
	@echo "🔧 Environnement:"
	@echo "  Node.js: $(NODE_VERSION)"
	@echo "  npm: $(NPM_VERSION)"
	@echo "  TypeScript: $(shell npx tsc --version 2>/dev/null || echo "non installé")"
	@echo ""
	@echo "📦 Dépendances:"
	@echo "  Installées: $(shell [ -d node_modules ] && echo "✅" || echo "❌")"
	@echo "  .env.local: $(shell [ -f .env.local ] && echo "✅" || echo "❌")"
	@echo ""

# Commande par défaut
.DEFAULT_GOAL := help