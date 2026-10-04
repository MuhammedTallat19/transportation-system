import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/app_button.dart';
import 'widgets/app_text_field.dart';
import 'widgets/station_picker_field.dart';
import 'widgets/fare_display_card.dart';
import 'widgets/rating_stars.dart';
import 'widgets/status_badge.dart';
import 'widgets/empty_state.dart';
import 'widgets/error_banner.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/app_map_marker.dart';

/// Development gallery for visual review of the Transportation App design system.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isRtl = false;
  int _rating = 4;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transportation App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: Directionality(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Builder(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: const Text('Transportation App Components'),
              actions: [
                IconButton(
                  tooltip: 'Toggle light and dark theme',
                  icon: Icon(_themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  onPressed: () => setState(() => _themeMode =
                      _themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark),
                ),
                IconButton(
                  tooltip: 'Toggle right-to-left layout',
                  icon: const Icon(Icons.translate_rounded),
                  onPressed: () => setState(() => _isRtl = !_isRtl),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Typography',
                    style: Theme.of(ctx).textTheme.headlineMedium),
                Text('Display', style: Theme.of(ctx).textTheme.displaySmall),
                Text('Body text for transit information and fare details.',
                    style: Theme.of(ctx).textTheme.bodyLarge),
                const SizedBox(height: 24),
                Text('Buttons', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: const [
                  AppButton(label: 'Primary', icon: Icons.directions_bus),
                  AppButton(label: 'Secondary', isPrimary: false),
                  AppButton(label: 'Text', isText: true),
                  AppButton(label: 'Danger', isDanger: true),
                ]),
                const SizedBox(height: 24),
                const AppTextField(
                    label: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                const SizedBox(height: 16),
                StationPickerField(
                  label: 'Start station',
                  hint: 'Select station',
                  options: const [
                    StationOption(
                        id: '1',
                        name: 'Central Station',
                        nameAr: 'المحطة المركزية'),
                    StationOption(
                        id: '2',
                        name: 'University Gate',
                        nameAr: 'بوابة الجامعة'),
                  ],
                ),
                const SizedBox(height: 16),
                const FareDisplayCard(
                  fareCents: 1910,
                  currency: 'EGP',
                  distanceKm: 9.4,
                  etaMinutes: 20,
                  routeName: 'Central - Industrial Line',
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, children: [
                  StatusBadge.fromStatus('REQUESTED'),
                  StatusBadge.fromStatus('STARTED'),
                  StatusBadge.fromStatus('COMPLETED'),
                  StatusBadge.fromStatus('CANCELLED'),
                ]),
                const SizedBox(height: 16),
                RatingStars(
                    value: _rating,
                    onChanged: (v) => setState(() => _rating = v)),
                const SizedBox(height: 16),
                const ErrorBanner(
                    message: 'Unable to load stations. Check your connection.'),
                const SizedBox(height: 16),
                const EmptyState(
                    title: 'No trips yet',
                    subtitle: 'Your completed trips will appear here.',
                    icon: Icons.route_outlined),
                const SizedBox(height: 16),
                const LoadingIndicator(message: 'Calculating fare...'),
                const SizedBox(height: 16),
                Row(children: [
                  AppMapMarker.station(size: 36),
                  const SizedBox(width: 12),
                  AppMapMarker.vehicle(size: 36),
                  const SizedBox(width: 12),
                  AppMapMarker.passenger(size: 36),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() => runApp(const ComponentGalleryScreen());
