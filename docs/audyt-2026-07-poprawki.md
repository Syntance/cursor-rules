# Audyt reguł cursor-rules + projekt poprawek (2026-07-07)

Cel audytu: reguły mają prowadzić model do stron klasy Awwwards SOTD, maksymalnego
cyberbezpieczeństwa, niezawodności (w tym ochrony przed utratą baz danych), pełnego
compliance PL/EU, światowego UX/UI, checkoutu twardszego niż standard Lumine oraz
dyscypliny kodowania na poziomie Claude Fable 5.

Werdykt ogólny: fundament jest bardzo mocny (checkout standards, security, legal,
perf/a11y to poziom rzadko spotykany w regułach AI). Audyt znalazł jednak:
**(A) sprzeczności między regułami**, **(B) ciche bugi w globach** (reguły się nie
doładowują), **(C) luki w ochronie danych/backupach**, **(D) brak reguły dyscypliny
agenta**, **(E) kilka braków prawnych i checkoutowych**. Poniżej projekt poprawek
per plik, w kolejności wdrożenia.

---

## P0 — Sprzeczności i bugi (napraw najpierw; koszt niski, ryzyko wysokie)

### P0.1 Globy nie łapią realnych struktur projektów (standard checkoutu może się NIE doładować)
Problem: auto-attach w Cursorze dopasowuje globy do ścieżki od korzenia repo.
- Reguły `fundament/*` używają `src/**/*.tsx` — NIE zmatchują monorepo
  (`apps/storefront/src/**`), czyli w sklepach reguły design/rendering/perf/security
  nie doładowują się przy edycji plików.
- `medusa/46-checkout-standards.mdc` i `checkout-forms.mdc` używają
  `apps/*/app/**/checkout/**` — NIE zmatchują układu `apps/*/src/app/**/checkout/**`
  (a `cart-state.mdc` zakłada właśnie `apps/storefront/src/...`). Efekt: przy edycji
  checkoutu model może nie dostać twardego standardu.
- `medusa/20-ecom-design.mdc` hardkoduje nazwę appki `apps/storefront/` — projekt
  z inną nazwą appki nie dostanie reguły.
- `55-security.mdc` ma `src/middleware.ts`, a Next dopuszcza też root `middleware.ts`.

Poprawka (jednolita konwencja globów we WSZYSTKICH plikach):
- `src/**/X` → `**/src/**/X` (łapie solo repo i monorepo),
- checkout: `**/app/**/checkout/**`, `**/components/checkout/**`,
  `**/lib/validation/checkout*.ts`, `packages/commerce/**`,
- backend: `**/backend/src/modules/**`, `**/backend/src/api/**`, `**/backend/src/jobs/**`,
- `**/middleware.ts`, `**/next.config.ts`,
- zakaz hardkodowania nazw appek (`apps/*/` zamiast `apps/storefront/`).

### P0.2 Sprzeczność: DOMPurify
- `55-security.mdc` (Input validation): „użyj `isomorphic-dompurify`".
- `46-checkout-standards.mdc` §5: „NIE `isomorphic-dompurify` (jsdom → SSR crash
  `ERR_REQUIRE_ESM` na Vercel/Next16/Turbopack)".

Poprawka w `55-security.mdc`: sanityzacja HTML —
1) proste pola tekstowe (order notes, komentarze bez rich text): lekki strip-HTML
   (`sanitize-order-notes.ts` z `Syntance/moduly`), backend re-sanityzuje;
2) rich text (Tiptap itp.): DOMPurify client-side przed zapisem + walidacja schematu
   po stronie serwera; `isomorphic-dompurify` TYLKO w czystym środowisku Node
   (nigdy edge/Turbopack SSR path);
3) zasada „sanitize at rest" bez zmian.

### P0.3 Sprzeczność: View Transitions
- `00-core.mdc` (rozstrzygnięcia): `experimental.viewTransition` + React
  `<ViewTransition>`; NIE ręczny `document.startViewTransition()` na route change.
- `10-stack.mdc` („Page transitions") i `30-motion.mdc` mówią odwrotnie
  („`document.startViewTransition()` na każdym route change").

Poprawka: ujednolić 10-stack i 30-motion do wersji z 00-core (React `<ViewTransition>`
w App Router; ręczny `startViewTransition` tylko poza nawigacją routera, np. zmiana
motywu/galerii in-place).

### P0.4 Niespójność: CAPTCHA
`55-security.mdc` (Auth): „CAPTCHA (hCaptcha…)". Standard checkoutu: wyłącznie
Turnstile. Poprawka: wszędzie **Cloudflare Turnstile** (zero-cookie, GDPR-safe);
usunąć hCaptcha.

### P0.5 Konflikt: MFA panelu admina
`55-security.mdc`: „Admin panel = MFA obowiązkowo". `magazyn/magazyn-panel.mdc`:
2FA/MFA w Roadmap („świadomie nie-MVP"). Dla celu „mega bezpieczeństwo" poprawka:
- Panel wystawiony publicznie na prod = MUST przynajmniej jedno z:
  **passkey/TOTP MFA** (Better Auth) LUB dostęp za Cloudflare Access / IP allowlist.
- Allowlist e-maili + rate-limit pozostają, ale przestają wystarczać same.
- Przenieść MFA z Roadmap do MUST w `magazyn-panel.mdc` (co najmniej dla prod).

### P0.6 Martwa referencja
`46-checkout-standards.mdc` §6: „to nadpisuje starsze «nie dodawaj captchy»
z checkout-forms.mdc" — checkout-forms już ma sekcję Turnstile zgodną ze standardem.
Usunąć zdanie.

### P0.7 README — liczby reguł
README mówi raz „17 reguł" (struktura), a niżej „15 User File Rules" i „Tylko
fundament (15 reguł)". Ujednolicić do stanu faktycznego (17).

### P0.8 Duplikat graphify
`fundament/05-graphify.mdc` i `.cursor/rules/graphify.mdc` to identyczna treść
w dwóch miejscach. Dodać w README notkę „źródłem jest fundament/05, kopia w .cursor
dla tego repo — synchronizuj przy zmianie" (albo generować kopię skryptem sync).

---

## P1 — Ochrona danych, niezawodność, checkout „lepiej niż Lumine"

### P1.1 NOWA reguła: `fundament/02-agent-discipline.mdc` (alwaysApply) — „koduj jak Fable 5”
Największa pojedyncza luka: żadna reguła nie mówi agentowi, czego mu NIE WOLNO
zrobić z infrastrukturą/danymi i jak weryfikować własną pracę. Projekt treści:

- **Czytaj zanim edytujesz.** Zanim zmienisz plik: przeczytaj go i sąsiadów; dopasuj
  się do konwencji projektu (nazewnictwo, idiomy, gęstość komentarzy).
- **Root cause > plaster.** Nie maskuj objawów (try/catch wyciszający, `any`,
  `@ts-ignore`, skip testu). Napraw przyczynę albo STOP i opisz problem.
- **Minimalny diff.** Zero martwego kodu, zero TODO-placeholderów, zero
  wykomentowanych bloków, zero „przy okazji" refaktorów bez zgody.
- **Nie halucynuj API.** Wersje i sygnatury bibliotek → context7 MCP / oficjalna
  dokumentacja. Nie zgaduj.
- **Weryfikacja przed „gotowe".** `pnpm typecheck && pnpm lint && pnpm test && pnpm build`
  FAKTYCZNIE uruchomione; wynik raportowany zgodnie z prawdą (fail = pokaż output,
  nie „powinno działać").
- **Nigdy nie osłabiaj zabezpieczeń, żeby przeszło CI**: nie wyłączaj testów, CSP,
  walidacji Zod, reguł ESLint/TS bez wyraźnej zgody i wpisu w PR.
- **Akcje destrukcyjne — NIGDY bez wyraźnej zgody człowieka:**
  - `git push --force` na main / kasowanie brancha zdalnego,
  - `prisma migrate reset`, `db push --force-reset`, `DROP TABLE/DATABASE`,
    `TRUNCATE`, `DELETE` bez `WHERE` — na JAKIEJKOLWIEK nie-lokalnej bazie,
  - kasowanie/edycja plików migracji, które już wyszły na prod,
  - `rm -rf` poza katalogiem roboczym zadania,
  - commit/echo sekretów; edycja `.env` produkcyjnych.
- **Prod DB = read-only dla agenta.** Każda migracja prod poprzedzona snapshotem
  (patrz P1.2). Migracje wykonuje pipeline, nie ręczna komenda agenta.
- **Niepewność biznesowa → STOP i pytaj** (spójne z Rule #1 w 00-core).

### P1.2 `90-release.mdc` — backup/DR podniesione do celu „zero utraty danych"
Obecnie: daily backup + retention 30 dni + weekly export + kwartalny test restore.
Luki i poprawki:
- **RPO per klasa projektu.** Sklep/aplikacja transakcyjna: daily backup = utrata
  nawet 24h zamówień. MUST: **PITR/WAL** (Neon point-in-time restore, Railway wal-g)
  z RPO ≤ 15 min + daily snapshot + weekly offsite. Strona treściowa: daily wystarcza.
- **Backup odporny na kompromitację (ransomware-proof, 3-2-1):** kopia offsite na
  OSOBNYM koncie/kluczu — klucze produkcyjne NIE mogą kasować backupów; wersjonowanie
  + immutability (S3 Object Lock) dla kopii tygodniowej; szyfrowanie at rest.
- **Migracje bez utraty danych (nowa sekcja):** wzorzec expand → migrate → contract;
  ZAKAZ DROP/RENAME kolumny w tym samym deployu co kod, który jej używa; snapshot
  przed każdą migracją prod; rollback migracji opisany w PR.
- **Restore drill:** mierz i zapisuj czas odtworzenia (realny RTO) w runbooku,
  nie tylko „czy się udało".
- **Dead-man's switch na crony:** Sentry Cron Monitoring / healthchecks.io dla
  backup jobów i reconcile — alert gdy job się NIE wykonał (znany failure mode:
  scheduled jobs cicho nie chodzą przy złym `MEDUSA_WORKER_MODE`). Obecne alerty
  łapią „reconcile coś odzyskał", ale nie „reconcile przestał chodzić".

### P1.3 `46-checkout-standards.mdc` — ponad standard Lumine
Dopisać do §10 (monitoring) i §11 (testy):
- **§10 Dead-man's switch:** monitoring wykonań cronu reconcile (jak wyżej) —
  brak wykonania w oknie 2× harmonogram → alert. To domyka jedyną pozostałą dziurę
  5 torów (wszystkie tory mogą cicho przestać chodzić i nikt się nie dowie).
- **§10 Dzienne uzgodnienie finansowe (money reconciliation):** raport dzienny
  porównujący listę transakcji z API bramki (P24/Tpay/Stripe) z zamówieniami w DB —
  kwoty co do grosza, per status. Drift → alert. Łapie klasę błędów, której
  per-koszykowy reconcile nie widzi (np. płatność bez koszyka, podwójny capture).
- **§10 Success-rate per provider:** alert gdy payment success rate providera spada
  > X% względem baseline (degradacja bramki widoczna zanim klienci napiszą).
- **§11 Testy anty-fałszerskie (regresja):**
  - E2E: wejście na `/checkout/<provider>/return?status=success` bez realnej
    płatności NIE tworzy zamówienia;
  - E2E: próba manipulacji kwotą po stronie klienta → serwer liczy z DB, order
    ma kwotę z DB;
  - unit: podwójne `completeCart` (return page + reconcile równolegle) → drugi
    dostaje 409/cached state, żadnych dwóch zamówień;
  - integ: webhook bez podpisu / ze złym podpisem → 401, zero zmian stanu.
- **§5:** rate-limit „fail-open bez Upstash" — dopisać: na prod fail-open MUSI
  logować głośny alert (Sentry) przy każdym requeście bez limitera; brak Upstash
  na prod to incydent konfiguracyjny, nie tryb pracy.

### P1.4 `55-security.mdc` — domknięcie CSP i supply chain
- **CSP pełny szkielet** (dziś tylko script/style/report): dopisać
  `default-src 'self'; base-uri 'none'; object-src 'none'; frame-ancestors 'none'`
  (clickjacking!), `form-action 'self' + domeny bramek` (ochrona przed przejęciem
  submitu formularza checkoutu), `upgrade-insecure-requests`.
  W `46-checkout-standards.mdc` §5 dopisać `form-action` z domenami bramek.
- **Supply chain 2026:** pnpm `minimumReleaseAge` (cooldown ≥ 4–7 dni na świeże
  wersje paczek — ochrona przed falami ataków npm), pin GitHub Actions po SHA
  (nie tagu), `--frozen-lockfile` już jest.
- **Passkeys:** WebAuthn/passkey jako preferowany drugi czynnik (Better Auth
  passkey plugin), TOTP + backup codes jako fallback.

### P1.5 `60-quality.mdc` / DoD — realne urządzenia
Dopisać do Definition of Done: test na fizycznym iPhone Safari (scroll, animacje,
100dvh, widgety bramek/InPost) — Safari to miejsce, gdzie „ładne" strony psują się
najczęściej; emulator nie wystarcza.

---

## P2 — Awwwards/UX, prawo, parytet narzędzi

### P2.1 `20-design.mdc` (lub 00-core PROCES) — SOTD self-review gate
Przed oddaniem strony/hero model wykonuje samoocenę wg kryteriów jury Awwwards
(Design 40 / Usability 30 / Creativity 20 / Content 10):
- jest DOKŁADNIE jeden zapadający w pamięć moment i wszystko go wspiera;
- spójna **motion identity**: 2–3 sygnaturowe ruchy (easing + reveal pattern)
  zdefiniowane w briefie i używane konsekwentnie w całym projekcie (dopisek też
  do `30-motion.mdc`);
- interaction inventory: KAŻDY interaktywny element ma stan hover/focus/active
  z motion (nie tylko primary CTA);
- typografia działa jako element designu (skala, kontrast wag, detale OpenType),
  nie tylko nośnik tekstu;
- art direction fotografii spójna (grading spec), zero surowego stocka;
- usability nie ucierpiała: keyboard path + task completion na ścieżce konwersji.

### P2.2 `56-legal.mdc` — trzy braki
- **GPSR** (rozporządzenie o ogólnym bezpieczeństwie produktów, obowiązuje od
  13.12.2024): sklep z produktami fizycznymi MUSI pokazywać przy produkcie dane
  producenta / osoby odpowiedzialnej w UE (nazwa, adres, e-mail) + ostrzeżenia.
  Dopisać też linijkę w `45-commerce.mdc` (PDP).
- **AI Act (transparentność):** jeśli strona ma chatbota AI / treści generowane AI —
  obowiązek poinformowania użytkownika, że rozmawia z AI; oznaczanie treści
  syntetycznych tam, gdzie wymagane.
- **KSeF:** doprecyzować etapy (1.02.2026 najwięksi podatnicy, 1.04.2026 pozostali —
  obowiązek już trwa) w `order-pipeline.mdc`.

### P2.3 `README.md` — parytet narzędzi z Claude-rules
README nie mówi, jak w Cursorze podpiąć narzędzia, na których polegają reguły
(10-stack odsyła do 21st.dev Magic MCP, 50-perf do Chrome DevTools MCP). Dodać
sekcję „MCP dla Cursora": **21st.dev Magic** (`/ui`), **context7** (aktualne API
bibliotek — wymagane przez 02-agent-discipline), **Playwright MCP** (E2E/a11y),
**Chrome DevTools MCP** (PageSpeed loop). Framer Motion (`motion/react`), GSAP,
Aceternity/Magic UI/21st.dev są już poprawnie pokryte w 10-stack — bez zmian.

### P2.4 Drobne
- `medusa/00-ecom-core.mdc`: „AbortSignal.timeout(30_000)" dla Medusy vs
  `60-quality` „external API 5s" — dopisać w 60-quality wyjątek: self-hosted backend
  z cold-startem (Railway) może mieć 30s; wartości per typ celu, nie jedna.
- `checkout-forms.mdc` Express checkout: dopisać, że Apple Pay/Google Pay NIE omija
  złotej zasady (order nadal tworzy `completeCart` po potwierdzeniu Stripe, nigdy
  sam frontend).

---

## Kolejność wdrożenia
1. **P0.1 globy** (bez tego reszta reguł bywa niewidoczna dla modelu) → P0.2–P0.8.
2. **P1.1 agent-discipline** (nowy plik) + **P1.2 backup/DR** + **P1.3 checkout**.
3. **P1.4 security**, **P1.5 DoD**.
4. **P2.x** design gate, legal, README.

Po wdrożeniu: zsynchronizować zmiany do repo `Claude-rules` (osobny audyt:
`E:\Software development\Claude-rules\docs\audyt-2026-07-poprawki.md`).
