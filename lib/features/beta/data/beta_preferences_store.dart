import 'package:shared_preferences/shared_preferences.dart';

/// Préférences beta : dernier build vu (What's New) + file d'attente feedback.
class BetaPreferencesStore {
  const BetaPreferencesStore();

  static const lastSeenBuildKey = 'beta_last_seen_build';
  static const pendingFeedbackKey = 'beta_pending_feedback_json';

  Future<int> loadLastSeenBuild() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lastSeenBuildKey) ?? 0;
  }

  Future<void> saveLastSeenBuild(int buildNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastSeenBuildKey, buildNumber);
  }

  Future<String?> loadPendingFeedbackJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(pendingFeedbackKey);
  }

  Future<void> savePendingFeedbackJson(String? json) async {
    final prefs = await SharedPreferences.getInstance();
    if (json == null || json.isEmpty) {
      await prefs.remove(pendingFeedbackKey);
    } else {
      await prefs.setString(pendingFeedbackKey, json);
    }
  }
}
