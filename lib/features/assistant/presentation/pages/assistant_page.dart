import 'package:flutter/material.dart';

import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../itineraries/presentation/pages/trip_list_page.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../domain/assistant_repository.dart';
import '../assistant_scope.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/assistant_quick_actions_row.dart';
import '../widgets/assistant_suggestions_wrap.dart';

/// Écran Assistant Atlas — expérience native, pas un chatbot générique.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      AtlasPageRoute(page: const AssistantPage()),
    );
  }

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  AssistantRepository? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AssistantScope.of(context);
    if (!identical(repository, _repository)) {
      _repository?.removeListener(_onRepo);
      _repository = repository;
      _repository!.addListener(_onRepo);
      if (!_repository!.isLoaded) {
        _repository!.load();
      } else {
        _repository!.refreshContextHints();
      }
    }
  }

  @override
  void dispose() {
    _repository?.removeListener(_onRepo);
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRepo() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _composer.text).trim();
    if (text.isEmpty) return;
    _composer.clear();
    await _repository?.sendUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = AssistantScope.of(context);
    final profile = ProfileScope.of(context).profile;
    final conversation = repository.activeConversation;
    final messages = conversation.messages;
    final showEmptyChrome = messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Atlas'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle conversation',
            onPressed: repository.isStreaming
                ? null
                : () => repository.startNewConversation(),
            icon: const Icon(Icons.edit_note_outlined),
          ),
          if (repository.conversations.length > 1)
            IconButton(
              tooltip: 'Historique',
              onPressed: () => _openHistory(context, repository),
              icon: const Icon(Icons.history_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: AtlasSpacing.lg),
                children: [
                  AtlasContentContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AtlasPageHeader(
                          title: 'Bonjour ${profile.resolvedDisplayName}',
                          subtitle:
                              'Contexte : ${profile.preferredCity} · ${profile.userType.label}',
                        ),
                        if (repository.statusMessage != null) ...[
                          const SizedBox(height: AtlasSpacing.md),
                          AtlasCard(
                            emphasis: AtlasCardEmphasis.compact,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  repository.isOfflineFallback
                                      ? Icons.cloud_off_outlined
                                      : Icons.info_outline,
                                  color: AtlasColors.midnightBlueMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: AtlasSpacing.sm),
                                Expanded(
                                  child: Text(
                                    repository.statusMessage!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AtlasSpacing.lg),
                        AssistantQuickActionsRow(
                          onAction: (action) {
                            if (action.id == 'itineraries') {
                              Navigator.of(context).pop();
                              TripListPage.open(context);
                              return;
                            }
                            Navigator.of(context).pop();
                            ShellNavigationScope.goToTab(
                              context,
                              action.shellTabIndex,
                            );
                          },
                        ),
                        if (showEmptyChrome) ...[
                          const SizedBox(height: AtlasSpacing.xl),
                          AssistantSuggestionsWrap(
                            suggestions: repository.suggestions,
                            enabled: repository.canSendMessage,
                            onSelected: (s) => _send(s.prompt),
                          ),
                          const SizedBox(height: AtlasSpacing.xl),
                          const AtlasEmptyState(
                            icon: Icons.auto_awesome_outlined,
                            message:
                                'Posez une question sur la météo, le change, '
                                'vos démarches ou votre Admission Temporaire. '
                                'Atlas s’appuie sur vos données — jamais sur des inventions.',
                          ),
                        ] else ...[
                          const SizedBox(height: AtlasSpacing.xl),
                          for (final message in messages)
                            AssistantMessageBubble(message: message),
                          if (!repository.isStreaming &&
                              repository.suggestions.isNotEmpty) ...[
                            const SizedBox(height: AtlasSpacing.md),
                            AssistantSuggestionsWrap(
                              suggestions: repository.suggestions,
                              enabled: repository.canSendMessage,
                              onSelected: (s) => _send(s.prompt),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _ComposerBar(
              controller: _composer,
              enabled: repository.canSendMessage,
              isStreaming: repository.isStreaming,
              usageLabel:
                  '${repository.remainingMessagesToday}/${repository.dailyMessageLimit} messages · '
                  '${repository.dailyUsage.usage.totalTokens} tokens aujourd’hui',
              onSend: _send,
              onCancel: repository.cancelStreaming,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openHistory(
    BuildContext context,
    AssistantRepository repository,
  ) async {
    await showAtlasBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Conversations'),
                subtitle: Text('Historique local sur cet appareil'),
              ),
              for (final conversation in repository.conversations)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(
                    conversation.title?.trim().isNotEmpty == true
                        ? conversation.title!
                        : 'Conversation',
                  ),
                  subtitle: Text(
                    '${conversation.messages.length} messages',
                  ),
                  selected: conversation.id == repository.activeConversation.id,
                  onTap: () {
                    repository.openConversation(conversation.id);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.enabled,
    required this.isStreaming,
    required this.usageLabel,
    required this.onSend,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isStreaming;
  final String usageLabel;
  final Future<void> Function() onSend;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      color: AtlasColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.lg,
          AtlasSpacing.sm,
          AtlasSpacing.lg,
          AtlasSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              usageLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AtlasColors.midnightBlueFaint,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled && !isStreaming,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: enabled && !isStreaming ? (_) => onSend() : null,
                    decoration: const InputDecoration(
                      hintText: 'Demander à Atlas…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AtlasSpacing.sm),
                if (isStreaming)
                  IconButton.filled(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_rounded),
                    tooltip: 'Arrêter',
                  )
                else
                  IconButton.filled(
                    onPressed: enabled ? onSend : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    tooltip: 'Envoyer',
                  ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.xs),
            Text(
              'Réponses basées sur les données Atlas disponibles.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AtlasColors.midnightBlueFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
