/// Psalm numbering bridge.
///
/// Biblia Traditio's scripture (Clementine Vulgate + Matos Soares) uses the
/// traditional **Vulgate/Septuagint** psalm numbering. Most modern readers know
/// the **Hebrew/Masoretic** numbers (e.g. "Psalm 23" = the Good Shepherd). The
/// two diverge for most of the Psalter because the Vulgate merges Hebrew 9+10
/// (so the rest shifts by one), with merge/split regions around 113–117 and 147.
///
/// This is the single source of truth for:
///  - the secondary "(Hebrew)" number shown beside Vulgate psalms, and
///  - resolving a Hebrew psalm number to the Vulgate chapter for navigation,
///    search, and the reading plan.
///
/// Scripture, the Latin, and stored annotations are never renumbered — only the
/// display label and lookups are bridged. (Mirror of the importer's
/// `psalmHebrewToVulgate`, kept in sync.)
class PsalmNumbering {
  const PsalmNumbering._();

  /// Hebrew/Masoretic psalm number → Vulgate chapter the app stores.
  /// For Hebrew psalms that the Vulgate splits across two, returns the first.
  static int hebrewToVulgate(int h) {
    if (h <= 8) return h;
    if (h == 9 || h == 10) return 9; // Vulgate 9 = Hebrew 9 + 10
    if (h <= 113) return h - 1; // 11..113 → 10..112
    if (h == 114 || h == 115) return 113; // Vulgate 113 = Hebrew 114 + 115
    if (h == 116) return 114; // Hebrew 116 spans Vulgate 114–115 → first
    if (h <= 146) return h - 1; // 117..146 → 116..145
    if (h == 147) return 146; // Hebrew 147 spans Vulgate 146–147 → first
    return h; // 148..150 coincide
  }

  /// The Hebrew number(s) to show in parentheses beside a Vulgate psalm, or
  /// null when the two numbering systems agree (Ps 1–8, 148–150) so no suffix
  /// is shown. May be a range (e.g. Vulgate 9 → "9-10").
  static String? hebrewLabel(int vulgate) {
    if (vulgate <= 8) return null;
    if (vulgate == 9) return '9-10';
    if (vulgate <= 112) return '${vulgate + 1}'; // 10..112 → 11..113
    if (vulgate == 113) return '114-115';
    if (vulgate == 114 || vulgate == 115) return '116';
    if (vulgate <= 145) return '${vulgate + 1}'; // 116..145 → 117..146
    if (vulgate == 146 || vulgate == 147) return '147';
    return null; // 148..150
  }

  /// "22 (23)" for Vulgate psalms whose Hebrew number differs, else "22".
  static String dualLabel(int vulgate) {
    final h = hebrewLabel(vulgate);
    return h == null ? '$vulgate' : '$vulgate ($h)';
  }
}
