import 'package:flutter/material.dart';

/// App-wide messenger so transient confirmations can be shown without a
/// Scaffold context (e.g. from inside modal sheets or after a pop). Wired into
/// MaterialApp.router via `scaffoldMessengerKey`.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shows a brief, single confirmation toast. Clears any in-flight snack first
/// so rapid taps (e.g. toggling a favorite) don't stack.
void showSnack(String message, {SnackBarAction? action}) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      action: action,
    ));
}
