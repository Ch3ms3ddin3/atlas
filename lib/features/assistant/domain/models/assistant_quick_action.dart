import 'package:flutter/material.dart';

/// Action rapide — navigation native Atlas uniquement (pas de prompt LLM).
class AssistantQuickAction {
  const AssistantQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.shellTabIndex,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Index [AtlasShellTab] cible.
  final int shellTabIndex;
}
