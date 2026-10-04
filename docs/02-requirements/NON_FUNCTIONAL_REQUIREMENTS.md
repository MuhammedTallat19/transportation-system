# Non-Functional Requirements (NFR)

| ID | Category | Requirement | Target |
|---|---|---|---|
| NFR-01 | Performance | Fare calculation API response time | p95 < 300ms, p99 < 800ms |
| NFR-02 | Performance | Route/station search autocomplete response | p95 < 200ms |
| NFR-03 | Performance | GPS location update propagation to listening clients | < 5 seconds end-to-end |
| NFR-04 | Scalability | System shall support at least 50,000 concurrent passenger sessions per governorate | Horizontal scaling of API layer |
| NFR-05 | Scalability | System shall support 10,000+ stations and 5,000+ routes without query degradation | Proper indexing (see DB docs) |
| NFR-06 | Availability | Core API uptime | ≥ 99.9% monthly |
| NFR-07 | Availability | Firestore realtime layer uptime | Inherits Firebase SLA (≥ 99.95%) |
| NFR-08 | Reliability | GPS data loss tolerance | App must buffer & retry location updates on reconnect |
| NFR-09 | Security | All traffic must use HTTPS/TLS 1.2+ | Enforced at load balancer & Firebase |
| NFR-10 | Security | All Firestore access must pass Firestore Security Rules role checks | See [Security Guide](../10-security/SECURITY_GUIDE.md) |
| NFR-11 | Security | Passwords/secrets never stored in plaintext; JWT signed with rotating secret | RS256 or HS256 with KMS-managed key |
| NFR-12 | Usability | Passenger app onboarding to first fare calculation | < 3 taps after station selection |
| NFR-13 | Accessibility | App shall support dynamic text scaling and screen-reader labels on core flows | WCAG 2.1 AA where feasible |
| NFR-14 | Localization | App shall support Arabic (RTL) and English at launch | Full RTL layout support |
| NFR-15 | Maintainability | Codebase shall follow Clean Architecture with ≥ 70% unit test coverage on domain layer | Enforced in CI |
| NFR-16 | Portability | Backend shall be fully containerized and runnable via Docker Compose locally | `docker compose up` works out of the box |
| NFR-17 | Observability | All services shall emit structured logs and expose `/health` and `/metrics` endpoints | Prometheus-compatible |
| NFR-18 | Data Integrity | Monetary values stored as integers (minor currency units); all financial calculations must be deterministic and reproducible | No floating-point currency math |
| NFR-19 | Battery/Data usage | Driver app GPS broadcast shall balance accuracy vs. battery — configurable interval (default 7s active trip, off when idle) | Configurable via `Settings` table |
| NFR-20 | Compliance | Personal data (location, phone) shall be retained per configurable retention policy and deletable on user request | GDPR-style data subject rights |
| NFR-21 | Disaster Recovery | PostgreSQL automated backups | Daily full + PITR (point-in-time recovery), RPO ≤ 1h, RTO ≤ 4h |
| NFR-22 | Extensibility | Adding a new governorate, fare rule type, or route shall require zero mobile app code changes | Verified via architecture review |

## Capacity Planning Assumptions

| Metric | Assumption (Year 1, single governorate) |
|---|---|
| Registered passengers | 100,000 |
| Daily active passengers | 10,000–15,000 |
| Registered drivers/vehicles | 500–1,000 |
| Concurrent active trips (peak) | 300 |
| GPS updates/sec (peak) | ~45 (300 vehicles × 1 update/7s) |
| Fare calculations/day | 40,000+ |

## Non-Functional Testing References

See [Testing Guide](../09-testing/TESTING_GUIDE.md) §5 (Performance Testing) and §6 (Security Testing) for how each NFR above is validated.
