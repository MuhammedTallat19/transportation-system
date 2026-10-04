import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class StationOption {
  final String id;
  final String name;
  final String? nameAr;

  const StationOption({required this.id, required this.name, this.nameAr});

  String displayName(bool isArabic) =>
      (isArabic && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;
}

/// Searchable station picker — loads options dynamically from API-provided list.
class StationPickerField extends StatelessWidget {
  final String label;
  final String? hint;
  final StationOption? value;
  final List<StationOption> options;
  final ValueChanged<StationOption?>? onChanged;
  final bool enabled;
  final bool isLoading;

  const StationPickerField({
    required this.label,
    required this.options,
    this.hint,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    super.key,
  });

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || isLoading) return;

    final selected = await showModalBottomSheet<StationOption>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _StationSearchSheet(label: label, options: options, selected: value),
    );

    if (selected != null) onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: enabled ? () => _openPicker(context) : null,
      borderRadius:
          BorderRadius.circular(TransportationAppDesignTokens.radius12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : const Icon(Icons.search_rounded),
        ),
        child: Text(
          value?.displayName(isRtl) ?? hint ?? 'Select station',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _StationSearchSheet extends StatefulWidget {
  final String label;
  final List<StationOption> options;
  final StationOption? selected;

  const _StationSearchSheet(
      {required this.label, required this.options, this.selected});

  @override
  State<_StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<_StationSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StationOption> get _filtered {
    if (_query.isEmpty) return widget.options;
    final q = _query.toLowerCase();
    return widget.options.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.nameAr?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: TransportationAppDesignTokens.neutral400,
                    borderRadius: BorderRadius.circular(99))),
            Padding(
              padding:
                  const EdgeInsets.all(TransportationAppDesignTokens.space16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: theme.textTheme.titleLarge),
                    const SizedBox(
                        height: TransportationAppDesignTokens.space12),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: isRtl ? 'ابحث عن محطة' : 'Search stations',
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ]),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(isRtl ? 'لا توجد محطات' : 'No stations found',
                          style: theme.textTheme.bodyMedium))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final station = _filtered[i];
                        final isSelected = widget.selected?.id == station.id;
                        return ListTile(
                          leading: Icon(Icons.location_on_outlined,
                              color: isSelected
                                  ? TransportationAppDesignTokens.primary
                                  : null),
                          title: Text(station.displayName(isRtl)),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: TransportationAppDesignTokens.primary)
                              : null,
                          onTap: () => Navigator.pop(context, station),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
