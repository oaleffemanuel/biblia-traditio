import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../core/snack.dart';

/// How long the reader has to confirm an exit by pressing Back a second time.
const kExitConfirmWindow = Duration(seconds: 2);

/// What the Android Back button should do at a given moment.
enum BackAction {
  /// A tab other than Home is showing its root screen → go Home first.
  goHome,

  /// Home is showing → warn once, then exit on a second press in the window.
  warnBeforeExit,

  /// The warning is still on screen → this press exits.
  exit,
}

/// Decides the Back behaviour from the current tab and the time of the last
/// press. Pure so the rule is testable without a widget tree.
///
/// Secondary screens never reach here: go_router pops the branch navigator
/// before the shell is consulted, so normal back navigation always wins first.
BackAction resolveBackAction({
  required int currentIndex,
  required DateTime? lastPress,
  required DateTime now,
}) {
  if (currentIndex != 0) return BackAction.goHome;
  if (lastPress != null && now.difference(lastPress) <= kExitConfirmWindow) {
    return BackAction.exit;
  }
  return BackAction.warnBeforeExit;
}

/// Wraps the tab shell so Android Back walks *out* of the app in stages —
/// secondary screen → tab root → Home → confirm → exit — instead of closing
/// the app under the reader's thumb.
class BackNavigationScope extends StatefulWidget {
  final StatefulNavigationShell navShell;
  final Widget child;
  const BackNavigationScope(
      {super.key, required this.navShell, required this.child});

  @override
  State<BackNavigationScope> createState() => _BackNavigationScopeState();
}

class _BackNavigationScopeState extends State<BackNavigationScope> {
  DateTime? _lastPress;

  void _handle(BuildContext context) {
    final action = resolveBackAction(
      currentIndex: widget.navShell.currentIndex,
      lastPress: _lastPress,
      now: DateTime.now(),
    );
    switch (action) {
      case BackAction.goHome:
        _lastPress = null;
        widget.navShell.goBranch(0);
      case BackAction.warnBeforeExit:
        _lastPress = DateTime.now();
        showSnack(context.l10n.pressBackAgainToExit);
      case BackAction.exit:
        _lastPress = null;
        // Only Android has a Back button to honour this way; on other
        // platforms quitting from a button is not the convention.
        if (!kIsWeb && Platform.isAndroid) SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Always false: this scope only ever sees a Back press that the branch
      // navigator already declined, and every such press is handled here.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handle(context);
      },
      child: widget.child,
    );
  }
}
