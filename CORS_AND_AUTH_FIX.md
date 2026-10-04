# Transportation App CORS and API Access

The Django backend includes `django-cors-headers` and configures CORS in `backend/backend_project/backend_project/settings.py`. Update the allowed origins there for the actual client origins in your deployment; do not substitute guessed production domains.

The backend uses JWT authentication:

- `POST /api/token/` obtains an access and refresh token.
- `POST /api/token/refresh/` refreshes an access token.
- Protected transportation resources are registered under `/api/`, including `/api/stations/`, `/api/routes/`, `/api/trips/`, `/api/payments/`, and `/api/notifications/`.

Use the token flow in [AUTHENTICATION_IMPLEMENTATION.md](AUTHENTICATION_IMPLEMENTATION.md) to test authenticated API requests. The current Flutter package is a shared component gallery, not a client application, so it does not make API requests or require a Flutter authentication setup.
