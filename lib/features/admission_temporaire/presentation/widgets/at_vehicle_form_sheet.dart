import 'package:flutter/material.dart';

import '../../../../core/uuid/atlas_uuid.dart';
import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../data/at_calculator.dart';
import '../../domain/models/at_vehicle.dart';

/// Pays proposés pour la plaque (liste courte MVP).
const kAtCountryOptions = <({String code, String label})>[
  (code: 'FR', label: 'France'),
  (code: 'BE', label: 'Belgique'),
  (code: 'NL', label: 'Pays-Bas'),
  (code: 'DE', label: 'Allemagne'),
  (code: 'ES', label: 'Espagne'),
  (code: 'IT', label: 'Italie'),
  (code: 'CH', label: 'Suisse'),
  (code: 'GB', label: 'Royaume-Uni'),
  (code: 'OTHER', label: 'Autre'),
];

/// Feuille d'ajout / édition d'un véhicule.
class AtVehicleFormSheet extends StatefulWidget {
  const AtVehicleFormSheet({
    super.key,
    this.initial,
  });

  final AtVehicle? initial;

  static Future<AtVehicle?> show(
    BuildContext context, {
    AtVehicle? initial,
  }) {
    return showAtlasBottomSheet<AtVehicle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AtVehicleFormSheet(initial: initial),
    );
  }

  @override
  State<AtVehicleFormSheet> createState() => _AtVehicleFormSheetState();
}

class _AtVehicleFormSheetState extends State<AtVehicleFormSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _plateController;
  late final TextEditingController _notesController;
  late final TextEditingController _customDurationController;

  late AtVehicleType _type;
  late String _countryCode;
  late DateTime _entryDate;
  late int _durationDays;
  late bool _useCustomDuration;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _plateController = TextEditingController(text: initial?.plate ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _type = initial?.type ?? AtVehicleType.car;
    _countryCode = initial?.countryCode ?? 'FR';
    _entryDate = initial?.entryDate ?? AtCalculator.calendarDay(
      AtCalculator.casablancaNow(),
    );
    final duration = initial?.durationDays ?? 180;
    _useCustomDuration = duration != 90 && duration != 180;
    _durationDays = duration;
    _customDurationController = TextEditingController(
      text: _useCustomDuration ? '$duration' : '',
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  int get _resolvedDuration {
    if (_useCustomDuration) {
      return int.tryParse(_customDurationController.text.trim()) ?? 0;
    }
    return _durationDays;
  }

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: AtCalculator.casablancaNow().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _entryDate = AtCalculator.calendarDay(picked));
  }

  void _submit() {
    final label = _labelController.text.trim();
    final plate = _plateController.text.trim();
    final duration = _resolvedDuration;
    if (label.isEmpty || plate.isEmpty || duration <= 0 || duration > 730) {
      setState(() {
        _error = 'Vérifiez le nom, la plaque et la durée (1–730 jours).';
      });
      return;
    }

    final country = kAtCountryOptions.firstWhere(
      (c) => c.code == _countryCode,
      orElse: () => kAtCountryOptions.last,
    );
    final expiry = AtCalculator.expiryFromEntry(
      entryDate: _entryDate,
      durationDays: duration,
    );
    final now = DateTime.now().toUtc();
    final initial = widget.initial;

    final vehicle = AtVehicle(
      id: initial?.id ?? AtlasUuid.v4(),
      label: label,
      plate: plate,
      countryCode: country.code,
      countryLabel: country.label,
      type: _type,
      entryDate: _entryDate,
      expiryDate: expiry,
      durationDays: duration,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
      notificationSlot: initial?.notificationSlot ?? 0,
    );

    Navigator.of(context).pop(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final expiry = _resolvedDuration > 0
        ? AtCalculator.expiryFromEntry(
            entryDate: _entryDate,
            durationDays: _resolvedDuration,
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: AtlasSpacing.pageHorizontal,
        right: AtlasSpacing.pageHorizontal,
        bottom: bottom + AtlasSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initial == null ? 'Ajouter un véhicule' : 'Modifier le véhicule',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              'Suivi personnel local — Atlas ne valide pas vos documents douaniers.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AtlasTextStyles.helper(theme.colorScheme),
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            TextField(
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom du véhicule',
                hintText: 'Ex. Golf, van famille…',
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plaque',
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            Text('Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: AtlasSpacing.sm),
            Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              children: [
                for (final type in AtVehicleType.values)
                  AtlasFilterChip(
                    label: type.labelFr,
                    isSelected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.lg),
            Text('Pays de la plaque', style: theme.textTheme.labelLarge),
            const SizedBox(height: AtlasSpacing.sm),
            Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              children: [
                for (final country in kAtCountryOptions)
                  AtlasFilterChip(
                    label: country.label,
                    isSelected: _countryCode == country.code,
                    onTap: () => setState(() => _countryCode = country.code),
                  ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date d\'entrée'),
              subtitle: Text(
                '${_entryDate.day}/${_entryDate.month}/${_entryDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickEntryDate,
            ),
            const SizedBox(height: AtlasSpacing.md),
            Text(
              'Durée d\'admission temporaire',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              children: [
                AtlasFilterChip(
                  label: '90 jours',
                  isSelected: !_useCustomDuration && _durationDays == 90,
                  onTap: () => setState(() {
                    _useCustomDuration = false;
                    _durationDays = 90;
                  }),
                ),
                AtlasFilterChip(
                  label: '180 jours',
                  isSelected: !_useCustomDuration && _durationDays == 180,
                  onTap: () => setState(() {
                    _useCustomDuration = false;
                    _durationDays = 180;
                  }),
                ),
                AtlasFilterChip(
                  label: 'Personnalisé',
                  isSelected: _useCustomDuration,
                  onTap: () => setState(() => _useCustomDuration = true),
                ),
              ],
            ),
            if (_useCustomDuration) ...[
              const SizedBox(height: AtlasSpacing.md),
              TextField(
                controller: _customDurationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durée (jours)',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (expiry != null) ...[
              const SizedBox(height: AtlasSpacing.md),
              Text(
                'Expiration calculée : '
                '${expiry.day}/${expiry.month}/${expiry.year}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AtlasTextStyles.helper(theme.colorScheme),
                ),
              ),
            ],
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AtlasSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AtlasSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(
                  widget.initial == null ? 'Enregistrer' : 'Mettre à jour',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
