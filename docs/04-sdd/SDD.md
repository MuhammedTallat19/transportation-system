# Software Design Document (SDD)

## 1. Design Goals

1. **Zero hardcoded network data** — every station/route/fare is data-driven.
2. **Clean Architecture** in all Flutter clients — domain layer has no dependency on Flutter, Firebase, or HTTP packages.
3. **Single source of truth per concern** — PostgreSQL for relational/billing data, Firestore for realtime/ephemeral data (live GPS, presence, chat-like notifications).
4. **Extensibility over configuration** — new fare rule types, governorates, and vehicle types added via enums/JSONB config, not schema migrations.

## 2. Module Decomposition

```mermaid
graph TD
    subgraph Mobile Clients
        PAX[Passenger App]
        DRV[Driver App]
    end
    subgraph Shared
        CORE[core: network, error, theming, di]
        SHARED[shared: widgets, models, utils]
    end
    subgraph Backend Modules
        AUTHM[Auth Module]
        NETM[Network Module\nStations/Routes]
        FAREM[Fare Engine Module]
        TRIPM[Trip Module]
        NOTIFM[Notification Module]
        REPORTM[Reporting Module]
    end
    PAX --> CORE
    DRV --> CORE
    PAX --> SHARED
    DRV --> SHARED
    PAX -.REST/Firestore.-> AUTHM & NETM & FAREM & TRIPM & NOTIFM
    DRV -.REST/Firestore.-> AUTHM & TRIPM & NOTIFM
    TRIPM --> FAREM
    TRIPM --> NETM
    REPORTM --> TRIPM
```

## 3. Class Design (Core Domain)

```mermaid
classDiagram
    class Governorate {
        +UUID id
        +String name
        +String nameAr
        +bool isActive
    }
    class Station {
        +UUID id
        +UUID governorateId
        +String name
        +double latitude
        +double longitude
        +bool isActive
    }
    class Route {
        +UUID id
        +UUID governorateId
        +String name
        +UUID fareRuleId
        +bool isActive
        +getOrderedStations() List~Station~
    }
    class RouteStation {
        +UUID routeId
        +UUID stationId
        +int sequenceOrder
        +double distanceFromStartKm
    }
    class Vehicle {
        +UUID id
        +String plateNumber
        +int capacity
        +VehicleType type
        +UUID currentDriverId
    }
    class Driver {
        +UUID id
        +UUID userId
        +String licenseNumber
        +double averageRating
    }
    class Trip {
        +UUID id
        +UUID routeId
        +UUID vehicleId
        +UUID driverId
        +TripStatus status
        +DateTime startedAt
        +DateTime endedAt
        +start()
        +end()
        +cancel()
    }
    class FareRule {
        +UUID id
        +UUID routeId
        +FareRuleType type
        +JSON config
        +DateTime validFrom
        +DateTime validTo
        +calculate(startStation, destStation, distanceKm) Money
    }
    class FareEngine {
        <<service>>
        +resolveRoute(startStationId, destStationId) Route
        +calculateFare(route, startStation, destStation) FareResult
    }

    Governorate "1" --> "many" Station
    Governorate "1" --> "many" Route
    Route "1" --> "many" RouteStation
    RouteStation "many" --> "1" Station
    Route "1" --> "1" FareRule
    Route "1" --> "many" Trip
    Vehicle "1" --> "many" Trip
    Driver "1" --> "many" Trip
    FareEngine ..> FareRule : uses
    FareEngine ..> Route : uses
```

## 4. Fare Engine — Strategy Pattern

The Fare Engine is designed with the **Strategy Pattern** so new pricing models never require schema or app changes — only a new `rule_type` implementation registered in the backend and a `config` JSONB payload.

```mermaid
classDiagram
    class IFareStrategy {
        <<interface>>
        +calculate(context: FareContext) Money
    }
    class FixedFareStrategy {
        +calculate(context) Money
    }
    class DistanceFareStrategy {
        +calculate(context) Money
    }
    class StationCountFareStrategy {
        +calculate(context) Money
    }
    class DynamicFareStrategy {
        +calculate(context) Money
    }
    class FareStrategyFactory {
        +getStrategy(ruleType) IFareStrategy
    }
    IFareStrategy <|.. FixedFareStrategy
    IFareStrategy <|.. DistanceFareStrategy
    IFareStrategy <|.. StationCountFareStrategy
    IFareStrategy <|.. DynamicFareStrategy
    FareStrategyFactory ..> IFareStrategy
```

**Config examples (`fare_rules.config` JSONB):**

```json
// FIXED
{ "amount_minor": 500 }

// DISTANCE
{ "base_amount_minor": 200, "per_km_minor": 75, "min_fare_minor": 300 }

// STATION_COUNT
{ "per_station_minor": 100, "min_stations_fare_minor": 200 }

// DYNAMIC (v2 — surge)
{ "base_strategy": "DISTANCE", "surge_multiplier_source": "traffic_index", "max_multiplier": 2.0 }
```

## 5. Sequence Diagram — Trip Search & Fare Calculation

```mermaid
sequenceDiagram
    actor P as Passenger
    participant App as Passenger App
    participant API as REST API
    participant NET as Network Module
    participant FARE as Fare Engine
    participant DB as PostgreSQL
    participant MAPS as Google Directions API

    P->>App: Select start & destination station
    App->>API: POST /trips/search {start_id, dest_id}
    API->>NET: resolveRoutes(start_id, dest_id)
    NET->>DB: SELECT routes via RouteStations ordering
    DB-->>NET: matching route(s)
    NET-->>API: Route candidates
    API->>FARE: calculateFare(route, start, dest)
    FARE->>DB: fetch active FareRule
    FARE-->>API: FareResult {amount, currency}
    API->>MAPS: getETA(start, dest, traffic=true)
    MAPS-->>API: duration, distance
    API-->>App: {route, fare, eta, distanceKm}
    App-->>P: Show fare + ETA + map
```

## 6. Sequence Diagram — Driver Trip Lifecycle & Live GPS

```mermaid
sequenceDiagram
    actor D as Driver
    participant DApp as Driver App
    participant API as REST API
    participant FS as Firestore
    participant PApp as Passenger App
    actor Pa as Passenger

    D->>DApp: Tap "Start Trip"
    DApp->>API: POST /trips/{id}/start
    API->>FS: create TripLocations/{tripId} doc
    API-->>DApp: 200 OK, status=in_progress

    loop every 5-10s while trip active
        DApp->>API: POST /trips/{id}/location {lat,lng,heading,speed}
        API->>FS: update TripLocations/{tripId}
        FS-->>PApp: realtime push (listener)
        PApp-->>Pa: Vehicle marker moves on map
    end

    D->>DApp: Tap "End Trip"
    DApp->>API: POST /trips/{id}/end
    API->>API: snapshot TripHistory, aggregate stats
    API-->>DApp: 200 OK, status=completed
```

## 7. Presentation Layer Design (Flutter, Riverpod)

Each feature follows: **UI (Widgets) → Controller/Provider (Riverpod `AsyncNotifier`) → UseCase (domain) → Repository (interface, domain) → RepositoryImpl (data) → RemoteDataSource (REST/Firestore)**.

```mermaid
classDiagram
    class TripSearchScreen {
        <<Widget>>
    }
    class TripSearchController {
        <<AsyncNotifier>>
        +search(startId, destId)
    }
    class SearchTripUseCase {
        +call(startId, destId) FareResult
    }
    class TripRepository {
        <<interface>>
        +searchTrip(startId, destId) FareResult
    }
    class TripRepositoryImpl {
        +searchTrip(startId, destId) FareResult
    }
    class TripRemoteDataSource {
        +postSearch(startId, destId) Json
    }
    TripSearchScreen --> TripSearchController
    TripSearchController --> SearchTripUseCase
    SearchTripUseCase --> TripRepository
    TripRepository <|.. TripRepositoryImpl
    TripRepositoryImpl --> TripRemoteDataSource
```

## 8. Error Handling Design

- Domain layer returns `Either<Failure, T>` (via `fpdart` or `dartz`) — no exceptions cross into the presentation layer.
- API layer returns RFC-7807-style problem responses (`{ "type", "title", "status", "detail", "traceId" }`).
- All Firestore listener errors are caught and mapped to a `ConnectivityFailure` / `PermissionFailure` shown via a shared `ErrorBanner` widget.

## 9. Caching & Offline Strategy

| Data | Cache Strategy |
|---|---|
| Stations/Routes | Cached locally (Hive/SQLite) with `last_synced_at`; refreshed on app start + pull-to-refresh; served from cache if offline |
| Active Fare Rules | Cached with TTL of 1 hour |
| Trip live location | Not cached (realtime only); last known shown greyed-out if disconnected |
| User profile | Cached, synced on login/update |

## 10. Design Decisions & Rationale (ADR summary)

| Decision | Rationale |
|---|---|
| PostgreSQL as relational SoT, Firestore for realtime | Firestore excels at low-latency pub/sub (GPS); PostgreSQL gives strong relational integrity + reporting SQL for billing/analytics |
| Money as integer minor units | Avoids floating-point rounding bugs (NFR-18) |
| Strategy pattern for Fare Engine | Enables new pricing models without redeploying mobile apps |
| Riverpod over Bloc/Provider | Compile-time safety, less boilerplate, first-class async support, easy testing via `ProviderContainer` overrides |
| Clean Architecture | Testability, separation of concerns, framework independence of business logic |
