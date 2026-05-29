#!/usr/bin/env bash
# Synchronizuje fundament/ z GitHub do ~/.cursor/rules + patch skanera User Rules.
# macOS / Linux. Po aktualizacji Cursora uruchom ponownie (patch jest nadpisywany).

set -euo pipefail

RULES_DIR="${HOME}/.cursor/rules"
TEMP_REPO="${TMPDIR:-/tmp}/cursor-rules-import"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Klonowanie Syntance/cursor-rules..."
rm -rf "$TEMP_REPO"
git clone --depth 1 https://github.com/Syntance/cursor-rules.git "$TEMP_REPO"

mkdir -p "$RULES_DIR"
cp "$TEMP_REPO/fundament/"*.mdc "$RULES_DIR/"

COUNT=$(find "$RULES_DIR" -maxdepth 1 -name '*.mdc' | wc -l | tr -d ' ')
echo "Skopiowano ${COUNT} plików do ${RULES_DIR}"

node "$SCRIPT_DIR/patch-cursor-user-rules.js" || {
  echo ""
  echo "Patch nieudany. Możliwe przyczyny:"
  echo "  - inna wersja Cursora (OLD_STRING_NOT_FOUND)"
  echo "  - brak uprawnień do /Applications/Cursor.app — spróbuj:"
  echo "    sudo node \"$SCRIPT_DIR/patch-cursor-user-rules.js\""
  echo ""
  echo "Reguły są na dysku w ~/.cursor/rules — bez patcha UI User Rules może być puste."
  exit 1
}

echo ""
echo "Gotowe. W Cursorze: Cmd+Shift+P → Developer: Reload Window"
echo "Potem: Cursor Settings → Rules → User (powinno być ${COUNT} User File Rules)"
