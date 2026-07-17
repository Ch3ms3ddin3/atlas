import 'assistant_token_usage.dart';

/// Événements de streaming renvoyés par un [AssistantLlmProvider].
sealed class AssistantStreamEvent {
  const AssistantStreamEvent();
}

class AssistantStreamDelta extends AssistantStreamEvent {
  const AssistantStreamDelta(this.text);
  final String text;
}

class AssistantStreamUsage extends AssistantStreamEvent {
  const AssistantStreamUsage(this.usage);
  final AssistantTokenUsage usage;
}

class AssistantStreamDone extends AssistantStreamEvent {
  const AssistantStreamDone();
}

class AssistantStreamError extends AssistantStreamEvent {
  const AssistantStreamError(this.message, {this.isOffline = false});
  final String message;
  final bool isOffline;
}
