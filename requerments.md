# Transportation App — Full Backend Integration + Business CRUD Frontend

I have an existing Django REST Framework backend and an existing React frontend.

I want you to integrate the frontend with the existing Django backend and build a complete production-quality transportation management frontend.

DO NOT create fake CRUD behavior.
DO NOT keep important data only in local state.
DO NOT invent API endpoints.
DO NOT invent database fields.
The Django REST API is the source of truth.

==================================================
1. BACKEND API
==================================================

The backend contains these resources:

/stations/
/routes/
/route-stations/
/vehicles/
/drivers/
/fare-rules/
/trips/
/payments/
/notifications/

There is also a Users resource if it is exposed by the backend.

First inspect the actual Django backend implementation.

Inspect:

- models.py
- serializers.py
- views.py / ViewSets
- urls.py
- routers
- permissions
- authentication
- pagination
- filtering
- ordering
- search
- validation
- relationships
- status fields
- foreign keys
- unique constraints

Do not guess the API contract.

If the frontend and backend currently disagree about a field or endpoint, use the actual backend implementation as the source of truth.

==================================================
2. CONNECT THE FRONTEND TO DJANGO
==================================================

Create a centralized API configuration.

Example concept:

src/api/client.ts

The API base URL must come from an environment variable.

Example:

VITE_API_BASE_URL

Do NOT hardcode localhost throughout the application.

Create a centralized HTTP client.

For example:

src/api/client.ts

Responsibilities:

- base URL
- authentication headers
- JSON handling
- error handling
- timeout handling
- request interceptors if needed
- response handling

All API services must use this client.

Do NOT use scattered fetch/axios calls directly inside React components.

==================================================
3. API SERVICE LAYER
==================================================

Create separate API services:

src/api/
    client.ts
    users.ts
    drivers.ts
    vehicles.ts
    stations.ts
    routes.ts
    routeStations.ts
    fareRules.ts
    trips.ts
    payments.ts
    notifications.ts

Each service must map directly to the actual Django API.

Example architecture:

drivers.ts

- getDrivers()
- getDriver(id)
- createDriver(data)
- updateDriver(id, data)
- deleteDriver(id)

But ONLY implement operations that the backend actually supports.

If the backend supports PATCH but not PUT, use PATCH.

If the backend does not support DELETE, do not create a fake delete operation.

==================================================
4. TYPESCRIPT TYPES
==================================================

Create TypeScript interfaces/types matching the Django serializers.

Example:

Driver
Vehicle
Station
Route
RouteStation
FareRule
Trip
Payment
Notification
User

Do not invent properties.

The frontend types must reflect the real API responses.

Keep request and response types separate when necessary.

Example:

DriverResponse
CreateDriverRequest
UpdateDriverRequest

==================================================
5. AUTHENTICATION
==================================================

Inspect the existing Django authentication mechanism.

Determine whether it uses:

- JWT
- Token Authentication
- Session Authentication
- another authentication mechanism

Integrate the frontend accordingly.

Do not invent an authentication system if one already exists.

If JWT is used:

- store tokens safely according to the existing architecture
- attach Authorization headers automatically
- handle expired tokens
- handle 401 responses
- redirect to login when appropriate

Do not expose secrets in frontend code.

==================================================
6. REAL API DATA
==================================================

Replace fake/mock data with real API data wherever the backend endpoint exists.

For example:

Drivers page
    ↓
GET /drivers/
    ↓
API response
    ↓
React state/query
    ↓
Drivers table

Creating:

User submits form
    ↓
POST /drivers/
    ↓
Django validation
    ↓
Success
    ↓
Refresh/update frontend data

Editing:

Open driver
    ↓
GET /drivers/{id}/
    ↓
Display data
    ↓
PATCH /drivers/{id}/
    ↓
Update UI

Deleting/deactivating:

User clicks action
    ↓
Business confirmation
    ↓
DELETE/PATCH if supported
    ↓
Django response
    ↓
Refresh UI

==================================================
7. SERVER STATE MANAGEMENT
==================================================

Use an appropriate server-state solution such as TanStack Query if it is already available or appropriate for this project.

Use server state for:

- Drivers
- Vehicles
- Stations
- Routes
- Route Stations
- Fare Rules
- Trips
- Payments
- Notifications
- Users

Do not duplicate server data unnecessarily in multiple React states.

Use:

- queries
- mutations
- query invalidation
- optimistic updates only when safe

For example:

createDriver()
    ↓
invalidate drivers query
    ↓
GET updated drivers
    ↓
refresh table

==================================================
8. EVERY MANAGEMENT PAGE MUST USE REAL API DATA
==================================================

Create management pages for:

/management/users
/management/drivers
/management/vehicles
/management/stations
/management/routes
/management/route-stations
/management/fare-rules
/management/trips
/management/payments
/management/notifications

Each page must communicate with Django.

==================================================
9. USERS
==================================================

Create:

Users List
User Details
Create User
Edit User

Use the actual User API.

Do not duplicate authentication logic inside the Users CRUD.

Respect backend permissions.

==================================================
10. DRIVERS
==================================================

Create:

Drivers List
Driver Details
Create Driver
Edit Driver
Driver status management

Integrate:

GET
POST
PATCH/PUT
DELETE

only when actually supported.

Display related:

- user
- vehicle
- trips
- status

only if those relationships exist in the backend.

==================================================
11. VEHICLES
==================================================

Create:

Vehicles List
Vehicle Details
Create Vehicle
Edit Vehicle
Vehicle status

Use the real API.

Validate fields according to Django serializer validation.

If plate number is unique, handle duplicate errors from the backend correctly.

==================================================
12. STATIONS
==================================================

Create:

Stations List
Station Details
Create Station
Edit Station
Delete/Deactivate

Integrate real station data.

If latitude/longitude exist:

- validate geographic ranges
- optionally display map location
- do not change the backend representation

==================================================
13. ROUTES
==================================================

Create:

Routes List
Route Details
Create Route
Edit Route

Route Details should display related Route Stations.

Example:

Route
Cairo → Alexandria

Stations:

1. Cairo
2. Banha
3. Tanta
4. Alexandria

The stations must come from the backend.

Do not hardcode them.

==================================================
14. ROUTE STATIONS
==================================================

This is a relationship resource.

Do not treat it as a completely independent generic CRUD page.

Allow administrators to manage:

Route
+
Station
+
Order/sequence

if those fields exist in the backend.

Example:

Route:
Cairo → Alexandria

Station sequence:

1. Cairo
2. Banha
3. Tanta
4. Alexandria

When the order changes, send the appropriate API request.

Do not update only the frontend.

Persist changes through Django.

==================================================
15. FARE RULES
==================================================

Create:

Fare Rules List
Fare Rule Details
Create Fare Rule
Edit Fare Rule
Activate/Deactivate if supported

Use actual backend validation.

Do not allow obviously invalid values in the UI.

However, the backend remains responsible for final validation.

If Django returns:

400

with:

{
    "base_fare": ["..."]
}

display the error next to the corresponding field.

==================================================
16. TRIPS
==================================================

Trips are NOT ordinary CRUD records.

Build the frontend according to the actual Trip model and backend status workflow.

Display:

- rider
- driver
- vehicle
- route
- pickup
- destination
- status
- fare
- payment
- timestamps

Use the backend status values.

Do NOT invent a status state machine.

Do NOT allow arbitrary modification of historical trips.

If the backend only allows status transitions through dedicated actions, use those actions.

Example:

Trip Details

Status:
Requested

Actions:
Accept
Cancel

After backend response:

Status:
Accepted

The UI must reflect the actual backend state.

==================================================
17. PAYMENTS
==================================================

Treat payments as financial records.

Create:

Payments List
Payment Details

Use real payment data.

Support filtering by:

- status
- method
- trip
- date

Do not allow arbitrary editing of:

- amount
- transaction reference
- completed transaction information

unless the backend explicitly supports it.

==================================================
18. NOTIFICATIONS
==================================================

Create:

Notifications List
Notification Details
Create Notification
Edit Notification
Delete Notification

Use the real API.

If notifications are associated with users, load users from the backend.

Do not hardcode recipient lists.

==================================================
19. RELATIONSHIPS
==================================================

Whenever a form contains a foreign key, load the options from the backend.

Example:

Create Driver

Vehicle:
[Select vehicle]

Do NOT use:

Vehicle:
[Car 1]
[Car 2]
[Car 3]

hardcoded in the frontend.

Instead:

GET /vehicles/
    ↓
Vehicle selection
    ↓
POST /drivers/

Same principle applies to:

Driver
Vehicle
Station
Route
User
Trip
Payment

etc.

==================================================
20. DEPENDENT SELECTS
==================================================

When one entity depends on another:

Example:

Route
    ↓
Stations

or:

Driver
    ↓
Vehicle

load the appropriate data dynamically.

Do not load unrelated datasets unnecessarily.

==================================================
21. SEARCH / FILTER / PAGINATION
==================================================

If Django supports server-side:

- search
- filtering
- ordering
- pagination

use them.

Example:

GET /drivers/?search=Ahmed&page=2

Do not download thousands of records just to filter them in React.

Use debounced search.

Preserve filter state where appropriate.

==================================================
22. API ERROR HANDLING
==================================================

Create centralized API error handling.

Handle:

400
401
403
404
409
422
500
network errors
timeouts

Convert Django validation errors into useful UI messages.

Example backend:

{
    "plate_number": [
        "Vehicle with this plate number already exists."
    ]
}

Frontend:

Plate Number
[ABC-123]

⚠ Vehicle with this plate number already exists.

Do not display:

"Request failed with status code 400"

when a useful backend message exists.

==================================================
23. LOADING STATES
==================================================

Every API operation must have a proper loading state.

Examples:

Loading drivers...
Creating vehicle...
Updating route...
Deleting station...

Disable submit buttons during mutations.

Prevent duplicate submissions.

Use skeletons for tables and details pages.

==================================================
24. SUCCESS STATES
==================================================

After successful mutations:

Show appropriate feedback.

Examples:

"Driver created successfully."

"Vehicle updated successfully."

"Station deleted successfully."

Then refresh/invalidate the relevant server state.

Do not manually fake the updated result if the backend can return the actual object.

==================================================
25. DELETE SAFETY
==================================================

Before deletion:

Check the business relationship where possible.

Example:

Deleting a Driver who has Trips.

Do not blindly execute DELETE.

Show:

Driver has associated historical trips.

If the backend supports deactivation:

Use:

Deactivate Driver

instead of:

Delete Driver

If the backend rejects deletion:

Display the backend error.

Never bypass backend constraints.

==================================================
26. NO FAKE SUCCESS
==================================================

This is extremely important.

Never do:

setDrivers(...)
toast("Driver created")

before the backend confirms success.

The correct flow is:

Form
↓
API request
↓
Django response
↓
Success
↓
Update/invalidate server state
↓
Success message

If Django returns an error:

Do NOT show success.

==================================================
27. OFFLINE / NETWORK FAILURE
==================================================

If the backend cannot be reached:

Show:

"Unable to connect to the transportation server."

Provide:

Retry

Do not replace real API data with fake data silently.

==================================================
28. MOCK DATA POLICY
==================================================

Mock data may only be used for UI development where the backend does not yet provide the required resource.

Clearly isolate mock data.

Once an API exists:

REMOVE the mock implementation and use the real API.

The production management screens must use Django.

==================================================
29. API DEBUGGING
==================================================

During integration verify:

Request URL
HTTP method
Headers
Request body
Response status
Response body

Fix:

- CORS issues
- incorrect URLs
- incorrect field names
- incorrect HTTP methods
- serializer mismatches
- authentication issues
- pagination mismatches

Do not work around backend errors by changing the frontend to hide them.

==================================================
30. CORS
==================================================

If frontend and backend run on different origins, identify the required CORS configuration.

Do not put security-sensitive CORS workarounds in the frontend.

If backend configuration must be changed, clearly report the required Django configuration.

==================================================
31. API CONTRACT REPORT
==================================================

Before implementing each resource, internally build a mapping:

Entity
↓
Endpoint
↓
GET list
↓
GET detail
↓
POST
↓
PUT/PATCH
↓
DELETE
↓
Relationships
↓
Validation
↓
Permissions

Only implement operations actually supported by the backend.

==================================================
32. FRONTEND ARCHITECTURE
==================================================

Use:

src/
│
├── api/
│   ├── client.ts
│   ├── users.ts
│   ├── drivers.ts
│   ├── vehicles.ts
│   ├── stations.ts
│   ├── routes.ts
│   ├── routeStations.ts
│   ├── fareRules.ts
│   ├── trips.ts
│   ├── payments.ts
│   └── notifications.ts
│
├── features/
│   ├── users/
│   ├── drivers/
│   ├── vehicles/
│   ├── stations/
│   ├── routes/
│   ├── routeStations/
│   ├── fareRules/
│   ├── trips/
│   ├── payments/
│   └── notifications/
│
├── components/
├── hooks/
├── types/
├── layouts/
└── pages/

Keep API communication separate from UI components.

==================================================
33. SECURITY
==================================================

Never:

- expose Django secrets
- expose database credentials
- put private API keys in frontend code
- bypass backend permissions
- trust frontend authorization as security

The backend is authoritative.

==================================================
34. TESTING
==================================================

After integration test every entity.

For each:

LIST
CREATE
DETAIL
UPDATE
DELETE/DEACTIVATE
SEARCH
FILTER
PAGINATION
VALIDATION
ERROR HANDLING

Also test:

- unauthorized request
- expired authentication
- network failure
- backend validation error
- duplicate records
- relationship conflicts
- empty results

==================================================
35. FINAL INTEGRATION CHECK
==================================================

Before finishing, verify:

Frontend
    ↓
API Client
    ↓
Django REST API
    ↓
Serializer
    ↓
Django Model
    ↓
Database

and the reverse:

Database
    ↓
Django
    ↓
Serializer
    ↓
API
    ↓
API Client
    ↓
React
    ↓
UI

Every important management operation must follow this real data flow.

==================================================
36. FINAL REPORT
==================================================

At the end provide:

TRANSPORTATION APP
BACKEND INTEGRATION REPORT

For each resource:

Users
Drivers
Vehicles
Stations
Routes
Route Stations
Fare Rules
Trips
Payments
Notifications

Report:

API connected: PASS/FAIL
List: PASS/FAIL
Create: PASS/FAIL
Details: PASS/FAIL
Update: PASS/FAIL
Delete/Deactivate: PASS/FAIL/N/A
Search: PASS/FAIL/N/A
Filters: PASS/FAIL/N/A
Pagination: PASS/FAIL/N/A
Validation: PASS/FAIL
Authentication: PASS/FAIL
Error handling: PASS/FAIL

Also report:

- API endpoints used
- backend limitations discovered
- operations intentionally disabled
- unresolved integration problems
- required Django changes, if any

==================================================
EXECUTION ORDER
==================================================

Do NOT implement everything blindly.

Follow this order:

PHASE 1
Inspect Django backend.

PHASE 2
Map models → serializers → ViewSets → URLs.

PHASE 3
Create API contract.

PHASE 4
Create centralized API client.

PHASE 5
Create TypeScript API types.

PHASE 6
Create API services.

PHASE 7
Create reusable CRUD components.

PHASE 8
Integrate Users.

PHASE 9
Integrate Drivers.

PHASE 10
Integrate Vehicles.

PHASE 11
Integrate Stations.

PHASE 12
Integrate Routes.

PHASE 13
Integrate Route Stations.

PHASE 14
Integrate Fare Rules.

PHASE 15
Integrate Trips.

PHASE 16
Integrate Payments.

PHASE 17
Integrate Notifications.

PHASE 18
Test all API operations.

PHASE 19
Remove obsolete mock data.

PHASE 20
Run final code audit.

PHASE 21
Run production build.

PHASE 22
Show the final integration report.

IMPORTANT:

Do not proceed by guessing missing backend behavior.

If a backend endpoint, serializer field, relationship, or business rule is missing, identify it clearly and continue with the parts that can be safely implemented.

Do not create fake backend behavior to make the UI appear functional.