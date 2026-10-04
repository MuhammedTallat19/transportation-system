# API Documentation

This folder describes the **target-state** HTTP API. The API currently implemented in this checkout is the Django REST API at `http://127.0.0.1:8000/api/` (see `backend/backend_project/core/urls.py`). Do not treat the hostnames below as live services.

Base URL (target-state): `https://api.transportation-app.example.com/v1` (staging: `https://api-staging.transportation-app.example.com/v1`)
Auth: Bearer JWT (Firebase ID Token, verified server-side via Firebase Admin SDK). All endpoints require `Authorization: Bearer <token>` unless marked **Public**.

## 1. Conventions

- All request/response bodies are `application/json`.
- Timestamps: ISO 8601 UTC (`2026-08-01T10:30:00Z`).
- Money: integer cents + `currency` field (e.g., `{"amountCents": 1910, "currency": "EGP"}`).
- Pagination: `?page=1&pageSize=20` → response includes `{"data": [...], "page":1, "pageSize":20, "total":134}`.
- Errors: standard envelope —
```json
{
  "error": {
    "code": "FARE_RULE_NOT_FOUND",
    "message": "No active fare rule exists for this route.",
    "details": {}
  }
}
```

## 2. Standard HTTP Status Codes

| Code | Meaning |
|---|---|
| 200 | OK |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Validation error |
| 401 | Missing/invalid auth token |
| 403 | Authenticated but not authorized (RBAC) |
| 404 | Resource not found |
| 409 | Conflict (e.g., duplicate active fare rule) |
| 422 | Semantically invalid (e.g., start station == destination station) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

## 3. Authentication

### `POST /auth/register` — **Public**
Registers a user profile after Firebase client-side sign-up (this endpoint links the Firebase UID to a `users` row).

**Request**
```json
{
  "firebaseIdToken": "eyJhbGciOi...",
  "fullName": "Sara Ahmed",
  "phoneNumber": "+201001234567",
  "governorateId": "11111111-1111-1111-1111-111111111111",
  "role": "PASSENGER"
}
```
**Response `201`**
```json
{
  "id": "66666666-6666-6666-6666-666666666601",
  "fullName": "Sara Ahmed",
  "status": "PENDING_VERIFICATION",
  "roles": ["PASSENGER"]
}
```

### `GET /auth/me`
Returns the authenticated user's profile + roles.

### `POST /auth/logout`
Invalidates server-side session cache (Firebase tokens themselves expire client-side; this clears any cached refresh state).

## 4. Governorates

### `GET /governorates` — **Public**
```json
{ "data": [ { "id": "111...", "name": "Ismailia", "isActive": true } ] }
```

## 5. Stations (dynamic — never cached client-side beyond TTL)

### `GET /governorates/{governorateId}/stations`
Query params: `?search=central&activeOnly=true`
```json
{
  "data": [
    { "id": "222...01", "name": "Central Station", "latitude": 30.5965, "longitude": 32.2715, "isActive": true }
  ]
}
```

### `GET /stations/{id}`
### `POST /stations` — **Admin/Authority only**
```json
{ "governorateId": "111...", "name": "New Station", "latitude": 30.60, "longitude": 32.25 }
```
### `PUT /stations/{id}` — **Admin/Authority only**
### `DELETE /stations/{id}` — **Admin/Authority only** (soft delete → `isActive=false`; returns `409` if referenced by an active route and hard-delete is attempted)

### `GET /stations/nearby?lat=30.60&lng=32.27&radiusKm=2`
Returns nearest active stations using the PostGIS geography index (see [Database Documentation §2.7](../06-database/DATABASE_DOCUMENTATION.md#27-stations)).

## 6. Routes & Route Stations

### `GET /governorates/{governorateId}/routes`
### `GET /routes/{id}/stations`
Returns the **ordered** station sequence for a route — this is the endpoint the Passenger App calls to render the destination picker after a start station is chosen.
```json
{
  "routeId": "333...01",
  "stations": [
    { "stationId": "222...01", "name": "Central Station", "order": 1, "distanceFromStartKm": 0.0 },
    { "stationId": "222...02", "name": "University Gate", "order": 2, "distanceFromStartKm": 2.8 },
    { "stationId": "222...04", "name": "Industrial Zone", "order": 4, "distanceFromStartKm": 9.4 }
  ]
}
```

### `GET /routes/search?startStationId=&destStationId=`
Returns all routes serving both stations (start order < dest order), sorted by fewest stops.
```json
{
  "data": [
    { "routeId": "333...01", "routeName": "Central - Industrial Line", "stops": 3, "distanceKm": 9.4 }
  ]
}
```

### `POST /routes` / `PUT /routes/{id}` / `DELETE /routes/{id}` — **Admin/Authority only**
### `POST /routes/{id}/stations` — **Admin/Authority only** — add/reorder a station on a route
```json
{ "stationId": "222...03", "order": 3, "distanceFromStartKm": 5.6 }
```
### `PUT /routes/{id}/stations/reorder` — **Admin/Authority only** — bulk reorder
```json
{ "order": [ { "stationId": "222...01", "order": 1 }, { "stationId": "222...02", "order": 2 } ] }
```

## 7. Fare Engine

### `GET /fares/calculate?routeId=&startStationId=&destStationId=`
The core dynamic pricing endpoint — see [SDD §4 Fare Engine](../04-sdd/SDD.md) for the algorithm.
```json
{
  "routeId": "333...01",
  "fareRuleId": "444...01",
  "fareType": "DISTANCE_BASED",
  "breakdown": {
    "baseFareCents": 500,
    "distanceComponentCents": 1410,
    "stationComponentCents": 0,
    "surchargeCents": 0
  },
  "totalCents": 1910,
  "currency": "EGP",
  "distanceKm": 9.4,
  "estimatedDurationSec": 1200
}
```
**Errors:** `404 FARE_RULE_NOT_FOUND` if no active fare rule exists for the route; `422 INVALID_STATION_PAIR` if the two stations aren't on the same route.

### `GET /routes/{id}/fare-rules` — **Admin/Authority**
### `POST /routes/{id}/fare-rules` — **Admin** (creates a **draft**, `isActive=false`)
```json
{
  "fareType": "DISTANCE_BASED",
  "baseFareCents": 500,
  "perKmRateCents": 150,
  "minFareCents": 500,
  "effectiveFrom": "2026-09-01T00:00:00Z"
}
```
### `POST /fare-rules/{id}/approve` — **Transport Authority only** — flips `isActive=true`, deactivates the prior active rule, writes an `AuditLog` entry with `action=APPROVE`.

## 8. Trips

### `POST /trips` — creates a trip request
```json
{
  "routeId": "333...01",
  "startStationId": "222...01",
  "destStationId": "222...04"
}
```
**Response `201`**
```json
{
  "id": "777...01",
  "status": "REQUESTED",
  "fareAmountCents": 1910,
  "estimatedDurationSec": 1200
}
```

### `GET /trips/{id}`
### `GET /trips?status=COMPLETED&passengerId=` (Admin) / defaults to current user's trips
### `PATCH /trips/{id}/assign` — **system/Admin** — assigns driver + vehicle
```json
{ "driverId": "666...02", "vehicleId": "555...01" }
```
### `PATCH /trips/{id}/start` — **Driver only**, must own the trip's driver_id
### `PATCH /trips/{id}/end` — **Driver only**
### `PATCH /trips/{id}/cancel`
```json
{ "reason": "Passenger requested cancellation" }
```

## 9. GPS / Live Location

### `POST /trips/{id}/location` — **Driver only**, high frequency (every 5s while trip active)
```json
{ "latitude": 30.599, "longitude": 32.273, "speedKmh": 32.5, "headingDeg": 87.0 }
```
> In production this write also mirrors to Firestore `trips/{tripId}` for realtime client listeners (see [Architecture §6](../05-architecture/ARCHITECTURE.md)); the REST call persists the durable breadcrumb to `trip_locations`.

### `GET /trips/{id}/locations?since=` — full or incremental breadcrumb trail (used for post-trip analytics/replay, not live tracking — live tracking uses the Firestore stream directly from the client).

## 10. Notifications

### `GET /notifications?unreadOnly=true`
### `PATCH /notifications/{id}/read`
### `POST /notifications/broadcast` — **Admin/Authority** — send to all users in a governorate or a specific role
```json
{ "governorateId": "111...", "role": "PASSENGER", "title": "Service Alert", "body": "Route R-01 delayed 15 min due to road works." }
```

## 11. Payments & Tickets

### `POST /trips/{id}/payments`
```json
{ "method": "CASH", "amountCents": 1910 }
```
### `GET /tickets/{ticketCode}/validate` — **Driver only** — validates a passenger's ticket code at boarding
```json
{ "valid": true, "tripId": "777...01", "passengerName": "Sara Ahmed" }
```

## 12. Reviews & Favorites

### `POST /reviews`
```json
{ "tripId": "777...01", "rating": 5, "comment": "Smooth ride, on time." }
```
### `GET /favorites` / `POST /favorites` / `DELETE /favorites/{id}`

## 13. Admin / Reporting

### `GET /admin/reports/revenue?from=&to=&governorateId=`
### `GET /admin/reports/ridership?from=&to=&routeId=`
### `GET /admin/vehicles/live` — live fleet positions (last known `trip_locations` per active trip) for the dashboard map
### `GET /admin/audit-logs?entityType=FareRule&entityId=`

## 14. Validation Rules (examples)

| Endpoint | Field | Rule |
|---|---|---|
| `POST /trips` | startStationId ≠ destStationId | 422 `INVALID_STATION_PAIR` |
| `POST /stations` | latitude | -90 ≤ x ≤ 90 |
| `POST /stations` | longitude | -180 ≤ x ≤ 180 |
| `POST /routes/{id}/fare-rules` | perKmRateCents | ≥ 0 |
| `POST /reviews` | rating | integer 1–5 |
| `PATCH /trips/{id}/start` | caller | must equal `trips.driver_id` |

## 15. Role-Based Endpoint Access Matrix

| Endpoint group | Passenger | Driver | Admin | Transport Authority |
|---|---|---|---|---|
| Stations/Routes (read) | ✅ | ✅ | ✅ | ✅ |
| Stations/Routes (write) | ❌ | ❌ | ✅ | ✅ |
| Fare rule draft | ❌ | ❌ | ✅ | ✅ |
| Fare rule approve/publish | ❌ | ❌ | ❌ | ✅ |
| Trip create | ✅ | ❌ | ✅ (on behalf) | ✅ |
| Trip start/end | ❌ | ✅ (own) | ❌ | ❌ |
| GPS post | ❌ | ✅ (own trip) | ❌ | ❌ |
| Admin reports | ❌ | ❌ | ✅ | ✅ |
| Audit logs | ❌ | ❌ | ✅ (read-only own actions) | ✅ (full) |

Full detail in [Security Guide §4](../10-security/SECURITY_GUIDE.md).

## 16. OpenAPI

A machine-readable OpenAPI 3.0 contract mirroring this document should be maintained at `api/openapi.yaml` and validated in CI (contract tests) — see [Testing Guide §5](../09-testing/TESTING_GUIDE.md).
