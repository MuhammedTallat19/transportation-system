# Architecture Documentation

## 1. Architectural Style

Transportation App is specified to use a **hybrid architecture**:
- **BaaS-first (Firebase)** for auth, realtime sync, push, and storage — minimizes operational overhead for high-churn realtime data (GPS, presence, notifications).
- **Custom REST API (Node.js/NestJS)** backed by **PostgreSQL** as the relational source of truth for master/billing data (routes, fares, trips ledger, reporting) where strong consistency, complex joins, and SQL-based analytics are required.
- **Clean Architecture** on all Flutter clients, isolating domain logic from Flutter/Firebase/HTTP frameworks.

This is a deliberate **polyglot persistence** choice: Firestore is excellent for realtime document sync but weak for relational integrity/reporting; PostgreSQL is the reverse. Each is used for what it's best at.

## 2. C4 Model

### 2.1 Level 1 — System Context

```mermaid
C4Context
    title Transportation App - System Context
    Person(passenger, "Passenger")
    Person(driver, "Driver")
    Person(admin, "Administrator")
    Person(authority, "Transport Authority")
    System(transportationApp, "Transportation App")
    System_Ext(firebase, "Firebase")
    System_Ext(gmaps, "Google Maps Platform")
    System_Ext(fcm, "FCM Push Delivery")
    Rel(passenger, transportationApp, "Plans trips, tracks vehicle")
    Rel(driver, transportationApp, "Runs trips")
    Rel(admin, transportationApp, "Manages network")
    Rel(authority, transportationApp, "Views analytics")
    Rel(transportationApp, firebase, "Auth/DB/Storage/Push")
    Rel(transportationApp, gmaps, "Maps/Directions/Places")
    Rel(transportationApp, fcm, "Sends notifications")
```

### 2.2 Level 2 — Containers

```mermaid
C4Container
    title Transportation App - Container Diagram
    Person(passenger, "Passenger")
    Person(driver, "Driver")
    Person(admin, "Administrator")

    Container(paxapp, "Passenger App", "Flutter/Dart", "Trip search, tracking, ratings")
    Container(drvapp, "Driver App", "Flutter/Dart", "Trip lifecycle, GPS broadcast")
    Container(admweb, "Admin Dashboard", "Flutter Web", "Master data & analytics")
    Container(api, "REST API", "Node.js/NestJS", "Business logic, fare engine, reporting")
    ContainerDb(pg, "PostgreSQL", "Relational DB", "Routes, stations, fares, trips ledger")
    ContainerDb(firestore, "Firestore", "NoSQL Realtime DB", "Live GPS, trip status, notifications feed")
    Container(authsvc, "Firebase Auth", "BaaS", "Identity & session tokens")
    Container(storage, "Firebase Storage", "BaaS", "Profile photos, documents")
    Container(fcm, "FCM", "BaaS", "Push delivery")
    System_Ext(gmaps, "Google Maps Platform")

    Rel(passenger, paxapp, "Uses")
    Rel(driver, drvapp, "Uses")
    Rel(admin, admweb, "Uses")

    Rel(paxapp, authsvc, "Authenticates")
    Rel(drvapp, authsvc, "Authenticates")
    Rel(admweb, authsvc, "Authenticates")

    Rel(paxapp, api, "REST calls (JWT)")
    Rel(drvapp, api, "REST calls (JWT)")
    Rel(admweb, api, "REST calls (JWT)")

    Rel(paxapp, firestore, "Realtime listeners")
    Rel(drvapp, firestore, "Writes GPS pings")
    Rel(admweb, firestore, "Realtime fleet map")

    Rel(api, pg, "SQL (TypeORM/Prisma)")
    Rel(api, firestore, "Admin SDK writes (mirrors trip status)")
    Rel(api, fcm, "Sends push via Admin SDK")

    Rel(paxapp, gmaps, "Maps/Directions/Places")
    Rel(drvapp, gmaps, "Maps/Directions")
    Rel(paxapp, storage, "Upload profile photo")
```

### 2.3 Level 3 — API Component Diagram

```mermaid
C4Component
    title REST API - Component Diagram
    Container_Boundary(api, "REST API (NestJS)") {
        Component(authc, "Auth Controller/Guard", "Verifies Firebase ID token, issues app JWT, RBAC guard")
        Component(netc, "Network Controller", "Stations/Routes CRUD")
        Component(farec, "Fare Controller", "Fare rule CRUD + calculation endpoint")
        Component(tripc, "Trip Controller", "Trip lifecycle, GPS ingestion")
        Component(notifc, "Notification Controller", "Notification dispatch/history")
        Component(reportc, "Reporting Controller", "Aggregated analytics endpoints")
        Component(fareengine, "Fare Engine Service", "Strategy-pattern fare calculation")
        Component(orm, "Data Access Layer", "Prisma/TypeORM repositories")
    }
    ContainerDb(pg, "PostgreSQL")
    ContainerDb(firestore, "Firestore")

    Rel(tripc, fareengine, "uses")
    Rel(farec, fareengine, "uses")
    Rel(authc, orm, "reads Users/Roles")
    Rel(netc, orm, "CRUD")
    Rel(farec, orm, "CRUD")
    Rel(tripc, orm, "CRUD")
    Rel(reportc, orm, "read-heavy SQL")
    Rel(orm, pg, "SQL")
    Rel(tripc, firestore, "mirror trip/GPS status")
    Rel(notifc, firestore, "notification feed")
```

## 3. Deployment Architecture

```mermaid
graph TB
    subgraph "Client Devices"
        A1[Passenger Phones]
        A2[Driver Phones]
        A3[Admin Browser]
    end

    subgraph "Google Cloud / Firebase Project"
        FB1[Firebase Auth]
        FB2[Cloud Firestore]
        FB3[Cloud Messaging]
        FB4[Firebase Storage]
        FB5[Cloud Functions\noptional triggers]
    end

    subgraph "Application VPC (Docker Swarm / Kubernetes)"
        LB[Load Balancer / Ingress\nNGINX + TLS]
        API1[API Instance 1]
        API2[API Instance 2]
        API3[API Instance N]
        REDIS[(Redis\nCache/Rate-limit)]
    end

    subgraph "Managed PostgreSQL"
        PGP[(Primary)]
        PGR[(Read Replica)]
    end

    subgraph "Observability"
        PROM[Prometheus]
        GRAF[Grafana]
        SENTRY[Sentry / Crashlytics]
    end

    A1 & A2 & A3 -->|HTTPS| LB
    A1 & A2 & A3 -->|SDK| FB1 & FB2 & FB3 & FB4
    LB --> API1 & API2 & API3
    API1 & API2 & API3 --> REDIS
    API1 & API2 & API3 --> PGP
    API1 & API2 & API3 -.read.-> PGR
    API1 & API2 & API3 --> PROM
    PROM --> GRAF
    API1 & API2 & API3 --> SENTRY
    FB5 -.optional.-> API1
```

## 4. Data Flow — "Never Hardcode Stations" Principle

```mermaid
flowchart LR
    ADMIN[Admin adds/edits Station or Route] --> API[REST API validates & writes]
    API --> PG[(PostgreSQL)]
    API --> FSMIRROR[Firestore mirror\n'stations', 'routes' collections\nfor low-latency reads]
    PAXAPP[Passenger App] -->|on launch / pull-to-refresh| FSMIRROR
    PAXAPP -->|fallback / search| API
    PAXAPP --> LOCALCACHE[(Local Cache\nHive/SQLite)]
    LOCALCACHE -->|offline read| PAXAPP
```

**Key point:** The mobile client code contains **no station/route identifiers or names**. All UI lists (station pickers, route displays) are populated at runtime from Firestore (fast path, cached) or the REST API (authoritative path), backed by the local cache for offline resilience.

## 5. Environments

| Environment | Purpose | Firebase Project | API Host |
|---|---|---|---|
| `dev` | Local/dev testing | `gstms-dev` | `api-dev.transportation-app.local` (docker-compose) |
| `staging` | QA / UAT | `gstms-staging` | `api-staging.transportation-app.example.com` |
| `production` | Live | `gstms-prod` | `api.transportation-app.example.com` |

Flutter **flavors** (`dev`, `staging`, `prod`) select the correct `google-services.json` / `GoogleService-Info.plist`, API base URL, and Maps API key at build time. See [Deployment Guide](../08-deployment/DEPLOYMENT_GUIDE.md).

## 6. Cross-Cutting Concerns

| Concern | Implementation |
|---|---|
| Logging | Structured JSON logs (pino/winston), correlation/trace ID per request |
| Rate limiting | Redis-backed sliding window, per-IP + per-user |
| Caching | Redis for hot reads (active fare rules, route lookups); Firestore mirror for near-real-time station/route reads |
| Config management | `.env` per environment + `Settings` table for runtime-tunable values (no redeploy needed) |
| Feature flags | `Settings` table entries consumed by both API and clients |
