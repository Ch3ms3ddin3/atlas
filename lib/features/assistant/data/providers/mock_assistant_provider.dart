import '../../domain/assistant_knowledge_source.dart';
import '../../domain/assistant_llm_provider.dart';
import '../../domain/models/assistant_context_snapshot.dart';
import '../../domain/models/assistant_message.dart';
import '../../domain/models/assistant_stream_event.dart';
import '../../domain/models/assistant_token_usage.dart';
import '../assistant_system_prompt.dart';

/// Provider local pour tests / démo sans backend.
class MockAssistantProvider implements AssistantLlmProvider {
  MockAssistantProvider({
    this.chunkDelay = const Duration(milliseconds: 12),
    this.replyBuilder,
  });

  final Duration chunkDelay;
  final String Function(
    List<AssistantMessage> messages,
    AssistantContextSnapshot context,
  )? replyBuilder;

  @override
  AssistantProviderKind get kind => AssistantProviderKind.mock;

  @override
  String get displayName => 'Atlas Mock';

  @override
  AssistantProviderCapabilities get capabilities =>
      const AssistantProviderCapabilities();

  @override
  bool get isAvailable => true;

  @override
  Stream<AssistantStreamEvent> streamChat({
    required List<AssistantMessage> messages,
    required AssistantContextSnapshot context,
    List<AssistantKnowledgeSnippet> knowledgeSnippets = const [],
  }) async* {
    final lastUser = messages.reversed
        .firstWhere(
          (m) => m.role == AssistantMessageRole.user,
          orElse: () => AssistantMessage(
            id: 'empty',
            role: AssistantMessageRole.user,
            content: '',
            createdAt: DateTime.now().toUtc(),
          ),
        )
        .content
        .trim();

    final reply = replyBuilder?.call(messages, context) ??
        _defaultReply(lastUser, context);

    // Ignore system prompt length for mock token estimate.
    final promptEstimate =
        AssistantSystemPrompt.build(context).length ~/ 4 + lastUser.length ~/ 4;
    var emitted = 0;
    const step = 18;
    while (emitted < reply.length) {
      final end = (emitted + step).clamp(0, reply.length);
      final delta = reply.substring(emitted, end);
      emitted = end;
      yield AssistantStreamDelta(delta);
      if (chunkDelay > Duration.zero) {
        await Future<void>.delayed(chunkDelay);
      }
    }
    yield AssistantStreamUsage(
      AssistantTokenUsage(
        promptTokens: promptEstimate,
        completionTokens: reply.length ~/ 4,
      ),
    );
    yield const AssistantStreamDone();
  }

  String _defaultReply(String question, AssistantContextSnapshot context) {
    final buffer = StringBuffer()
      ..writeln('Voici ce que je peux dire avec le contexte Atlas actuel :')
      ..writeln()
      ..writeln('• Ville : ${context.city}')
      ..writeln('• Profil : ${context.userType}');
    if (context.weatherSummary != null) {
      buffer.writeln('• Météo : ${context.weatherSummary}');
    } else {
      buffer.writeln('• Météo : indisponible dans Atlas pour le moment.');
    }
    if (context.exchangeRateSummary != null) {
      buffer.writeln('• Change : ${context.exchangeRateSummary}');
    }
    if (context.vehicleSummaries.isNotEmpty) {
      buffer.writeln(
        '• AT : ${context.vehicleSummaries.take(2).join(' ; ')}',
      );
    }
    buffer
      ..writeln()
      ..writeln(
        question.isEmpty
            ? 'Posez-moi une question sur votre quotidien au Maroc.'
            : 'Pour « $question », utilisez aussi Explorer, la Carte ou Démarches '
                'si vous souhaitez agir dans l\'app.',
      );
    return buffer.toString().trim();
  }
}
