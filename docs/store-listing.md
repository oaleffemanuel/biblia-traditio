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
- **Support email:** `atendimento@colegioaltavista.com.br` (confirm/replace if a dedicated app-support address is preferred)
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
- **Comentário dos Padres da Igreja** (patristics) — Catena/Haydock, public-domain
  sources; machine translation reviewed/curated; flagged as machine translation.

---

## Open questions before publishing (privacy policy + store)

1. **Publisher / developer legal name** for the store account and the policy
   header? (Is the publisher "Colégio Alta Vista", a personal developer account,
   or another entity?)
2. ~~Where will the privacy policy be hosted?~~ **DONE** — GitHub Pages from
   `/docs` on `main`: `https://oaleffemanuel.github.io/biblia-traditio/privacy.html`.
   (Enable once in Settings → Pages; see "Public URLs" above.)
3. **Support email** — currently `atendimento@colegioaltavista.com.br` (org
   address) is published on the Support page. Confirm this, or swap for a
   dedicated app-support inbox before public release.
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
