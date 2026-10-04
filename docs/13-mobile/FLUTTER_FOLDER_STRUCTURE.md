# Flutter Folder Structure (Clean Architecture)

Both `passenger_app` and `driver_app` share the same architectural pattern and a common internal package (`shared_package`) to avoid duplicating models, theming, and core networking code.

## 1. Top-Level Layout

```
mobile/
├── passenger_app/
│   ├── lib/
│   │   ├── main_dev.dart
│   │   ├── main_staging.dart
│   │   ├── main_prod.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   ├── features/
│   │   └── ...
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── driver_app/
│   └── (mirrors passenger_app structure)
└── shared_package/
    ├── lib/
    │   ├── models/
    │   ├── theme/
    │   ├── widgets/
    │   └── utils/
    └── pubspec.yaml
```

## 2. `lib/core/` — App-Wide Infrastructure

```
core/
├── constants/
│   ├── app_constants.dart          # non-network-data constants only (e.g., animation durations)
│   └── env_config.dart             # reads --dart-define values (API_BASE_URL, MAPS_KEY, etc.)
├── di/
│   └── providers.dart              # top-level Riverpod provider overrides / bootstrapping
├── error/
│   ├── failures.dart                # sealed Failure classes (ServerFailure, NoRouteFoundFailure, ...)
│   └── exceptions.dart
├── network/
│   ├── api_client.dart              # Dio/http wrapper, interceptors (auth header, logging)
│   ├── firestore_client.dart
│   └── connectivity_service.dart
├── router/
│   └── app_router.dart              # go_router configuration
├── theming/
│   ├── app_theme.dart
│   └── app_text_styles.dart
└── localization/
    ├── app_en.arb
    └── app_ar.arb
```

**Critical rule:** `core/constants/app_constants.dart` **must never** contain station names, route IDs, or fare values (FR-NET-03). Only structural/UI constants belong here.

## 3. `lib/features/` — Feature Modules (Clean Architecture per feature)

Each feature follows the same three-layer split:

```
features/
└── trip_search/
    ├── data/
    │   ├── datasources/
    │   │   ├── trip_remote_data_source.dart     # REST calls
    │   │   └── trip_local_data_source.dart      # Hive cache
    │   ├── models/
    │   │   └── fare_result_model.dart           # DTO with fromJson/toJson
    │   └── repositories/
    │       └── trip_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── fare_result.dart                  # pure Dart, no Flutter/Firebase imports
    │   ├── repositories/
    │   │   └── trip_repository.dart              # abstract interface
    │   └── usecases/
    │       └── search_trip_usecase.dart
    └── presentation/
        ├── controllers/
        │   └── trip_search_controller.dart       # Riverpod AsyncNotifier
        ├── screens/
        │   └── trip_search_screen.dart
        └── widgets/
            ├── station_picker.dart
            ├── fare_display_card.dart
            └── route_map_view.dart
```

### Full Feature List — Passenger App

```
features/
├── auth/                  # phone/email/google sign-in, profile
├── trip_search/           # station pickers, fare calc, ETA, map
├── live_tracking/         # Firestore listeners, vehicle marker, share trip
├── trip_history/          # past trips list/detail
├── favorites/             # favorite stations CRUD
├── reviews/               # rate driver after trip
├── notifications/         # notification inbox
└── profile/               # edit profile, language switch
```

### Full Feature List — Driver App

```
features/
├── auth/
├── assigned_route/        # today's route + vehicle
├── trip_lifecycle/         # start/end trip, GPS broadcast service
├── trip_stats/             # completed trips, average rating
├── notifications/
└── profile/
```

### Full Feature List — Admin Dashboard (Flutter Web)

```
features/
├── auth/
├── dashboard_home/         # KPIs summary
├── stations_management/    # CRUD + map picker for lat/lng
├── routes_management/      # CRUD + drag-to-reorder route stations
├── fare_rules_management/  # CRUD + draft/approve workflow
├── vehicles_management/
├── drivers_management/
├── live_fleet_map/          # real-time all-vehicle map
├── trips_monitor/           # active/completed/cancelled trip list & filters
├── reports/                 # revenue, ridership, driver performance charts
└── settings/                # system settings key/value editor
```

## 4. `lib/shared/` (or `shared_package`) — Cross-Feature Reuse

```
shared_package/lib/
├── models/
│   ├── station.dart          # shared entity used by trip_search, favorites, admin
│   ├── route.dart
│   └── user_profile.dart
├── widgets/
│   ├── app_button.dart
│   ├── app_loading_indicator.dart
│   ├── error_banner.dart
│   └── rating_stars.dart
├── theme/
│   └── design_tokens.dart
└── utils/
    ├── currency_formatter.dart   # formats minor units -> display string per NFR-18
    └── date_formatter.dart
```

## 5. Riverpod Provider Conventions

```dart
// features/trip_search/presentation/controllers/trip_search_controller.dart
@riverpod
class TripSearchController extends _$TripSearchController {
  @override
  FutureOr<FareResult?> build() => null;

  Future<void> search(String startStationId, String destStationId) async {
    state = const AsyncLoading();
    final useCase = ref.read(searchTripUseCaseProvider);
    final result = await useCase(startId: startStationId, destId: destStationId);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (fareResult) => AsyncData(fareResult),
    );
  }
}
```

- One `@riverpod` controller per screen/major widget subtree.
- Repositories are provided as interfaces (`tripRepositoryProvider` returns `TripRepository`, bound to `TripRepositoryImpl` in `core/di/providers.dart`) so tests can override with fakes.
- No `Provider` reads business logic directly from Firestore/HTTP in the presentation layer — always through a UseCase.

## 6. Testing Mirror Structure

```
test/
├── features/
│   └── trip_search/
│       ├── domain/usecases/search_trip_usecase_test.dart
│       ├── data/repositories/trip_repository_impl_test.dart
│       └── presentation/controllers/trip_search_controller_test.dart
└── core/
    └── network/api_client_test.dart
integration_test/
├── passenger_trip_flow_test.dart
└── driver_trip_lifecycle_test.dart
```

## 7. Dependency Rule (enforced via `import_lint` / architecture test)

```
presentation  →  domain  →  (nothing)
     ↑              ↑
   data  ───────────┘
```

- `domain/` has **zero** imports from `flutter`, `firebase_*`, `dio`, or `google_maps_flutter`.
- `data/` implements `domain/repositories` interfaces and is the only layer allowed to import Firebase/HTTP/Hive packages.
- `presentation/` depends on `domain` (entities, usecases) and Riverpod/Flutter — never directly on `data/`.

This is validated in CI via a lightweight custom lint script (or `flutter_lints` custom rule set) that fails the build if a `domain/` file imports a forbidden package.
