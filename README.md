# cursor-rules

Reguły Cursora (`.mdc`) dla projektów Syntance. Źródło prawdy — konsumowane per **projekt** (`degit` → `.cursor/rules/`) albo globalnie jako **User Rules** (`~/.cursor/rules/`).

## Struktura

```
cursor-rules/
├── fundament/          # 15 reguł — dowolny projekt Next.js + React (+ konwersja, rendering, e-commerce)
│   ├── 00-core.mdc
│   ├── 10-stack.mdc
│   ├── 15-rendering.mdc
│   ├── 20-design.mdc
│   ├── 25-conversion.mdc
│   ├── 30-motion.mdc
│   ├── 40-3d.mdc
│   ├── 45-commerce.mdc
│   ├── 50-perf-a11y.mdc
│   ├── 55-security.mdc
│   ├── 56-legal.mdc
│   ├── 60-quality.mdc
│   ├── 70-copy.mdc
│   ├── 80-assets.mdc
│   └── 90-release.mdc
├── medusa/             # 11 reguł — projekty ecommerce na Medusa v2 (w tym checkout standards)
├── magazyn/            # 3 reguły — panel „Magazyn" + CMS + pliki (moduł Syntance/moduly)
│   ├── magazyn-panel.mdc
│   ├── cms-content.mdc
│   └── storage-files.mdc
└── scripts/            # instalacja User Rules (macOS / Windows / Linux)
    ├── patch-cursor-user-rules.js
    ├── sync-user-rules.sh
    └── sync-user-rules.ps1
```

## User Rules (globalnie, wszystkie projekty)

**Problem:** Cursor domyślnie pokazuje w **Settings → Rules → User** tylko reguły wpisane w UI. Pliki w `~/.cursor/rules/` **nie są skanowane** bez patcha rozszerzenia `cursor-agent-exec`.

**Rozwiązanie:** skopiuj `fundament/` do `~/.cursor/rules/` + uruchom patch (jednorazowo; powtórz po aktualizacji Cursora).

### macOS / Linux

```bash
git clone https://github.com/Syntance/cursor-rules.git /tmp/cursor-rules
chmod +x /tmp/cursor-rules/scripts/sync-user-rules.sh
/tmp/cursor-rules/scripts/sync-user-rules.sh
```

Jeśli patch zwróci błąd uprawnień do `/Applications/Cursor.app`:

```bash
sudo node /tmp/cursor-rules/scripts/patch-cursor-user-rules.js
```

Potem w Cursorze: **Cmd+Shift+P → Developer: Reload Window** → **Settings → Rules → User** (powinno być 15 User File Rules).

### Windows

```powershell
git clone https://github.com/Syntance/cursor-rules.git $env:TEMP\cursor-rules
& "$env:TEMP\cursor-rules\scripts\sync-user-rules.ps1"
```

Potem: **Ctrl+Shift+P → Developer: Reload Window**.

### Ręcznie (bez skryptu)

```bash
mkdir -p ~/.cursor/rules
cp fundament/*.mdc ~/.cursor/rules/
node scripts/patch-cursor-user-rules.js
```

Reguły muszą leżeć w **`~/.cursor/rules/`** (nie w `~/.cursor/` ani w repo projektu).

## Użycie w nowym projekcie (Project Rules)

### Strona (portfolio / landing / content)

Tylko fundament (15 reguł):

```bash
pnpm dlx degit Syntance/cursor-rules/fundament .cursor/rules
```

### Sklep (Medusa v2 + storefront)

Fundament + Medusa:

```bash
pnpm dlx degit Syntance/cursor-rules/fundament .cursor/rules
pnpm dlx degit Syntance/cursor-rules/medusa    .cursor/rules
```

### Sklep z panelem „Magazyn" + CMS (moduł Syntance/moduly)

Dodatkowo, gdy wpinasz pakiet `magazyn` (panel admina + CMS na `Store.metadata`):

```bash
pnpm dlx degit Syntance/cursor-rules/magazyn .cursor/rules
```

## Checkout standards

Checkout i bramki płatnicze mają osobny, twardy kontrakt (utwardzony na incydentach produkcyjnych) — by każdy nowy sklep dostawał TEN SAM, zabezpieczony checkout:

- `medusa/46-checkout-standards.mdc` — skonsolidowany standard: 5 torów domknięcia płatności, kontrakt adaptera bramki, idempotencja sesji, self-healing reconcile (endpoint + cron niezależny od workera), security/CSP, compliance PL/EU, Turnstile za flagą, „Częste bugi i fixy".
- `medusa/payment-flow.mdc` — moduł providera (`modules/<provider>`), webhooki (wbudowana deduplikacja Medusa v2), maszyna stanów, reconcile.
- `medusa/checkout-forms.mdc` — formularz: Zod/RHF, double-submit guard, slow-state, sanitize bez dompurify, Turnstile gated.
- `medusa/checkout-clone-playbook.mdc` — krok po kroku jak postawić checkout kopiując z `Syntance/moduly` + manifest ENV + checklist deploy.

Kod referencyjny (kopiuj stamtąd): `Syntance/moduly` (`packages/commerce`, `apps/backend`).

## Aktualizacje

- **User Rules:** ponownie uruchom `scripts/sync-user-rules.sh` (lub `.ps1` na Windows).
- **Project Rules:** re-run `degit` (nadpisuje lokalne) lub merge ręczny.

Zmiany filozofii → PR do tego repo + ADR w `docs/adr/`.

## Jak reguły działają w Cursorze

- Pliki `.mdc` z frontmatterem YAML.
- `alwaysApply: true` — reguła aktywna zawsze (tylko `00-core` w fundament).
- `globs: [...]` — reguła gdy pasujące pliki są otwarte.
- `description` bez `alwaysApply` — **Apply Intelligently** (agent ładuje gdy temat pasuje).

## Benchmark

Fundament: Active Theory, Resn, Locomotive, Obys, Igloo Inc., Basement, Immersive Garden (+ konwersja: Stripe, Linear, Vercel).

Medusa: Aimé Leon Dore, Kith, APC, Frankie Shop, Allbirds, Gymshark.
