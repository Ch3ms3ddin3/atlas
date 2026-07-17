import 'package:flutter/material.dart';

import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/itinerary_repository.dart';
import '../../domain/models/itinerary_enums.dart';
import '../itinerary_scope.dart';

/// Feuille de création / génération d'itinéraire.
class TripCreateSheet extends StatefulWidget {
  const TripCreateSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const TripCreateSheet(),
    );
  }

  @override
  State<TripCreateSheet> createState() => _TripCreateSheetState();
}

class _TripCreateSheetState extends State<TripCreateSheet> {
  final _titleController = TextEditingController();
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 3));
  String _city = MoroccoCities.fallback.name;
  String _pace = 'balanced';
  final String _budgetBand = 'balanced';
  bool _includeFavorites = true;
  bool _prayerAware = true;
  bool _weatherAware = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int get _dayCount {
    final start = DateTime(_start.year, _start.month, _start.day);
    final end = DateTime(_end.year, _end.month, _end.day);
    return end.difference(start).inDays + 1;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _start = picked;
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(days: 2));
      }
      if (_dayCount > ItineraryLimits.maxDays) {
        _end = _start.add(Duration(days: ItineraryLimits.maxDays - 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: _start.add(Duration(days: ItineraryLimits.maxDays - 1)),
    );
    if (picked == null) return;
    setState(() => _end = picked);
  }

  Future<void> _generate() async {
    if (_dayCount < 1 || _dayCount > ItineraryLimits.maxDays) {
      setState(() => _error = 'Durée max : ${ItineraryLimits.maxDays} jours.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ItineraryScope.of(context);
    final result = await repo.generateTrip(
      TripGenerationRequest(
        startDate: _start,
        endDate: _end,
        primaryCity: _city,
        pace: _pace,
        budgetBand: _budgetBand,
        includeFavorites: _includeFavorites,
        prayerAware: _prayerAware,
        weatherAware: _weatherAware,
        title: _titleController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.pop(context, result.trip.id);
  }

  Future<void> _manual() async {
    if (_dayCount < 1 || _dayCount > ItineraryLimits.maxDays) {
      setState(() => _error = 'Durée max : ${ItineraryLimits.maxDays} jours.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ItineraryScope.of(context);
    final trip = await repo.createManualTrip(
      title: _titleController.text,
      startDate: _start,
      endDate: _end,
      primaryCity: _city,
      pace: _pace,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (trip == null) {
      setState(() => _error = 'Impossible de créer le voyage.');
      return;
    }
    Navigator.pop(context, trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AtlasSpacing.lg,
        0,
        AtlasSpacing.lg,
        AtlasSpacing.lg + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouveau voyage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: const InputDecoration(
                labelText: 'Ville principale',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final city in MoroccoCities.supportedNames)
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _city = value);
                    },
            ),
            const SizedBox(height: AtlasSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _pickStart,
                    child: Text('Début · ${_fmt(_start)}'),
                  ),
                ),
                const SizedBox(width: AtlasSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _pickEnd,
                    child: Text('Fin · ${_fmt(_end)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              '$_dayCount jour${_dayCount > 1 ? 's' : ''} '
              '(max ${ItineraryLimits.maxDays})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AtlasColors.midnightBlueMuted,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Wrap(
              spacing: AtlasSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Détente'),
                  selected: _pace == 'relaxed',
                  onSelected: (_) => setState(() => _pace = 'relaxed'),
                ),
                ChoiceChip(
                  label: const Text('Équilibré'),
                  selected: _pace == 'balanced',
                  onSelected: (_) => setState(() => _pace = 'balanced'),
                ),
                ChoiceChip(
                  label: const Text('Intensif'),
                  selected: _pace == 'packed',
                  onSelected: (_) => setState(() => _pace = 'packed'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Inclure mes favoris'),
              value: _includeFavorites,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _includeFavorites = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Respecter les prières'),
              value: _prayerAware,
              onChanged:
                  _busy ? null : (v) => setState(() => _prayerAware = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tenir compte de la météo'),
              value: _weatherAware,
              onChanged:
                  _busy ? null : (v) => setState(() => _weatherAware = v),
            ),
            if (_error != null) ...[
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AtlasColors.error,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
            ],
            FilledButton(
              onPressed: _busy ? null : _generate,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Générer avec Atlas'),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            OutlinedButton(
              onPressed: _busy ? null : _manual,
              child: const Text('Créer manuellement'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
