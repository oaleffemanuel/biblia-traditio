import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// Convenience accessor: `context.l10n.navHome`.
extension L10nX on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
