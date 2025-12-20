# API Testing Plan - Booking Flow

Simple step-by-step guide to test flight and hotel booking flows with the API.

## Prerequisites

- API running on `http://localhost:3000` (or your API URL)
- Stripe test keys configured
- Amadeus test credentials configured

---

## 1. Authentication

### Register a new user
```http
POST /v1/auth/register
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123",
  "fullName": "John Doe",
  "phone": "+33612345678"
}
```

**Response:**
```json
{
  "token": "eyJhbGci...",
  "user": {
    "id": "uuid",
    "email": "test@example.com"
  }
}
```

### Login
```http
POST /v1/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

**Save the `token` for all subsequent requests:**
```
Authorization: Bearer <token>
```

---

## 2. Create a Trip

```http
POST /v1/trips
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Paris to Rome",
  "originIata": "PAR",
  "destinationIata": "ROM",
  "startDate": "2026-01-10",
  "endDate": "2026-01-13"
}
```

**Response:**
```json
{
  "id": "trip-uuid",
  "title": "Paris to Rome",
  "status": "draft",
  ...
}
```

**Save `tripId` for next steps.**

---

## 3. Add Travelers

```http
POST /v1/trips/{tripId}/travelers
Authorization: Bearer <token>
Content-Type: application/json

{
  "amadeusTravelerRef": "1",
  "travelerType": "ADULT",
  "firstName": "John",
  "lastName": "Doe",
  "dateOfBirth": "1990-05-15",
  "gender": "MALE",
  "documents": [
    {
      "documentType": "PASSPORT",
      "number": "12AB34567",
      "expiryDate": "2030-01-01",
      "issuanceCountry": "FR",
      "nationality": "FR"
    }
  ],
  "contacts": {
    "emailAddress": "test@example.com",
    "phoneNumber": "+33612345678"
  }
}
```

**Response:**
```json
{
  "id": "traveler-uuid",
  "firstName": "John",
  "lastName": "Doe",
  ...
}
```

**Save `travelerId` for flight booking.**

---

## 4. FLIGHT BOOKING FLOW

### Step 4.1: Search Flights

```http
POST /v1/trips/{tripId}/flights/searches
Authorization: Bearer <token>
Content-Type: application/json

{
  "originIata": "PAR",
  "destinationIata": "ROM",
  "departureDate": "2026-01-10",
  "returnDate": "2026-01-13",
  "adults": 1,
  "currency": "EUR",
  "travelClass": "ECONOMY"
}
```

**Response:**
```json
{
  "searchId": "search-uuid",
  "offers": [
    {
      "id": "offer-uuid",
      "grandTotal": 245.90,
      "currency": "EUR",
      "summary": {
        "stops": 0
      }
    }
  ]
}
```

**Save `offerId` (flight offer ID).**

### Step 4.2: (Optional) Price the Offer

```http
POST /v1/trips/{tripId}/flights/offers/{offerId}/price
Authorization: Bearer <token>
```

**Response:**
```json
{
  "offerId": "offer-uuid",
  "pricedOffer": { ... }
}
```

### Step 4.3: Create Booking Intent

```http
POST /v1/trips/{tripId}/booking-intents
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "flight",
  "flightOfferId": "offer-uuid"
}
```

**Response:**
```json
{
  "id": "intent-uuid",
  "type": "flight",
  "status": "INIT",
  "amount": 245.90,
  "currency": "EUR",
  "selectedOfferId": "offer-uuid"
}
```

**Save `intentId`.**

### Step 4.4: Authorize Payment (Stripe)

```http
POST /v1/booking-intents/{intentId}/payment/authorize
Authorization: Bearer <token>
Content-Type: application/json

{
  "returnUrl": "https://yourapp.com/callback"
}
```

**Response:**
```json
{
  "stripePaymentIntentId": "pi_xxx",
  "clientSecret": "pi_xxx_secret_xxx",
  "status": "requires_payment_method"
}
```

**Frontend:** Use Stripe SDK to confirm payment with `clientSecret`. After successful payment, Stripe webhook will update intent status to `AUTHORIZED`.

### Step 4.5: Wait for Authorization

**The webhook automatically sets status to `AUTHORIZED` when payment is confirmed.**

You can poll the booking intent or wait for webhook:
```http
GET /v1/trips/{tripId}
Authorization: Bearer <token>
```

### Step 4.6: Book the Flight

```http
POST /v1/booking-intents/{intentId}/book
Authorization: Bearer <token>
Content-Type: application/json

{
  "travelerIds": ["traveler-uuid"],
  "contacts": [
    {
      "emailAddress": "test@example.com"
    }
  ]
}
```

**Response:**
```json
{
  "bookingIntent": {
    "id": "intent-uuid",
    "status": "BOOKED"
  },
  "amadeus": {
    "type": "flight",
    "orderId": "eJz..."
  }
}
```

### Step 4.7: Capture Payment

```http
POST /v1/booking-intents/{intentId}/payment/capture
Authorization: Bearer <token>
```

**Response:**
```json
{
  "bookingIntent": {
    "id": "intent-uuid",
    "status": "CAPTURED"
  },
  "stripe": {
    "paymentIntentId": "pi_xxx"
  }
}
```

**✅ Flight booking complete!**

---

## 5. HOTEL BOOKING FLOW

### Step 5.1: Search Hotels

```http
POST /v1/trips/{tripId}/hotels/searches
Authorization: Bearer <token>
Content-Type: application/json

{
  "cityCode": "ROM",
  "checkIn": "2026-01-10",
  "checkOut": "2026-01-13",
  "adults": 1,
  "roomQty": 1,
  "currency": "EUR"
}
```

**Response:**
```json
{
  "searchId": "search-uuid",
  "offers": [
    {
      "id": "offer-uuid",
      "hotelId": "AMH123",
      "offerId": "OFFER_456",
      "totalPrice": 390.0,
      "currency": "EUR"
    }
  ]
}
```

**Save `offerId` (hotel offer ID).**

### Step 5.2: Create Booking Intent

```http
POST /v1/trips/{tripId}/booking-intents
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "hotel",
  "hotelOfferId": "offer-uuid"
}
```

**Response:**
```json
{
  "id": "intent-uuid",
  "type": "hotel",
  "status": "INIT",
  "amount": 390.0,
  "currency": "EUR",
  "selectedOfferId": "offer-uuid"
}
```

**Save `intentId`.**

### Step 5.3: Authorize Payment (Same as Flight)

```http
POST /v1/booking-intents/{intentId}/payment/authorize
Authorization: Bearer <token>
Content-Type: application/json

{
  "returnUrl": "https://yourapp.com/callback"
}
```

**Use Stripe SDK to confirm payment, wait for `AUTHORIZED` status.**

### Step 5.4: Book the Hotel

```http
POST /v1/booking-intents/{intentId}/book
Authorization: Bearer <token>
Content-Type: application/json

{
  "guests": [
    {
      "name": {
        "firstName": "John",
        "lastName": "Doe"
      },
      "contact": {
        "email": "test@example.com"
      }
    }
  ],
  "roomAssociations": [
    {
      "guestReferences": ["1"],
      "hotelOfferId": "OFFER_456"
    }
  ]
}
```

**Response:**
```json
{
  "bookingIntent": {
    "id": "intent-uuid",
    "status": "BOOKED"
  },
  "amadeus": {
    "type": "hotel",
    "bookingId": "eJz..."
  }
}
```

### Step 5.5: Capture Payment (Same as Flight)

```http
POST /v1/booking-intents/{intentId}/payment/capture
Authorization: Bearer <token>
```

**✅ Hotel booking complete!**

---

## 6. Error Handling

### Check Booking Intent Status

```http
GET /v1/trips/{tripId}
Authorization: Bearer <token>
```

**Possible statuses:**
- `INIT` - Created, waiting for payment
- `AUTHORIZED` - Payment authorized, ready to book
- `BOOKING_PENDING` - Booking in progress
- `BOOKED` - Booking confirmed, ready to capture
- `CAPTURED` - Payment captured, complete
- `FAILED` - Booking failed
- `CANCELLED` - Cancelled
- `PAYMENT_CAPTURE_FAILED` - Capture failed

### Cancel Payment (if needed)

```http
POST /v1/booking-intents/{intentId}/payment/cancel
Authorization: Bearer <token>
```

---

## 7. Quick Reference

### Base URL
```
http://localhost:3000
```

### Required Headers
```
Authorization: Bearer <token>
Content-Type: application/json
```

### Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/auth/register` | POST | Register user |
| `/v1/auth/login` | POST | Login |
| `/v1/trips` | POST | Create trip |
| `/v1/trips/{tripId}/travelers` | POST | Add traveler |
| `/v1/trips/{tripId}/flights/searches` | POST | Search flights |
| `/v1/trips/{tripId}/hotels/searches` | POST | Search hotels |
| `/v1/trips/{tripId}/booking-intents` | POST | Create booking intent |
| `/v1/booking-intents/{intentId}/payment/authorize` | POST | Authorize payment |
| `/v1/booking-intents/{intentId}/book` | POST | Book flight/hotel |
| `/v1/booking-intents/{intentId}/payment/capture` | POST | Capture payment |

---

## 8. Testing Checklist

### Flight Booking
- [ ] Register/Login
- [ ] Create trip
- [ ] Add traveler
- [ ] Search flights
- [ ] Create booking intent
- [ ] Authorize payment (Stripe)
- [ ] Wait for AUTHORIZED status
- [ ] Book flight
- [ ] Capture payment
- [ ] Verify CAPTURED status

### Hotel Booking
- [ ] Search hotels
- [ ] Create booking intent
- [ ] Authorize payment (Stripe)
- [ ] Wait for AUTHORIZED status
- [ ] Book hotel
- [ ] Capture payment
- [ ] Verify CAPTURED status

---

## Notes

- **Stripe Webhook**: Must be configured to automatically update booking intent status to `AUTHORIZED`
- **Amounts**: Stored in database as decimal, but Stripe expects cents (minor units) - handled automatically
- **Idempotency**: All operations are idempotent - safe to retry
- **Error Handling**: Check `last_error` field in booking intent if status is `FAILED`

