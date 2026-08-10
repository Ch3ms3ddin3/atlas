import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_repository.dart';
import '../auth_scope.dart';
import 'password_recovery_sheet.dart';

/// Ouvre [PasswordRecoverySheet] dès qu'une session `PASSWORD_RECOVERY` est active.
class AuthPasswordRecoveryListener extends StatefulWidget {
  const AuthPasswordRecoveryListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AuthPasswordRecoveryListener> createState() =>
      _AuthPasswordRecoveryListenerState();
}

class _AuthPasswordRecoveryListenerState
    extends State<AuthPasswordRecoveryListener> {
  AuthRepository? _auth;
  bool _sheetVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (!identical(_auth, auth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth;
      _auth!.addListener(_onAuthChanged);
    }
    _onAuthChanged();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted || _sheetVisible) return;
    final auth = _auth;
    if (auth == null || !auth.isPasswordRecoveryPending) return;

    _sheetVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await PasswordRecoverySheet.show(context);
      } finally {
        if (mounted) {
          _sheetVisible = false;
          final current = _auth;
          if (current != null && current.isPasswordRecoveryPending) {
            unawaited(current.cancelPasswordRecovery());
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
