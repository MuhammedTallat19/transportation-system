# Maintenance Guide

## 1. Ownership & On-Call

| Area | Primary Owner | Escalation |
|---|---|---|
| Mobile Apps (Passenger/Driver) | Mobile Team Lead | Engineering Manager |
| REST API / Backend | Backend Team Lead | Engineering Manager |
| Database | Database Administrator | Backend Team Lead |
| Firebase Project | DevOps/Platform Engineer | Engineering Manager |
| Google Maps Platform billing/keys | Platform Engineer | Product Owner |

Maintain an up-to-date on-call rotation (PagerDuty/Opsgenie) covering API and database incidents 24/7 once in production with real ridership.

## 2. Monitoring & Alerting

| Signal | Tool | Alert Threshold |
|---|---|---|
| API error rate | Prometheus + Grafana | > 2% 5xx over 5 min |
| API latency (p95) | Prometheus + Grafana | > 500ms sustained 5 min |
| DB connection pool saturation | pg_stat_activity exporter | > 80% utilized |
| Disk usage (DB host) | Node exporter | > 85% |
| Firestore quota usage | Firebase console / Cloud Monitoring | > 80% of daily quota |
| Crash-free rate (mobile) | Firebase Crashlytics | < 99% crash-free sessions |
| Failed GPS ingestion | Custom metric on API | > 5% of expected pings missing per active trip |

## 3. Backup & Recovery

- **PostgreSQL:** automated daily full backup + continuous WAL archiving for point-in-time recovery (PITR). RPO ≤ 1 hour, RTO ≤ 4 hours (see NFR-21).
- **Firestore:** scheduled exports to Cloud Storage (daily) via `gcloud firestore export`.
- **Backup restoration drills:** quarterly test restore into a scratch environment, verified against a checklist (row counts, referential integrity spot-checks, application smoke test).

```bash
# Example PITR restore (managed Postgres, syntax varies by provider)
pg_basebackup -h backup-host -D /restore/base -Fp -Xs -P
# then replay WAL to target timestamp via recovery.conf / provider console
```

## 4. Routine Maintenance Tasks

| Task | Frequency | Notes |
|---|---|---|
| Review slow query log | Weekly | Add/adjust indexes per [Database Documentation §4](../06-database/DATABASE_DOCUMENTATION.md) |
| Rotate JWT signing secret | Quarterly | Coordinate with a grace-period dual-key validation window |
| Rotate Google Maps API keys | Annually or on suspected leak | Update restricted key in Secret Manager, redeploy |
| Vacuum/analyze PostgreSQL | Auto (autovacuum) + manual `VACUUM ANALYZE` after bulk imports | |
| Dependency updates | Monthly | `npm outdated`, `flutter pub outdated`, review Dependabot PRs |
| Archive old `trip_locations` partitions | Monthly (once partitioned) | Move 90+ day partitions to cold storage per retention policy |
| Review `audit_logs` for anomalies | Weekly | Look for unexpected `DELETE`/off-hours `APPROVE` actions |
| Certificate renewal | Automated (Let's Encrypt/managed TLS) with alerting on renewal failure | |

## 5. Runbooks

### 5.1 API 5xx Spike
1. Check Grafana dashboard for correlated DB latency/connection saturation.
2. Check recent deploys — roll back the API image tag if a recent release correlates with the spike.
3. Check dependent services (Firebase Admin SDK errors, Google Maps API quota errors) in logs.
4. If DB-bound: check for long-running queries (`pg_stat_activity`), kill runaway queries if safe, consider failover to read replica for read traffic.

### 5.2 GPS Data Not Updating for a Trip
1. Confirm driver app has connectivity (check last successful ping timestamp in `trip_locations`).
2. Check Firestore write success in API logs for that `tripId`.
3. If isolated to one driver device: advise app restart / check OS-level battery optimization killing background location.
4. If widespread: check Firestore quota/outage status, check API ingestion endpoint health.

### 5.3 Fare Dispute Investigation
1. Pull the `trips` row and its linked `fares` breakdown + `fare_rules` snapshot (immutable via `fare_rule_id` FK).
2. Cross-reference `audit_logs` for any fare rule changes around the trip's `requested_at` timestamp.
3. Because `fares`/`trip_history` are immutable snapshots, the historical calculation is always reproducible regardless of later rule edits (BR-6).

### 5.4 Suspicious Admin Activity
1. Query `audit_logs` filtered by `actor_user_id` and time range.
2. Compare `before_state`/`after_state` diffs for the affected entities.
3. If unauthorized, disable the account (`users.status = SUSPENDED`), rotate any credentials, notify security incident process (see [Security Guide §12](../10-security/SECURITY_GUIDE.md)).

## 6. Capacity Review

Quarterly review of the [Non-Functional Requirements](../02-requirements/NON_FUNCTIONAL_REQUIREMENTS.md) capacity assumptions against actual metrics (active users, peak concurrent trips, GPS ping volume) to decide when to scale out API replicas, add a DB read replica, or shard `trip_locations`.

## 7. Documentation Maintenance

This documentation set is a living artifact. Any schema change, new endpoint, or architectural decision **must** be accompanied by an update to the relevant document in `docs/` within the same pull request — enforced via PR review checklist.
