# Localization & translations — how to add more

The app exposes only what is actually implemented. UI languages are gated by
`AppLanguage.implemented`; Bible translations are gated by what the content DB
actually contains (`availableTranslationsProvider`). Nothing "future" is shown
until it ships.

## UI languages

**Implemented today:** Portuguese (`pt`), English (`en`).

Strings live in `lib/l10n/app_pt.arb` (template peer) and `lib/l10n/app_en.arb`
(`app_en.arb` is the `template-arb-file` in `l10n.yaml`). All user-facing text
must go through `context.l10n` — no hardcoded strings. New keys added in any task
must be filled for **both** pt and en.

### To add a new UI language (e.g. Spanish `es`, Italian `it`, Latin `la`)

1. Create `lib/l10n/app_<code>.arb` with every key from `app_en.arb` translated.
2. `flutter gen-l10n` (regenerates `app_localizations*.dart`).
3. Add the enum value to `AppLanguage` if missing, then add it to
   `AppLanguage.implemented` in `lib/features/settings/domain/settings.dart`.
4. In `lib/app/app.dart`, map the code in `_localeFor` (currently only en→en,
   else pt) and ensure `AppL10n.supportedLocales` includes it (auto from ARBs).
5. The onboarding/Settings language pickers read `AppLanguage.implemented`, so the
   new language appears automatically once steps 1–3 are done.

Latin (`la`) as a UI language is feasible but low priority (chrome would need a
full Latin ARB); the Latin **Bible** already ships (see below).

## Bible translations

Translations are rows in the bundled content DB, surfaced by
`availableTranslationsProvider`. Onboarding and Settings list **only** these — a
user can never select a translation that isn't installed.

**Bundled today:** `pt_matos_soares` (default), `vulgata` (Latin), `pt_beta`
(legacy internal PT; still selectable while installed).

### To add a Bible translation

1. Obtain a **public-domain or properly licensed** text. Do not import
   legally-unclear sources.
2. Add an importer path (USFX via `dart run bin/import.dart usfx …`, or the
   `biblejson` shape for structured JSON; see `tool/build_content_db.sh` and
   `tool/importer/`), into the same bible DB; bump the package version in the
   manifest.
3. Validate (chapter/verse counts vs canon; `BETA=1 ./tool/check_release.sh`).
4. It then appears automatically in pickers and Parallel Reading.

### Recommended sources per language (future)

- **English (Catholic):** Douay–Rheims (Challoner) — public domain; available in
  USFX from open-bibles (`eng-dra`). Cleanest next addition.
- **Latin:** Clementine Vulgate already shipped; Nova Vulgata is copyrighted.
- **Spanish (Catholic):** Torres Amat or Félix Torres (PD candidates) need
  sourcing/validation; modern (BAC/CEE) are copyrighted.
- **Italian (Catholic):** Martini (PD, translator †1809) exists only as
  Archive.org scans/OCR — needs a cleanup effort; CEI is copyrighted.

Keep the rule: **only show what is installed; never import unclear texts.**
