# Biblia Traditio — Complete Build Blueprint

> *"Scripture in the Light of Tradition"*
>
> The most beautiful, traditional, spiritually rich, and technically excellent **Catholic** Bible app for iOS & Android (Flutter), architected to grow to tablet, macOS, and web.

This blueprint is grounded in two real assets inspected on disk:

- **Patristic corpus** — `~/Downloads/Bíblia Católica Tradicional - Comentada/Comentários/` — 70 verse-keyed JSON files + an alias map.
- **iacula-mobile** — `~/workspace/iacula-mobile/iacula_app/` — a mature offline-first Flutter app whose Clean Architecture, storage layering, DI, theme, onboarding, and **existing `bible` feature** we adopt as the foundation.

---

## 0. Two decisions to confirm before building

| # | Question | What I found / recommend |
|---|----------|--------------------------|
| **A** | **3 tabs or 5?** Your written spec says **3 tabs** (Home, Liturgy, Bible). The screenshots show **5** (Início, Liturgia, Plano, Bíblia, Explorar). | Build **3 tabs** as specified. Reach `Plano` (Reading Plan) and `Explorar` (Search/Patristics hub) through flows now; promote them to tabs later only if usage demands. The router (StatefulShellRoute) makes adding a 4th/5th branch a one-line change. |
| **B** | **Matos Soares text source.** | The 1932 Matos Soares translation text is the goal. Copyright in Brazil lasts **70 years after the translator's death** (Lei 9.610/98). The legally safe path is the **public-domain primary text**, *not* MBC's specific edition (their layout/notes/typesetting are a separate protectable work). See §16 — confirm the death date before shipping. |

Everything below assumes 3 tabs and a PD-sourced primary translation, both easily changed.

---

## Build status (what is already implemented & verified)

> Confirmed decisions: **3 tabs**; scaffold app + importer.

**Importer (`tool/importer/`) — DONE & verified on real data.**
- 4-stage pipeline (parse → validate → normalize → build SQLite+FTS5) with the anti-drift heading detector and validation layer; `dart test` passes (incl. the exact `LIVRO SAPIENCIAL` failure case).
- Ran on the real corpus: **73 books, 223 Fathers, 57,485 commentaries, 0 unresolved book codes**; offline FTS5 search works and is diacritic-insensitive; centuries auto-derived from year; machine-translation flag set. Output DB 103 MB (text-bound; ship compressed/as a pack).

**Flutter app (`lib/`) — foundation scaffolded, `flutter analyze` clean (0 issues).**
- Stack: Flutter 3.44 / Dart 3.12, Riverpod 3.3, GoRouter `StatefulShellRoute` (3 tabs), `sqlite3` read-only content DB.
- Theme tokens matching the screenshots (near-black + terracotta, EB Garamond serif Scripture / Inter chrome), light+dark.
- Screens: Home (greeting, quick-action cards, liturgy preview), Liturgy (date strip + celebration card shell), **Bible Library (reads the real 73 books)**, Chapters grid, **Reader** (medallion header, interleaved section headings, superscript verse numbers, marginal "Fathers" glyph, verse action bar), **Patristic sheet** (author · century · source, wired to the real corpus), Settings (shows installed patristics count).
- Content DB resolves on-device (dev copies the importer output in on first run).

**User-data layer — DONE & verified (`flutter test` green).**
- Writable SQLite store (`lib/core/storage/user/user_database.dart`) for notes, highlights, bookmarks, favorites, reading progress. Every row carries `uuid + updated_at + is_dirty + is_deleted` → drop-in last-write-wins sync later.
- Wired into the Reader: 5-color highlights (with on-verse background), bookmark/favorite toggles, note editor (create/edit/delete), and "Continue Reading" recorded per chapter. Notes/Favorites/Highlights list screens + Home quick-action counts.
- 4 unit tests cover upsert/remove, toggles, note CRUD+search (soft-delete excluded), single-row progress.

> **Deliberate deviation from §5.2/§6 (Isar → SQLite for user data).** Isar 3 (OSS) is abandoned and its generator pins an old `analyzer` that conflicts with Riverpod 3 + modern `flutter_test` (version solve fails). User data therefore uses a writable `sqlite3` DB — same engine as the content DB, no codegen, fully under control. The sync-ready columns preserve the blueprint's Phase-2 sync plan. If Isar is required later, the maintained `isar_community` fork is the drop-in; otherwise Drift is the SQLite-native alternative. **At-rest encryption** (SQLCipher or field-level) remains a documented follow-up — data currently lives in the OS app-private sandbox.

**Global search — DONE & verified.**
- Unified offline search across **Scripture (FTS5)**, **patristics (FTS5)**, and **notes** (`lib/features/search/`), with debounced input, scope chips (Tudo/Escritura/Padres/Notas + live counts), and FTS5 `snippet()` excerpts with matched terms emphasised. Diacritic-insensitive (`misericordia` → `misericórdia`), confirmed against the real 57k-commentary corpus. Entry point: search icon on Home; results deep-link into the Reader.

**Onboarding + settings — DONE & verified.**
- Elegant 6-step carousel (`lib/features/onboarding/`): welcome → name → UI language → translation → notifications → reading-plan, with AnimatedSwitcher fade+slide, progress dots, name-gated button, and skip option; choices persist to an `app_setting` KV table in the user DB.
- `settingsProvider`/`SettingsController` make settings the app's source of truth — name (Home greeting), translation (Reader/Search queries), UI language, **theme mode (light/dark/system, live)**, notifications, reading-plan flag. Settings screen edits them all.
- Routing gates on `onboardingCompleted` (router is a `Provider.family<GoRouter,bool>`; the app shows a splash until the user DB opens, then picks `/onboarding` vs `/home`). Verified: 3 settings round-trip tests + a widget test walking all 6 onboarding steps to completion. Full suite: **8 tests green** + `flutter analyze` clean.

**Liturgical calendar — DONE & verified (accurate, offline, data-free).**
- A pure computation engine (`lib/features/liturgy/domain/liturgical_calendar.dart`) derives — from the date alone — the season, liturgical colour, Sunday cycle (A/B/C), weekday cycle (I/II), and the movable + principal fixed solemnities (Easter computus → Ash Wed, Palm Sunday, Triduum, Ascension, Pentecost, Trinity, Corpus Christi, Sacred Heart, Christ the King; plus Christmas/Epiphany/Assumption/All Saints/Immaculate Conception, etc.), incl. Gaudete/Laetare rose.
- Liturgy tab rewired to real data: date strip with per-day computed colour dots, a real celebration card (title · season · Ano A/B/C · rank · colour), and a **calendar modal** (month grid with colour dots, month nav, Confirmar) matching the screenshots.
- **7 calendar tests** validate it — incl. the exact screenshot day (12 Jun 2026 = Sacred Heart, Tempo Comum, **Ano A**), Easter dates 2024-27, cycle rotation, season colours, fixed solemnities. Full suite now **15 tests green**, `flutter analyze` clean.
- **Readings** are deliberately behind a `LectionaryRepository` interface (empty until a pack ships) — the calendar is exact; fabricating Scripture references would be unacceptable. The tab shows a clear "Lecionário em breve" notice.

**Pending next:** scripture text import (awaits the legal call on Matos Soares) + lectionary pack, Parallel Reading Mode, localization (ARB) wiring, at-rest encryption.

---

## 1. Product Requirements Document (PRD)

### Vision
A sacred, timeless, calm reading environment that unites **Scripture + Tradition**: the Catholic canon (73 books incl. deuterocanon), multiple translations and languages read side-by-side, and the **Church Fathers' commentary attached to individual verses** — all fully offline.

### Non-negotiable principles
- **Offline-first.** After first install/import, *zero* network needed for reading, notes, highlights, liturgy, or patristics.
- **Catholic by construction.** 73-book canon, Catholic versification, liturgical calendar (General Roman Calendar), traditional sensibility. Never a Protestant 66-book layout.
- **No gamification.** No streaks, points, badges, social feeds, or public profiles. Calm over engagement-bait.
- **Beauty as a feature.** Serif scripture typography, engraved book emblems, restrained terracotta-on-near-black palette (per screenshots), generous whitespace.

### Target users
Catholics who pray and study: daily-Mass-readings followers, lectio divina practitioners, catechists, seminarians, traditionally-minded faithful who want the Fathers at hand.

### Personas (abbreviated)
- **The Daily Pray-er** — opens to today's liturgy + a short reading. Wants speed and calm.
- **The Student** — reads with the Fathers open, takes notes, compares Latin/Portuguese.
- **The Catechist** — searches across Scripture + Fathers to prepare lessons; exports notes.

### Functional requirements (MVP-tagged in §12)
1. Browse OT/NT → book → chapter → verse, with engraved book emblems.
2. Premium reading view: adjustable font size & line spacing, light/dark, verse actions (copy, share, highlight, bookmark, favorite, note, "Church Fathers").
3. **Parallel Reading Mode** — two synchronized, verse-aligned columns across translations/languages.
4. **Patristic Commentary panel** per verse (author, century/year, source, text).
5. Liturgy tab — horizontal date strip + calendar modal, celebration metadata (season, color, year A/B/C), expandable readings (1st, Psalm, 2nd, Gospel).
6. Home — greeting, quick-action cards, daily liturgy preview.
7. Notes & Highlights — local, verse-attached, searchable, editable, exportable.
8. **Global offline search** across books, verses, notes, highlights, and patristics.
9. Onboarding — name, language, translation, notifications, reading-plan opt-in.
10. Settings — name, language, translation, theme, font, notifications, downloaded resources.

### Non-functional
- Cold start < 1.5s; chapter open < 100ms; search first results < 200ms (FTS5).
- Bundle: ship one translation + core; others as on-demand downloadable packs.
- Localization-ready for pt, en, es, it, la from day one.
- Accessibility: Dynamic Type scaling, semantic labels, ≥ 4.5:1 contrast.

### Out of scope (architected-for, not built — see §13)
AI commentary, Catechism, Church documents, audio Bible, lectio divina mode, prayer journal, daily reflections, cross-device sync.

---

## 2. Information Architecture

```
Biblia Traditio
├── Onboarding (first run only)
├── Home  [tab]
│   ├── Greeting + Settings entry
│   ├── Quick Actions: Continue · Today's Readings · Reading Plan · Notes · Favorites
│   ├── Daily Liturgy preview card → Liturgy
│   └── [future widget slots: Saint of Day · Reflection · Father of Day · Quote · Catechism]
├── Liturgy  [tab]
│   ├── Horizontal date selector + Calendar modal
│   ├── Celebration header (season · color · year A/B/C · rank)
│   └── Readings (expandable): 1st · Psalm · 2nd · Gospel  → verse deep-links into Bible
├── Bible  [tab]
│   ├── Library (OT / NT segmented, book list w/ emblems, search field)
│   ├── Book → Chapter grid → Chapter reader
│   ├── Reader  → verse actions, Parallel Mode, Patristic panel, type/theme sheet
│   └── Parallel Reading Mode (2 synced columns)
└── Cross-cutting flows (modal/pushed, not tabs)
    ├── Search (global)         ├── Notes list & editor
    ├── Favorites               ├── Highlights list
    ├── Reading Plan            ├── Settings + Downloaded Resources
    └── Patristic browser (by Father / by book)
```

**Content domains** kept independently versioned & swappable: *Scripture* (per translation), *Patristics*, *Liturgical calendar + lectionary*, *Book emblems/artwork*, *User data*.

---

## 3. User Flows (key paths)

**Continue Reading** — Home → tap "Continue" → Reader opens at last `ReadingProgress` (book/chapter/scroll).

**Read with the Fathers** — Bible → book → chapter → tap verse → action bar → "Padres da Igreja" → bottom sheet lists commentaries (author · século · fonte) → expand/scroll → "Copy/Share" or close. (Verses with commentary show a subtle marginal glyph.)

**Parallel Mode** — Reader → ⋯ → "Leitura Paralela" → choose right-column translation/language → two columns scroll-locked by verse anchor → either column's type sheet adjusts both.

**Today's Liturgy** — Liturgy tab opens on today → date strip shows colored season dots → tap reading chip ("Evangelho") → expands inline → "Abrir na Bíblia" deep-links the passage into the Reader.

**Browse any date** — Liturgy → calendar icon → month modal (color dots per day) → tap day → Confirm → liturgy loads.

**Create a note** — verse → action bar → "Nota" → editor (markdown-lite) → save (local, instant) → appears in Notes list + global search.

**Onboarding** — Welcome → Name → Language → Translation → Notifications (system prompt) → Reading-plan opt-in → done → Home. (Skippable after Name; sensible defaults.)

---

## 4. Screen Map

| Tab/Flow | Screens |
|---|---|
| Onboarding | Welcome · Name · Language · Translation · Notifications · Reading Plan |
| Home | Home · Settings (+ Downloaded Resources, About) |
| Liturgy | Liturgy Day · Calendar Modal · Reading Detail |
| Bible | Library (OT/NT) · Chapters · **Reader** · Reader Type/Theme Sheet · Verse Action Bar · **Patristic Sheet** · **Parallel Reader** · Translation Picker |
| Cross-cutting | Global Search · Notes List · Note Editor · Favorites · Highlights · Reading Plan · Patristic Browser |

~26 screens; MVP ships ~16 (§12).

---

## 5. Database Architecture

Three stores, each with one job — mirroring iacula's proven split, extended for Scripture + search.

### 5.1 Content DB — **bundled, read-only SQLite (FTS5)**  ⟵ *recommended over asset-JSON for this app*
iacula loads Bible from asset JSON into memory; that's fine for one translation but breaks down with **5 languages × multiple translations + 100k+ commentaries + global search**. Use a **prebuilt SQLite file** (built offline by the importer, §15) shipped as an asset and/or downloaded per pack. Gives O(1) verse lookup, trivial parallel-column joins, and **FTS5** full-text search with diacritic folding.

```sql
-- Canonical book registry (shared across all translations/languages)
CREATE TABLE book (
  id            TEXT PRIMARY KEY,      -- canonical code: 'gn','ex','mt','ps'...
  testament     TEXT NOT NULL,         -- 'OT' | 'NT'
  canon_order   INTEGER NOT NULL,      -- Catholic 73-book order
  is_deutero    INTEGER NOT NULL DEFAULT 0,
  chapter_count INTEGER NOT NULL,
  emblem_asset  TEXT                   -- engraved icon path
);

CREATE TABLE book_name (                -- localized display names
  book_id TEXT, lang TEXT, name TEXT, abbrev TEXT,
  PRIMARY KEY (book_id, lang)
);

CREATE TABLE translation (              -- a Bible edition
  id        TEXT PRIMARY KEY,           -- 'matos1932','drb','vulgata','rvse'...
  lang      TEXT NOT NULL,              -- 'pt','en','la','es','it'
  title     TEXT NOT NULL,              -- 'Matos Soares (1932)'
  license   TEXT, source TEXT,
  versification TEXT NOT NULL           -- 'vulgate' | 'septuagint' | 'modern'
);

CREATE TABLE verse (                    -- the heart; one row per verse per translation
  translation_id TEXT NOT NULL,
  book_id        TEXT NOT NULL,
  chapter        INTEGER NOT NULL,
  verse          INTEGER NOT NULL,      -- NEVER a heading/title (see §15)
  verse_suffix   TEXT DEFAULT '',       -- '', 'a','b' for split verses
  text           TEXT NOT NULL,
  PRIMARY KEY (translation_id, book_id, chapter, verse, verse_suffix)
);

CREATE TABLE section_heading (          -- editorial titles, stored as METADATA not verses
  translation_id TEXT, book_id TEXT, chapter INTEGER,
  before_verse   INTEGER,               -- heading appears above this verse
  kind           TEXT,                  -- 'section'|'chapter_intro'|'book_intro'|'note'
  text           TEXT
);

-- Verse alignment across versification schemes (critical for Parallel Mode)
CREATE TABLE verse_map (
  from_versification TEXT, to_versification TEXT,
  book_id TEXT, from_ref TEXT, to_ref TEXT   -- e.g. Ps 9:22 (Vulg) ↔ Ps 10:1 (Mod)
);

-- Patristics (from your corpus; one logical row per commentary)
CREATE TABLE father (id TEXT PRIMARY KEY, name TEXT, century TEXT, year TEXT);
CREATE TABLE commentary (
  id        INTEGER PRIMARY KEY,
  book_id   TEXT NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL,
  father_id TEXT NOT NULL,
  source    TEXT,                       -- e.g. 'Catena/Haydock', work title
  lang      TEXT NOT NULL,              -- 'pt-BR'
  is_machine_translation INTEGER DEFAULT 1,  -- your corpus = argos MT; flag it
  text      TEXT NOT NULL
);
CREATE INDEX idx_comm_ref ON commentary(book_id, chapter, verse);

-- Full-text search (contentless FTS5, diacritic-insensitive via custom tokenizer/unaccent)
CREATE VIRTUAL TABLE verse_fts      USING fts5(text, content='verse',      tokenize='unicode61 remove_diacritics 2');
CREATE VIRTUAL TABLE commentary_fts USING fts5(text, content='commentary', tokenize='unicode61 remove_diacritics 2');

-- Lectionary / liturgical calendar (can also be a yearly JSON pack; SQLite preferred for queries)
CREATE TABLE liturgical_day (
  date TEXT PRIMARY KEY,                -- 'YYYY-MM-DD'
  celebration TEXT, season TEXT, color TEXT, rank TEXT, cycle TEXT, weekday_cycle TEXT
);
CREATE TABLE liturgical_reading (
  date TEXT, slot TEXT,                 -- 'first'|'psalm'|'second'|'gospel'
  ref TEXT,                             -- 'Jo 3,16-21' canonical reference
  PRIMARY KEY (date, slot)
);
```

### 5.2 User DB — **Isar, encrypted** (exactly iacula's pattern)
All personal/mutable data. Encryption key in `flutter_secure_storage`, as iacula does for spiritual data. Collections in §9. Sync-ready (`isDirty`, `updatedAt`, `uuid`) so Supabase sync (§13) drops in later with no model changes.

### 5.3 App DB — **SQLite (key-value/settings)** (iacula's `app_database.dart` pattern)
Settings, theme, font prefs, downloaded-pack registry, notification history. Small, migration-versioned.

> **Why this split:** read-only content (huge, shared, search-heavy) ⇒ prebuilt SQLite+FTS5; private mutable data ⇒ encrypted Isar with sync hooks; app prefs ⇒ tiny SQLite. Same philosophy as iacula, scaled for Scripture.

---

## 6. Flutter Architecture

**Adopt iacula's stack verbatim** (proven, offline-first, already in your codebase):

- **State / DI:** Riverpod (`flutter_riverpod`), DI composed as `ProviderScope` overrides in an `AppBootstrap` (singletons: content DB, Isar, app DB, repositories).
- **Architecture:** Clean Architecture per feature — `domain/` (entities, repo interfaces, services) · `application/` (use cases, notifiers/state) · `infrastructure/` (repo impls, data sources) · `presentation/` (screens, widgets).
- **Routing:** **GoRouter** with `StatefulShellRoute.indexedStack` for the 3 tabs (each branch keeps its own navigator stack — same UX as iacula's tab-isolated navigators, but deep-link & web ready). This is the one place I'd upgrade from iacula's `CupertinoTabScaffold`, because Parallel Mode, liturgy date deep-links, and future web all want URL-addressable routes.
- **Localization:** `flutter_localizations` + ARB (`flutter gen-l10n`) for **UI**; content language is data-driven (translation packs), independent of UI locale.
- **Theme:** token-based `ColorScheme`/`TextTheme` like iacula's `cupertino_tokens.dart`, with `google_fonts` (serif for Scripture, sans for chrome) — see §14.

### Layer diagram
```
Presentation (screens/widgets, ConsumerWidget)
        │ watches
Application (Notifiers / Use cases)         ← Riverpod providers
        │ calls
Domain (entities + repository interfaces)   ← pure Dart, no Flutter/DB imports
        ▲ implemented by
Infrastructure (ContentSqliteRepo · IsarUserRepo · AppDbRepo · asset loaders)
        │
Data: bundled SQLite (FTS5) · encrypted Isar · app SQLite · assets (emblems/fonts)
```

### Parallel Reading — designed in from the start
The data model makes it nearly free: a chapter in translation X is `SELECT … FROM verse WHERE translation_id=? AND book_id=? AND chapter=?`. Two columns = two such queries joined on the **canonical verse key** `(book_id, chapter, verse)`, remapped through `verse_map` when versification differs.

- `ParallelReaderController` holds `leftTranslation`, `rightTranslation`, and a shared `verseAnchor`.
- Scroll sync via two `ScrollController`s + `ItemPositionsListener` (use `scrollable_positioned_list`): the leading visible **verse number** in the active column drives the other column to the same anchor (not pixel offset — text reflows differently per language).
- One `ReaderSettings` (font/spacing/theme) applies to both columns.

---

## 7. Recommended Packages

| Concern | Package | Note |
|---|---|---|
| State/DI | `flutter_riverpod` ^2.6 | as iacula |
| Routing | `go_router` | StatefulShellRoute for 3 tabs |
| User DB | `isar` ^3.1 + `isar_flutter_libs` | encrypted, as iacula |
| Content/App DB | `sqflite` (+`sqflite_common_ffi` for the build tool & desktop) | FTS5 |
| Bundled DB asset | `sqlite3_flutter_libs` | ensures FTS5 available |
| Verse-aligned scroll | `scrollable_positioned_list` | jump-to-verse + parallel sync |
| Localization | `flutter_localizations`, `intl` | ARB / gen-l10n |
| Fonts | `google_fonts` | serif + sans (or bundle for full offline) |
| Secure key | `flutter_secure_storage` | Isar encryption key |
| Notifications | `flutter_local_notifications`, `timezone` | as iacula |
| Share/Copy | `share_plus` | verse sharing |
| Paths | `path`, `path_provider` | DB/pack locations |
| Downloads | `dio` (+ `crypto` for checksum) | translation/patristic packs |
| Connectivity | `connectivity_plus` | online-gated downloads only |
| SVG emblems | `flutter_svg` | book artwork |
| IDs | `uuid` | user records |
| Future sync | `supabase_flutter`, `workmanager` | Phase 2, already in iacula |

Build-tool only (not shipped): `dart:io`, `args`, `sqlite3` (Dart) for the importer (§15).

---

## 8. Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                 # MaterialApp.router + theme + l10n
│   └── router.dart              # GoRouter StatefulShellRoute (3 branches)
├── core/
│   ├── bootstrap/app_bootstrap.dart      # builds ProviderScope overrides (iacula pattern)
│   ├── di/providers.dart                 # global providers
│   ├── storage/
│   │   ├── content/content_database.dart # opens bundled/downloaded SQLite (FTS5)
│   │   ├── isar/isar_store.dart          # encrypted user Isar
│   │   └── app_db/app_database.dart      # settings/prefs SQLite
│   ├── theme/   # tokens.dart, app_theme.dart, fonts.dart
│   ├── l10n/    # *.arb
│   └── utils/   # reference parser, versification mapper, diacritics
└── features/
    ├── onboarding/      {presentation}
    ├── home/            {domain,application,presentation}
    ├── liturgy/         {domain,application,infrastructure,presentation}
    ├── bible/
    │   ├── domain/         # Book, Chapter, Verse, ReaderSettings, ParallelConfig
    │   ├── application/     # ReaderNotifier, ParallelReaderController, BookListNotifier
    │   ├── infrastructure/  # ContentSqliteBibleRepository
    │   └── presentation/    # library / chapters / reader / parallel / sheets
    ├── patristics/      {domain,application,infrastructure,presentation}
    ├── notes/           {domain,application,infrastructure,presentation}
    ├── highlights/      {…}
    ├── favorites/       {…}
    ├── bookmarks/       {…}
    ├── search/          {…}            # cross-domain FTS aggregator
    ├── reading_plan/    {…}            # Phase 1.5
    ├── settings/        {…}
    └── downloads/       {…}            # resource pack manager
assets/
├── content/biblia_traditio.sqlite       # prebuilt core DB (or downloaded)
├── emblems/*.svg
└── fonts/

tool/                         # OFFLINE build pipeline — NOT shipped (§15)
├── importer/
│   ├── bin/import.dart        # CLI: raw → validate → normalize → build DB
│   ├── parsers/               # source-format adapters
│   ├── detectors/             # heading-vs-verse classifier
│   ├── validators/            # numbering/duplication/heading checks
│   └── builders/              # JSON → SQLite(+FTS5)
└── data/
    ├── raw/                   # source files
    ├── normalized/            # validated JSON (review artifact)
    └── reports/               # validation reports per book
```

---

## 9. Data Models

### Content (domain entities — pure Dart)
```dart
enum Testament { ot, nt }
enum Versification { vulgate, septuagint, modern }

class BibleBook {
  final String id;            // 'gn'
  final Testament testament;
  final int canonOrder;
  final bool isDeutero;
  final int chapterCount;
  final String emblemAsset;
  final String name;          // localized
}

class Verse {
  final String bookId; final int chapter; final int number;
  final String suffix;        // '', 'a', 'b'
  final String text;
  VerseKey get key => VerseKey(bookId, chapter, number); // canonical join key
}

class SectionHeading {        // editorial — never a Verse
  final String bookId; final int chapter; final int beforeVerse;
  final HeadingKind kind;     // section | chapterIntro | bookIntro | note
  final String text;
}

class Commentary {
  final int id;
  final VerseKey ref;
  final String fatherName;    // 'São João Crisóstomo'
  final String century;       // derived from year
  final String source;        // 'Catena / Haydock'
  final bool isMachineTranslation;
  final String text;
}
```

### User data (Isar collections — encrypted, sync-ready)
```dart
@collection
class NoteDoc {
  Id id = Isar.autoIncrement;
  late String uuid;
  late String bookId; late int chapter; late int verse;  // anchor
  late String translationId;                              // context
  late String bodyMarkdown;
  late DateTime createdAt; late DateTime updatedAt;
  bool isDirty = true;            // sync flag (Phase 2)
  bool isDeleted = false;
}

@collection
class HighlightDoc {
  Id id = Isar.autoIncrement;
  late String uuid;
  late String bookId; late int chapter; late int verse;
  int? startOffset; int? endOffset;   // null = whole verse
  late String colorKey;               // 'gold','rose','sky','sage','lilac'
  late DateTime createdAt; bool isDirty = true; bool isDeleted = false;
}

@collection
class BookmarkDoc { /* uuid, bookId, chapter, verse?, label?, updatedAt, isDirty */ }

@collection
class FavoriteDoc { /* uuid, verse anchor + cached text snapshot, createdAt, isDirty */ }

@collection
class ReadingProgressDoc {   // powers "Continue Reading"
  Id id = Isar.autoIncrement;
  late String translationId; late String bookId; late int chapter;
  late int firstVisibleVerse; late DateTime updatedAt;
}
```
All user docs carry `uuid + updatedAt + isDirty + isDeleted` → last-write-wins sync (iacula's `SyncConflictResolver`) attaches with zero migration in Phase 2.

### Settings (app DB)
`displayName, uiLanguage, primaryTranslationId, parallelTranslationId?, themeMode, fontScale, lineSpacing, notificationsEnabled, onboardingCompleted, installedPacks[]`.

---

## 10. Offline Strategy

**Same schema as iacula: offline-first, network optional.**

- **Bundled core:** app ships with the primary translation + patristics + current-year liturgy in `assets/content/biblia_traditio.sqlite`. First-run copies/opens it from `path_provider` dir. Reading works the instant the app launches — **no download required**.
- **Resource packs:** additional translations (en/la/es/it), full multi-year liturgy, and high-res artwork are **downloadable packs** (each its own attachable SQLite or attached table-set), tracked in the App DB `installedPacks` registry. Managed in **Settings → Downloaded Resources** (size, download, delete).
- **All user data is local-first** — notes/highlights/bookmarks/favorites/progress write to encrypted Isar synchronously; UI never waits on a network.
- **Network is used only for:** downloading optional packs, and (Phase 2) opt-in Supabase backup/sync. Reading, search, liturgy (within installed years), and patristics are **100% offline**.
- **Connectivity** (`connectivity_plus`) gates *downloads only*; it never blocks reading.
- **Search is offline** via the bundled FTS5 index.

---

## 11. Localization Strategy

Two independent axes — keep them separate:

1. **UI language** (chrome, buttons, settings) — ARB files via `flutter gen-l10n` for `pt, en, es, it` (+ `la` optional). Chosen in onboarding, changeable in settings.
2. **Content language/translation** — data-driven `translation` rows; selecting a translation selects its language. Book display names come from `book_name(book_id, lang)`.

Rules: never concatenate translated sentence fragments; use ICU plurals/gender in ARB; store dates/refs canonically and format per-locale; canonical book codes are language-neutral so cross-references survive language switches; diacritic-insensitive search via FTS5 `remove_diacritics`. Default UI locale follows device, falling back to `pt`.

---

## 12. MVP Scope

**Goal: a beautiful, fully-offline Catholic reader with the Fathers — one translation, pt-BR.**

✅ In MVP
- 3-tab shell (Home, Liturgy, Bible) + onboarding (name, language, translation, notifications, plan opt-in).
- Bible library (OT/NT, emblems) → chapters → **Reader** (font size, line spacing, light/dark, section headings rendered correctly).
- Verse action bar: copy, share, **highlight** (multi-color), **bookmark**, **favorite**, **note**.
- **Patristic Commentary panel** (your corpus, pt-BR).
- **Parallel Reading Mode** — even MVP-worthy because the model makes it cheap; ship with pt-BR + Latin (Vulgata, PD) as the second column.
- Notes & Highlights lists; **Continue Reading**; Favorites.
- **Global offline search** (verses + patristics + notes).
- Liturgy tab: date strip + calendar modal + today's readings (current liturgical year), deep-link to Reader.
- Settings (incl. Downloaded Resources scaffold).
- The **import pipeline** (§15) producing the bundled DB.

🚫 Not in MVP (Phase 2+): cross-device sync, additional translations beyond pt+la, AI, Catechism/Church docs, audio, lectio mode, prayer journal, daily reflections, reading-plan engine (ship a single "Bible in a year" as 1.5).

---

## 13. Phase 2 Roadmap

| Phase | Theme | Items |
|---|---|---|
| **1.5** | Plans & polish | Reading-plan engine + "Plano" surface; en/es/it translation packs; multi-year liturgy packs; widget slots on Home (Saint/Reflection/Father of the day). |
| **2** | Sync & accounts | Optional Supabase sync (notes/highlights/favorites/progress) using iacula's orchestrator + conflict resolver; anonymous→account merge; home-screen widgets. |
| **2.5** | Study depth | Patristic browser by Father/by work; cross-references; Strong's-style word study; export notes (PDF/Markdown). |
| **3** | Tradition library | Catechism (CCC) integration; Church documents; Latin Vulgate study layer; Lectio Divina guided mode; audio Bible. |
| **3.5** | AI (faithful) | On-device/opt-in **AI commentary grounded only in the bundled Catholic sources** (RAG over your Fathers corpus + Catechism), always citing sources, never replacing them. |
| **4** | Platforms | Tablet two-pane layouts, macOS, web (router & SQLite already portable). |

---

## 14. UI/UX Recommendations (matched to your screenshots)

**Visual language** — near-black canvas `#0B0B0C`, elevated surfaces `#161617`, **terracotta/sacral-red accent** (~`#C2492E`/`#D45A3C`) used sparingly for emblems, active states, and the engraved book medallions. White/ivory text at ~85–90% opacity for body. This is the screenshots' identity — keep it.

**Typography** — Scripture in a refined **serif** (Lora as in iacula, or step up to *EB Garamond*/*Cormorant* for a more traditional, breviary feel); chrome/labels in a quiet sans (Inter). Verse numbers as small **superscript** in muted accent. Section headings in semibold serif, clearly distinct from verse text (your screenshots already do this with "Primeiro dia da Criação").

**Reader details that sell "premium"**
- Centered **book emblem medallion** + book name + "Capítulo N" header (per screenshot) at chapter top.
- Generous line spacing default; per-verse vertical rhythm; comfortable side margins.
- **Verse-number rail / chapter scrubber** on the right edge (screenshot 3) for fast in-book jumps.
- Type sheet as a bottom sheet: "Modo de cor" (Claro/Escuro) + "Tamanho da fonte" slider with `Aa…Aa` (exactly your screenshot) — add line-spacing + serif/sans toggle.
- Verses with patristic commentary get a subtle marginal dot/glyph; long-press a verse opens the action bar.

**Liturgy** — horizontal day cards with weekday + day + a **liturgical-color dot** (green/red/white/purple/rose); selected day filled. Calendar modal shows color dots per day (screenshot 7) + "Confirmar". Celebration card: title + `Tempo Comum · Ano A · [rank glyph]`. Reading chips (1ª leitura · Salmo · 2ª leitura · Evangelho) scroll horizontally and expand inline with a hero image for solemnities (Sagrado Coração screenshot).

**Motion** — calm, never bouncy: 250–300ms ease transitions (iacula's onboarding uses fade+slide 0.08 — reuse). Page-turn feel in Reader via subtle shared-axis. No confetti, no badges, ever.

**Onboarding** — reuse iacula's `onboarding_screen.dart` structure (carousel + AnimatedSwitcher + keyboard-aware padding), restyled to the terracotta/serif identity; sacred imagery, one decision per screen, skippable after Name.

---

## 15. Technical Implementation Plan — incl. the Import & Parsing Pipeline

This section answers your **critical** requirement: **editorial content must NEVER be stored as a verse**, and verse numbering must never drift.

### 15.1 Pipeline philosophy — correctness over speed, 4 stages, reviewable artifacts
Build an **offline Dart CLI** in `tool/importer/` (never inside the app). It never writes the app DB directly — it emits reviewable JSON, then builds the DB from approved JSON.

```
RAW source ─▶ [1 Parse] ─▶ raw_blocks.json
                              │
                ▶ [2 Validate] ─▶ reports/<book>.report.json   (warnings/errors, human review)
                              │
                ▶ [3 Extract metadata] ─▶ normalized/<book>.json (verses + headings separated)
                              │
                ▶ [4 Build] ─▶ assets/content/biblia_traditio.sqlite (+FTS5)
```

### 15.2 Stage 1 — Parse into typed *blocks* (don't assume verse yet)
Read the source and emit an ordered list of **blocks**, each classified, **without renumbering anything**. A block is one of: `Verse`, `SectionHeading`, `ChapterIntro`, `BookIntro`, `EditorialNote`, `Unknown`.

### 15.3 The detector — heading-vs-verse classifier (the core safety mechanism)
A block becomes a **Verse only if** it begins with a valid verse marker (`^\s*(\d+)`) **and** the remaining text passes content checks. Everything else is metadata. Rules (your list, made executable):

```
Treat as METADATA (never a verse) when ANY:
  • Fully UPPERCASE line with no leading verse number   → SectionHeading
      e.g. "LIVRO SAPIENCIAL", "PRIMEIRA PARTE", "DISCURSO DE SALOMÃO"
  • Matches /^CAP[IÍ]TULO\b/i or /^CAP\.?\s*\d/i          → chapter marker (consumed, not a verse)
  • No leading integer verse marker                      → heading/intro/note
  • Known editorial label (footnote marker, "Introdução",
    "Nota", translator heading, historical preface)      → EditorialNote/BookIntro
  • Title-case short line directly above a verse 1        → SectionHeading (chapter section title)

Create a VERSE only when:
  • A leading integer N is present, AND
  • the text after N is genuine scripture (not all-caps, not a bare title)
Then: verse.number = N taken FROM THE SOURCE (never an auto-incremented counter).
```
**Anti-drift guarantee:** verse numbers are read *from the source text*, never inferred from position. A misclassified heading therefore cannot shift subsequent numbers — the very failure mode you described (`v1="LIVRO SAPIENCIAL"` pushing everything down) is structurally impossible because headings are removed *before* numbering and numbers come from the source.

Output of correct handling (your spec):
```json
{ "chapter": 1,
  "metadata": { "sectionTitle": "Livro Sapiencial" },
  "verses": [ { "verse": 1, "text": "O temor do Senhor é o princípio da sabedoria..." } ] }
```

### 15.4 Stage 2 — Validation pass (fail loud, never silently import)
Run every parsed book through validators that emit a **report** (errors block the build; warnings require sign-off):

- **Numbering jumps** — verse sequence skips (1,2,4) → error.
- **Duplicate verse numbers** within a chapter → error.
- **Missing verses** vs. expected count (per a Catholic versification reference table) → warning.
- **Suspicious all-caps verse** — a `Verse` whose text is ≥80% uppercase → error (likely a heading that leaked).
- **Too-short verse** — `< 5` words → warning (review; some genuine verses are short).
- **Heading-as-verse** — text matches the heading patterns above but got typed as Verse → error.
- **Chapter count** mismatch vs. book registry → error.
- **Orphan commentary** — a commentary refs a (book,ch,verse) with no verse → warning.

Each finding includes book/chapter/verse + the offending text, written to `tool/data/reports/<book>.report.json`. **Build refuses to run while any error remains.**

### 15.5 Stage 3 — Metadata extraction → normalized JSON
Produce the clean, reviewable artifact: `verses[]` (number + text, source-numbered) separated from `headings[]` (kind + beforeVerse + text). This is the human-auditable source of truth, kept in git.

### 15.6 Stage 4 — Build the bundled SQLite (+FTS5)
From approved normalized JSON: insert `book/translation/verse/section_heading`, populate `verse_fts`. **Patristics**: ingest your 70 JSON files directly — they're already `chapters[ch][verse] → [{author, year, text}]`. Normalize author names + derive `century` from `year`, resolve book codes through `aliases_normalizados.json`, set `is_machine_translation = 1` (argos), populate `commentary` + `commentary_fts`. Add a **post-build integrity test**: random-sample 200 verses and assert text round-trips; assert every commentary's verse ref resolves.

### 15.7 App build order (engineering sequence)
1. Project skeleton + theme tokens + GoRouter 3-tab shell (copy iacula bootstrap/DI patterns).
2. Importer (§15.1–15.6) → produce `biblia_traditio.sqlite` from Matos-Soares-PD + Vulgata + your patristics.
3. `ContentDatabase` opener + `ContentSqliteBibleRepository` + library/chapters screens.
4. Reader + section-heading rendering + type/theme sheet + verse action bar.
5. Encrypted Isar user store + notes/highlights/bookmarks/favorites/progress + "Continue Reading".
6. Patristic sheet (FTS-backed lookup by verse).
7. Parallel Reading Mode (verse-anchored sync).
8. Liturgy tab (date strip, calendar modal, readings, deep-links).
9. Global search (verse + commentary + notes FTS aggregator).
10. Onboarding + Settings + Downloaded Resources.
11. Localization wiring + accessibility + performance pass.

---

## 16. Legal Considerations — Bible Translations

> Not legal advice; validate with Brazilian IP counsel before release.

- **Brazilian rule (Lei 9.610/98):** a translation is a protected derivative work; rights last **70 years after the *translator's* death** (counted from Jan 1 of the following year). The text enters the public domain on that basis regardless of any publisher's claims.
- **Matos Soares (1932/1956 editions):** the determining fact is **Padre Matos Soares's death year**. **Confirm it precisely.** If he died in 1950 → PD since 2021; if 1956 → PD from 2027. Until confirmed PD, do not assume free use of the text.
- **MBC ("Minha Biblioteca Católica") edition:** even when the *underlying translation* is PD, a specific modern **edition** (its footnotes, introductions, section headings, typesetting, cover art, and any revisions) is a **separately protected work**. Do **not** scrape MBC's edition. Instead, source the **original 1932 text** from a primary public-domain witness and do your own editorial layout. Headings you generate (or take from a PD source) are yours.
- **Recommended primary translation path:** confirm Matos Soares death year → if PD, transcribe from an original PD edition/scan; if not yet PD, **license** it (contact the rights holder) **or** ship an unambiguously-PD Catholic Portuguese text as the default (e.g. an older PD Catholic version) and offer Matos Soares as a licensed/downloadable pack.
- **Other columns / packs:**
  - **Latin Vulgate (Clementine)** — public domain. Safe default second column. ✅
  - **Douay–Rheims (Challoner)** — public domain (English). ✅
  - **Spanish/Italian** — pick PD Catholic translations (e.g. older Torres Amat for ES) or license; verify per edition.
- **Patristic corpus you provided:** the *underlying* Fathers are PD; **Haydock (1859), Challoner, Theophylact** are PD. **But your text is a machine translation (argos)** — that derivative is yours to use, yet (a) flag it as machine-translated in-app for honesty/quality, and (b) where a *modern* human translation was the MT's source, ensure the MT wasn't derived from an in-copyright modern edition. Prefer MT built from PD originals.
- **In-app practice:** store `license` + `source` per translation and per commentary; show an attributions screen; mark machine translations.

---

## 17. How Biblia Traditio surpasses YouVersion / Logos — while staying faithful to Tradition

1. **The Fathers, on every verse, offline.** YouVersion has none; Logos hides patristics behind expensive desktop libraries and a login. You ship a Catena-class corpus (Crisóstomo, Agostinho, Ambrósio, Jerônimo, Haydock…) attached to verses, fully offline, one tap away. **This is the moat.**
2. **Genuinely Catholic by construction.** 73-book canon, Catholic versification with proper cross-scheme mapping, General Roman Calendar, liturgical colors/seasons/year — not a Protestant app with Apocrypha bolted on.
3. **Liturgy + Scripture as one experience.** Daily readings deep-link straight into the annotated Reader with the Fathers available — Universalis-grade liturgy fused with a real study Bible. Neither competitor does this elegantly on mobile.
4. **First-class Parallel Reading across language *and* tradition** — pt ↔ Latin Vulgate ↔ English Douay, verse-locked, with versification mapping handled correctly (most parallel views break on Septuagint/Vulgate numbering).
5. **Beauty and calm as differentiators.** Breviary-grade serif typography, engraved book emblems, terracotta-on-black restraint, **zero gamification**. It feels like a sacred object, not a growth-hacked feed.
6. **Honesty about sources.** Per-text license/attribution, machine-translation flags, century-dated Fathers — scholarly integrity competitors gloss over.
7. **Private by default.** All notes/highlights local & encrypted, no account required, optional sync later. The anti-surveillance Bible app.
8. **Faithful-AI later, never instead.** When AI arrives it's **RAG grounded only in the bundled Catholic sources, always citing**, never a free-floating oracle — study aid, not magisterium-replacement.

---

### Immediate next steps
1. Confirm the two open decisions (§0): **3 vs 5 tabs**, and **Matos Soares death year** for the legal path.
2. I scaffold the Flutter project (iacula patterns) + the `tool/importer` pipeline, and run your patristic JSON + a PD scripture text through it to produce the first `biblia_traditio.sqlite`.
3. Build the Reader + Patristic sheet against that DB as the first vertical slice.
```
