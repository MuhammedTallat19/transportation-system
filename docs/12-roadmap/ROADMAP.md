# Roadmap

## Phase 0 — Foundations (Weeks 1–4)
- Finalize SRS/SDD sign-off, provision Firebase projects (dev/staging/prod), provision Google Maps Platform billing/keys.
- Stand up backend skeleton (NestJS + PostgreSQL + Docker), CI pipeline, base Flutter project structure (Clean Architecture scaffolding for both apps).
- Seed one pilot governorate's stations/routes (from Transport Authority-supplied data).

## Phase 1 — Core MVP (Weeks 5–12)
- Passenger App: auth, station/route dynamic loading, trip search + fare calculation, map display with polyline/ETA.
- Driver App: auth, assigned route view, start/end trip, GPS broadcast.
- Admin Dashboard: CRUD for stations, routes, route-stations ordering, fare rules, vehicles, drivers.
- Backend: full REST API per [API Documentation](../07-api/API_DOCUMENTATION.md), Fare Engine (Fixed + Distance + Station-count strategies).
- Notifications (trip status, admin broadcast).
- Internal QA pass against [Testing Guide](../09-testing/TESTING_GUIDE.md).

## Phase 2 — Pilot Launch (Weeks 13–16)
- Closed pilot with a single governorate, limited driver/vehicle set.
- Trip history, favorites, ratings/reviews.
- Basic Admin reporting (revenue, ridership by route).
- Play Store internal/closed testing track (see [Google Play Checklist](../14-publishing/GOOGLE_PLAY_CHECKLIST.md)).

## Phase 3 — General Availability (Weeks 17–24)
- Public launch for the governorate.
- Performance hardening to NFR targets (load testing per [Testing Guide §6](../09-testing/TESTING_GUIDE.md)).
- Full analytics dashboard for Transport Authority.
- iOS parity release.
- Security audit / penetration test completed.

## Phase 4 — Expansion & Enhancement (Months 7–12)
- Second governorate onboarding (validates BR-1/BR-2 multi-governorate data model with zero schema change).
- Digital wallet payment integration (pluggable payment gateway).
- Trip transfer suggestions (multi-route journeys where no single direct route exists).
- Driver incentive/performance dashboard.

## Phase 5 — Advanced Capabilities (Year 2+)
- Dynamic/surge pricing (`DYNAMIC` fare rule type activation).
- ML-based ETA prediction beyond raw Directions API estimates.
- Predictive demand analytics for route planning (Transport Authority tool).
- Accessibility enhancements, additional language support.

See [Future Features](FUTURE_FEATURES.md) for the full backlog beyond this timeline.
