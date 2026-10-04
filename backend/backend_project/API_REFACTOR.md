# Function-Based DRF API

The resource API now uses DRF `@api_view` functions. Resource URLs, HTTP
methods, serializers, JWT authentication defaults, response shapes, and the
router-style API root are retained. Format suffixes such as `.json` remain
available on resource URLs.

## Dependency flow

- CRUD resources: `URL -> function API view -> shared CRUD helper -> ORM
  QuerySet + serializer -> model`.
- Trip search and creation: `URL -> function API view -> dependency provider ->
  TripService -> TripRepository -> models`.
- The trip service receives its repository through its constructor. The
  provider is the production composition point and can be replaced in tests.
- Simple CRUD endpoints use explicit `QuerySet` and serializer arguments to
  the shared API helpers; separate per-model services/repositories would only
  duplicate DRF/ORM behavior.

## Endpoint mapping

All resource endpoints use the configured JWT authentication class. Every
resource endpoint requires `IsAuthenticated`; registration alone uses
`AllowAny`. The project does not currently configure role-based or
object-level permissions, so this refactor preserves the existing
authenticated-user access policy rather than inventing an admin-only rule.

| Endpoint | Methods | Permissions | Validation / service | Database and response |
|---|---|---|---|---|
| `/api/` | GET | Authenticated | API-root function reverses the resource list routes | No database access; returns the resource-to-URL mapping |
| `/api/register/` | POST | Public (`AllowAny`) | `UserRegistrationSerializer`; creates a passenger account | Creates one user; returns `UserSerializer` data with HTTP 201. Invalid input returns serializer errors |
| `/api/stations/`, `/api/stations/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `StationSerializer`; shared CRUD helpers | Reads active stations only; normal create/update/delete ORM operations. Collection/detail responses match the prior ViewSet |
| `/api/routes/`, `/api/routes/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `RouteSerializer`; shared CRUD helpers | Route stations and their stations are prefetched for nested serialization |
| `/api/route-stations/`, `/api/route-stations/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `RouteStationSerializer`; shared CRUD helpers | Related station is selected with the query; deletion retains the model's cascade behavior |
| `/api/vehicles/`, `/api/vehicles/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `VehicleSerializer`; shared CRUD helpers | Standard ORM operations; unique registration validation remains serializer/model-backed |
| `/api/drivers/`, `/api/drivers/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `DriverSerializer`; shared CRUD helpers | User and vehicle relations are selected; existing one-to-one/cascade behavior is unchanged |
| `/api/fare-rules/`, `/api/fare-rules/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `FareRuleSerializer`; shared CRUD helpers | Route relation is selected; fare calculations remain in `FareRule.calculate_amount` |
| `/api/trips/`, `/api/trips/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `TripSerializer`; POST delegates to `TripService` | Related trip entities and only each trip's first payment are selected/prefetched. Create persists the trip and its cash payment atomically; response retains the nested `payment` field |
| `/api/trips/search/` | POST | Authenticated | `TripSearchSerializer`, then `TripService.search_routes` | Repository loads candidate routes, ordered route stops, and active fare rules; the service preserves forward-only stop ordering and chooses the first active fare rule. Returns `{ "results": [...] }`; missing stations return 404 |
| `/api/payments/`, `/api/payments/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `PaymentSerializer`; shared CRUD helpers | Trip relation is selected; normal model cascade behavior is unchanged |
| `/api/notifications/`, `/api/notifications/{pk}/` | GET/POST; GET/PUT/PATCH/DELETE | Authenticated | `NotificationSerializer`; shared CRUD helpers | User relation is selected; model ordering and cascade behavior are unchanged |

For collection endpoints, GET returns a serialized list and POST returns the
created record with HTTP 201. Detail endpoints return a serialized record for
GET, PUT, and PATCH; DELETE returns HTTP 204. Missing detail records return
HTTP 404. Unsupported methods return HTTP 405. Serializer validation retains
DRF's HTTP 400 error structure.

## Preserved behavior and scope

- Route paths, trailing slashes, router resource-root keys, reverse names,
  detail `pk` arguments, format suffix routes, and CRUD method sets are
  preserved.
- The active-station queryset, trip search ordering/fare rules, registration
  validation, password hashing, payment-on-trip-create behavior, model
  relationships, and existing permission defaults are unchanged.
- No model, migration, or database schema changes were made.
- There were no pre-existing services, repositories, managers, signals, or
  custom validators in the `core` app. Authentication remains JWT from the
  project DRF settings; middleware remains the existing Django/CORS stack.
- The token obtain/refresh endpoints remain SimpleJWT's supplied class-based
  views; they are third-party auth endpoints, not `core` resource APIs.
- Existing driver/route-station create constraints and destructive cascade
  semantics were not changed by this API-layer refactor.

## Potential consumer risks / remaining work

- Imports of removed `UserRegistrationView` or `*ViewSet` Python symbols are
  not public URL contracts and were not found in this workspace. External code
  importing those implementation classes must switch to the function views.
- Trip creation now rolls back the trip if creation of its companion payment
  fails. This closes the prior partial-write possibility and is an intentional
  transaction-safety improvement.
- `StationViewSet` previously exposed only active stations, including for
  detail lookup; that restriction remains, so inactive stations still return
  404 and cannot be reactivated through this API.
- Role-based API authorization, pagination, server-side filtering, and
  additional domain validation require separate requirements and were not
  introduced here.
