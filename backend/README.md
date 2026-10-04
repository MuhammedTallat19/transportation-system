# Transportation App Backends

This folder contains two backend implementations with different levels of integration:

- `backend_project/` is the Django REST API currently serving the transportation resources.
- `src/` is a separate NestJS scaffold. Its root application currently wires health and Prisma; its other feature modules are not connected to the running app.

The Django API registers `stations`, `routes`, `route-stations`, `vehicles`, `drivers`, `fare-rules`, `trips`, `payments`, and `notifications` under `/api/`. JWT token endpoints are available at `/api/token/` and `/api/token/refresh/`.

## Run the Django API

From this folder, create and activate a virtual environment, then install the pinned Python dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Set-Location backend_project
python manage.py migrate
python manage.py runserver 8000
```

Swagger and ReDoc are available at `http://127.0.0.1:8000/swagger/` and `http://127.0.0.1:8000/redoc/`.

## Build the NestJS scaffold

```powershell
npm install
npm run build
```

The NestJS scaffold is not a replacement for the Django resource API.
