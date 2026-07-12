import 'package:flutter/material.dart';

import 'app/atlas_app.dart';
import 'core/notifications/prayer_notification_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapPrayerNotifications();
  runApp(const AtlasApp());
}
