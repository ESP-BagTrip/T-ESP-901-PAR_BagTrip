# Frontend Environment Variables Setup

Guide for configuring environment variables in frontend applications that use the BagTrip API.

## Required Environment Variables

### 1. API Configuration

```bash
# API Base URL
NEXT_PUBLIC_API_URL=http://localhost:3000
# or for production:
# NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

**For Flutter/Dart apps:**
```dart
// Use a config file or environment variables
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);
```

### 2. Stripe Configuration (Required for Payments)

```bash
# Stripe Publishable Key (PUBLIC - safe to expose in frontend)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
# or for production:
# NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx
```

**Important:**
- Use **Publishable Key** (starts with `pk_`) in frontend
- **Never** use Secret Key (starts with `sk_`) in frontend
- Test key: `pk_test_...`
- Live key: `pk_live_...`

### 3. Optional: App Configuration

```bash
# App Name
NEXT_PUBLIC_APP_NAME=BagTrip

# App Version
NEXT_PUBLIC_APP_VERSION=1.0.0

# Environment
NODE_ENV=development
```

---

## Setup by Framework

### Next.js / React

Create `.env.local` file in your project root:

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
NODE_ENV=development
```

**Usage in code:**
```typescript
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
const stripeKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
```

**Note:** In Next.js, only variables prefixed with `NEXT_PUBLIC_` are exposed to the browser.

### Flutter / Dart

Create a `.env` file or use `--dart-define`:

**Option 1: Using .env file (with flutter_dotenv package)**
```bash
# .env
API_BASE_URL=http://localhost:3000
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
```

**Option 2: Using --dart-define (recommended)**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000 \
           --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
```

**Usage in code:**
```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

const stripeKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: '',
);
```

### Vue.js / Nuxt

Create `.env` file:

```bash
# .env
VUE_APP_API_URL=http://localhost:3000
VUE_APP_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
```

**Usage in code:**
```javascript
const apiUrl = process.env.VUE_APP_API_URL;
const stripeKey = process.env.VUE_APP_STRIPE_PUBLISHABLE_KEY;
```

### Vanilla JavaScript / HTML

Create a `config.js` file:

```javascript
// config.js
const CONFIG = {
  API_BASE_URL: 'http://localhost:3000',
  STRIPE_PUBLISHABLE_KEY: 'pk_test_xxxxxxxxxxxxx',
};
```

---

## Stripe Setup

### Getting Your Stripe Publishable Key

1. Go to https://dashboard.stripe.com/apikeys
2. Copy the **Publishable key** (starts with `pk_test_` for test mode)
3. Add it to your `.env` file

### Using Stripe in Frontend

**React/Next.js example:**
```typescript
import { loadStripe } from '@stripe/stripe-js';

const stripePromise = loadStripe(
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!
);

// When authorizing payment
const stripe = await stripePromise;
const { error } = await stripe.confirmCardPayment(clientSecret, {
  payment_method: {
    card: cardElement,
  },
});
```

**Flutter example:**
```dart
import 'package:stripe_flutter/stripe_flutter.dart';

await Stripe.publishableKey = stripePublishableKey;
await Stripe.instance.confirmPayment(
  paymentIntentClientSecret: clientSecret,
  data: PaymentMethodParams.card(
    paymentMethodData: PaymentMethodData(),
  ),
);
```

---

## Environment-Specific Configuration

### Development
```bash
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
NODE_ENV=development
```

### Staging
```bash
NEXT_PUBLIC_API_URL=https://staging-api.yourdomain.com
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
NODE_ENV=production
```

### Production
```bash
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx
NODE_ENV=production
```

---

## Security Notes

### ✅ Safe to Expose (Public Keys)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` - Stripe publishable key
- `NEXT_PUBLIC_API_URL` - API base URL

### ❌ Never Expose (Secret Keys)
- `STRIPE_SECRET_KEY` - Only in backend
- `STRIPE_WEBHOOK_SECRET` - Only in backend
- `AMADEUS_CLIENT_SECRET` - Only in backend
- JWT secrets - Only in backend

### Best Practices
1. Use different keys for development and production
2. Never commit `.env` files to git
3. Add `.env.local` to `.gitignore`
4. Use environment-specific config files
5. Validate environment variables at app startup

---

## Example .env Files

### Next.js (.env.local)
```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:3000

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_51SgOhcFxLMG99CzZEoSGdLlV563pHvHFRbojC1OeHlqZ0Q6SajGA2ZYR20BwMZ47sDWL0c1ZLfMZJoZXUF2zjDfd00uAwghfNg

# App
NEXT_PUBLIC_APP_NAME=BagTrip
NODE_ENV=development
```

### Flutter (.env)
```bash
API_BASE_URL=http://localhost:3000
STRIPE_PUBLISHABLE_KEY=pk_test_51SgOhcFxLMG99CzZEoSGdLlV563pHvHFRbojC1OeHlqZ0Q6SajGA2ZYR20BwMZ47sDWL0c1ZLfMZJoZXUF2zjDfd00uAwghfNg
```

---

## Quick Setup Checklist

- [ ] Create `.env.local` (or `.env`) file
- [ ] Add `NEXT_PUBLIC_API_URL` with your API URL
- [ ] Add `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` from Stripe dashboard
- [ ] Verify `.env.local` is in `.gitignore`
- [ ] Restart your dev server after adding env vars
- [ ] Test API connection
- [ ] Test Stripe payment flow

---

## Troubleshooting

### Env vars not loading?
- **Next.js**: Restart dev server after adding env vars
- **Flutter**: Rebuild app after changing env vars
- **Vue**: Restart dev server

### Stripe not working?
- Verify you're using **publishable key** (starts with `pk_`)
- Check if key matches your environment (test vs live)
- Ensure Stripe SDK is properly initialized

### API connection failed?
- Verify `NEXT_PUBLIC_API_URL` is correct
- Check CORS settings on API
- Verify API is running

