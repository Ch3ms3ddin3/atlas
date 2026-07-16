import '../../../core/uuid/atlas_uuid.dart';
import '../domain/at_repository.dart';
import '../domain/models/at_vehicle.dart';
import 'at_calculator.dart';
import 'at_preferences_store.dart';

/// Repository local-only — architecture prête pour SyncingAtRepository.
class LocalAtRepository extends AtRepository {
  LocalAtRepository({
    AtPreferencesStore? store,
  })  : _store = store ?? const AtPreferencesStore(),
        super.base();

  final AtPreferencesStore _store;

  List<AtVehicle> _vehicles = const [];
  bool _isLoaded = false;
  bool _notificationsEnabled = false;
  bool _notificationPromptShown = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  List<AtVehicle> get vehicles => List.unmodifiable(_vehicles);

  @override
  List<AtVehicle> get activeVehicles =>
      _vehicles.where((v) => v.isActive).toList(growable: false);

  @override
  bool get notificationsEnabled => _notificationsEnabled;

  @override
  bool get notificationPromptShown => _notificationPromptShown;

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _vehicles = List<AtVehicle>.from(snapshot.vehicles);
    _notificationsEnabled = snapshot.notificationsEnabled;
    _notificationPromptShown = snapshot.notificationPromptShown;
    _isLoaded = true;
    notifyListeners();
  }

  @override
  Future<bool> addVehicle(AtVehicle vehicle) async {
    final normalized = _normalize(vehicle);
    if (normalized == null) return false;

    final withSlot = normalized.copyWith(
      notificationSlot: _nextFreeSlot(),
      id: normalized.id.isEmpty ? AtlasUuid.v4() : normalized.id,
    );

    _vehicles = [..._vehicles, withSlot];
    await _persist();
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateVehicle(AtVehicle vehicle) async {
    final normalized = _normalize(vehicle);
    if (normalized == null) return false;

    final index = _vehicles.indexWhere((v) => v.id == normalized.id);
    if (index < 0) return false;

    final existing = _vehicles[index];
    final updated = normalized.copyWith(
      createdAt: existing.createdAt,
      notificationSlot: existing.notificationSlot,
      updatedAt: DateTime.now().toUtc(),
      isActive: true,
    );

    final next = List<AtVehicle>.from(_vehicles);
    next[index] = updated;
    _vehicles = next;
    await _persist();
    notifyListeners();
    return true;
  }

  @override
  Future<bool> deleteVehicle(String id) async {
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index < 0) return false;

    final next = List<AtVehicle>.from(_vehicles);
    next[index] = next[index].copyWith(
      isActive: false,
      updatedAt: DateTime.now().toUtc(),
    );
    _vehicles = next;
    await _persist();
    notifyListeners();
    return true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _store.setNotificationsEnabled(enabled);
    notifyListeners();
  }

  @override
  Future<void> markNotificationPromptShown() async {
    _notificationPromptShown = true;
    await _store.setNotificationPromptShown(true);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.saveVehicles(_vehicles);
  }

  int _nextFreeSlot() {
    final used = {
      for (final v in _vehicles.where((v) => v.isActive)) v.notificationSlot,
    };
    for (var slot = 0; slot < 100; slot++) {
      if (!used.contains(slot)) return slot;
    }
    return 0;
  }

  AtVehicle? _normalize(AtVehicle vehicle) {
    final label = vehicle.label.trim();
    final plate = vehicle.plate.trim().toUpperCase();
    final countryCode = vehicle.countryCode.trim().toUpperCase();
    final countryLabel = vehicle.countryLabel.trim();
    final notes = vehicle.notes?.trim();
    final duration = vehicle.durationDays;

    if (label.isEmpty ||
        plate.isEmpty ||
        countryCode.isEmpty ||
        countryLabel.isEmpty ||
        duration <= 0) {
      return null;
    }

    final entry = AtCalculator.calendarDay(vehicle.entryDate);
    final expiry = AtCalculator.calendarDay(vehicle.expiryDate);
    if (expiry.isBefore(entry)) return null;

    final now = DateTime.now().toUtc();
    return vehicle.copyWith(
      label: label,
      plate: plate,
      countryCode: countryCode,
      countryLabel: countryLabel,
      entryDate: entry,
      expiryDate: expiry,
      durationDays: duration,
      notes: (notes == null || notes.isEmpty) ? null : notes,
      clearNotes: notes == null || notes.isEmpty,
      createdAt: vehicle.createdAt,
      updatedAt: now,
      isActive: true,
    );
  }
}
