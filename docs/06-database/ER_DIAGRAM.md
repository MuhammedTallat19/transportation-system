# Entity-Relationship Diagram

This ERD matches the authoritative DDL in [`database/schema.sql`](../../database/schema.sql) exactly. See [Database Documentation](DATABASE_DOCUMENTATION.md) for column-level narrative and design rationale.

```mermaid
erDiagram
    GOVERNORATES ||--o{ STATIONS : "contains"
    GOVERNORATES ||--o{ ROUTES : "contains"
    GOVERNORATES ||--o{ VEHICLES : "operates in"
    GOVERNORATES ||--o{ USERS : "scopes"
    GOVERNORATES ||--o{ SETTINGS : "scopes (nullable = global)"

    ROLES ||--o{ USER_ROLES : "assigned via"
    USERS ||--o{ USER_ROLES : "holds"
    USERS ||--o| PASSENGERS : "extends"
    USERS ||--o| DRIVERS : "extends"

    STATIONS ||--o| PASSENGERS : "home_station (optional)"
    ROUTES ||--o{ ROUTE_STATIONS : "ordered stops"
    STATIONS ||--o{ ROUTE_STATIONS : "appears on"
    ROUTES ||--o{ VEHICLE_ROUTE_ASSIGNMENTS : "assigned"
    VEHICLES ||--o{ VEHICLE_ROUTE_ASSIGNMENTS : "assigned to"
    DRIVERS ||--o| VEHICLES : "assigned_vehicle / current_driver"

    ROUTES ||--o{ FARE_RULES : "priced by"
    ROUTES ||--o{ TRIPS : "executed as"
    STATIONS ||--o{ TRIPS : "start_station"
    STATIONS ||--o{ TRIPS : "dest_station"
    USERS ||--o{ TRIPS : "passenger_id"
    DRIVERS ||--o{ TRIPS : "driver_id"
    VEHICLES ||--o{ TRIPS : "vehicle_id"
    FARE_RULES ||--o{ TRIPS : "fare_rule_id"

    TRIPS ||--o{ TRIP_LOCATIONS : "GPS breadcrumbs"
    TRIPS ||--o| TRIP_HISTORY : "archived as"
    TRIPS ||--o{ FARES : "quoted as"
    TRIPS ||--o| TICKETS : "issued as"
    TRIPS ||--o{ PAYMENTS : "paid via"
    TRIPS ||--o| REVIEWS : "rated via"

    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ FAVORITES : "saves"
    STATIONS ||--o{ FAVORITES : "favorited as"
    USERS ||--o{ AUDIT_LOGS : "performs (actor)"

    GOVERNORATES {
        uuid id PK
        varchar name
        varchar name_ar
        char country_code
        boolean is_active
        varchar timezone
    }
    ROLES {
        smallserial id PK
        varchar code UK
        varchar description
    }
    USERS {
        uuid id PK
        varchar firebase_uid UK
        varchar full_name
        varchar email UK
        varchar phone_number UK
        varchar profile_photo_url
        varchar preferred_language
        user_status status
        uuid governorate_id FK
    }
    USER_ROLES {
        uuid user_id PK_FK
        smallint role_id PK_FK
        timestamptz assigned_at
    }
    PASSENGERS {
        uuid user_id PK_FK
        uuid home_station_id FK
        int loyalty_points
        int total_trips
        numeric average_rating_given
    }
    DRIVERS {
        uuid user_id PK_FK
        varchar license_number UK
        date license_expiry
        varchar national_id UK
        driver_status status
        uuid assigned_vehicle_id FK
        numeric average_rating
        int total_trips
        date hired_at
    }
    VEHICLES {
        uuid id PK
        uuid governorate_id FK
        varchar plate_number
        varchar vehicle_type
        smallint capacity
        smallint manufacture_year
        vehicle_status status
        date inspection_expiry
        uuid current_driver_id FK
    }
    STATIONS {
        uuid id PK
        uuid governorate_id FK
        varchar name
        varchar name_ar
        numeric latitude
        numeric longitude
        varchar address
        boolean is_active
        geography geog "generated"
    }
    ROUTES {
        uuid id PK
        uuid governorate_id FK
        varchar name
        varchar code
        boolean is_active
        numeric total_distance_km
    }
    ROUTE_STATIONS {
        uuid id PK
        uuid route_id FK
        uuid station_id FK
        smallint station_order
        numeric distance_from_start_km
    }
    VEHICLE_ROUTE_ASSIGNMENTS {
        uuid id PK
        uuid vehicle_id FK
        uuid route_id FK
        timestamptz assigned_from
        timestamptz assigned_to
        boolean is_current
    }
    FARE_RULES {
        uuid id PK
        uuid route_id FK
        fare_type fare_type
        int base_fare_cents
        int per_km_rate_cents
        int per_station_rate_cents
        int min_fare_cents
        int max_fare_cents
        char currency
        timestamptz effective_from
        timestamptz effective_to
        boolean is_active
        uuid drafted_by FK
        uuid approved_by FK
    }
    TRIPS {
        uuid id PK
        uuid passenger_id FK
        uuid driver_id FK
        uuid vehicle_id FK
        uuid route_id FK
        uuid start_station_id FK
        uuid dest_station_id FK
        uuid fare_rule_id FK
        int fare_amount_cents
        char currency
        trip_status status
        timestamptz requested_at
        timestamptz assigned_at
        timestamptz started_at
        timestamptz ended_at
        int estimated_duration_sec
        numeric estimated_distance_km
    }
    TRIP_LOCATIONS {
        bigserial id PK
        uuid trip_id FK
        numeric latitude
        numeric longitude
        numeric speed_kmh
        numeric heading_deg
        timestamptz recorded_at
    }
    TRIP_HISTORY {
        uuid id PK
        uuid trip_id FK UK
        uuid passenger_id
        uuid driver_id
        varchar route_name_snapshot
        varchar start_station_snapshot
        varchar dest_station_snapshot
        int fare_amount_cents
        trip_status final_status
        numeric distance_km
        int duration_sec
    }
    FARES {
        uuid id PK
        uuid trip_id FK
        uuid fare_rule_id FK
        int base_component_cents
        int distance_component_cents
        int station_component_cents
        int surcharge_cents
        int total_cents
        char currency
    }
    TICKETS {
        uuid id PK
        uuid trip_id FK UK
        varchar ticket_code UK
        ticket_status status
        timestamptz issued_at
        timestamptz validated_at
        timestamptz expires_at
    }
    PAYMENTS {
        uuid id PK
        uuid trip_id FK
        uuid payer_id FK
        int amount_cents
        char currency
        payment_method method
        payment_status status
        varchar provider_ref
        timestamptz paid_at
    }
    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        varchar title
        text body
        notification_channel channel
        jsonb data
        boolean is_read
    }
    REVIEWS {
        uuid id PK
        uuid trip_id FK UK
        uuid passenger_id FK
        uuid driver_id FK
        smallint rating
        text comment
    }
    FAVORITES {
        uuid id PK
        uuid user_id FK
        uuid station_id FK
        varchar label
    }
    SETTINGS {
        uuid id PK
        uuid governorate_id FK "nullable = global"
        varchar key
        jsonb value
        varchar description
    }
    AUDIT_LOGS {
        bigserial id PK
        uuid actor_user_id FK
        audit_action action
        varchar entity_type
        uuid entity_id
        jsonb before_state
        jsonb after_state
        inet ip_address
    }
```

## Key Cardinality Notes

- A **Governorate** scopes `stations`, `routes`, `vehicles`, `users`, and (optionally) `settings` — enabling multi-governorate expansion with zero schema change (BR-1).
- **`users` ↔ `roles`** is many-to-many via `user_roles`: a single account can, in principle, hold both `ADMIN` and `TRANSPORT_AUTHORITY`.
- **`passengers`** and **`drivers`** are table-per-subtype extensions of `users` (PK = FK = `user_id`), avoiding a wide, sparsely-populated `users` table.
- **`route_stations`** is the ordered join that makes the network fully dynamic: `station_order` + `distance_from_start_km` let the app render stations in the correct sequence and let the Fare Engine compute distance-based fares without a live Directions call.
- **`vehicle_route_assignments`** tracks which vehicle serves which route over time (`is_current` flags the active pairing); `vehicles.current_driver_id` and `drivers.assigned_vehicle_id` are denormalized "who's active right now" pointers for fast dashboard reads.
- **`fare_rules`** is versioned configuration (only one `is_active = TRUE` row per route, enforced by a partial unique index); **`fares`** is the computed line-item breakdown captured per trip — kept separate so editing a rule never retroactively changes an already-quoted trip (BR-6).
- **`trips`** is the central transactional entity, directly referencing passenger, driver, vehicle, route, both stations, and the fare rule that was active at request time.
- **`trip_history`** is an intentionally denormalized, immutable snapshot (station/route *names* as text) so historical records remain readable even if a station is later renamed.
