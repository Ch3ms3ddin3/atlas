import 'dart:async';
import 'dart:convert';

import '../../../../core/config/atlas_env.dart';
import '../../../../core/network/atlas_http_client.dart';
import '../../../../core/supabase/supabase_bootstrap.dart';
import '../../domain/assistant_knowledge_source.dart';
import '../../domain/assistant_llm_provider.dart';
import '../../domain/models/assistant_context_snapshot.dart';
import '../../domain/models/assistant_message.dart';
import '../../domain/models/assistant_stream_event.dart';
import '../../domain/models/assistant_token_usage.dart';
import '../assistant_system_prompt.dart';

/// OpenAI via Supabase Edge Function `assistant-chat` (clé secrète côté serveur).
class OpenAiEdgeAssistantProvider implements AssistantLlmProvider {
  OpenAiEdgeAssistantProvider({
    AtlasEnv? env,
    this.functionName = 'assistant-chat',
  }) : _env = env ?? AtlasEnv.fromCompileTime();

  final AtlasEnv _env;
  final String functionName;

  @override
  AssistantProviderKind get kind => AssistantProviderKind.openAi;

  @override
  String get displayName => 'OpenAI';

  @override
  AssistantProviderCapabilities get capabilities =>
      const AssistantProviderCapabilities();

  @override
  bool get isAvailable =>
      _env.isConfigured && SupabaseBootstrap.isInitialized;

  @override
  Stream<AssistantStreamEvent> streamChat({
    required List<AssistantMessage> messages,
    required AssistantContextSnapshot context,
    List<AssistantKnowledgeSnippet> knowledgeSnippets = const [],
  }) async* {
    if (!isAvailable) {
      yield const AssistantStreamError(
        AssistantSystemPrompt.offlineFallbackFr,
        isOffline: true,
      );
      return;
    }

    final base = _env.supabaseUrl.replaceAll(RegExp(r'/$'), '');
    final url = '$base/functions/v1/$functionName';
    final session = SupabaseBootstrap.clientOrNull()?.auth.currentSession;
    final bearer = session?.accessToken ?? _env.supabaseAnonKey;

    final payload = <String, dynamic>{
      'model': 'gpt-4o-mini',
      'context': context.toJson(),
      'system': AssistantSystemPrompt.build(context),
      'messages': [
        for (final message in messages)
          if (message.role != AssistantMessageRole.system)
            {
              'role': message.role.name,
              'content': message.content,
            },
      ],
      if (knowledgeSnippets.isNotEmpty)
        'knowledge': [
          for (final snippet in knowledgeSnippets)
            {
              'id': snippet.id,
              'title': snippet.title,
              'content': snippet.content,
              if (snippet.source != null) 'source': snippet.source,
            },
        ],
    };

    try {
      final stream = AtlasHttpClient.postJsonStream(
        url: url,
        headers: {
          'Authorization': 'Bearer $bearer',
          'apikey': _env.supabaseAnonKey,
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        },
        body: jsonEncode(payload),
      );

      var buffer = '';
      await for (final chunk in stream) {
        buffer += chunk;
        final parts = buffer.split('\n');
        buffer = parts.removeLast();
        for (final line in parts) {
          final event = _parseSseLine(line.trim());
          if (event != null) yield event;
        }
      }
      if (buffer.trim().isNotEmpty) {
        final event = _parseSseLine(buffer.trim());
        if (event != null) yield event;
      }
      yield const AssistantStreamDone();
    } catch (error) {
      final message = error.toString();
      final offline = message.contains('SocketException') ||
          message.contains('Failed host lookup') ||
          message.contains('Network is unreachable') ||
          message.contains('ClientException');
      yield AssistantStreamError(
        offline
            ? AssistantSystemPrompt.offlineFallbackFr
            : 'Assistant temporairement indisponible. Réessayez dans un instant.',
        isOffline: offline,
      );
    }
  }

  AssistantStreamEvent? _parseSseLine(String line) {
    if (line.isEmpty || line.startsWith(':')) return null;
    var data = line;
    if (data.startsWith('data:')) {
      data = data.substring(5).trim();
    }
    if (data == '[DONE]') return const AssistantStreamDone();
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String? ?? 'delta';
      switch (type) {
        case 'delta':
          final text = json['text'] as String? ?? '';
          if (text.isEmpty) return null;
          return AssistantStreamDelta(text);
        case 'usage':
          return AssistantStreamUsage(
            AssistantTokenUsage(
              promptTokens: json['prompt_tokens'] as int? ?? 0,
              completionTokens: json['completion_tokens'] as int? ?? 0,
            ),
          );
        case 'error':
          return AssistantStreamError(
            json['message'] as String? ?? 'Erreur assistant',
            isOffline: json['offline'] as bool? ?? false,
          );
        case 'done':
          return const AssistantStreamDone();
        default:
          final text = json['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return AssistantStreamDelta(text);
          }
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}
