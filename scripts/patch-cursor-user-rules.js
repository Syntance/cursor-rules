#!/usr/bin/env node
/**
 * Włącza skanowanie ~/.cursor/rules w UI Cursor → Settings → Rules → User.
 * Cursor domyślnie skanuje tylko workspace; ten patch dodaje LocalCursorRulesService na homedir().
 *
 * Uruchom ponownie po każdej aktualizacji Cursora (patch jest nadpisywany).
 * Wymaga: Cursor zamknięty lub Reload Window po patchu.
 */

const fs = require("fs");
const path = require("path");

const OLD_STRING =
  'Ee=k.map(e=>new E.KO(f,Y,e,!0,V,X)),ve=new E.EV(f,k,K.homedir(),Y,!0,X,V,A,"ide"),_e=new E.Rx(f,()=>({importThirdPartyPlugins:V()}),X,fe),Te=new E.Px([...Ee,ve,_e])';

const NEW_STRING =
  'Ee=k.map(e=>new E.KO(f,Y,e,!0,V,X)),UserHomeRulesSvc=new E.KO(f,Y,K.homedir(),!0,V,X),ve=new E.EV(f,k,K.homedir(),Y,!0,X,V,A,"ide"),_e=new E.Rx(f,()=>({importThirdPartyPlugins:V()}),X,fe),Te=new E.Px([...Ee,UserHomeRulesSvc,ve,_e])';

function findCursorMainJs() {
  const home = process.env.HOME || process.env.USERPROFILE || "";
  const candidates = [];

  if (process.platform === "win32") {
    if (process.env.LOCALAPPDATA) {
      candidates.push(
        path.join(
          process.env.LOCALAPPDATA,
          "Programs/cursor/resources/app/extensions/cursor-agent-exec/dist/main.js"
        )
      );
    }
  } else if (process.platform === "darwin") {
    candidates.push(
      "/Applications/Cursor.app/Contents/Resources/app/extensions/cursor-agent-exec/dist/main.js",
      path.join(
        home,
        "Applications/Cursor.app/Contents/Resources/app/extensions/cursor-agent-exec/dist/main.js"
      )
    );
  } else {
    candidates.push(
      "/usr/share/cursor/resources/app/extensions/cursor-agent-exec/dist/main.js",
      path.join(
        home,
        ".local/share/cursor/resources/app/extensions/cursor-agent-exec/dist/main.js"
      ),
      path.join(
        home,
        "Applications/cursor/resources/app/extensions/cursor-agent-exec/dist/main.js"
      )
    );
  }

  return candidates.find((p) => fs.existsSync(p)) ?? null;
}

const cursorExec = findCursorMainJs();

if (!cursorExec) {
  console.error("CURSOR_EXEC_NOT_FOUND");
  console.error("Szukane ścieżki zależą od platformy — ustaw CURSOR_MAIN_JS=/ścieżka/do/main.js");
  process.exit(1);
}

const override = process.env.CURSOR_MAIN_JS;
const target = override && fs.existsSync(override) ? override : cursorExec;

const content = fs.readFileSync(target, "utf8");

if (content.includes("UserHomeRulesSvc")) {
  console.log("ALREADY_PATCHED");
  console.log(target);
  process.exit(0);
}

if (!content.includes(OLD_STRING)) {
  console.error("OLD_STRING_NOT_FOUND");
  console.error("Wersja Cursora ma inny bundle — patch wymaga aktualizacji skryptu.");
  console.error(target);
  process.exit(1);
}

fs.writeFileSync(target, content.replace(OLD_STRING, NEW_STRING));
console.log("PATCHED_OK");
console.log(target);
