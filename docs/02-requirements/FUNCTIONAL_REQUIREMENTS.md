# Functional Requirements

Each requirement is uniquely identified (`FR-<module>-<num>`), has a priority (`Must`/`Should`/`Could` — MoSCoW), and is traceable to SRS use cases and API endpoints.

## 1. Authentication & Account Management

| ID | Requirement | Priority |
|---|---|---|
| FR-AUTH-01 | System shall allow registration via phone number + OTP (Firebase Auth). | Must |
| FR-AUTH-02 | System shall allow registration/login via email + password. | Should |
| FR-AUTH-03 | System shall allow login via Google Sign-In. | Could |
| FR-AUTH-04 | System shall assign a Role (Passenger/Driver/Admin/Authority) to every account at creation. | Must |
| FR-AUTH-05 | System shall enforce role-based access on every API endpoint and Firestore collection. | Must |
| FR-AUTH-06 | System shall allow password reset / OTP re-verification. | Must |
| FR-AUTH-07 | System shall issue a signed JWT (backend) and a Firebase ID token (client) for authenticated sessions. | Must |

## 2. Station & Route Management (Dynamic Network)

| ID | Requirement | Priority |
|---|---|---|
| FR-NET-01 | System shall store all stations in the database with name, geolocation, governorate reference. | Must |
| FR-NET-02 | System shall store all routes with an ordered list of stations (`RouteStations`, with `sequence_order`). | Must |
| FR-NET-03 | The mobile app shall load stations and routes exclusively from the API/Firestore — no station/route may be hardcoded in app source code. | Must |
| FR-NET-04 | Administrator shall be able to create, edit, deactivate, and delete a station. | Must |
| FR-NET-05 | Administrator shall be able to create a route and assign an ordered list of existing stations to it. | Must |
| FR-NET-06 | Administrator shall be able to reorder stations within a route. | Must |
| FR-NET-07 | System shall support a station belonging to multiple routes. | Must |
| FR-NET-08 | System shall support unlimited routes, stations, vehicles, drivers, and (future) governorates without schema changes. | Must |

## 3. Trip Search & Fare Calculation

| ID | Requirement | Priority |
|---|---|---|
| FR-TRIP-01 | Passenger shall select a Start Station and Destination Station from dynamically loaded lists (with search/autocomplete). | Must |
| FR-TRIP-02 | System shall resolve all routes on which both stations exist, in the correct order (start precedes destination). | Must |
| FR-TRIP-03 | System shall calculate the fare using the active `FareRule` applicable to the resolved route/station-pair. | Must |
| FR-TRIP-04 | System shall display the estimated travel time using Google Directions API, factoring live traffic. | Must |
| FR-TRIP-05 | System shall display the nearest available vehicle(s) currently operating on the matched route(s). | Must |
| FR-TRIP-06 | If no route connects the two stations, system shall clearly inform the passenger ("No direct route found") and may suggest a transfer (v2). | Must |
| FR-TRIP-07 | System shall persist a `Trip` record when a passenger confirms boarding intent (or when a Driver starts a trip which passengers can join). | Must |

## 4. Live Tracking

| ID | Requirement | Priority |
|---|---|---|
| FR-GPS-01 | Driver app shall broadcast GPS location every 5–10 seconds while a trip is in progress. | Must |
| FR-GPS-02 | System shall store the latest location in Firestore (`TripLocations`) for real-time listeners. | Must |
| FR-GPS-03 | System shall persist a historical breadcrumb trail for completed trips (`TripHistory`) for analytics/audit. | Should |
| FR-GPS-04 | Passenger app shall render vehicle position, passenger position, stations, and route polyline on Google Maps. | Must |
| FR-GPS-05 | Passenger shall be able to share live trip location with a third party via a shareable link. | Could |

## 5. Fare Engine

| ID | Requirement | Priority |
|---|---|---|
| FR-FARE-01 | System shall support Fixed fare rules (flat amount per route). | Must |
| FR-FARE-02 | System shall support Distance-based fare rules (base + per-km rate). | Must |
| FR-FARE-03 | System shall support Station-count-based fare rules (amount per number of stations traveled). | Must |
| FR-FARE-04 | System shall support a `valid_from`/`valid_to` window per fare rule to allow scheduled fare changes. | Must |
| FR-FARE-05 | Administrator shall be able to add/edit/deactivate fare rules without any app release. | Must |
| FR-FARE-06 | System architecture shall support future Dynamic/Surge pricing rule type without schema migration (rule type is extensible via `rule_type` enum + `config` JSONB). | Should |
| FR-FARE-07 | Every fare calculation shall be logged for auditability (`Fares` table row per resolved trip). | Must |

## 6. Admin Dashboard

| ID | Requirement | Priority |
|---|---|---|
| FR-ADM-01 | Dashboard shall show live map of all active vehicles/trips. | Must |
| FR-ADM-02 | Dashboard shall provide full CRUD for Drivers, Vehicles, Stations, Routes, Fare Rules. | Must |
| FR-ADM-03 | Dashboard shall provide trip monitoring (active, completed, cancelled) with filters. | Must |
| FR-ADM-04 | Dashboard shall provide reports: revenue by route, trips by station, driver performance. | Must |
| FR-ADM-05 | Dashboard shall provide system settings (fare currency, default map center, notification templates). | Should |
| FR-ADM-06 | Dashboard shall log every administrative mutation to `AuditLogs`. | Must |

## 7. Passenger App

| ID | Requirement | Priority |
|---|---|---|
| FR-PAX-01 | Passenger shall manage a profile (name, phone, photo). | Must |
| FR-PAX-02 | Passenger shall view trip history with fare, route, date, driver rating given. | Must |
| FR-PAX-03 | Passenger shall save Favorite Stations for quick access. | Must |
| FR-PAX-04 | Passenger shall rate & review a Driver after trip completion (1–5 stars + comment). | Must |
| FR-PAX-05 | Passenger shall receive push notifications for vehicle arrival, trip status changes, fare changes on saved routes. | Must |

## 8. Driver App

| ID | Requirement | Priority |
|---|---|---|
| FR-DRV-01 | Driver shall view their assigned route(s) and vehicle for the day. | Must |
| FR-DRV-02 | Driver shall Start Trip / End Trip with a single tap. | Must |
| FR-DRV-03 | Driver shall view trip statistics (trips completed, distance, average rating). | Must |
| FR-DRV-04 | Driver shall receive push notifications (new assignment, admin messages). | Must |

## 9. Notifications

| ID | Requirement | Priority |
|---|---|---|
| FR-NOTIF-01 | System shall send FCM push notifications for: trip status, vehicle proximity, fare rule changes, admin broadcast messages. | Must |
| FR-NOTIF-02 | System shall persist notification history per user (`Notifications` table). | Must |

## 10. Payments (v1 scope: cash + ledger)

| ID | Requirement | Priority |
|---|---|---|
| FR-PAY-01 | System shall record a `Payment` entry per completed trip (method: cash/wallet). | Must |
| FR-PAY-02 | System architecture shall support pluggable payment gateway integration in v2 without schema changes to `Trips`. | Should |

## Requirement Traceability

Each `FR-*` ID above maps 1:1 to a use case in the [SRS](../03-srs/SRS.md) §5 and to one or more endpoints in the [API Documentation](../07-api/API_DOCUMENTATION.md).
