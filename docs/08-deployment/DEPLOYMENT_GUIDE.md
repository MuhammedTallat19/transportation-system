# Deployment Guide

## 1. Environment Overview

| Environment | Firebase Project | API Host | Database | Purpose |
|---|---|---|---|---|
| `dev` | `gstms-dev` | `localhost:3000` (docker-compose) | Local PostgreSQL container | Local development |
| `staging` | `gstms-staging` | `api-staging.transportation-app.example.com` | Managed PostgreSQL (staging instance) | QA / UAT |
| `production` | `gstms-prod` | `api.transportation-app.example.com` | Managed PostgreSQL (HA, primary + replica) | Live traffic |

## 2. Prerequisites

- Node.js 20 LTS, npm/yarn/pnpm
- Flutter 3.22+, Dart 3+
- Docker & Docker Compose v2
- PostgreSQL client (`psql`) 15+
- Firebase CLI (`npm i -g firebase-tools`)
- Google Cloud project with **Maps SDK for Android/iOS**, **Directions API**, **Places API** enabled and billing configured

## 3. Firebase Project Setup

```bash
firebase login
firebase projects:create gstms-dev
firebase use gstms-dev
```

1. Enable **Authentication** providers: Phone, Email/Password, Google.
2. Create a **Cloud Firestore** database (Native mode), region matching your users (e.g., `europe-west1`).
3. Enable **Cloud Messaging**.
4. Enable **Cloud Storage**, create default bucket.
5. Download config files:
   - Android: `google-services.json` → `mobile/passenger_app/android/app/src/dev/`
   - iOS: `GoogleService-Info.plist` → `mobile/passenger_app/ios/Runner/Dev/`
   - Repeat per flavor (`staging`, `prod`) and per app (`passenger_app`, `driver_app`).
6. Deploy Firestore security rules and indexes (see [Security Guide](../10-security/SECURITY_GUIDE.md)):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## 4. Backend (Node.js REST API) — Local via Docker Compose

`backend/docker-compose.yml` (reference):

```yaml
version: "3.9"
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://gstms:gstms@postgres:5432/gstms_db
      - REDIS_URL=redis://redis:6379
      - FIREBASE_PROJECT_ID=gstms-dev
      - JWT_SECRET=${JWT_SECRET}
      - GOOGLE_MAPS_SERVER_KEY=${GOOGLE_MAPS_SERVER_KEY}
    depends_on:
      - postgres
      - redis
    volumes:
      - ./src:/app/src
  postgres:
    image: postgis/postgis:15-3.4
    environment:
      - POSTGRES_USER=gstms
      - POSTGRES_PASSWORD=gstms
      - POSTGRES_DB=gstms_db
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
volumes:
  pgdata:
```

`backend/Dockerfile` (reference):

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY package*.json ./
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

Bring the stack up:

```bash
cd backend
cp .env.example .env    # fill in Firebase service account, Maps server key, JWT secret
docker compose up -d --build
docker compose exec postgres psql -U gstms -d gstms_db -f /schema.sql
```

## 5. Database Migration Strategy

- Use a migration tool (Prisma Migrate or TypeORM migrations) in application code for iterative schema changes post-v1.
- `database/schema.sql` remains the canonical "from-zero" bootstrap script (used in CI and fresh environment setup).
- Every migration must be reversible and reviewed against the [Database Documentation](../06-database/DATABASE_DOCUMENTATION.md) normalization/indexing notes.

## 6. Mobile App Builds (Flutter Flavors)

`android/app/build.gradle` flavor dimensions: `dev`, `staging`, `prod`, each with its own `applicationIdSuffix`, API base URL (via `--dart-define`), and Maps API key.

```bash
# Debug run against staging
flutter run --flavor staging -t lib/main_staging.dart \
  --dart-define=API_BASE_URL=https://api-staging.transportation-app.example.com

# Release Android App Bundle for production
flutter build appbundle --flavor prod -t lib/main_prod.dart \
  --dart-define=API_BASE_URL=https://api.transportation-app.example.com \
  --release
```

iOS release:

```bash
flutter build ipa --flavor prod -t lib/main_prod.dart --release
```

## 7. CI/CD Pipeline (GitHub Actions)

See [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml). Pipeline stages:

1. **Lint & Analyze** — `flutter analyze`, `dart format --set-exit-if-changed`, backend `eslint`.
2. **Test** — `flutter test --coverage`, backend `npm test -- --coverage`.
3. **Build** — Android AAB (`flutter build appbundle`), backend Docker image.
4. **Deploy (staging, on `develop` branch)** — push Docker image to registry, roll out via `docker compose pull && up -d` or Kubernetes rollout; `firebase deploy` for Firestore rules/indexes.
5. **Deploy (production, on tagged release)** — manual approval gate → same deploy steps against prod environment.

## 8. Production Deployment Topology

```mermaid
graph LR
    DNS[DNS: api.transportation-app.example.com] --> LB[Load Balancer / NGINX Ingress + TLS]
    LB --> API1[API Pod 1]
    LB --> API2[API Pod 2]
    LB --> API3[API Pod N]
    API1 & API2 & API3 --> PGPRIMARY[(PostgreSQL Primary)]
    API1 & API2 & API3 -.read.-> PGREPLICA[(PostgreSQL Read Replica)]
    API1 & API2 & API3 --> REDIS[(Redis)]
    PGPRIMARY -->|streaming replication| PGREPLICA
    PGPRIMARY -->|WAL archiving| BACKUP[(Object Storage\nDaily Backups)]
```

Recommended: run the API as a container service on any of Kubernetes (GKE/EKS), a managed container platform (Cloud Run, ECS Fargate), or a small Docker Swarm cluster for lower initial scale. PostgreSQL should be a managed offering (Cloud SQL, RDS, or equivalent) with automated backups and a read replica for reporting queries.

## 9. Rollback Procedure

1. Revert the API Docker image tag to the previous known-good tag via the deployment tool.
2. If a migration was applied, run the corresponding `down` migration (never destructive `DROP` without a verified backup).
3. Mobile app rollback: since network/fare data lives in the DB, most "incidents" are fixed via Admin Dashboard data correction, not an app rollback. True app-code rollback requires a Play Store staged rollout halt + previous APK/AAB re-promotion.

## 10. Post-Deployment Verification Checklist

- [ ] `/health` returns `200` on all API instances.
- [ ] Sample `GET /governorates` and `GET /stations` succeed.
- [ ] `POST /trips/search` returns a correct fare for a known seed route.
- [ ] Firestore rules deployed (`firebase firestore:rules:release` shows latest ruleset).
- [ ] FCM test notification delivered to a test device.
- [ ] Grafana dashboards show incoming traffic/metrics.
