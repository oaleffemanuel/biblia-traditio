# Biblia Traditio — Store Listing Drafts

Tone: Catholic, elegant, traditional. Not Protestant-coded, not salesy.
For the eventual **public** listing — confirm the Portuguese Bible's provenance
before publishing publicly (see privacy-policy / check_release `BETA=1` gate).

---

## Public URLs (App Store Connect / Play Console)

Hosted on **GitHub Pages** from `/docs` on `main` (static, no backend):

- **Privacy Policy URL:** `https://oaleffemanuel.github.io/biblia-traditio/privacy.html` (PT-BR + EN on one page)
- **Support URL:** `https://oaleffemanuel.github.io/biblia-traditio/support.html`
- **Landing:** `https://oaleffemanuel.github.io/biblia-traditio/`
- **Support email:** `ealeff586@gmail.com`
- **Support WhatsApp:** +55 31 97596-5032

Source files: `docs/index.html`, `docs/privacy.html`, `docs/support.html`,
`docs/styles.css`, `docs/.nojekyll`. Pages must be enabled once in repo
**Settings → Pages → Source: Deploy from a branch → `main` / `/docs`**.

---

## Subtitle / short description

**Apple subtitle** (≤ 30 chars):
- EN: `Read Scripture with the Church`
- PT: `A Escritura com a Tradição`

**Google Play short description** (≤ 80 chars):
- EN: `A Catholic study Bible — the Church Fathers on every verse, fully offline.`
- PT: `Bíblia católica de estudo — os Padres da Igreja em cada versículo, offline.`

---

## Long description

### EN

Biblia Traditio is a Catholic study Bible made for prayerful, faithful reading —
Scripture read with the Church, never alone.

Tap any verse to read the Church Fathers on it: a Catena-style commentary drawn
from the Fathers and Doctors, one tap away and fully offline. Read the Latin
Vulgate beside the vernacular in verse-locked Parallel Reading. Keep your own
notes, highlights and favorites — private, on your device, with no account.

• The Fathers on the verse — Chrysostom, Augustine, Jerome and more, attached to
  Scripture and available offline.
• Parallel Reading — the vernacular and the Clementine Vulgate, side by side,
  verse by verse.
• Catholic by design — the 73-book canon in Catholic order, with the General
  Roman Calendar.
• Beautiful and quiet — breviary-grade typography, no feeds, no gamification, no
  ads.
• Private by default — your notes and highlights stay on your device.

Read Scripture with the Church.

### PT-BR

O Biblia Traditio é uma Bíblia católica de estudo, feita para uma leitura orante
e fiel — a Escritura lida com a Igreja, nunca sozinho.

Toque em qualquer versículo para ler os Padres da Igreja sobre ele: um comentário
ao estilo da Catena, colhido dos Padres e Doutores, a um toque e totalmente
offline. Leia a Vulgata latina ao lado da língua vernácula na Leitura Paralela,
travada versículo a versículo. Guarde suas notas, destaques e favoritos — de
forma privada, no seu aparelho, sem conta.

• Os Padres sobre o versículo — Crisóstomo, Agostinho, Jerônimo e outros, ligados
  à Escritura e disponíveis offline.
• Leitura Paralela — a língua vernácula e a Vulgata Clementina, lado a lado,
  versículo a versículo.
• Católico por desígnio — o cânon de 73 livros na ordem católica, com o
  Calendário Romano Geral.
• Belo e silencioso — tipografia de breviário, sem feeds, sem gamificação, sem
  anúncios.
• Privado por padrão — suas notas e destaques permanecem no seu aparelho.

Leia a Escritura com a Igreja.

---

## Keywords

**Apple** (single 100-char field, comma-separated, no spaces):
```
bíblia,católica,padres,igreja,vulgata,escritura,comentário,tradição,latim,santos,lectio,catena,offline
```

**Google Play** (woven into the description naturally; ideas):
bíblia católica, Padres da Igreja, Vulgata, Escritura Sagrada, comentário
patrístico, Bíblia offline, leitura paralela, tradição católica, lectio divina,
Doutores da Igreja, calendário litúrgico.

**Category:** Reference (primary) or Books — Reference recommended.
**Age rating:** 4+ / Everyone (no objectionable content, no data collection).

---

## Content provenance

- **Vulgata Clementina** (`vulgata`, Latin) — public domain; source open-bibles
  (Clementine USFX).
- **Bíblia Católica em Português** (`pt_beta`) — internal iacula corpus; provenance
  **unconfirmed**; beta-gated.
- **Padre Matos Soares** (`pt_matos_soares`, Portuguese) — Catholic translation by
  Fr. António Pereira de Matos Soares (**d. 1950**). Under Brazilian copyright
  (life + 70 years) the work is a **public-domain candidate since 2021**. Text was
  collected from padrepauloricardo.org (edição *matos-soares*) — a faithful
  digitisation adds no new rights to a public-domain text; the PD basis is the
  translator's death + 70 years, not the digitiser. Full 73-book Catholic canon,
  35,816 verses, chapter counts validated against the canon. **Beta-gated** until
  provenance (and the specific edition) is formally signed off.
- **Comentário dos Padres da Igreja** (patristics, pack v4) — Catena Aurea /
  Haydock, public-domain sources; machine translation reviewed and curated;
  flagged as machine translation in the app. 54,531 commentaries over 23,427
  verses from 190 commentators, each carrying the commentator's function
  (`função`) and century as given by the curated corpus. Built as a per-verse
  overlay of the revised corpus on the original, so a partial revision never
  reduces coverage (`tool/build_content_db.sh`; report at
  `tool/importer/data/reports/patristics_coverage.json`).
- **Septuaginta / Texto Massorético** — **not shipped.** The app has the layout,
  RTL and font handling for Greek and Hebrew, but offers a parallel column only
  for texts that are actually installed; no placeholder or fabricated text is
  ever shown.

---

## Google Play publication audit (2026-08-08)

**Blocker — no upload keystore.** The release build falls back to the debug key
(`CN=Android Debug`, verified with `apksigner`/`jarsigner` on the built
artifacts). Nothing can be uploaded until an upload key exists:

```bash
keytool -genkey -v -keystore ~/keys/biblia-traditio.jks -storetype JKS \
        -keyalg RSA -keysize 2048 -validity 10000 -alias bibliatraditio
cp android/key.properties.example android/key.properties   # fill in 4 values
flutter build appbundle --release
```

`android/key.properties`, `**/*.jks` and `**/*.keystore` are gitignored, and
`test/android_release_test.dart` fails if a real `key.properties` appears in the
repo. **Back the .jks up** — Play cannot reissue a lost upload key.

**Blocker — fonts are fetched at runtime, not bundled.** `google_fonts` resolves
in three steps (bundled asset → device cache → HTTP to `fonts.gstatic.com`).
The built APK contains only `MaterialIcons-Regular.otf` and `CupertinoIcons.ttf`
— **no EB Garamond, no Inter** — and `GoogleFonts.config.allowRuntimeFetching`
is left at its default (true). Consequences:

- **Android:** the release manifest has no `INTERNET` permission, so the fetch
  fails and google_fonts silently falls back to the platform font. The app's
  typography — the "breviary-grade typography" of the store listing — does not
  render on Android.
- **iOS:** the fetch *succeeds* (iOS has no network permission gate), so the app
  contacts a Google server on first run. That sits awkwardly with the "fully
  offline" claim and with a clean "no data collected" declaration.

Fix: bundle EB Garamond and Inter (both SIL OFL 1.1, redistributable with the
licence) as assets and set `allowRuntimeFetching = false`. Upstream ships only
variable fonts (`EBGaramond[wght].ttf`), which google_fonts' static-filename
lookup does not match — so either generate static instances or declare the
variable fonts directly in `pubspec.yaml` and set `fontFamily` in
`BtTypography`. Needs on-device verification on Android before shipping.

---

## Open questions before publishing (privacy policy + store)

1. **Publisher / developer legal name** for the store account and the policy
   header? (Is the publisher "Colégio Alta Vista", a personal developer account,
   or another entity?)
2. ~~Where will the privacy policy be hosted?~~ **DONE** — GitHub Pages from
   `/docs` on `main`: `https://oaleffemanuel.github.io/biblia-traditio/privacy.html`.
   (Enable once in Settings → Pages; see "Public URLs" above.)
3. ~~Support email~~ **DONE** — `ealeff586@gmail.com` is published on the Support
   and Privacy pages and used in App Store Connect.
4. **Effective date** — confirm 16 June 2026, or set to first public submission.
5. **Portuguese Bible provenance** — `pt_beta` (internal iacula corpus) still has
   unconfirmed provenance. A provenance-documented alternative, **`pt_matos_soares`
   (Padre Matos Soares)**, now ships alongside it (see "Content provenance" below);
   decide before public release whether Matos Soares replaces `pt_beta` as default.
   The `BETA=1` release gate still blocks public shipping of both PT texts until
   their provenance is formally signed off.
6. **Data Safety form (Google) / App Privacy (Apple)** — we'll declare "no data
   collected." Confirm that remains true at submission (no analytics/crash SDK
   added).
7. **Account/age confirmation** — confirm there is no account and no age gate, so
   we can mark the app as not collecting data from children.
