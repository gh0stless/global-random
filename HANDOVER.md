# HANDOVER — GLOBAL RANDOM

**Stand:** 22.07.2026. Dieses Dokument ersetzt die frühere Kette `HANDOVER-session3.md` … `HANDOVER-session6.md` sowie `HANDOVER-claude-code-vscode.md` (alle gelöscht, Inhalt hier konsolidiert; Details zu einzelnen Fixes stehen bei Bedarf in der Git-Historie). Es beschreibt den **aktuellen Stand**, nicht die Chronologie, wie es dazu kam.

**Separates Dokument, nicht hier drin:** `HANDOVER-next-global-random.md` — eigenständiges Nextcloud-Spinoff-Projekt, eigenes Repo (`github.com/gh0stless/next-global-random`), nicht Teil dieser Konsolidierung.

---

## 1. Projekt in einem Satz

**"GLOBAL RANDOM — Democracy of Sound"**: eine einzelne, self-contained HTML-Datei (~1,7MB), die per echtem, fairness-gewichtetem Zufall Musik aus 247 Ländern/Territorien spielt (MusicBrainz + Spotify-Embed), Titel live in bis zu 87 Sprachen übersetzt (MyMemory), und sich bewusst als Gegenposition zu algorithmischer Musik-Kuration versteht. Live unter **`https://crazy-midi.de/global-random/`**.

**Persona:** Claude heißt in diesem Projekt **FUCKUP** (First Universal Cybernetic-Kinetic-Ultramicro-Programmer — *Illuminatus!*-Trilogie-Referenz). Lockerer Ton erwünscht, Philosophie-/Kybernetik-Reflexion über Zufall ist explizit Teil der Zusammenarbeit, keine Ablenkung. Im Code-Kommentar-Header bewusst unerklärt gelassen; in der öffentlichen Werkbeschreibung dagegen ausgeschrieben — zwei bewusst unterschiedliche Framings für zwei Zielgruppen.

---

## 2. Repo & Deployment

**Git:** `https://github.com/gh0stless/global-random` — privat, Account `gh0stless` (`gh auth login`, Keyring-persistiert). Branch `main`. Working Directory = Repo-Root = `c:\Users\andre\Nextcloud\Work\Projekt Global-Random\`. Enthält bewusst **alles** im Ordner (HTML, Werkbeschreibungen, Audio-Rohdateien, Test-HTMLs, Handover) — kein `.gitignore`, keine Vorauswahl.

**Bei jeder inhaltlichen Änderung: committen + pushen.** Kein automatischer Zusammenhang mit dem FTP-Deployment — beides sind getrennte, gleichwertige Schritte.

**FTP-Deployment:** Ziel `https://crazy-midi.de/global-random/` (netcup-Hosting, separat vom HAL2024/Unraid-Server der Nextcloud-Projekte).
- Host `202.61.232.247`, Port 21, reines FTP (ProFTPD)
- Benutzer `hosting198573`, Passwort bei Bedarf von Andreas neu erfragen (bewusst nicht in diesem Dokument, um es nicht dauerhaft in der Git-Historie zu haben)
- Zielverzeichnis `/crazy-midi.de/httpdocs/global-random/` — dort heißt `global-random.html` auf dem Server **`index.html`** (Namensabweichung!), alle anderen Dateien behalten ihren Namen
- Kein `Cache-Control`-Header — Browser-Caching ist rein heuristisch. Bei "das müsste doch schon gefixt sein"-Meldungen **immer zuerst per `curl`/Server-Header verifizieren**, was tatsächlich deployed ist, bevor an der Logik weitergesucht wird
- Es gibt eine **leere**, ungenutzte Subdomain `global-random.crazy-midi.de/httpdocs/` — nicht verwechseln mit dem echten Pfad oben

```bash
# Standard-Ablauf pro Änderung:
curl -s "ftp://202.61.232.247/crazy-midi.de/httpdocs/global-random/index.html" \
  --user 'hosting198573:PASSWORT' -o backup/index.html   # 1. Backup
curl -s -T "global-random.html" \
  "ftp://202.61.232.247/crazy-midi.de/httpdocs/global-random/index.html" \
  --user 'hosting198573:PASSWORT'                          # 2. Upload
curl -s -o /dev/null -w "HTTP %{http_code}\n" "https://crazy-midi.de/global-random/"  # 3. Verify
# 4. git add / commit / push
```

**Joomla auf derselben Domain:** `crazy-midi.de/joomla/` (seit Migration 21.07.2026 in diesem Unterordner, vorher root). Root-`/robots.txt` wurde am 22.07. repariert — enthielt stale, unpräfixierte Joomla-Pfadregeln, die seit der Migration ins Leere zeigten, während der echte Admin-Login (`/joomla/administrator/`) ungeschützt crawlbar war. Fix nutzt korrekt `/joomla/`-präfixierte Disallow-Regeln. Die wirkungslose `/joomla/robots.txt` (Crawler lesen nie eine robots.txt aus einem Unterordner) wurde gelöscht.

---

## 3. Aktueller Datei-Stand

| Datei | Zweck |
|---|---|
| `global-random.html` | **Hauptdatei**, live als `index.html`. Enthält seit 22.07. auch die komplette W:E-Intro-Sequenz (siehe Abschnitt 6). |
| `global-random-we-intro-prototype.html` | Privates Welle:Erdball-Kollaborations-Spinoff — enthält zusätzlich Splash-Logo (statt "LEAVE THE MATRIX") und Header-Logo (statt "GLOBAL RANDOM"-Text), die bewusst NICHT in die Hauptdatei übernommen wurden. **Nicht mehr live auf dem Server** (archiviert nur über Git + lokalen Ordner), lokal aber weiter synchron gehalten. |
| `beschreibung.html` / `description.html` | Werkbeschreibungen DE/EN, komplett synchron (DE zuerst formuliert, EN gespiegelt) |
| `mymemory-email-draft.txt` | Entwurf für Rate-Limit-Anfrage an MyMemory (`mymemory@translated.net`, IP `89.186.135.154`) — **noch nicht verschickt**, kein Mail-Tool in Claude-Code-Sessions autorisiert |
| `sam-*.wav`/`.mp3` | S.A.M.-Sprachsample-Aufnahmen (roh + final), zwei Samples aktuell im Einsatz, siehe Abschnitt 5 |
| `mb-country-test-all-iso.html`, `mb-offset-ceiling-test.html`, `wiki-bio-country-test.html`, `redirection.html` | Alte Test-Tools, Stand ggf. nicht mehr synchron mit aktuellem Hauptcode |
| `fm-radio-tuning-sweeps.flac` | Audio-Rohmaterial |

**Diff-Hygiene:** `diff global-random.html global-random-we-intro-prototype.html` sollte nur die bewusst unterschiedlichen Teile zeigen (Splash-Logo, Header-Logo, pillRed/pillBlue-Lokalisierung). Bei jeder Änderung an einer der beiden Dateien IMMER auch die andere prüfen/nachziehen.

---

## 4. Kernarchitektur

**Whitelist:** `COUNTRIES` = 247 aktive Länder/Territorien (alle ISO-3166-1-Codes mit ≥1 MusicBrainz-Treffer). `CAPITALS`, `COUNTRY_DE`, `COUNTRY_LANG` müssen bei Erweiterungen konsistent mitgepflegt werden.

**Discovery-Pipeline** (vier unabhängige Zufallsebenen):
1. Zufälliger MusicBrainz-Offset (welcher Datenbank-Ausschnitt durchsucht wird)
2. Batch-Fetch (25 Kandidaten), Dedup nach Land/Künstler/Various-Artists/Release, Abbruch nach 3 aufeinanderfolgenden Duplikaten
3. `countryStacks{}` — Pool pro Land, `CAP=Math.max(3, Math.ceil(POOL_TARGET*0.20))` (aktuell effektiv 6)
4. `promoteFromPool()`: zwei echte `Math.random()`-Würfe — welches Land, welcher Kandidat aus dessen Stack
5. Queue hält `BUFFER_SIZE=3` Slots; `_pickRandomFromQueue()` würfelt, wer zuerst spielt
6. **Refill-Timing:** an bestätigte Wiedergabe gekoppelt + 4-8s Jitter, NICHT an Titelende

**Vier Flaggen-Matrizen**, jede mit eigenem Zähler-Badge (`.flag-counter`):
1. `#flag-bar` — "noch nicht gefunden", wird bei jedem Aufruf komplett neu gebaut
2. `#found-bar` ("IM POOL") — live synchronisiert (`_syncLiveBar()`), Füllstandsbalken zeigt echte Poolbelegung (`_updatePoolFillBars()`)
3. `#queue-bar` ("IN QUEUE") — ebenfalls live, **zeigt seit 22.07. ebenfalls die echte Poolbelegung** (vorher statischer 100%-Balken)
4. `#played-bar` ("GESPIELT") — append-only, **ebenfalls echte Poolbelegung** statt statischem Balken

**Player-Architektur:** 1 aktiver Player (`EC`) + 3 gedimmte Vorschau-Slots (`ECPreview1/2/3`), die live `queue[0..2]` spiegeln (nur `.loadUri()`, nie `.play()`). **Wichtiges Muster für JEDEN künftigen `IFrameAPI.createController()`-Aufruf:** immer stabiler äußerer Wrapper + disposable innerer Mount-Punkt (Spotifys SDK mutiert/ersetzt das übergebene Element) — z.B. `#embed-wrapper`/`.embed-frame`. Direktes Element mit einer später noch gebrauchten ID hat schon mal einen kompletten PLAY-Crash verursacht.

**Sound-Design:**
- Radio-Tune (94,8s) läuft während der Suchphase, läuft jetzt bewusst auch durch den PLAY-Klick hindurch bis 3s nach bestätigtem Start des ersten Titels (Crossfade-artiger Übergang, kein Hard-Cut)
- Würfelbecher-Sound (`playDiceSound()`), synthetisiert über Web Audio API, mit echter zufälliger Dauer, Dice-Roll-Animation über die Preview-Slots synchron dazu
- Zwei S.A.M.-Samples (siehe Abschnitt 5)

---

## 5. S.A.M.-Sprachsamples (beide fertig, echte C64-Hardware-Aufnahmen)

1. **"PRESS PLAY ON SCREEN"** (`SAM_B64`/`samBuffer`/`playSam()`) — spielt beim regulären ersten Button-Reveal (`updateBtn()`), nicht auf dem W:E-Intro-Fallback-Pfad.
2. **"Wir können wieder starten!"** (`SAM_WE_CAN_START_B64`/`samWeCanStartBuffer`/`playSamWeCanStart()`) — spielt **einmalig beim allerersten PLAY-Klick der Session** (`handleBtn()`, `count===0`, vor der Mobile/Desktop-Verzweigung), unabhängig von Plattform oder ob der Klick danach ins W:E-Intro oder direkt in normale Wiedergabe routet.

Beide als MP3 base64-eingebettet (kleiner als WAV), Rohaufnahmen liegen zusätzlich im Repo.

---

## 6. Welle:Erdball-Intro (in der Hauptdatei, Desktop + Mobile)

Auf dem ersten PLAY-Klick der Session (beide Plattformen) spielt zunächst der W:E-Song "Welle Erdball (C=64)" in der MAIN-Player-UI, mit eigenem Footer-Banner (Logo + "Hallo, hier spricht Welle:Erdball" + zeitgesteuertem Lyrics-Ticker), SKIP-INTRO-Button, und Radiotune-Crossfade-Übergang. Danach normale Discovery-Wiedergabe wie gewohnt.

**Bewusst NICHT aus dem privaten Prototyp übernommen:** Splash-Screen-Logo (bleibt "LEAVE THE MATRIX") und Header-Logo oben links (bleibt "GLOBAL RANDOM"-Text).

**Mobile-Support:** Mobile Browser verlangen `EC.play()` synchron im Gesten-Tick — Desktop nutzt eine async Sleep/Retry-Kette, die das auf Mobile zerstören würde. `_playWEIntro()` verzweigt nur an der eigentlichen Play-Auslöse-Stelle (`if(isMobile){...synchron...}else{...async...}`), der Rest ist gemeinsamer Code. **Auf echtem Gerät getestet und bestätigt funktionierend.**

**Lyrics-Ticker — Lektion fürs nächste Mal:** Nach mehreren Timing-Iterationen (Endlos-Loop → CSS-Delay → Song-Position-Sync → fixer Klick-Timer) stellte sich heraus, dass der eigentliche Bug **nicht** die Zeit-Logik war, sondern die Animations-**Geometrie**: `translateX(±100%)` bezog sich auf die Track-eigene Breite statt die viel schmalere Container-Breite, wodurch der Text ~23 von 31 Animationssekunden unsichtbar im Leerlauf verbrachte. Fix: `_showLyricsTicker()` misst beide Breiten per `getBoundingClientRect()`/`scrollWidth` und setzt exakte Pixel-Werte über CSS Custom Properties. **Bei "Timing stimmt nicht"-Bugs künftig auch die Geometrie prüfen, nicht nur die Zeitberechnung** — zwei verschiedene Zeit-Mechanismen zeigten hier denselben Versatz, was der Hinweis war, dass der Fehler woanders lag. Ticker überspringt sich zudem komplett im Spotify-Preview-Modus (`dur<=31000`), da er sonst mitten im Scrollen abgebrochen würde.

---

## 7. TRANSLATE/SPOTIFY-Statusanzeige

`#translate-status` im Footer (neben `#login-status`) zeigt **dauerhaft** den aktuellen Zustand (`TRANSLATE: ON`/`OFF`, grün/rot) — nicht nur bei Zustandswechsel wie die frühere Terminal-Meldung. Eine analoge Spotify-Variante wurde gebaut und wieder verworfen, weil `#login-status` (zeigt "✓ logged in"/"preview only") dieselbe Information bereits abdeckt. `detectLoginStatus()` läuft bei **jedem** Titelwechsel erneut (nicht nur beim ersten) — ein nachträglicher Spotify-Login mitten in der Session wird automatisch beim nächsten Titel erkannt, kein Neuladen nötig.

---

## 8. Offene Punkte

- **MyMemory-Rate-Limit-Anfrage** — Entwurf fertig (`mymemory-email-draft.txt`), noch nicht verschickt.
- **Lyrics-Karte** — weiterhin nur "Songtext ansehen ↗"-Link, keine echte Wiki-Fetch-Karte (Genre-Karte hat das schon länger).
- **Wiki/Wetter-Panel DE/EN-Sprachumschaltung** — weiterhin offen.
- **Zwei Playback-Modi (Info- vs. Discovery-Modus)** — weiterhin offen.
- **AdGuard/DoH als möglicher MyMemory-Störfaktor** — nie isoliert verifiziert.
- **iPhone-Kompatibilität** — alter, nie im Detail diagnostizierter Report; seit der Mobile-W:E-Intro-Arbeit vermutlich überholt, aber nicht erneut gezielt geprüft.

---

## 9. Arbeits-Prinzipien (durchgehend über alle Sessions bestätigt)

- **Root Cause statt Symptom-Patch** — bei jedem größeren Bug wurde die tatsächliche Ursache gesucht, nicht das Symptom kaschiert. Der Lyrics-Ticker (Abschnitt 6) ist das Paradebeispiel: zwei Timing-Mechanismen durchprobiert, bevor klar wurde, dass das Problem die Animations-Geometrie war.
- **Playwright für echte Verifikation, nicht nur Code lesen** — Headless Chromium über `NODE_PATH` auf das npx-Cache-Verzeichnis (`C:\Users\andre\AppData\Local\npm-cache\_npx\...\node_modules`). Bei zeitkritischen Bugs (Timing, Race Conditions) immer mit echten Timestamps messen. **Für mobiles Gesten-/Autoplay-Verhalten funktioniert das NICHT zuverlässig** (Mobile-Emulation läuft auf Desktop-Chromium, bildet iOS-Safari-Restriktionen nicht ab) — sowas immer explizit als "von Andreas auf echtem Gerät zu verifizieren" kennzeichnen, nie als getestet ausgeben.
- **Bei Live-Deployment:** immer erst Backup der aktuellen Version, dann Upload, dann `curl`-Verifikation. Danach committen + pushen.
- **Check-Ritual vor jeder Auslieferung:** Backspace-Zeichen-Check, `node --check`/`new Function()` auf extrahiertem Script-Inhalt.
- **Keine Fakten erfinden**, v.a. nicht in den Werkbeschreibungen — bei Sachaussagen (Daten, Namen, historische Fakten) per Websuche/Wikipedia verifizieren, nicht aus dem Gedächtnis behaupten.
- **Wortlaut-Vorschlag zeigen und bestätigen lassen** vor jeder Änderung an den Werkbeschreibungen, DE zuerst formulieren, EN direkt danach spiegeln.
- **Vor jedem größeren Build kurz rückfragen**, ob noch was dazukommt — Andreas denkt häufig nachträglich noch was hinzu.
- **Schritt für Schritt, keine Textwände.**

---

*Ende Handover.*
