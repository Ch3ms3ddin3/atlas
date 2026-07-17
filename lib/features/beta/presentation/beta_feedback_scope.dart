import 'package:flutter/material.dart';

import '../data/beta_feedback_repository.dart';

class BetaFeedbackScope extends InheritedNotifier<BetaFeedbackRepository> {
  const BetaFeedbackScope({
    super.key,
    required BetaFeedbackRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static BetaFeedbackRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BetaFeedbackScope>();
    assert(scope != null, 'BetaFeedbackScope introuvable.');
    return scope!.notifier!;
  }

  static BetaFeedbackRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BetaFeedbackScope>()
        ?.notifier;
  }
}
