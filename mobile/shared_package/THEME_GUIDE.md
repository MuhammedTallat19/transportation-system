# Transportation App Theme Guide

Professional, trustworthy design system for governorate public transit apps.

## Palette

| Token | Light usage | Hex |
|---|---|---|
| Primary | App bars, primary CTAs, links | `#0F4C81` |
| Secondary | Success states, secondary actions | `#2E8B57` |
| Accent | Live tracking, in-progress | `#00A8A8` |
| Success / Warning / Error / Info | Semantic feedback | `#0F7A4A` / `#B26A00` / `#B42318` / `#2563EB` |

Both `AppTheme.light()` and `AppTheme.dark()` wire full Material 3 theming — no default Material surfaces left unstyled.

## Typography

Noto Sans via Google Fonts — Material 3 scale (`display` → `label`) with Arabic + Latin coverage.

```dart
import 'package:shared_package/theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
);
```

## Spacing & radius

4/8pt spacing scale (`space4` … `space48`), radii `8/12/16/24`.

## Components

```dart
// Primary action
AppButton(label: 'Search trip', icon: Icons.search, onPressed: () {});

// Searchable station picker (API-loaded options)
StationPickerField(
  label: 'Start station',
  options: stations.map((s) => StationOption(id: s.id, name: s.name)).toList(),
  onChanged: (station) => setState(() => _start = station),
);

// Fare result
FareDisplayCard(fareCents: 1910, currency: 'EGP', distanceKm: 9.4, etaMinutes: 20);

// Trip status pill
StatusBadge.fromStatus('STARTED');

// Money display (minor units → formatted string)
CurrencyFormatter.format(1910, currency: 'EGP'); // "EGP 19.10"
```

## Component gallery

Run the gallery for a visual review checkpoint:

```bash
cd mobile/shared_package
flutter pub get
flutter run -t lib/component_gallery.dart
```

Toggle light/dark and RTL from the app bar.

## Iconography

Material Symbols (`Icons.*_rounded`) used consistently across Transportation App interfaces.
