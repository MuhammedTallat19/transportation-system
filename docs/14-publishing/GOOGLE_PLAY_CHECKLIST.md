# Google Play Publishing Checklist

Applies to both `passenger_app` and `driver_app` (published as two separate listings, since they serve distinct user bases).

## 1. Developer Account & App Setup

- [ ] Google Play Console developer account (organization-owned, not individual, for a governorate-operated service).
- [ ] Create app entries: `Transportation App — Passenger` and `Transportation App — Driver`.
- [ ] Set correct category: **Maps & Navigation** or **Travel & Local**.
- [ ] Configure content rating questionnaire (expect "Everyone" or "Everyone 10+").
- [ ] Set target countries/regions to the governorate's country only (initially).
- [ ] Set up **App Signing by Google Play** (enroll, upload signing key).

## 2. Store Listing

| Field | Requirement |
|---|---|
| App name | ≤ 30 characters, e.g., "Transportation App" |
| Short description | ≤ 80 characters |
| Full description | ≤ 4000 characters, in both English and Arabic |
| App icon | 512×512 PNG, 32-bit with alpha |
| Feature graphic | 1024×500 PNG/JPEG |
| Screenshots | Minimum 2, recommended 4–8 per device type (phone required; tablet optional) |
| Promo video | Optional YouTube link |
| Privacy Policy URL | **Mandatory** — must be publicly accessible, matches data collected (see §4) |

### Suggested Screenshot Set (Passenger App)
1. Station/destination picker with map.
2. Fare + ETA result screen.
3. Live vehicle tracking on map.
4. Trip history list.
5. Driver rating screen.

### Suggested Screenshot Set (Driver App)
1. Assigned route/vehicle summary.
2. Start Trip confirmation.
3. Active trip with live GPS indicator.
4. Trip statistics screen.

## 3. App Content Declarations

- [ ] **Data safety form** completed accurately — declare collection of: precise location, name, phone number, and (if applicable) payment info.
- [ ] Declare location data is used for "App functionality" (live tracking) and, if applicable, "Analytics."
- [ ] Declare whether data is shared with third parties (Google Maps Platform processes location as a service provider — disclose accordingly).
- [ ] Ads declaration: **No ads** (if applicable).
- [ ] Target API level compliance with current Play requirements at submission time.
- [ ] Permissions declared and justified: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (Driver app only, with prominent disclosure per Play policy), `POST_NOTIFICATIONS`, `CAMERA`/`READ_MEDIA_IMAGES` (profile photo).

## 4. Privacy Policy Requirements

Must clearly state, at minimum:
- What personal data is collected (name, phone/email, GPS location, profile photo, trip history).
- Purpose of collection (trip fulfillment, fare calculation, safety, service improvement).
- Third parties data is shared with (Firebase/Google Cloud, Google Maps Platform).
- Data retention period and deletion request process.
- Contact information for data protection inquiries.

## 5. Terms of Service Requirements

- User eligibility (minimum age, valid governorate resident or visitor).
- Fare and payment terms (cash handling, refund/dispute policy).
- Driver conduct and passenger conduct expectations.
- Liability limitations, dispute resolution process.
- Governing law (governorate/country jurisdiction).

## 6. Pre-Launch Testing Tracks

- [ ] **Internal testing** track — core team, 5–10 testers, rapid iteration.
- [ ] **Closed testing** track — pilot drivers + a controlled passenger group (aligns with [Roadmap](../12-roadmap/ROADMAP.md) Phase 2).
- [ ] **Open testing** (optional) before full production release.
- [ ] Run Google Play's automated **Pre-launch report** (crash/ANR/security scan on real devices) and resolve all flagged issues.

## 7. Release Readiness

- [ ] Signed release AAB built via CI (`flutter build appbundle --flavor prod --release`).
- [ ] Version code/name bumped per semantic versioning; version code strictly increasing.
- [ ] ProGuard/R8 rules verified (no crashes from over-aggressive obfuscation, especially around Firebase/Google Maps reflection usage).
- [ ] Crashlytics symbol upload configured in CI for readable stack traces.
- [ ] Staged rollout plan: 10% → 25% → 50% → 100%, monitoring Crashlytics/ANR rate at each stage.

## 8. Post-Launch

- [ ] Monitor Play Console vitals (crash rate, ANR rate, battery usage — especially relevant given continuous GPS in the Driver app).
- [ ] Respond to user reviews (support channel/process defined).
- [ ] Schedule quarterly policy compliance review (Play policies change frequently, especially around location and background permissions).
