-- =====================================================================
-- Transportation App relational database schema
-- Full PostgreSQL Schema
-- Version: 1.0
-- Engine: PostgreSQL 15+
-- Naming convention: snake_case, singular logical entity / plural table name
-- All monetary values stored as INTEGER in smallest currency unit (e.g. piastres)
-- All IDs are UUID (gen_random_uuid()) unless noted
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";      -- for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "postgis";       -- optional, for geography types / distance calcs

-- =====================================================================
-- ENUM TYPES
-- =====================================================================
CREATE TYPE user_status AS ENUM ('ACTIVE', 'SUSPENDED', 'PENDING_VERIFICATION', 'DELETED');
CREATE TYPE vehicle_status AS ENUM ('ACTIVE', 'MAINTENANCE', 'INACTIVE', 'RETIRED');
CREATE TYPE driver_status AS ENUM ('OFF_DUTY', 'ON_DUTY', 'ON_TRIP', 'SUSPENDED');
CREATE TYPE trip_status AS ENUM ('REQUESTED', 'ASSIGNED', 'STARTED', 'COMPLETED', 'CANCELLED', 'NO_SHOW');
CREATE TYPE fare_type AS ENUM ('FIXED', 'DISTANCE_BASED', 'STATION_BASED', 'DYNAMIC');
CREATE TYPE payment_method AS ENUM ('CASH', 'CARD', 'WALLET', 'MOBILE_MONEY');
CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED');
CREATE TYPE ticket_status AS ENUM ('ISSUED', 'VALIDATED', 'EXPIRED', 'CANCELLED');
CREATE TYPE notification_channel AS ENUM ('PUSH', 'SMS', 'EMAIL', 'IN_APP');
CREATE TYPE audit_action AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'PUBLISH', 'APPROVE');

-- =====================================================================
-- 1. GOVERNORATES  (supports unlimited future expansion)
-- =====================================================================
CREATE TABLE governorates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(120) NOT NULL,
    name_ar         VARCHAR(120),
    country_code    CHAR(2) NOT NULL DEFAULT 'EG',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    timezone        VARCHAR(50) NOT NULL DEFAULT 'Africa/Cairo',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_governorates_name UNIQUE (name)
);

-- =====================================================================
-- 2. ROLES
-- =====================================================================
CREATE TABLE roles (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(30) NOT NULL UNIQUE,   -- PASSENGER, DRIVER, ADMIN, TRANSPORT_AUTHORITY
    description VARCHAR(255)
);

-- =====================================================================
-- 3. USERS  (base identity table, mirrors Firebase Auth UID)
-- =====================================================================
CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid        VARCHAR(128) NOT NULL UNIQUE,
    full_name           VARCHAR(150) NOT NULL,
    email               VARCHAR(150) UNIQUE,
    phone_number        VARCHAR(20)  UNIQUE,
    profile_photo_url   TEXT,
    preferred_language  VARCHAR(5) NOT NULL DEFAULT 'ar',
    status              user_status NOT NULL DEFAULT 'PENDING_VERIFICATION',
    governorate_id      UUID REFERENCES governorates(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_users_contact CHECK (email IS NOT NULL OR phone_number IS NOT NULL)
);
CREATE INDEX idx_users_governorate ON users(governorate_id);
CREATE INDEX idx_users_status ON users(status);

-- Many-to-many: users <-> roles (a user could theoretically hold multiple roles, e.g. Admin + Authority)
CREATE TABLE user_roles (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id     SMALLINT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, role_id)
);

-- =====================================================================
-- 4. PASSENGERS  (1-1 extension of users)
-- =====================================================================
CREATE TABLE passengers (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    home_station_id     UUID,  -- FK added after stations table created
    loyalty_points      INTEGER NOT NULL DEFAULT 0,
    total_trips         INTEGER NOT NULL DEFAULT 0,
    average_rating_given NUMERIC(2,1),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 5. DRIVERS  (1-1 extension of users)
-- =====================================================================
CREATE TABLE drivers (
    user_id                 UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    license_number          VARCHAR(50) NOT NULL UNIQUE,
    license_expiry          DATE NOT NULL,
    national_id             VARCHAR(30) NOT NULL UNIQUE,
    status                  driver_status NOT NULL DEFAULT 'OFF_DUTY',
    assigned_vehicle_id     UUID,  -- FK added after vehicles table created
    average_rating          NUMERIC(2,1) DEFAULT 5.0,
    total_trips             INTEGER NOT NULL DEFAULT 0,
    hired_at                DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_drivers_status ON drivers(status);

-- =====================================================================
-- 6. VEHICLES
-- =====================================================================
CREATE TABLE vehicles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    governorate_id      UUID NOT NULL REFERENCES governorates(id) ON DELETE RESTRICT,
    plate_number        VARCHAR(20) NOT NULL,
    vehicle_type        VARCHAR(30) NOT NULL,          -- BUS, MICROBUS, VAN
    capacity            SMALLINT NOT NULL CHECK (capacity > 0),
    manufacture_year    SMALLINT,
    status              vehicle_status NOT NULL DEFAULT 'ACTIVE',
    inspection_expiry    DATE,
    current_driver_id   UUID REFERENCES drivers(user_id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_vehicles_plate UNIQUE (governorate_id, plate_number)
);
CREATE INDEX idx_vehicles_governorate ON vehicles(governorate_id);
CREATE INDEX idx_vehicles_status ON vehicles(status);

ALTER TABLE drivers
    ADD CONSTRAINT fk_drivers_vehicle FOREIGN KEY (assigned_vehicle_id) REFERENCES vehicles(id) ON DELETE SET NULL;

-- =====================================================================
-- 7. STATIONS  (never hardcoded client-side; always queried live)
-- =====================================================================
CREATE TABLE stations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    governorate_id  UUID NOT NULL REFERENCES governorates(id) ON DELETE RESTRICT,
    name            VARCHAR(150) NOT NULL,
    name_ar         VARCHAR(150),
    latitude        NUMERIC(9,6) NOT NULL,
    longitude       NUMERIC(9,6) NOT NULL,
    address         VARCHAR(255),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_station_name_per_gov UNIQUE (governorate_id, name),
    CONSTRAINT chk_station_lat CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_station_lng CHECK (longitude BETWEEN -180 AND 180)
);
CREATE INDEX idx_stations_governorate ON stations(governorate_id);
CREATE INDEX idx_stations_active ON stations(is_active);
-- Geospatial index for "nearest station" queries (requires postgis extension, loaded above)
ALTER TABLE stations ADD COLUMN geog geography(Point, 4326)
    GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED;
CREATE INDEX idx_stations_geog ON stations USING gist (geog);

ALTER TABLE passengers
    ADD CONSTRAINT fk_passengers_home_station FOREIGN KEY (home_station_id) REFERENCES stations(id) ON DELETE SET NULL;

-- =====================================================================
-- 8. ROUTES
-- =====================================================================
CREATE TABLE routes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    governorate_id  UUID NOT NULL REFERENCES governorates(id) ON DELETE RESTRICT,
    name            VARCHAR(150) NOT NULL,
    code            VARCHAR(20) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    total_distance_km NUMERIC(6,2),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_route_code_per_gov UNIQUE (governorate_id, code)
);
CREATE INDEX idx_routes_governorate ON routes(governorate_id);
CREATE INDEX idx_routes_active ON routes(is_active);

-- =====================================================================
-- 9. ROUTE_STATIONS  (ordered join table: route <-> station, stores sequence)
-- =====================================================================
CREATE TABLE route_stations (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id                UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    station_id              UUID NOT NULL REFERENCES stations(id) ON DELETE RESTRICT,
    station_order           SMALLINT NOT NULL,          -- 1-based order along the route
    distance_from_start_km  NUMERIC(6,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_route_station_order UNIQUE (route_id, station_order),
    CONSTRAINT uq_route_station_pair UNIQUE (route_id, station_id),
    CONSTRAINT chk_station_order_positive CHECK (station_order > 0)
);
CREATE INDEX idx_route_stations_route ON route_stations(route_id, station_order);
CREATE INDEX idx_route_stations_station ON route_stations(station_id);

-- Vehicle-to-route assignment (many vehicles can rotate on one route over time)
CREATE TABLE vehicle_route_assignments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id      UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    route_id        UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    assigned_from   TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_to     TIMESTAMPTZ,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX idx_vra_current ON vehicle_route_assignments(route_id, is_current);

-- =====================================================================
-- 10. FARE_RULES  (versioned, admin-configurable, no app redeploy needed)
-- =====================================================================
CREATE TABLE fare_rules (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id            UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    fare_type           fare_type NOT NULL,
    base_fare_cents     INTEGER NOT NULL DEFAULT 0,
    per_km_rate_cents   INTEGER NOT NULL DEFAULT 0,
    per_station_rate_cents INTEGER NOT NULL DEFAULT 0,
    min_fare_cents      INTEGER NOT NULL DEFAULT 0,
    max_fare_cents      INTEGER,
    currency            CHAR(3) NOT NULL DEFAULT 'EGP',
    effective_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to        TIMESTAMPTZ,
    is_active           BOOLEAN NOT NULL DEFAULT FALSE,   -- becomes true only after Authority approval
    drafted_by          UUID REFERENCES users(id),
    approved_by         UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_fare_amounts_nonneg CHECK (base_fare_cents >= 0 AND per_km_rate_cents >= 0 AND per_station_rate_cents >= 0)
);
CREATE INDEX idx_fare_rules_route_active ON fare_rules(route_id, is_active);
-- Ensures only one active fare rule per route at any time (partial unique index)
CREATE UNIQUE INDEX uq_one_active_fare_per_route ON fare_rules(route_id) WHERE is_active = TRUE;

-- =====================================================================
-- 11. TRIPS
-- =====================================================================
CREATE TABLE trips (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id        UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    driver_id           UUID REFERENCES drivers(user_id) ON DELETE SET NULL,
    vehicle_id          UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    route_id            UUID NOT NULL REFERENCES routes(id) ON DELETE RESTRICT,
    start_station_id    UUID NOT NULL REFERENCES stations(id) ON DELETE RESTRICT,
    dest_station_id     UUID NOT NULL REFERENCES stations(id) ON DELETE RESTRICT,
    fare_rule_id        UUID NOT NULL REFERENCES fare_rules(id) ON DELETE RESTRICT,
    fare_amount_cents   INTEGER NOT NULL,
    currency            CHAR(3) NOT NULL DEFAULT 'EGP',
    status              trip_status NOT NULL DEFAULT 'REQUESTED',
    requested_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_at         TIMESTAMPTZ,
    started_at          TIMESTAMPTZ,
    ended_at            TIMESTAMPTZ,
    estimated_duration_sec INTEGER,
    estimated_distance_km  NUMERIC(6,2),
    cancellation_reason  VARCHAR(255),
    CONSTRAINT chk_trip_stations_diff CHECK (start_station_id <> dest_station_id)
);
CREATE INDEX idx_trips_passenger ON trips(passenger_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_route ON trips(route_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_requested_at ON trips(requested_at);

-- =====================================================================
-- 12. TRIP_LOCATIONS  (GPS breadcrumb trail per trip; high write volume)
-- =====================================================================
CREATE TABLE trip_locations (
    id          BIGSERIAL PRIMARY KEY,
    trip_id     UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    latitude    NUMERIC(9,6) NOT NULL,
    longitude   NUMERIC(9,6) NOT NULL,
    speed_kmh   NUMERIC(5,2),
    heading_deg NUMERIC(5,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_trip_locations_trip_time ON trip_locations(trip_id, recorded_at);
-- Partitioning recommended by month at scale (see Database Documentation §7)

-- =====================================================================
-- 13. TRIP_HISTORY  (immutable snapshot once a trip is finalized)
-- =====================================================================
CREATE TABLE trip_history (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id             UUID NOT NULL UNIQUE REFERENCES trips(id) ON DELETE RESTRICT,
    passenger_id        UUID NOT NULL,
    driver_id           UUID,
    route_name_snapshot VARCHAR(150) NOT NULL,
    start_station_snapshot VARCHAR(150) NOT NULL,
    dest_station_snapshot  VARCHAR(150) NOT NULL,
    fare_amount_cents   INTEGER NOT NULL,
    final_status        trip_status NOT NULL,
    distance_km         NUMERIC(6,2),
    duration_sec        INTEGER,
    completed_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_trip_history_passenger ON trip_history(passenger_id);
CREATE INDEX idx_trip_history_completed_at ON trip_history(completed_at);

-- =====================================================================
-- 14. FARES  (computed/quoted fare snapshots — distinct from fare_rules config)
-- =====================================================================
CREATE TABLE fares (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id             UUID REFERENCES trips(id) ON DELETE CASCADE,
    fare_rule_id        UUID NOT NULL REFERENCES fare_rules(id),
    base_component_cents INTEGER NOT NULL DEFAULT 0,
    distance_component_cents INTEGER NOT NULL DEFAULT 0,
    station_component_cents  INTEGER NOT NULL DEFAULT 0,
    surcharge_cents     INTEGER NOT NULL DEFAULT 0,
    total_cents         INTEGER NOT NULL,
    currency            CHAR(3) NOT NULL DEFAULT 'EGP',
    quoted_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_fares_trip ON fares(trip_id);

-- =====================================================================
-- 15. TICKETS
-- =====================================================================
CREATE TABLE tickets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL UNIQUE REFERENCES trips(id) ON DELETE CASCADE,
    ticket_code     VARCHAR(20) NOT NULL UNIQUE,   -- human/QR-friendly reference
    status          ticket_status NOT NULL DEFAULT 'ISSUED',
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    validated_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ
);
CREATE INDEX idx_tickets_status ON tickets(status);

-- =====================================================================
-- 16. PAYMENTS
-- =====================================================================
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE RESTRICT,
    payer_id        UUID NOT NULL REFERENCES users(id),
    amount_cents    INTEGER NOT NULL CHECK (amount_cents >= 0),
    currency        CHAR(3) NOT NULL DEFAULT 'EGP',
    method          payment_method NOT NULL DEFAULT 'CASH',
    status          payment_status NOT NULL DEFAULT 'PENDING',
    provider_ref    VARCHAR(100),
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_trip ON payments(trip_id);
CREATE INDEX idx_payments_payer ON payments(payer_id);
CREATE INDEX idx_payments_status ON payments(status);

-- =====================================================================
-- 17. NOTIFICATIONS
-- =====================================================================
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(150) NOT NULL,
    body            TEXT NOT NULL,
    channel         notification_channel NOT NULL DEFAULT 'PUSH',
    data            JSONB,                 -- deep-link payload (tripId, screen, etc.)
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read);

-- =====================================================================
-- 18. REVIEWS
-- =====================================================================
CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL UNIQUE REFERENCES trips(id) ON DELETE CASCADE,
    passenger_id    UUID NOT NULL REFERENCES users(id),
    driver_id       UUID REFERENCES drivers(user_id),
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_reviews_driver ON reviews(driver_id);

-- =====================================================================
-- 19. FAVORITES  (favorite stations per passenger)
-- =====================================================================
CREATE TABLE favorites (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    station_id      UUID NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
    label           VARCHAR(50),           -- e.g. "Home", "Work"
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_favorite_user_station UNIQUE (user_id, station_id)
);
CREATE INDEX idx_favorites_user ON favorites(user_id);

-- =====================================================================
-- 20. SETTINGS  (system-wide/governorate-wide configurable key-value settings)
-- =====================================================================
CREATE TABLE settings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    governorate_id  UUID REFERENCES governorates(id) ON DELETE CASCADE,  -- NULL = global default
    key             VARCHAR(100) NOT NULL,
    value           JSONB NOT NULL,
    description     VARCHAR(255),
    updated_by      UUID REFERENCES users(id),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_settings_key_scope UNIQUE (governorate_id, key)
);

-- =====================================================================
-- 21. AUDIT_LOGS  (immutable trail of all configuration changes)
-- =====================================================================
CREATE TABLE audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    actor_user_id   UUID REFERENCES users(id),
    action          audit_action NOT NULL,
    entity_type     VARCHAR(50) NOT NULL,   -- e.g. 'FareRule', 'Station', 'Route'
    entity_id       UUID,
    before_state    JSONB,
    after_state     JSONB,
    ip_address      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- =====================================================================
-- TRIGGERS: auto-update updated_at columns
-- =====================================================================
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_users BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_vehicles BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_stations BEFORE UPDATE ON stations
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_routes BEFORE UPDATE ON routes
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_drivers BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- =====================================================================
-- SEED DATA — ROLES
-- =====================================================================
INSERT INTO roles (code, description) VALUES
('PASSENGER', 'End-user booking trips'),
('DRIVER', 'Operates a vehicle on an assigned route'),
('ADMIN', 'Manages network configuration for a governorate'),
('TRANSPORT_AUTHORITY', 'Regulatory oversight and fare approval');

-- =====================================================================
-- SAMPLE DATA — single governorate seed (Ismailia used as illustrative example)
-- =====================================================================
INSERT INTO governorates (id, name, name_ar, country_code, timezone)
VALUES ('11111111-1111-1111-1111-111111111111', 'Ismailia', 'الإسماعيلية', 'EG', 'Africa/Cairo');

-- Sample stations
INSERT INTO stations (id, governorate_id, name, name_ar, latitude, longitude, address) VALUES
('22222222-2222-2222-2222-222222222201', '11111111-1111-1111-1111-111111111111', 'Central Station', 'المحطة المركزية', 30.5965, 32.2715, 'Downtown Ismailia'),
('22222222-2222-2222-2222-222222222202', '11111111-1111-1111-1111-111111111111', 'University Gate', 'بوابة الجامعة', 30.6060, 32.2610, 'Suez Canal University Rd'),
('22222222-2222-2222-2222-222222222203', '11111111-1111-1111-1111-111111111111', 'Lake District', 'حي البحيرة', 30.5830, 32.2790, 'Lake District'),
('22222222-2222-2222-2222-222222222204', '11111111-1111-1111-1111-111111111111', 'Industrial Zone', 'المنطقة الصناعية', 30.6180, 32.2450, 'Industrial Zone Rd');

-- Sample route
INSERT INTO routes (id, governorate_id, name, code, total_distance_km)
VALUES ('33333333-3333-3333-3333-333333333301', '11111111-1111-1111-1111-111111111111', 'Central - Industrial Line', 'R-01', 9.4);

-- Ordered route stations
INSERT INTO route_stations (route_id, station_id, station_order, distance_from_start_km) VALUES
('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222201', 1, 0.0),
('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222202', 2, 2.8),
('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222203', 3, 5.6),
('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222204', 4, 9.4);

-- Sample fare rule (distance-based, active)
INSERT INTO fare_rules (id, route_id, fare_type, base_fare_cents, per_km_rate_cents, min_fare_cents, is_active)
VALUES ('44444444-4444-4444-4444-444444444401', '33333333-3333-3333-3333-333333333301', 'DISTANCE_BASED', 500, 150, 500, TRUE);

-- Sample vehicle
INSERT INTO vehicles (id, governorate_id, plate_number, vehicle_type, capacity, manufacture_year, status)
VALUES ('55555555-5555-5555-5555-555555555501', '11111111-1111-1111-1111-111111111111', 'ISM-1234', 'MICROBUS', 14, 2021, 'ACTIVE');

INSERT INTO vehicle_route_assignments (vehicle_id, route_id, is_current)
VALUES ('55555555-5555-5555-5555-555555555501', '33333333-3333-3333-3333-333333333301', TRUE);

-- Sample users (passenger + driver + admin)
INSERT INTO users (id, firebase_uid, full_name, email, phone_number, governorate_id, status) VALUES
('66666666-6666-6666-6666-666666666601', 'fb-uid-passenger-01', 'Sara Ahmed', 'sara.ahmed@example.com', '+201001234567', '11111111-1111-1111-1111-111111111111', 'ACTIVE'),
('66666666-6666-6666-6666-666666666602', 'fb-uid-driver-01', 'Mohamed Ali', 'mohamed.ali@example.com', '+201007654321', '11111111-1111-1111-1111-111111111111', 'ACTIVE'),
('66666666-6666-6666-6666-666666666603', 'fb-uid-admin-01', 'Nourhan Admin', 'admin@gtms.gov.eg', '+201009998888', '11111111-1111-1111-1111-111111111111', 'ACTIVE');

INSERT INTO user_roles (user_id, role_id) VALUES
('66666666-6666-6666-6666-666666666601', (SELECT id FROM roles WHERE code = 'PASSENGER')),
('66666666-6666-6666-6666-666666666602', (SELECT id FROM roles WHERE code = 'DRIVER')),
('66666666-6666-6666-6666-666666666603', (SELECT id FROM roles WHERE code = 'ADMIN'));

INSERT INTO passengers (user_id, home_station_id) VALUES
('66666666-6666-6666-6666-666666666601', '22222222-2222-2222-2222-222222222201');

INSERT INTO drivers (user_id, license_number, license_expiry, national_id, assigned_vehicle_id, status) VALUES
('66666666-6666-6666-6666-666666666602', 'DRV-LIC-0001', '2027-05-01', '29001011234567', '55555555-5555-5555-5555-555555555501', 'OFF_DUTY');

UPDATE vehicles SET current_driver_id = '66666666-6666-6666-6666-666666666602'
WHERE id = '55555555-5555-5555-5555-555555555501';

-- Sample trip (completed) to demonstrate full lifecycle linkage
INSERT INTO trips (id, passenger_id, driver_id, vehicle_id, route_id, start_station_id, dest_station_id,
                    fare_rule_id, fare_amount_cents, status, requested_at, assigned_at, started_at, ended_at,
                    estimated_duration_sec, estimated_distance_km)
VALUES ('77777777-7777-7777-7777-777777777701',
        '66666666-6666-6666-6666-666666666601',
        '66666666-6666-6666-6666-666666666602',
        '55555555-5555-5555-5555-555555555501',
        '33333333-3333-3333-3333-333333333301',
        '22222222-2222-2222-2222-222222222201',
        '22222222-2222-2222-2222-222222222204',
        '44444444-4444-4444-4444-444444444401',
        1910, 'COMPLETED',
        now() - interval '2 hours', now() - interval '115 minutes',
        now() - interval '110 minutes', now() - interval '90 minutes',
        1200, 9.4);

INSERT INTO fares (trip_id, fare_rule_id, base_component_cents, distance_component_cents, total_cents)
VALUES ('77777777-7777-7777-7777-777777777701', '44444444-4444-4444-4444-444444444401', 500, 1410, 1910);

INSERT INTO tickets (trip_id, ticket_code, status, validated_at)
VALUES ('77777777-7777-7777-7777-777777777701', 'TCK-000001', 'VALIDATED', now() - interval '110 minutes');

INSERT INTO payments (trip_id, payer_id, amount_cents, method, status, paid_at)
VALUES ('77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666601', 1910, 'CASH', 'COMPLETED', now() - interval '90 minutes');

INSERT INTO trip_history (trip_id, passenger_id, driver_id, route_name_snapshot, start_station_snapshot,
                           dest_station_snapshot, fare_amount_cents, final_status, distance_km, duration_sec)
VALUES ('77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666601', '66666666-6666-6666-6666-666666666602',
        'Central - Industrial Line', 'Central Station', 'Industrial Zone', 1910, 'COMPLETED', 9.4, 1200);

INSERT INTO reviews (trip_id, passenger_id, driver_id, rating, comment)
VALUES ('77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666601', '66666666-6666-6666-6666-666666666602', 5, 'Smooth ride, on time.');

INSERT INTO favorites (user_id, station_id, label)
VALUES ('66666666-6666-6666-6666-666666666601', '22222222-2222-2222-2222-222222222201', 'Home');

INSERT INTO settings (governorate_id, key, value, description) VALUES
('11111111-1111-1111-1111-111111111111', 'gps_broadcast_interval_seconds', '5', 'How often driver app pushes GPS updates'),
('11111111-1111-1111-1111-111111111111', 'cancellation_window_minutes', '5', 'Minutes after request within which a passenger may cancel free of charge');

-- =====================================================================
-- VIEWS (convenience for reporting layer)
-- =====================================================================
CREATE OR REPLACE VIEW v_route_station_sequence AS
SELECT r.id AS route_id, r.name AS route_name, rs.station_order, s.id AS station_id, s.name AS station_name,
       rs.distance_from_start_km
FROM routes r
JOIN route_stations rs ON rs.route_id = r.id
JOIN stations s ON s.id = rs.station_id
ORDER BY r.id, rs.station_order;

CREATE OR REPLACE VIEW v_daily_revenue AS
SELECT date_trunc('day', p.paid_at) AS day, r.governorate_id, SUM(p.amount_cents) AS total_cents, COUNT(*) AS payment_count
FROM payments p
JOIN trips t ON t.id = p.trip_id
JOIN routes r ON r.id = t.route_id
WHERE p.status = 'COMPLETED'
GROUP BY 1, 2;

-- =====================================================================
-- END OF SCHEMA
-- =====================================================================
