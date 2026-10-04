# Future Features (Backlog)

Items below are intentionally **not** in v1 scope but are supported by the current data model/architecture without requiring a fundamental redesign.

## Payments
- Full digital wallet with top-up (card/mobile money) and in-app balance deduction per trip.
- Third-party payment gateway integration (`payments.method` enum already includes `CARD`, `WALLET`, `MOBILE_MONEY`).
- Fare splitting for shared trips.

## Routing & Fare Intelligence
- Multi-leg journeys with automatic transfer suggestions when no single route connects start/destination.
- Dynamic/surge pricing engine activation (`DYNAMIC` fare rule type, config-driven multiplier sourced from live traffic/demand index).
- Predictive ETA using historical trip data + ML instead of relying solely on Google Directions API.
- Route optimization suggestions for the Transport Authority based on ridership heatmaps.

## Multi-Governorate & Intercity
- Cross-governorate trip search (requires a "governorate adjacency"/transfer model on top of existing `governorate_id` scoping).
- National-level Transport Authority console aggregating multiple governorates.

## Passenger Experience
- In-app trip scheduling / reservations for off-peak planning.
- Accessibility mode (larger touch targets, screen-reader optimized flows, wheelchair-accessible vehicle filter).
- Loyalty/rewards program (`passengers.loyalty_points` column already reserved).
- Group/family accounts.

## Driver Experience
- Driver incentive dashboard (bonus for on-time performance, high ratings).
- In-app fuel/maintenance expense logging tied to `vehicles`.
- Voice-guided navigation overlay.

## Admin & Authority
- Automated anomaly detection on fare disputes / audit logs.
- Configurable approval workflows beyond the current Admin-drafts → Authority-approves fare model (e.g., multi-stage approval for large network changes).
- Public open-data export (anonymized ridership statistics) for civic transparency initiatives.

## Platform
- Native iOS feature parity validation suite.
- Offline-first trip history sync (already partially supported via local cache — extend to full offline queueing of ratings/favorites while disconnected).
- WebSocket-based alternative to Firestore listeners for self-hosted deployments that avoid vendor lock-in (architectural escape hatch, not currently planned).

## Explicitly Out of Scope (Not Currently Planned)
- Freight/cargo logistics.
- Ride-hailing/on-demand point-to-point dispatch (this system is fixed-route public transport, not a taxi-hailing platform).
