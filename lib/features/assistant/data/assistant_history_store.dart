import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/assistant_conversation.dart';

/// Persistance locale des conversations (v1 local-only).
class AssistantHistoryStore {
  const AssistantHistoryStore();

  static const conversationsKey = 'assistant_conversations_v1';
  static const activeIdKey = 'assistant_active_conversation_id_v1';

  Future<List<AssistantConversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(conversationsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            AssistantConversation.fromJson(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<String?> loadActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(activeIdKey);
  }

  Future<void> save({
    required List<AssistantConversation> conversations,
    required String? activeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      conversationsKey,
      jsonEncode(conversations.map((c) => c.toJson()).toList()),
    );
    if (activeId == null) {
      await prefs.remove(activeIdKey);
    } else {
      await prefs.setString(activeIdKey, activeId);
    }
  }
}
