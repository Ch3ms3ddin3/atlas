import '../domain/at_repository.dart';
import 'at_notification_coordinator.dart';
import 'local_at_repository.dart';
import 'syncing_at_repository.dart';

AtNotificationCoordinator? _atNotificationCoordinator;
AtRepository? _atRepository;

/// Repository partagé (lazy — sync cloud quand Supabase est prêt).
AtRepository get atRepository {
  return _atRepository ??= SyncingAtRepository();
}

AtNotificationCoordinator get atNotificationCoordinator {
  return _atNotificationCoordinator ??=
      AtNotificationCoordinator(repository: atRepository);
}

/// Initialise repository + coordinator (idempotent).
Future<void> ensureAtNotificationCoordinator({
  AtRepository? repository,
  AtNotificationCoordinator? coordinator,
}) async {
  if (repository != null) {
    _atRepository = repository;
  } else {
    _atRepository ??= SyncingAtRepository();
  }
  if (!_atRepository!.isLoaded) {
    await _atRepository!.load();
  }

  _atNotificationCoordinator = coordinator ??
      AtNotificationCoordinator(repository: _atRepository!);
  await _atNotificationCoordinator!.bootstrap();
}

/// Variante tests sans plugins natifs.
void ensureAtRepositoryForTests({AtRepository? repository}) {
  _atRepository = repository ?? LocalAtRepository();
  _atNotificationCoordinator = AtNotificationCoordinator(
    repository: _atRepository!,
  );
}

void resetAtBootstrapForTests() {
  _atRepository = null;
  _atNotificationCoordinator = null;
}
