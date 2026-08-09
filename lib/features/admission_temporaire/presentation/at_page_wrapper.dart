import 'package:flutter/widgets.dart';

import '../domain/at_repository.dart';
import 'at_scope.dart';

/// Réinjecte [AtScope] sur une route poussée hors de l'arbre du shell.
///
/// `AtScope` vit sous [AppShell] ; un `Navigator.push` racine place la page
/// hors de ce scope. Sans ce wrap, `AtScope.of` plante en profile/release
/// (`Null check operator used on a null value`).
///
/// Passer le [repository] capturé **avant** le push (depuis un context encore
/// sous le shell) — ne pas relire le scope depuis le context du [pageBuilder].
Widget wrapWithAtScope(AtRepository repository, Widget child) {
  return AtScope(repository: repository, child: child);
}
