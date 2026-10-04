<<<<<<< HEAD
# Transportation App

This workspace contains transportation API and UI building blocks:

- A Django REST API in `backend/backend_project` with JWT authentication and endpoints for stations, routes, route-stations, vehicles, drivers, fare rules, trips, payments, and notifications.
- A NestJS service scaffold in `backend/src`. Its active application module currently wires health and Prisma modules; the other feature modules are not yet connected.
- A Flutter shared component package and interactive component gallery in `mobile/shared_package`.
- A PostgreSQL schema, API examples, product specifications, and a static UI prototype.

**Scope note:** the product documents describe the intended rider, driver, and administration experience. This checkout does not contain separate passenger or driver Flutter applications, so those complete workflows are not implemented here.

## Documentation

The `docs/` folder contains the product and implementation specifications:

| Area | Documents |
|---|---|
| Product | [Project Overview](docs/01-overview/PROJECT_OVERVIEW.md), [Business Requirements](docs/01-overview/BUSINESS_REQUIREMENTS.md) |
| Requirements | [Functional Requirements](docs/02-requirements/FUNCTIONAL_REQUIREMENTS.md), [Non-Functional Requirements](docs/02-requirements/NON_FUNCTIONAL_REQUIREMENTS.md), [SRS](docs/03-srs/SRS.md) |
| Architecture | [Software Design](docs/04-sdd/SDD.md), [Architecture](docs/05-architecture/ARCHITECTURE.md) |
| Data and API | [ER Diagram](docs/06-database/ER_DIAGRAM.md), [Database Documentation](docs/06-database/DATABASE_DOCUMENTATION.md), [SQL Schema](database/schema.sql), [API Documentation](docs/07-api/API_DOCUMENTATION.md) |
| Delivery | [Deployment Guide](docs/08-deployment/DEPLOYMENT_GUIDE.md), [Testing Guide](docs/09-testing/TESTING_GUIDE.md), [Security Guide](docs/10-security/SECURITY_GUIDE.md), [Maintenance Guide](docs/11-maintenance/MAINTENANCE_GUIDE.md) |
| Roadmap and mobile | [Roadmap](docs/12-roadmap/ROADMAP.md), [Future Features](docs/12-roadmap/FUTURE_FEATURES.md), [Flutter Structure](docs/13-mobile/FLUTTER_FOLDER_STRUCTURE.md), [Google Play Checklist](docs/14-publishing/GOOGLE_PLAY_CHECKLIST.md) |

These documents are target-state specifications; use the source directories above to determine what is implemented in this checkout.

## Run the Django API

From the repository root, create an environment and install the backend requirements:

```powershell
Set-Location backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Set-Location backend_project
python manage.py migrate
python manage.py runserver 8000
```

The API root is `http://127.0.0.1:8000/api/`. The resource routes are registered in `backend/backend_project/core/urls.py`; JWT token endpoints are `/api/token/` and `/api/token/refresh/`. Swagger and ReDoc are available at `/swagger/` and `/redoc/`.

## Build the NestJS service

```powershell
Set-Location backend
npm install
npm run build
```

The NestJS service is a separate scaffold from the Django transportation API.

## Run the Flutter component gallery

```powershell
Set-Location mobile\shared_package
flutter pub get
flutter run -t lib\component_gallery.dart
```

The gallery exercises the shared theme and widgets, including light/dark mode and RTL layout. It is not a passenger or driver application.

## License

MIT — see [LICENSE](LICENSE).
=======
# transportation-system
>>>>>>> 85d7f34dd0c954754e22212f33ab5bfb4f9933c0
