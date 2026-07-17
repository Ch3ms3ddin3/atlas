/// Rôle d'un message dans une conversation Atlas.
enum AssistantMessageRole { user, assistant, system }

/// État d'affichage d'un message assistant.
enum AssistantMessageStatus { streaming, complete, failed, offline }

/// Message d'une conversation Atlas.
class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = AssistantMessageStatus.complete,
    this.promptTokens,
    this.completionTokens,
  });

  final String id;
  final AssistantMessageRole role;
  final String content;
  final DateTime createdAt;
  final AssistantMessageStatus status;
  final int? promptTokens;
  final int? completionTokens;

  AssistantMessage copyWith({
    String? content,
    AssistantMessageStatus? status,
    int? promptTokens,
    int? completionTokens,
  }) {
    return AssistantMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      status: status ?? this.status,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'created_at': createdAt.toUtc().toIso8601String(),
        'status': status.name,
        if (promptTokens != null) 'prompt_tokens': promptTokens,
        if (completionTokens != null) 'completion_tokens': completionTokens,
      };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'] as String,
      role: AssistantMessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AssistantMessageRole.assistant,
      ),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      status: AssistantMessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AssistantMessageStatus.complete,
      ),
      promptTokens: json['prompt_tokens'] as int?,
      completionTokens: json['completion_tokens'] as int?,
    );
  }
}
