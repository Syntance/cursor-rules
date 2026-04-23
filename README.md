# cursor-rules

Reguły Cursora (`.mdc`) dla projektów Syntance. Źródło prawdy — konsumowane w projektach przez `degit` do katalogu `.cursor/rules/`.

## Struktura

```
cursor-rules/
├── fundament/          # 12 reguł — dowolny projekt Next.js + React
│   ├── 00-core.mdc
│   ├── 10-stack.mdc
│   ├── 20-design.mdc
│   ├── 30-motion.mdc
│   ├── 40-3d.mdc
│   ├── 50-perf-a11y.mdc
│   ├── 55-security.mdc
│   ├── 56-legal.mdc
│   ├── 60-quality.mdc
│   ├── 70-copy.mdc
│   ├── 80-assets.mdc
│   └── 90-release.mdc
└── medusa/             # 9 reguł — projekty ecommerce na Medusa v2
    ├── 00-ecom-core.mdc
    ├── 20-ecom-design.mdc
    ├── cart-state.mdc
    ├── medusa-sdk.mdc
    ├── checkout-forms.mdc
    ├── payment-flow.mdc
    ├── shipping.mdc
    ├── order-pipeline.mdc
    └── inventory.mdc
```

## Użycie w nowym projekcie

### Strona (portfolio / landing / content)

Tylko fundament (12 reguł):

```bash
pnpm dlx degit Syntance/cursor-rules/fundament .cursor/rules
```

### Sklep (Medusa v2 + storefront)

Fundament + Medusa (21 reguł razem w jednym `.cursor/rules/`):

```bash
pnpm dlx degit Syntance/cursor-rules/fundament .cursor/rules
pnpm dlx degit Syntance/cursor-rules/medusa    .cursor/rules
```

Lub jednym strzałem przez skrypt bootstrap (patrz Notion → Setup — skrypt bootstrap).

## Aktualizacje

Reguły są wersjonowane przez commity w tym repo. Konsumenckie projekty mogą:

- Re-run `degit` aby zaciągnąć aktualną wersję (nadpisuje lokalne).
- Forkować regułę lokalnie — wtedy przy kolejnym `degit` zrobić merge ręcznie.

Zmiany filozofii (np. nowy framework, nowe benchmark studios) → PR do tego repo + ADR w `docs/adr/`.

## Jak reguły działają w Cursorze

- Pliki `.mdc` z frontmatterem YAML.
- `alwaysApply: true` — reguła aktywna zawsze.
- `globs: [...]` — reguła aktywna tylko dla plików pasujących do glob.
- Cursor czyta reguły przy każdym zapytaniu — mniej szumu = lepsza pamięć AI.

## Benchmark

Reguły fundamentu pisane pod agency-tier work. Benchmark studios: Active Theory, Resn, Locomotive, Obys, Igloo Inc., Basement, Immersive Garden.

Reguły medusy pisane pod PL/EU ecommerce w klasie: Aimé Leon Dore, Kith, APC, Frankie Shop, Allbirds, Gymshark.
