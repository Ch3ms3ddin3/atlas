import 'assistant_message.dart';

/// Conversation locale Atlas (historique v1 local-only).
class AssistantConversation {
  const AssistantConversation({
    required this.id,
    required this.messages,
    required this.updatedAt,
    this.title,
  });

  final String id;
  final String? title;
  final List<AssistantMessage> messages;
  final DateTime updatedAt;

  bool get isEmpty => messages.isEmpty;

  AssistantConversation copyWith({
    String? title,
    List<AssistantMessage>? messages,
    DateTime? updatedAt,
  }) {
    return AssistantConversation(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory AssistantConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    return AssistantConversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      messages: [
        for (final item in rawMessages)
          if (item is Map<String, dynamic>) AssistantMessage.fromJson(item),
      ],
    );
  }
}
