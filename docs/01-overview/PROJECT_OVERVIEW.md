# Project Overview

## 1. Vision

Public transport in a governorate today is fragmented: passengers rely on word of mouth to know which minibus/route goes where, drivers have no digital dispatch, and the transport authority has no real-time visibility into the network. **Transportation App** digitizes the entire governorate transport network — stations, routes, vehicles, drivers, and fares — into a single dynamic platform accessible from a mobile app.

The defining design principle is: **the network is data, not code.** A new station, a new route, a fare change, or an entirely new governorate must be addable through the Admin Dashboard with **no app store release**.

## 2. Problem Statement

| Problem | Impact |
|---|---|
| Passengers don't know which vehicle/route serves their trip | Wasted time, missed transport, poor experience |
| Fares are inconsistent / negotiated informally | Overcharging, disputes, no auditability |
| No visibility into vehicle location or ETA | Passengers wait blindly at stations |
| Drivers have no formal trip/route assignment system | Inefficient vehicle utilization |
| Transport Authority lacks real operational data | No basis for planning, subsidies, or route optimization |

## 3. Solution Summary

Transportation App provides:

- A **Passenger App** to search stations, compute fares instantly, and track vehicles live.
- A **Driver App** to receive assigned routes, start/end trips, and broadcast GPS.
- An **Admin Dashboard** for the Administrator to manage the entire master data set (stations, routes, vehicles, drivers, fare rules).
- A **Transport Authority Console** (a permission tier within the same dashboard) for oversight, analytics, and fare-policy approval.
- A **Fare Engine** that computes trip cost using pluggable strategies (fixed, distance-based, station-count-based, or future dynamic/surge pricing) — configured entirely via database records.

## 4. Scope

### In Scope (v1)
- Single governorate, multi-route, multi-station network.
- Passenger trip search (start → destination), fare calculation, live tracking, ratings, favorites, trip history.
- Driver trip lifecycle (assigned → started → in-progress → completed).
- Admin CRUD for all master data + live fleet map + reports/analytics.
- REST API + Firebase real-time layer.
- Push notifications, in-app trip sharing.

### Out of Scope (v1, planned for later — see [Future Features](../12-roadmap/FUTURE_FEATURES.md))
- Multi-governorate routing (cross-governorate trips).
- In-app wallet / online payment gateway integration (v1 supports cash + optional simple digital wallet ledger).
- Dynamic surge pricing algorithm (data model supports it; algorithm ships in v2).
- Predictive ETA using ML (v1 uses Google Directions API ETA + traffic).

## 5. Stakeholders

| Stakeholder | Interest |
|---|---|
| **Passengers** | Fast, accurate, transparent trip planning and fares |
| **Drivers** | Simple app to receive trips and report status |
| **Administrators** | Full control of network master data without engineering involvement |
| **Transport Authority** | Governorate-wide analytics, policy control, compliance |
| **Governorate Government** | Improved public transport quality of service, data-driven planning |
| **Development Team** | Clear specs to build against without ambiguity |

## 6. User Personas

### Passenger — "Mona, 27, office worker"
Needs to get from her neighborhood to downtown daily. Wants to know the fare before boarding, and wants to know when the vehicle will arrive.

### Driver — "Ahmed, 41, minibus driver"
Drives a fixed route daily. Wants a simple app: see today's route, tap Start Trip, tap End Trip, get paid fairly, no complex UI.

### Administrator — "Rania, 33, dispatch officer"
Manages 40 routes and 300 stations. Needs to add a new station in 30 seconds without calling a developer.

### Transport Authority — "Eng. Tarek, 50, governorate transport director"
Wants a monthly report: trips per route, revenue, most congested stations, complaint rates — to plan subsidies and route expansions.

## 7. Success Metrics (KPIs)

| KPI | Target (Year 1) |
|---|---|
| Daily active passengers | 10,000+ |
| Average fare calculation time | < 300 ms (p95) |
| Trip GPS update latency | < 5 seconds |
| Admin time to add a new station | < 1 minute |
| Crash-free session rate | > 99.5% |
| API uptime | > 99.9% |

## 8. Governorate Expansion Model

Although v1 targets a **single governorate**, the schema and app include a `governorates` table and a `governorate_id` foreign key on every network entity (stations, routes, vehicles) from day one. This means:

- Adding governorate #2 is a **data operation**, not a re-architecture.
- The Passenger App can later support a governorate switcher without any schema migration.

See [Database Documentation](../06-database/DATABASE_DOCUMENTATION.md) and [Roadmap](../12-roadmap/ROADMAP.md) for details.
