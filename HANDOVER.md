# HANDOVER — GLOBAL RANDOM

**Stand:** 08.08.2026. Dieses Dokument ersetzt die frühere Kette `HANDOVER-session3.md` … `HANDOVER-session6.md` sowie `HANDOVER-claude-code-vscode.md` (alle gelöscht, Inhalt hier konsolidiert; Details zu einzelnen Fixes stehen bei Bedarf in der Git-Historie). Es beschreibt den **aktuellen Stand**, nicht die Chronologie, wie es dazu kam. **Ab jetzt nicht mehr in Git getrackt** (siehe eigener Hinweis unten) — nur noch lokal, wird aber weiter aktuell gehalten.

**Separates Dokument, nicht hier drin:** `HANDOVER-next-global-random.md` — eigenständiges Nextcloud-Spinoff-Projekt, eigenes Repo (`github.com/gh0stless/next-global-random`), nicht Teil dieser Konsolidierung.

**Offizieller Release:** Am 04.08.2026 im MusicBrainz-Community-Forum angekündigt: [„GLOBAL RANDOM — a single-file art piece built on MusicBrainz data"](https://community.metabrainz.org/t/global-random-a-single-file-art-piece-built-on-musicbrainz-data/815397), gepostet von `gh0stless` (Andreas). Nennt `global-random.radio` als Zugangslink.

---

## 1. Projekt in einem Satz

**"GLOBAL RANDOM — Democracy of Sound"**: eine einzelne, self-contained HTML-Datei (~3,4MB, gewachsen durch die eingebetteten S.A.M.-Audiosamples — siehe Abschnitt 5), die per echtem, fairness-gewichtetem Zufall Musik aus 247 Ländern/Territorien spielt (MusicBrainz + Spotify-Embed), Titel live in bis zu 87 Sprachen übersetzt (MyMemory), und sich bewusst als Gegenposition zu algorithmischer Musik-Kuration versteht. Live unter **`https://crazy-midi.de/global-random/`** und unter der eigenen Domain **`https://global-random.radio`**. Lizenz: **CC BY-NC-ND 4.0** (seit dieser Session — geändert von der ursprünglichen SA-Variante, jetzt explizit ohne Bearbeitungen).

**Persona:** Claude heißt in diesem Projekt **FUCKUP** (First Universal Cybernetic-Kinetic-Ultramicro-Programmer — *Illuminatus!*-Trilogie-Referenz). Lockerer Ton erwünscht, Philosophie-/Kybernetik-Reflexion über Zufall ist explizit Teil der Zusammenarbeit, keine Ablenkung. Im Code-Kommentar-Header bewusst unerklärt gelassen; in der öffentlichen Werkbeschreibung dagegen ausgeschrieben — zwei bewusst unterschiedliche Framings für zwei Zielgruppen.

---

## 2. Repo & Deployment

**Git:** `https://github.com/gh0stless/global-random` — privat, Account `gh0stless` (`gh auth login`, Keyring-persistiert). Branch `main`. Working Directory = Repo-Root = `C:\Users\andre\Work\Projekt Global-Random\` (kein Nextcloud-Unterordner mehr im Pfad — falls das mal woanders stand, das hier ist der aktuelle). Enthält bewusst **alles** im Ordner (HTML, Werkbeschreibungen, Audio-Rohdateien, Test-HTMLs) — `.gitignore` deckt inzwischen `tools/recordings/` (rohe/finale S.A.M.-Audiodateien, siehe Abschnitt 5) und dieses Handover-Dokument selbst ab (siehe Hinweis ganz oben).

**Bei jeder inhaltlichen Änderung: committen + pushen.** Kein automatischer Zusammenhang mit dem FTP-Deployment — beides sind getrennte, gleichwertige Schritte.

**FTP-Deployment:** Ziel `https://crazy-midi.de/global-random/` (netcup-Hosting, separat vom [privater Server]/[privates NAS-System]-Server der Nextcloud-Projekte).
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
| `global-random.html` | **Hauptdatei**, live als `index.html`. Enthält die komplette W:E-Intro-Sequenz inkl. eigenem Schneefall-Effekt (siehe Abschnitt 6), das volle Jingle/Opener/Easteregg-System (Abschnitt 5), generalisiertes Länder-Namen-i18n (`COUNTRY_NAME_DICTS`, aktuell DE+AR statisch hinterlegt, alle anderen Sprachen live via MyMemory). |
| `beschreibung.html` / `description.html` | Werkbeschreibungen DE/EN, komplett synchron. „Bedienung"-Abschnitt beschreibt jetzt den echten Ablauf inkl. W:E-Intro/SKIP-INTRO (vorher veraltet). |
| `mymemory-email-draft.txt` | Entwurf für Rate-Limit-Anfrage an MyMemory (`mymemory@translated.net`, IP `89.186.135.154`) — **noch nicht verschickt** |
| `tools/global-random-jingle-batch.sh` | MIDI/VICE-Automationsskript (SendMIDI → loopMIDI → MidiKey2Key), tippt S.A.M.-Phonembefehle in einen C64-Emulator, nimmt automatisiert auf, normalisiert/trimmt via ffmpeg, kodiert zu MP3. 27-Einträge-Katalog (Opener/System/Punchline/Easteregg-Präfixe). |
| `tools/global-random-jingles.bas` | Native C64-BASIC-Variante desselben Skripts, für echte Hardware. |
| `tools/recordings/` | 27 finale S.A.M.-Aufnahmen (roh + final, WAV+MP3) — **git-ignored**, nie ins Repo, nur base64-eingebettet in `global-random.html` selbst. |
| `Country Name Batch Translator (Test Tool).html` (lokal umbenannt, liegt live weiterhin unter `.../global-random/test.html`) | Standalone-Tool, übersetzt alle 247 Ländernamen in eine Zielsprache via MyMemory (manuell über VPN laufen lassen, um die Quota des Dev-Rechners zu umgehen). Ergebnis dient als Vorlage für einen neuen `COUNTRY_XX`-Eintrag in `COUNTRY_NAME_DICTS`. |
| `W-E Snow-Phrase Comparison (Test Tool).html` (lokal umbenannt, liegt live weiterhin unter `.../global-random/test2.html`) | Standalone-Tool, vergleicht mehrere Kandidaten-Phrasen (z.B. „Radio Welle Erdball" vs. „Radio Station Erdball") über alle 86 Snow-Zielsprachen, zur Auswahl der besten Quellphrase für den W:E-Intro-Schneefall. |
| `mb-country-test-all-iso.html`, `mb-offset-ceiling-test.html`, `wiki-bio-country-test.html`, `redirection.html` | Alte Test-Tools, Stand ggf. nicht mehr synchron mit aktuellem Hauptcode |
| `fm-radio-tuning-sweeps.flac` | Audio-Rohmaterial |

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
7. **Jingle-Intervall:** alle 10-20 echte Minuten (Vollversion) bzw. 20-30 Minuten (Preview-only), randomisiert und pro Auftreten neu gewürfelt (`_rollNextJingleDelay()`)

**Vier Flaggen-Matrizen**, jede mit eigenem Zähler-Badge (`.flag-counter`):
1. `#flag-bar` — "noch nicht gefunden", wird bei jedem Aufruf komplett neu gebaut
2. `#found-bar` ("IM POOL") — live synchronisiert (`_syncLiveBar()`), zählt **distinkte Länder** (nicht Kandidaten-Anzahl), Füllstandsbalken zeigt echte Poolbelegung (`_updatePoolFillBars()`)
3. `#queue-bar` ("IN QUEUE") — **seit dieser Session slot-basiert, nicht mehr länder-dedupliziert**: eigene Sync-Funktion `_syncQueueBar()` (mirrort `_syncPreviewSlots()`s Muster), ein Flaggen-Chip pro stabilem Queue-`.slot` (0/1/2), nicht mehr ein Chip pro distinktem Land. Grund: der alte `_syncLiveBar()`-Ansatz (Set aus Ländercodes) ließ mehrere Unbekannt-Land-Funde in der Queue zu EINEM `??`-Chip kollabieren — Zähler zeigte z.B. "1/3" obwohl echt 3 Songs drin waren. Zähler-Badge zählt jetzt buchstäblich befüllte Slots.
4. `#played-bar` ("GESPIELT") — append-only, zählt ebenfalls distinkte Länder, echte Poolbelegung im Füllbalken

**Player-Architektur:** 1 aktiver Player (`EC`) + 3 gedimmte Vorschau-Slots (`ECPreview1/2/3`), die live `queue[0..2]` spiegeln (nur `.loadUri()`, nie `.play()`). **Wichtiges Muster für JEDEN künftigen `IFrameAPI.createController()`-Aufruf:** immer stabiler äußerer Wrapper + disposable innerer Mount-Punkt (Spotifys SDK mutiert/ersetzt das übergebene Element) — z.B. `#embed-wrapper`/`.embed-frame`. Direktes Element mit einer später noch gebrauchten ID hat schon mal einen kompletten PLAY-Crash verursacht.

**#track-info/#embed-wrapper — fixe Höhe, aber Deko konditional:** Beide reservieren immer ihren vollen Platz (kein `display:none`-Toggle — das würde den "nie springt was"-Anspruch wieder aufreißen). `#track-info`s Rahmenlinie ist stattdessen über die Klasse `.track-info-empty` (border-left transparent) an echten Inhalt gekoppelt; `#embed-wrapper` braucht das nicht, seine Basis-CSS hat ohnehin keinen Rahmen/Hintergrund ohne `.empty`-Klasse.

**Re-Entrancy-Schutz:** `_transitioning` (Modul-weites Flag) hält von Pick-Start bis `EC.play()` tatsächlich aufgelöst — Defense-in-Depth in `playReady()`/`mobileFirstPlay()`, falls ein künftiger Aufrufer die bestehenden Schutzmechanismen (disabled PLAY-Button, `currentId`-Check bei jedem automatischen Retrigger) vergisst. Ergänzt um `_checkQueueConsistency()`, die im 10s-Heartbeat `queue.length` gegen echte Preview-Slots/Queue-Bar-Chips gegenprüft und bei Abweichung `console.warn`t (rein diagnostisch).

**Sound-Design:**
- Radio-Tune (94,8s) läuft während der Suchphase, läuft jetzt bewusst auch durch den PLAY-Klick hindurch bis 3s nach bestätigtem Start des ersten Titels (Crossfade-artiger Übergang, kein Hard-Cut)
- Würfelbecher-Sound (`playDiceSound()`), synthetisiert über Web Audio API, mit echter zufälliger Dauer, Dice-Roll-Animation über die Preview-Slots synchron dazu
- Volles Jingle/Opener/Easteregg-Rotationssystem plus S.A.M.-Sprachsamples (siehe Abschnitt 5)

---

## 5. S.A.M.-Sprachsamples & Jingle-System (echte C64-Hardware-Aufnahmen)

Massiv erweitert diese Session, von 2 Einzelsamples zu einem vollen Rotationssystem. Aufgenommen über eine MIDI-Automationskette (SendMIDI → loopMIDI → MidiKey2Key tippt Phonem-Befehle in VICE), siehe `tools/global-random-jingle-batch.sh`. Alle Aufnahmen als MP3 base64-eingebettet, Roh-/Finaldateien liegen in `tools/recordings/` (git-ignored, nicht im Repo).

- **System-Samples** (feste Trigger-Punkte): `SAM_B64` ("PRESS PLAY ON SCREEN", regulärer erster Button-Reveal), `SAM_WE_CAN_START_B64` ("Wir können wieder starten!", einmalig beim allerersten PLAY-Klick), `SAM_WELCOME_B64` ("Welcome Listener"), `SAM_STANDBY_B64` ("I am searching, please stand by").
- **`SAM_JINGLES_B64`** — 18 Einträge, jeder `{b64, noOpener}`. Index 0 ist die feste Sign-on-Jingle ("give your faith a chance"), läuft immer direkt vor dem W:E-Intro. Rest ist der Zufalls-Pool für die periodische Sender-ID (siehe Jingle-Intervall, Abschnitt 4). `noOpener:true` markiert Punchlines, die als Fortsetzungssatz geschrieben sind und keinen "Radio Global Random"-Opener davor vertragen.
- **`SAM_OPENERS_B64`** — 2 Einträge, wird vor einer Jingle vorangestellt (außer bei `noOpener`).
- **`SAM_EASTEREGGS_B64`** — 3 Einträge, seltene Extra-Ansagen (`EASTEREGG_CHANCE=0.05`), nicht Teil der normalen Jingle-Rotation.
- Ein gemeinsamer `masterGain`-Knoten (`MASTER_VOLUME=0.5`) für alle Web-Audio-Wiedergabe.
- **Neu zufügen:** Einfach ein weiteres `{b64:'...', noOpener:false}` (bzw. reiner base64-String bei Opener/Easteregg) ans jeweilige Array anhängen, keine sonstigen Codeänderungen nötig.

---

## 6. Welle:Erdball-Intro (in der Hauptdatei, Desktop + Mobile)

Auf dem ersten PLAY-Klick der Session (beide Plattformen) spielt zunächst der W:E-Song "Welle Erdball (C=64)" in der MAIN-Player-UI, mit eigenem Footer-Banner (Logo + "Hallo, hier spricht Welle:Erdball" + zeitgesteuertem Lyrics-Ticker), SKIP-INTRO-Button, und Radiotune-Crossfade-Übergang. Danach normale Discovery-Wiedergabe wie gewohnt.

**Bewusst nicht mit übernommen** (aus dem inzwischen gelöschten privaten Prototyp, aus dem diese Sequenz ursprünglich stammt): Splash-Screen-Logo (bleibt "LEAVE THE MATRIX") und Header-Logo oben links (bleibt "GLOBAL RANDOM"-Text).

**Mobile-Support:** Mobile Browser verlangen `EC.play()` synchron im Gesten-Tick — Desktop nutzt eine async Sleep/Retry-Kette, die das auf Mobile zerstören würde. `_playWEIntro()` verzweigt nur an der eigentlichen Play-Auslöse-Stelle (`if(isMobile){...synchron...}else{...async...}`), der Rest ist gemeinsamer Code. **Auf echtem Gerät getestet und bestätigt funktionierend** (diese Session erneut verifiziert, inkl. dem `_startMobileMusic()`-Fix unten).

**`_startMobileMusic()`-Gesten-Fix (diese Session):** War die Queue beim ersten Mobile-Klick nach dem Intro noch leer, pollte der alte Code per `setInterval` und rief `mobileFirstPlay()` (mit seinem `EC.play()`) **aus dem Timer-Callback** auf — außerhalb des ursprünglichen Klick-Gestus. iOS Safari & Co. werten das nicht mehr zuverlässig als frischen User-Gesture, `EC.play()` kann still blockiert werden. Fix: Polling setzt nur noch einen frischen PLAY-Button wieder aktiv, sobald die Queue bereit ist — der nächste echte Tap trägt seinen eigenen gültigen Gestus.

**Schneefall-Effekt für den Intro (diese Session neu):** Der normale Schnee (`translateAll()`) läuft nur für echte MusicBrainz-Tracks — der Intro ist hardcodiert, hat kein `allWords`. Stattdessen `WE_INTRO_SNOW_WORDS`: eine statische Tabelle über 83 Sprachen (kein Live-API-Call, kein Quota-Risiko für diesen einmaligen Fixed-Content). Mehrere Iterationen der Quellphrase nötig (getestet via `test2.html`, siehe Abschnitt 3): "Welle Erdball" driftet in Französisch/Spanisch zur Meereswelle ab, "Frequenz Erdball" driftet in mehreren Sprachen zur "Häufigkeit"-Bedeutung ab. Gelandet bei **"Station Erdball"** — trifft inhaltlich sogar besser, was Welle:Erdball als Bandname bedeutet (Sender-Identität, nicht nur Physik). Abgefragt als "Radio Station Erdball" für saubere Kontextauflösung, "Radio"-Wort danach pro Sprache manuell rausgestrichen. `ha` (Hausa, liefert bei jeder getesteten Phrase Datenmüll) und `dz` (Dzongkha, nie eine verifizierbare vollständige Übersetzung) ausgeschlossen; `rw` (Kinyarwanda) ebenfalls ausgeschlossen nach wiederholt unzuverlässigen Ergebnissen. **Lektion:** der deutsche Quell-Eintrag im Array muss der ECHTE Bandname sein (`Welle:Erdball`), nicht die Fetch-Suchphrase — genau das war anfangs vertauscht.

**Cleanup bei SKIP INTRO mit noch leerer Queue (diese Session gefixt):** `finish()`s Empty-Queue-Fallback rief `playReady()` nicht auf (nichts zu spielen), wodurch dessen eingebautes Aufräumen (Banner/Karten/Player leeren) nie lief — W:E-Banner, Info-Karten und Player blieben eingefroren sichtbar, während die App im Hintergrund weitersuchte. Jetzt räumt der Fallback-Zweig selbst auf (`_showWEBanner(false)`, `_hideAllInfoCards()`, `track-info-empty`-Klasse, `t-title` etc. leeren).

**Lyrics-Ticker — Lektion fürs nächste Mal:** Nach mehreren Timing-Iterationen (Endlos-Loop → CSS-Delay → Song-Position-Sync → fixer Klick-Timer) stellte sich heraus, dass der eigentliche Bug **nicht** die Zeit-Logik war, sondern die Animations-**Geometrie**: `translateX(±100%)` bezog sich auf die Track-eigene Breite statt die viel schmalere Container-Breite, wodurch der Text ~23 von 31 Animationssekunden unsichtbar im Leerlauf verbrachte. Fix: `_showLyricsTicker()` misst beide Breiten per `getBoundingClientRect()`/`scrollWidth` und setzt exakte Pixel-Werte über CSS Custom Properties. **Bei "Timing stimmt nicht"-Bugs künftig auch die Geometrie prüfen, nicht nur die Zeitberechnung** — zwei verschiedene Zeit-Mechanismen zeigten hier denselben Versatz, was der Hinweis war, dass der Fehler woanders lag. Ticker überspringt sich zudem komplett im Spotify-Preview-Modus (`dur<=31000`), da er sonst mitten im Scrollen abgebrochen würde.

---

## 7. TRANSLATE/SPOTIFY-Statusanzeige

`#translate-status` im Footer (neben `#login-status`) zeigt **dauerhaft** den aktuellen Zustand (`TRANSLATE: ON`/`OFF`, grün/rot) — nicht nur bei Zustandswechsel wie die frühere Terminal-Meldung. Eine analoge Spotify-Variante wurde gebaut und wieder verworfen, weil `#login-status` (zeigt "✓ logged in"/"preview only") dieselbe Information bereits abdeckt. `detectLoginStatus()` läuft bei **jedem** Titelwechsel erneut (nicht nur beim ersten) — ein nachträglicher Spotify-Login mitten in der Session wird automatisch beim nächsten Titel erkannt, kein Neuladen nötig.

**`_previewConfirmed`-Bug gefunden & gefixt (diese Session):** Das Flag latchte dauerhaft `true`, sobald IRGENDEIN Track `dur<=31000` meldete — aber eine kurze Dauer beweist nicht "nicht eingeloggt" (kann auch bei vollem Login einfach ein echter kurzer Song/Interlude im Pool sein, oder sogar nur eine transiente Ladephase-Meldung vor der echten Trackdauer). Einmal gesetzt, wurde es **nie zurückgesetzt** — eine echte, eingeloggte Session mit einem einzigen kurzen Track früh in der Session verlor dauerhaft Artist-/Country-Karte (`skipMetaLookups` in `_renderPlayingMeta()`) UND den mehrsprachigen Schnee (`isMobile||_previewConfirmed`-Guard in `translateAll()`), obwohl "✓ logged in" die ganze Zeit korrekt dastand. Fix: der `dur>60000`-Zweig (der einzige Ort, der den früheren Fehlalarm beweisbar widerlegen kann) setzt `_previewConfirmed=false` zurück.

---

## 8. Offene Punkte

- **MyMemory-Rate-Limit-Anfrage** — Entwurf fertig (`mymemory-email-draft.txt`), noch nicht verschickt.
- **Lyrics-Karte** — weiterhin nur "Songtext ansehen ↗"-Link, keine echte Wiki-Fetch-Karte (Genre-Karte hat das schon länger).
- **Wiki/Wetter-Panel DE/EN-Sprachumschaltung** — **teilweise adressiert**: Länder-Namen sind jetzt generalisiert über `COUNTRY_NAME_DICTS` (Registry statt hartcodiertem DE/EN-Vergleich), aktuell nur DE+AR statisch befüllt. Weitere Sprachen: `Country Name Batch Translator`-Tool (Abschnitt 3) nutzen, Ergebnis hand-prüfen (MyMemory liefert bei manchen Sprachen Datenmüll oder Lücken), als neuen `COUNTRY_XX`-Eintrag ergänzen.
- **Zwei Playback-Modi (Info- vs. Discovery-Modus)** — weiterhin offen.
- **AdGuard/DoH als möglicher MyMemory-Störfaktor** — nie isoliert verifiziert.
- **Mobile getestet, unauffällig** (diese Session, echtes Gerät) — der alte offene Punkt zur iPhone-Kompatibilität kann als erledigt gelten, auch wenn nicht jeder Edge-Case explizit durchgegangen wurde.
- **isMobile-Schwelle (600px) vs. CSS-Mobile-Breakpoint (899px) inkonsistent** — `const isMobile=('ontouchstart'in window)||window.innerWidth<600` in JS, aber `@media (max-width:899px)` versteckt Preview-Stack/Info-Karten/Schnee per CSS. Für Viewports zwischen 600-899px (z.B. Handy im Querformat) denkt JS "Desktop" (voller 86-Sprachen-Batch, Preview-Iframes, alle Karten-Lookups), CSS versteckt trotzdem alles — verschwendete Arbeit, kein Darstellungsfehler, aber unnötiger Netzwerk-/API-Verbrauch in diesem Bereich.
- **Preview-Iframes laden immer, auch auf echtem Mobile** — `_syncPreviewSlots()` lädt/befüllt alle 3 Preview-Slots unabhängig von `isMobile`, obwohl CSS sie unter 899px komplett versteckt. Unnötiger Datenverbrauch auf dem Handy für etwas, das nie sichtbar wird.

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
- **Reale DOM-Messung statt Zeichenanzahl-Heuristik** — der Titel-Shrink-to-fit (`.pl-word-long`/`.pl-word-xlong`) nutzte lange einen `_titleLen>25/45`-Schwellwert als Proxy für "passt das rein" — hat aber keine Ahnung, wie viel Platz ein Flex-Sibling (`.pl-trans`) tatsächlich übrig lässt. Kurze Titel wie "Shades Of Gray" (14 Zeichen) blieben unter der Schwelle und liefen trotzdem in Ellipsis. Fix: echter `scrollWidth>clientWidth`-Check statt Schätzung — bei ähnlichen "sieht länger/kürzer aus als es ist"-Problemen künftig zuerst prüfen, ob eine Heuristik anstelle einer echten Messung verwendet wird.
- **Flags, die nur in eine Richtung kippen, brauchen einen Weg zurück** — `_previewConfirmed` (Abschnitt 7) und der fehlende Rahmen-Reset bei `#track-info` waren beides Fälle von "einmal gesetzt, nie wieder geprüft". Bei jedem neuen Session-weiten Boolean-Flag: gibt es ein Ereignis, das den ursprünglichen Verdacht beweisbar widerlegen kann — und passiert an GENAU dieser Stelle auch das Zurücksetzen?
- **Container-Größe reservieren, nur Deko konditional machen** — `display:none`/`''`-Toggles auf einem Element mit fester Höhe reißen den eigentlichen Sinn der festen Höhe ("nie springt was") wieder auf. Wenn nur eine Rahmenlinie/ein Platzhalter-Look das eigentliche Problem ist, eine Klasse für GENAU das umschalten, nicht den ganzen Container.
- **Mobile: `setInterval`/`setTimeout` zwischen Klick und `EC.play()` kann den Gesten-Kontext kosten** — iOS Safari & Co. werten User-Activation oft nicht über eine Timer-Grenze hinweg als gültig. Jeder Code-Pfad, der auf einen späteren Zeitpunkt wartet, bevor er `EC.play()` aufruft, sollte stattdessen einen frischen, expliziten Button/Tap abwarten statt automatisch loszulegen.
- **MyMemory-Übersetzungen von Hand gegenprüfen, nicht blind übernehmen** — bei Batch-Übersetzungen über viele Sprachen (Länder-Namen, W:E-Intro-Schnee) kamen wiederholt Datenmüll (`ha`/Hausa: wiederholte kyrillische Zeichen, unabhängig vom Input), unvollständige/falsche Treffer (Filipino driftete bei "Wellenlänge" zur Sturmwelle ab; Kinyarwanda lieferte einmal einen kalifornischen Ortsnamen statt einer Übersetzung) und reine Lauttranskriptionen statt echter Übersetzung vor. Bei sprachübergreifenden Batches immer stichprobenartig mit eigenem Sprachwissen gegenchecken, nicht nur "kam ein Text zurück, also passt's" werten.

---

*Ende Handover.*
