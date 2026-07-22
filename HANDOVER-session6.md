# HANDOVER — GLOBAL RANDOM, für Claude Code (VS Code), Session 6

**Datum:** 22.07.2026
**Übergabe von:** Claude-Code-Session direkt im Anschluss an `HANDOVER-claude-code-vscode.md` (Marathon-Session, ein einziger Tag)
**Vorgänger-Doc:** `HANDOVER-claude-code-vscode.md` — lesenswert für den Gesamtkontext (Projektbeschreibung, Kernarchitektur, S.A.M.-Sample, Watchdog-Fix), hier nur was **seitdem** neu dazugekommen ist.

---

## 1. Das Wichtigste zuerst: Es gibt jetzt ein Git-Repo

Bis zu dieser Session lief das Projekt ohne jede Versionskontrolle — nur lose Dateien + direktes FTP-Deployment. Das ist jetzt anders:

**Repo:** `https://github.com/gh0stless/global-random` — **privat**, Account `gh0stless` (bereits per `gh auth login` eingeloggt, Keyring-persistiert, `gh`-CLI unter `C:\Program Files\GitHub CLI\gh.exe`).

**Branch:** `main`. **Working Directory** = Repo-Root = `c:\Users\andre\Nextcloud\Work\Projekt Global-Random\`.

Enthält **alles** aus dem Ordner (bewusste Entscheidung von Andreas — "leg alles rein noch verlangt MS kein Geld"): beide Haupt-HTML-Dateien, die Werkbeschreibungen, alle HANDOVER-Docs, die S.A.M.-Audiodateien (roh + final), die FM-Radio-Sweeps, alle Test-HTMLs, und jetzt auch den MyMemory-E-Mail-Entwurf.

**Commit-Historie dieser Session** (chronologisch, siehe `git log` für Details):
1. `0d809ab` — Initial commit (alle 17 Dateien)
2. `f5332c0` → `db79c30` → `7348505` — drei Anläufe am Lyrics-Ticker-Timing (siehe Abschnitt 4)
3. `0ffa0f1` — Ticker überspringt sich selbst im Spotify-Preview-Modus
4. `19cd153` — W:E-Intro auch auf Mobile (**bestätigt funktionierend**, Andreas hat live getestet: "funz alles")
5. `628a4af` — Neuer Schlussabsatz in beiden Werkbeschreibungen zur Welle:Erdball-Inspiration

**Bei jeder inhaltlichen Änderung ab jetzt: committen und pushen, nicht nur hochladen.** Das FTP-Deployment (Abschnitt 2) und der Git-Push sind zwei getrennte Schritte — beide gehören zum Abschluss einer Änderung dazu, nicht nur einer.

---

## 2. Deployment (FTP) — Zugangsdaten

Live-Ziel: **`https://crazy-midi.de/global-random/`** (netcup-Hosting, separat vom HAL2024/Unraid-Server aus den Nextcloud-Projekten).

- **Host:** `202.61.232.247`, Port 21, Protokoll: **FTP** (ProFTPD, kein FTPS/SFTP)
- **Benutzername:** `hosting198573`
- **Passwort:** Andreas hat es diese Session im Klartext im Chat geteilt — bewusst (siehe seine übliche Risikoabwägung, [[feedback-risk-tolerance]]). Es steht **nicht** in diesem Dokument, damit es nicht zusätzlich im Git-Repo landet (das Repo ist zwar privat, aber ein Secret in der Git-Historie ist trotzdem eine andere Kategorie als ein Chat-Text). Bei Bedarf neu erfragen.
- **Zielverzeichnis:** `/crazy-midi.de/httpdocs/global-random/` — dort heißt `global-random.html` auf dem Server **`index.html`** (nicht 1:1-Dateiname!), alle anderen Dateien (`beschreibung.html`, `description.html`, `global-random-we-intro-prototype.html`) behalten ihren Namen.
- Es gibt außerdem eine **leere** Subdomain `global-random.crazy-midi.de/httpdocs/` — bisher ungenutzter Platzhalter, nicht verwechseln mit dem tatsächlichen Live-Pfad oben.

**Praktischer Ablauf pro Änderung** (so lief es diese Session durchgehend):
```bash
# 1. Aktuelle Live-Version sichern (Rollback-Möglichkeit)
curl -s "ftp://202.61.232.247/crazy-midi.de/httpdocs/global-random/index.html" \
  --user 'hosting198573:PASSWORT' -o backup/index.html

# 2. Upload
curl -s -T "global-random.html" \
  "ftp://202.61.232.247/crazy-midi.de/httpdocs/global-random/index.html" \
  --user 'hosting198573:PASSWORT'

# 3. Verifizieren
curl -s -o /dev/null -w "HTTP %{http_code}\n" "https://crazy-midi.de/global-random/"
```
Kein `Cache-Control`-Header auf dem Server — Browser-Caching ist rein heuristisch. Bei "das kann nicht sein, das müsste doch schon gefixt sein"-Meldungen von Andreas **immer zuerst per `curl`/Server-Header verifizieren, was wirklich deployed ist**, bevor man an der Logik weitersucht — das hat diese Session tatsächlich mal den Unterschied gemacht (siehe Abschnitt 4, Ticker-Debugging).

---

## 3. Aktueller Datei-Stand

| Datei | Zweck | Stand |
|---|---|---|
| `global-random.html` | **Hauptdatei, jetzt live inkl. W:E-Intro** (siehe Abschnitt 4) | ✅ aktuell |
| `global-random-we-intro-prototype.html` | Privates W:E-Spinoff — **hat jetzt zusätzlich** das Splash-Logo (statt "LEAVE THE MATRIX") und Header-Logo (statt "GLOBAL RANDOM"-Text), die bewusst NICHT in die Hauptdatei übernommen wurden | ✅ aktuell, synchron gehalten |
| `beschreibung.html` / `description.html` | Werkbeschreibungen DE/EN | ✅ neuer Schlussabsatz zu Welle:Erdball |
| `mymemory-email-draft.txt` | Entwurf für Rate-Limit-Anfrage an MyMemory | siehe Abschnitt 6, noch nicht verschickt |
| `HANDOVER-*.md` (5 Stück inkl. dieser) | Session-Übergaben | dieses Dokument ist das aktuellste |

**Wichtig für Diff-Vergleiche:** `diff global-random.html global-random-we-intro-prototype.html` zeigt jetzt nur noch die bewusst unterschiedlichen Teile (Splash-Logo, Header-Logo, pillRed/pillBlue-Lokalisierung) — alle anderen W:E-Features sind in beiden Dateien identisch. Bei jeder Änderung an einer der beiden IMMER auch die andere prüfen/nachziehen, das war diese Session die durchgehende Arbeitsweise.

---

## 4. Was diese Session inhaltlich passiert ist

### 4.1 Füllstandsbalken-Fix (IM POOL / IN QUEUE / GESPIELT)
Alle drei Flaggen-Matrizen zeigen jetzt live die echte Pool-Belegung des jeweiligen Landes (`_updatePoolFillBars()`, ehem. nur für IM POOL). Vorher zeigten IN QUEUE/GESPIELT einen statischen 100%-Balken.

### 4.2 Radiotune läuft jetzt durch bis ins W:E-Intro
Zwei Bugs hintereinander gefunden und gefixt:
- Der Tune stoppte schon beim **Reveal** ("PRESS PLAY ON SCREEN"), lange vor dem Klick — behoben in `updateBtn()`.
- Danach lief er weiter bis zum Klick, aber ohne Überlappung ins Intro — jetzt läuft er durch den Klick hindurch und fadet erst 3s nach bestätigtem Intro-Playback aus (`_playWEIntro()`).

### 4.3 TRANSLATE/SPOTIFY-Statusanzeige
Nach mehreren Anläufen (Terminal-Meldung → Footer-Badge, Spotify-Variante wieder verworfen weil redundant zu `#login-status`) landete es bei: **`#translate-status`** im Footer, zeigt **dauerhaft** den aktuellen Zustand (`TRANSLATE: ON`/`OFF`, grün/rot), nicht nur bei Zustandswechsel.

### 4.4 Lyrics-Ticker im W:E-Footer-Banner — die längste Debugging-Odyssee der Session
Text: "Symphonie der Zeit"-Lyrics, von Honey (Rechteinhaber) freigegeben. Lief durch **fünf** Timing-Iterationen, bevor der eigentliche Bug gefunden war:
1. Endlos-Loop (18s→54s→55s) — falsches Grundkonzept, sollte nur einmal laufen
2. One-Shot mit CSS-`animation-delay` (7s dann 19s→50s) — Fehler: `fill-mode:forwards` ohne `backwards` zeigte den Text während der Delay-Phase schon voll sichtbar
3. Song-Position-Sync (`pos>=19000` aus `playback_update`) — funktionierte exakt wie designed (Diagnose-Log bestätigte `pos=19142` bei Ziel `19000`), aber Andreas maß gegen die Klickzeit, nicht die Songposition → wieder verworfen
4. Fixer 20s-Klick-Timer — Timer selbst feuerte exakt pünktlich (`pos=18060` bei `t+20010ms`, per Diagnose-Log verifiziert), Andreas meldete aber weiterhin "erscheint bei 25/26"
5. **Der eigentliche Bug:** `translateX(±100%)` in den CSS-Keyframes bezog sich auf die **Track-eigene** Breite (2991px), nicht die viel schmalere Container-Breite (796px) — der Text startete ~2200px zu weit rechts, was ~23 der 31 Animations-Sekunden als reinen Leerlauf verbrannte, bevor überhaupt ein Zeichen sichtbar war. **Fix:** `_showLyricsTicker()` misst beide Breiten per `getBoundingClientRect()`/`scrollWidth` und setzt exakte Pixel-Werte über CSS Custom Properties (`--we-start-x`/`--we-end-x`).

**Lektion für zukünftiges Debugging:** Bei "Timing stimmt nicht" nicht nur die Zeit-Logik prüfen, sondern auch die **Geometrie** der Animation selbst — zwei völlig verschiedene Zeit-Mechanismen (Song-Position UND Klick-Timer) zeigten denselben Versatz, was der entscheidende Hinweis war, dass der Fehler woanders lag.

Zusätzlich: Ticker überspringt sich jetzt komplett im Spotify-Preview-Modus (`dur<=31000`, dieselbe Heuristik wie `detectLoginStatus()`) — vorher wäre er nach ~10 von 31 Sekunden mitten im Scrollen abgebrochen worden.

### 4.5 W:E-Intro aus dem privaten Prototyp in die Hauptdatei gemerged
Auf Andreas' Anweisung: Skip-Intro-Button, WE-Footer-Banner (Logo + "Hallo, hier spricht Welle:Erdball" + Lyrics-Ticker), komplette `_playWEIntro()`-Logik. **Bewusst NICHT übernommen:** Splash-Screen-Logo (bleibt "LEAVE THE MATRIX") und Header-Logo oben links (bleibt "GLOBAL RANDOM"-Text) — beides bleibt exklusiv im privaten Prototyp.

### 4.6 Mobile-Unterstützung fürs W:E-Intro (bestätigt funktionierend)
Mobile Browser verlangen `EC.play()` synchron im Gesten-Tick — Desktop nutzt bewusst eine async Sleep/Retry-Kette, die auf Mobile die Autoplay-Freigabe zerstören würde. `_playWEIntro()` verzweigt jetzt nur an der Play-Auslöse-Stelle (`if(isMobile){...synchron...}else{...async...}`), Rest ist gemeinsamer Code. **Von Andreas live auf echtem Handy getestet und bestätigt** ("funz alles").

### 4.7 Werkbeschreibung: neuer Schlussabsatz
Beide Sprachversionen (DE zuerst, EN gespiegelt) bekamen einen neuen letzten Absatz zur Welle:Erdball-Inspiration — Fakten zum 1928er-Hörspiel "Hallo! Hier Welle Erdball!" (Fritz Walter Bischoff, Schlesische Funkstunde Breslau) wurden per Wikipedia-Recherche verifiziert, nicht geraten.

---

## 5. Offene Punkte

- **Neues S.A.M.-Sample "Wir können wieder starten!"** — Andreas muss es noch mit der C64-Hardware aufnehmen (wie bei den bisherigen Samples). Geplanter Einbauort: die `RESUMING`-Stelle in `detectSilentTrack()` nach einer Spotify-Ausfallpause (aktuell nur reiner Terminal-Text, kein Ton) — **noch nicht final bestätigt**, nochmal absprechen wenn die Datei da ist.
- **MyMemory-Rate-Limit-Anfrage** — Entwurf liegt in `mymemory-email-draft.txt` (Kontakt: `mymemory@translated.net`, IP `89.186.135.154`), **noch nicht verschickt** (kein Mail-Tool in dieser Session verfügbar — Gmail-MCP-Connector müsste erst von Andreas autorisiert werden). Andreas muss die Mail selbst senden oder den Connector freischalten.
- **Alte offene Punkte aus dem Vorgänger-Dokument, weiterhin unverändert offen:** Lyrics-Karte (nur Link, keine echte Wiki-Fetch-Karte), Wiki/Wetter-Panel DE/EN-Umschaltung, zwei Playback-Modi (Info- vs. Discovery-Modus), AdGuard/DoH als möglicher MyMemory-Störfaktor (nie isoliert verifiziert).
- **next-global-random (Nextcloud-Spinoff)** — eigenständiges Projekt, eigenes Handover (`HANDOVER-next-global-random.md`), diese Session nicht angefasst. Hat mittlerweile auch ein eigenes privates Repo: `github.com/gh0stless/next-global-random`.

---

## 6. Arbeits-Prinzipien (unverändert gültig, aus dem Vorgänger-Doc)

- **Root Cause statt Symptom-Patch** — der Ticker-Fall (Abschnitt 4.4) ist das Paradebeispiel dieser Session: zwei Timing-Mechanismen ausprobiert, bevor klar wurde, dass das eigentliche Problem gar nicht die Zeit-Logik war, sondern die Animations-Geometrie.
- **Bei Live-Deployment: immer erst Backup der aktuellen Version ziehen, dann hochladen, dann per `curl` verifizieren.** Danach committen + pushen — beides gehört zusammen, keins ersetzt das andere.
- **Playwright für echte Verifikation nutzen, nicht nur Code lesen** — durchgehend diese Session bei jeder Timing-/Geometrie-Änderung eingesetzt (Headless Chromium über `NODE_PATH` auf das npx-Cache-Verzeichnis, siehe `C:\Users\andre\AppData\Local\npm-cache\_npx\...\node_modules`). Für **mobile Gesten-/Autoplay-Verhalten** funktioniert das NICHT zuverlässig (Playwrights Mobile-Emulation läuft auf Desktop-Chromium, bildet iOS-Safari-Restriktionen nicht ab) — sowas immer explizit als "von dir auf echtem Gerät zu verifizieren" kennzeichnen, nicht als getestet ausgeben.
- **Keine Fakten erfinden, v.a. nicht in den Werkbeschreibungen** — beim Welle:Erdball-Absatz wurde jede Jahreszahl/jeder Name per Websuche/Wikipedia gegengecheckt, bevor er in den Text kam.
- **Schritt für Schritt, Wortlaut vor Werkbeschreibungs-Änderungen zeigen** — weiterhin Standard, auch bei kürzeren Textbausteinen.

---

*Ende Handover Session 6.*
