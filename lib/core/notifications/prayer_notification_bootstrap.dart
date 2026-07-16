import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/home/data/prayer/prayer_notification_coordinator.dart';
import '../../features/home/data/prayer/prayer_repository.dart';

late final PrayerNotificationCoordinator prayerNotificationCoordinator;

/// Initialise le fuseau Africa/Casablanca et synchronise les rappels au lancement.
Future<void> bootstrapPrayerNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));

  final prayerRepository = PrayerRepository();
  PrayerRepository.registerInstance(prayerRepository);
  prayerNotificationCoordinator = PrayerNotificationCoordinator(
    prayerRepository: prayerRepository,
  );
  await prayerNotificationCoordinator.bootstrap();
}

/// Fournit un coordinateur pour les tests widget sans initialiser les plugins natifs.
void ensurePrayerNotificationCoordinatorForTests({
  PrayerRepository? prayerRepository,
}) {
  final repository = prayerRepository ?? PrayerRepository();
  PrayerRepository.registerInstance(repository);
  prayerNotificationCoordinator = PrayerNotificationCoordinator(
    prayerRepository: repository,
  );
}
