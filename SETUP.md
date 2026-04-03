# Promofy - Setup Guide

## Architecture Overview

```
promofy/
├── mobile/              # Flutter app (iOS + Android)
│   ├── lib/
│   │   ├── config/      # App config, theme, router
│   │   ├── models/      # Data models
│   │   ├── services/    # Supabase, auth, location, notifications
│   │   ├── providers/   # Riverpod state management
│   │   ├── screens/     # Consumer & Business screens
│   │   └── widgets/     # Reusable UI components
│   └── pubspec.yaml
├── web-dashboard/       # Next.js business dashboard
│   ├── src/
│   │   ├── app/         # Pages (auth, dashboard, promotions, analytics)
│   │   ├── components/  # UI components
│   │   ├── lib/         # Supabase client, utilities
│   │   └── types/       # TypeScript types
│   └── package.json
├── supabase/
│   ├── migrations/      # Database schema (PostGIS)
│   ├── functions/       # Edge Functions (geofencing, notifications, Stripe)
│   └── config.toml
└── docs/
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter (Dart) |
| Web Dashboard | Next.js 14 + TypeScript + Tailwind CSS |
| Backend | Supabase (PostgreSQL + PostGIS) |
| Auth | Supabase Auth (Email, Google, Facebook SSO) |
| Database | PostgreSQL 15 + PostGIS extension |
| Push Notifications | Firebase Cloud Messaging (FCM) + APNs |
| Payments | Stripe (subscription billing) |
| State Management | Riverpod (Flutter), React hooks (Web) |
| Maps | Google Maps (Flutter), Mapbox/Google Maps (Web) |

---

## Prerequisites

- Flutter SDK >= 3.2.0
- Node.js >= 18
- Supabase CLI
- Firebase project (for push notifications)
- Google Maps API key
- Stripe account (for payments)

---

## Step 1: Supabase Setup

### 1.1 Create a Supabase Project
1. Go to https://supabase.com and create a new project
2. Note your **Project URL** and **Anon Key** from Settings > API

### 1.2 Enable PostGIS
In the Supabase SQL editor, run:
```sql
CREATE EXTENSION IF NOT EXISTS "postgis";
```

### 1.3 Run Database Migration
Copy the contents of `supabase/migrations/001_initial_schema.sql` and run it in the Supabase SQL Editor.

This creates:
- All tables (profiles, businesses, promotions, redemptions, etc.)
- PostGIS spatial indexes for geofencing queries
- Row Level Security (RLS) policies
- Database functions (get_nearby_promotions, claim_promotion, validate_redemption)
- Auto-triggers (profile creation on signup, updated_at)

### 1.4 Enable Auth Providers
In Supabase Dashboard > Authentication > Providers:
- Enable **Email** (enabled by default)
- Enable **Google** (add OAuth credentials)
- Enable **Facebook** (add App ID & Secret)

### 1.5 Create Storage Bucket
In Supabase Dashboard > Storage:
- Create a bucket called `business-assets` (public)

### 1.6 Deploy Edge Functions
```bash
supabase functions deploy check-geofence
supabase functions deploy send-notification
supabase functions deploy stripe-webhook
```

Set secrets:
```bash
supabase secrets set FCM_SERVER_KEY=your_firebase_server_key
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_secret
```

---

## Step 2: Flutter Mobile App

### 2.1 Configure
Edit `mobile/lib/config/app_config.dart`:
```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_KEY';
```

### 2.2 Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com
2. Add iOS and Android apps
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in the respective platform directories

### 2.3 Google Maps Setup
1. Enable Maps SDK for iOS and Android in Google Cloud Console
2. Add your API key to:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`

### 2.4 Run the App
```bash
cd mobile
flutter pub get
flutter run
```

---

## Step 3: Web Dashboard

### 3.1 Configure
```bash
cd web-dashboard
cp .env.local.example .env.local
```

Edit `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
STRIPE_SECRET_KEY=sk_test_YOUR_KEY
```

### 3.2 Install & Run
```bash
npm install
npm run dev
```

Open http://localhost:3000

---

## Step 4: Stripe Setup (Payments)

1. Create a Stripe account at https://stripe.com
2. Create Products & Prices:
   - **Premium**: $49/mo and $79/mo
   - **Gold**: $129/mo and $199/mo
3. Set up a webhook endpoint pointing to your Supabase Edge Function:
   - URL: `https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook`
   - Events: `checkout.session.completed`, `customer.subscription.*`, `invoice.payment_failed`
4. Update the price IDs in `supabase/functions/stripe-webhook/index.ts`

---

## Key Features Implemented

### Consumer App (Flutter)
- Social login (Google, Facebook, Email)
- Location permissions & geofencing
- Map view with nearby promotions + geofence circles
- Promotion feed (list view)
- Promotion detail + claim flow
- QR code generation for redemption
- Real-time countdown timer on QR codes
- Profile & notification preferences

### Business App (Flutter)
- Business registration & profile setup
- Promotion creator with templates (Happy Hour, 2x1, % off, etc.)
- Scheduling (date range, time window, day-of-week)
- QR scanner for redemption validation
- Manual code entry fallback
- Real-time analytics dashboard
- Subscription management (Free/Premium/Gold)

### Web Dashboard (Next.js)
- Auth (email + Google SSO)
- Business dashboard with KPI cards
- Promotion CRUD (create, pause, delete)
- Analytics with conversion funnel
- Subscription plan comparison & upgrade
- Business settings (profile, location, category)

### Backend (Supabase)
- PostGIS spatial queries for geofencing
- RLS policies for data security
- Database functions for atomic operations
- Edge Functions for geofence checking & push notifications
- Stripe webhook handling for subscriptions
- Real-time subscriptions for QR code validation

---

## Subscription Tiers

| Tier | Price | Geofence | Promotions | Features |
|------|-------|----------|------------|----------|
| Free/Basic | $0-15/mo | 50-100m | 1 | Basic analytics |
| Premium | $49-79/mo | 500m-1km | Up to 3 | Advanced analytics |
| Gold | $129-199/mo | 2-5km | Unlimited | Priority listing |
