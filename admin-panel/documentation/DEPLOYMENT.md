# Guide de Déploiement - BagTrip Admin 🚀

Ce guide couvre tous les aspects du déploiement de l'application BagTrip Admin.

## 🎯 Environnements

### Développement (Local)
```bash
NODE_ENV=development
NEXT_PUBLIC_USE_MOCK_SERVICES=true
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

### Staging
```bash
NODE_ENV=production
NEXT_PUBLIC_USE_MOCK_SERVICES=false
NEXT_PUBLIC_API_URL=https://api-staging.bagtrip.com
```

### Production
```bash
NODE_ENV=production
NEXT_PUBLIC_USE_MOCK_SERVICES=false
NEXT_PUBLIC_API_URL=https://api.bagtrip.com
NEXT_PUBLIC_APP_URL=https://admin.bagtrip.com
```

## 📦 Build et optimisation

### Build local
```bash
# Build de production
make build

# Vérifier le build
make start

# Analyser le bundle (optionnel)
ANALYZE=true make build
```

### Optimisations automatiques
- **Next.js :** Tree shaking, code splitting automatique
- **Images :** Compression et formats modernes (WebP, AVIF)
- **Fonts :** Optimisation avec @next/font
- **CSS :** Purge automatique avec TailwindCSS
- **JavaScript :** Minification et compression

## ☁️ Déploiement cloud

### Vercel (Recommandé)

**1. Configuration automatique**
```bash
# Déploiement depuis GitHub
# 1. Connecter le repo à Vercel
# 2. Variables d'environnement ajoutées via dashboard
# 3. Deploy automatique sur push
```

**2. Variables d'environnement Vercel**
```env
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://api.bagtrip.com
NEXT_PUBLIC_APP_URL=https://admin.bagtrip.com
NEXT_PUBLIC_USE_MOCK_SERVICES=false

# Optionnel : Analytics et monitoring
VERCEL_ANALYTICS_ID=your_analytics_id
```

**3. Configuration vercel.json**
```json
{
  "framework": "nextjs",
  "buildCommand": "make build",
  "outputDirectory": ".next",
  "installCommand": "npm ci",
  "regions": ["cdg1"],
  "functions": {
    "app/**/*.tsx": {
      "maxDuration": 30
    }
  }
}
```

### Netlify

**1. Configuration netlify.toml**
```toml
[build]
  command = "make build"
  publish = ".next"

[build.environment]
  NODE_ENV = "production"
  NEXT_PUBLIC_API_URL = "https://api.bagtrip.com"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
```

### Docker

**1. Dockerfile**
```dockerfile
# Dockerfile
FROM node:22-alpine AS base

# Dependencies
FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Builder
FROM base AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runner
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 8000
ENV PORT 8000

CMD ["node", "server.js"]
```

**2. Docker Compose**
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  admin:
    build: .
    ports:
      - "8000:8000"
    environment:
      - NODE_ENV=production
      - NEXT_PUBLIC_API_URL=https://api.bagtrip.com
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - admin
```

## 🔐 Sécurité en production

### Headers de sécurité
```javascript
// next.config.ts
const securityHeaders = [
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on'
  },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload'
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  },
  {
    key: 'Referrer-Policy',
    value: 'origin-when-cross-origin'
  }
];
```

### Variables sensibles
```bash
# À configurer dans l'interface de déploiement
NEXTAUTH_SECRET=<strong-random-secret>
DATABASE_URL=<encrypted-database-url>
JWT_SECRET=<strong-jwt-secret>

# APIs externes
AMADEUS_CLIENT_SECRET=<encrypted>
GOOGLE_API_KEY=<encrypted>
MAPBOX_TOKEN=<encrypted>
```

### SSL/TLS
- Certificats automatiques (Vercel, Netlify)
- Let's Encrypt pour serveurs dédiés
- HSTS headers configurés
- Redirection HTTP → HTTPS

## 📊 Monitoring et Analytics

### Performance monitoring
```typescript
// Vercel Analytics (automatique)
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

### Error tracking
```typescript
// Sentry (optionnel)
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

### Logs et métriques
```bash
# Vercel : Logs automatiques dans le dashboard
# Docker : Configuration avec stdout/stderr
# Server : Winston ou similar pour logging structuré
```

## 🚦 CI/CD Pipeline

### GitHub Actions (configuré)

**Workflow de déploiement :**
```yaml
# .github/workflows/deploy.yml
name: 🚀 Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: Install and build
        run: |
          npm ci
          make build

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          vercel-args: '--prod'
```

### Validation pré-déploiement
- ✅ Tests E2E passent (18+ tests)
- ✅ Build réussit sans warnings
- ✅ TypeScript compile
- ✅ Audit de sécurité
- ✅ Performance budget respecté

## 🔄 Stratégie de déploiement

### Blue-Green Deployment
1. **Blue (production actuelle)** continue de servir le trafic
2. **Green (nouvelle version)** est déployée et testée
3. Switch du trafic de Blue vers Green
4. Blue garde en standby pour rollback rapide

### Rolling Updates
- Déploiement progressif par instances
- Zero-downtime deployment
- Health checks automatiques
- Rollback automatique en cas d'erreur

### Feature Flags
```typescript
// Utilisation de feature flags pour releases progressives
const isNewFeatureEnabled = process.env.NEXT_PUBLIC_FEATURE_NEW_UI === 'true';

export const Dashboard = () => {
  return isNewFeatureEnabled ? <NewDashboard /> : <OldDashboard />;
};
```

## 📋 Checklist de déploiement

### Avant le déploiement
- [ ] Tests locaux passent (`make check-all`)
- [ ] Build de production fonctionne (`make build`)
- [ ] Variables d'environnement configurées
- [ ] Base de données migrée (si applicable)
- [ ] CDN/Cache invalidé si nécessaire
- [ ] Monitoring configuré

### Après le déploiement
- [ ] Application accessible via HTTPS
- [ ] Tests de fumée (smoke tests) passent
- [ ] Logs ne montrent pas d'erreurs critiques
- [ ] Performance acceptable (Core Web Vitals)
- [ ] Fonctionnalités critiques testées manuellement

### En cas de problème
- [ ] Rollback immédiat possible
- [ ] Logs analysés et erreurs identifiées
- [ ] Incident communiqué aux utilisateurs
- [ ] Post-mortem programmé

## 🆘 Troubleshooting

### Erreurs communes

**1. Build failures**
```bash
# Erreur : TypeScript compilation failed
Solution: Vérifier make type-check localement

# Erreur : Module not found
Solution: Vérifier les imports et node_modules
```

**2. Runtime errors**
```bash
# Erreur : API calls failing
Solution: Vérifier NEXT_PUBLIC_API_URL et CORS

# Erreur : Authentication not working
Solution: Vérifier JWT secrets et cookies settings
```

**3. Performance issues**
```bash
# Erreur : Slow page loads
Solution: Analyser bundle avec ANALYZE=true make build

# Erreur : Memory leaks
Solution: Profiler avec React DevTools
```

### Rollback procedure
```bash
# Vercel : Via dashboard ou CLI
vercel rollback <deployment-id>

# Docker : Redéployer version précédente
docker-compose up -d --build

# Manual : Git revert + redeploy
git revert <commit-hash>
git push origin main
```

## 📞 Support de déploiement

**Contacts d'urgence :**
- **DevOps Lead :** urgence@bagtrip.com
- **Platform Status :** https://status.bagtrip.com
- **Monitoring :** Dashboard interne ou Datadog

**Documentation :**
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Vercel Documentation](https://vercel.com/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Happy Deploying! 🚀**
