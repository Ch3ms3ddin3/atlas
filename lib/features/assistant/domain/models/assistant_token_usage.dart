/// Compteurs de tokens pour un tour ou une période.
class AssistantTokenUsage {
  const AssistantTokenUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
  });

  const AssistantTokenUsage.zero() : this();

  final int promptTokens;
  final int completionTokens;

  int get totalTokens => promptTokens + completionTokens;

  AssistantTokenUsage operator +(AssistantTokenUsage other) {
    return AssistantTokenUsage(
      promptTokens: promptTokens + other.promptTokens,
      completionTokens: completionTokens + other.completionTokens,
    );
  }

  Map<String, dynamic> toJson() => {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
      };

  factory AssistantTokenUsage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AssistantTokenUsage.zero();
    return AssistantTokenUsage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
    );
  }
}

/// Usage journalier local (soft cap + affichage).
class AssistantDailyUsage {
  const AssistantDailyUsage({
    required this.dayKey,
    required this.messageCount,
    required this.usage,
  });

  final String dayKey;
  final int messageCount;
  final AssistantTokenUsage usage;

  AssistantDailyUsage copyWith({
    int? messageCount,
    AssistantTokenUsage? usage,
  }) {
    return AssistantDailyUsage(
      dayKey: dayKey,
      messageCount: messageCount ?? this.messageCount,
      usage: usage ?? this.usage,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_key': dayKey,
        'message_count': messageCount,
        'usage': usage.toJson(),
      };

  factory AssistantDailyUsage.fromJson(Map<String, dynamic> json) {
    return AssistantDailyUsage(
      dayKey: json['day_key'] as String? ?? '',
      messageCount: json['message_count'] as int? ?? 0,
      usage: AssistantTokenUsage.fromJson(
        json['usage'] as Map<String, dynamic>?,
      ),
    );
  }
}
