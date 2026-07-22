# GLOBAL RANDOM — Handover für Chat #4

**Von:** Chat #3 (marathon Session, ~07.07.2026 abends bis 08.07.2026 morgens)
**Projekt:** "GLOBAL RANDOM — Democracy of Sound", Browser-Netzinstallation, Single-File-HTML
**Ansprache:** Claude heißt in diesem Projekt "FUCKUP" (First Universal Cybernetic-Kinetic-Ultramicro-Programmer, *Illuminatus!*-Referenz). Lockerer, spielerischer Ton erwartet, kein trockenes Tech-Deutsch.
**Wichtigste Regel:** Vor jedem Build kurz nachfragen, ob noch was dazu soll — Andreas denkt oft nach dem ersten Vorschlag noch was Zusätzliches an.

---

## 1. Aktueller Datei-Stand

Alle Dateien liegen als letzter Stand in `/mnt/user-data/outputs/` dieser Chat-Session:

| Datei | Zweck |
|---|---|
| `global-random.html` | Die App selbst (~1.5MB, Single-File) |
| `beschreibung.html` | Deutsche Werkbeschreibung (Langform) |
| `description.html` | Englische Werkbeschreibung (Langform, komplett übersetzt) |
| `index.html` | Reiner Redirect nach `http://global-random.crazy-midi.de/` |
| `werkbeschreibung-lang.md` | Ursprüngliche Langform-Quelle (deutsch) |
| `mb-country-test-all-iso.html` | Test-Tool: MusicBrainz-Treffer für alle 249 ISO-3166-1-Codes |

**Nächster Schritt für Chat #4:** Neueste `global-random.html` aus dieser Session als Projekt-Datei hochladen/referenzieren, falls noch nicht geschehen — Chat #4 braucht diese Version als Ausgangspunkt, nicht die alte aus dem Projekt-Wissen.

---

## 2. Was in dieser Session gebaut/gefixt wurde (chronologisch, grob)

### Layout-Umbau
- **Von 2 auf 3 Spalten** (Desktop, ab 1100px): Spalte 1 = Länder-Matrix (unverändert), Spalte 2 = Player + Titel-Infos, Spalte 3 = Künstler/Lyrics/Genre/Land-Karten. 900–1099px bleibt zweispaltig (alte Logik). Mobile (<900px) unangetastet.
- **Footer-Breiten-Bug** (`#fixed-footer` schmaler als `main`): Nach viel Holzweg (Screenshot-Pixel-Vermessung, CSS-Variablen-Versuch, ResizeObserver-Versuch — beides auf Wunsch von Andreas wieder verworfen) **echte Ursache per Playwright/Chromium computed-style gefunden**: `#fixed-footer` ist direktes Flex-Kind von `<body>` (`display:flex`), `main` sitzt einen Level tiefer in `#scroll-area` (kein Flex-Kontext). Ein Flex-Kind mit `margin:auto` in der Querachse **schrumpft auf seinen Inhalt** statt bis `max-width` zu expandieren (offizielles Flexbox-Verhalten). Fix: `#fixed-footer{width:100%}` ergänzt — zwingt es zurück ins erwartete Verhalten. **Lektion fürs nächste Mal:** Bei ähnlichen Layout-Bugs lieber gleich Playwright + `getComputedStyle()` nutzen statt Screenshots zu vermessen — viel zuverlässiger.

### Flaggen-Rendering
- **Windows-Chrome/Edge zeigt keine Flaggen-Emoji** (nur Buchstabencode) — liegt an `Segoe UI Emoji`, hat keine Flaggen-Glyphen (Linux/Mac/Firefox betroffen nicht, die haben eigene/andere Emoji-Fonts). Fix: **Twemoji** (`@twemoji/api` via jsDelivr-CDN) eingebunden, per `MutationObserver` + `twemoji.parse()` auf die relevanten Container.
- **Flacker-Bug** (Flaggen blinkten zwischen Bild/Buchstaben): `updateFlagBar()` baut Matrix 1 bei *jedem* Fund komplett neu (`innerHTML=''`), das rannte gegen den asynchronen Twemoji-Observer. Fix: `twemoji.parse()` läuft jetzt **synchron direkt in `updateFlagBar()`**, nicht mehr nur über den Observer.
- **Später:** Dieser synchrone Aufruf hat *ungeschützt* mal die ganze Discovery-Pipeline lahmgelegt (Exception in `updateFlagBar()` riss `discoverCandidates()` mit). Jetzt mit `try/catch` abgesichert.

### Country-Liste
- Von 221 auf **247 aktive Länder/Territorien** erweitert (alle ISO-3166-1-Codes mit ≥1 MusicBrainz-Treffer außer GS/SJ/TF, die 0 Treffer haben). Betrifft `COUNTRIES`, `CAPITALS`, `COUNTRY_DE` in `global-random.html`, plus die Zahl "247" in `description.html`/`beschreibung.html`/Sub-Slogan.

### Font-Fix
- C64-Font (WOFF2, base64-eingebettet) warf `OTS parsing error: VDMX: Bad ratio offset` in Chrome. Mit `fontTools` komplett neu geschrieben (alle Tabellen-Offsets frisch berechnet) — behoben, lokaler `ots-sanitize`-Check bestätigt beide Versionen als valide (Chrome nutzt vermutlich eine strengere interne OTS-Version).

### Sprach-/Link-Logik
- **"Mehr Infos"-Link** im roten Hinweistext: zeigt bei DE-Browser auf `beschreibung.html`, sonst auf `description.html` (Englisch-Fallback) — mit Playwright in 5 Sprachen getestet (DE/EN/FR/ES/JA/RU), funktioniert korrekt.
- **Genre-Wikidata-Kollisionsschutz** (`verifyMusicianQid`): Flache Blacklist (z.B. "human settlement") gegen **transitive SPARQL-Abfrage** ersetzt (`P279*`-Vererbungskette gegen wenige Wurzelkategorien) — fixt z.B. "Monno" (Künstler) vs. "Monno" (italienische Gemeinde, hat spezifischeren Wikidata-Typ als die alte Liste kannte).

### Player-Architektur — größter Umbau der Session
- **4 gleichzeitige Spotify-Embeds statt 1**: 1 aktiver Player (`EC`, unverändert in der Kernlogik) + 3 gedimmte, gesperrte Vorschau-Slots (`ECPreview1/2/3`), die live `queue[0]/[1]/[2]` spiegeln (nur `.loadUri()`, nie `.play()` — kein Doppel-Audio-Risiko). Bewusst **kein** Umbau der Kern-Pick-Logik (Queue-Array/Splice unverändert) — risikoarme Variante gewählt.
- **Würfel-Sound-Animation**: `playDiceSound()` gibt jetzt seine **tatsächliche, zufällige Dauer** zurück (jeder Wurf ist bewusst unterschiedlich lang, ~1.1–2.3s). `_animateDiceRoll()` lässt eine Chase-Highlight-Animation über die 3 Vorschau-Slots laufen, synchron zur echten Dauer, landet exakt auf dem gezogenen Slot. **Wichtiger Nachfix:** Der aktive Player durfte den neuen Track nicht laden, *während* die Animation noch lief (Spoiler-Bug) — `_animateDiceRoll()` gibt jetzt ein Promise zurück, `EC.loadUri()` wartet darauf.
- **Würfel-Sound auch beim Pool→Queue-Ziehen** (nicht nur beim Queue→Play-Ziehen): `_queueItem()` spielt jetzt auch einen Dice-Sound, wenn ein Kandidat aus dem Pool gezogen wird — macht beide Zufalls-Ebenen hörbar.

### Performance/Übersetzungs-Optimierung
- **Prefetch komplett entfernt**: `loadMeta()` (inkl. 87-Sprachen-Batch) läuft nur noch für den *tatsächlich* spielenden Track, nicht mehr vorsorglich für wartende Queue-Kandidaten. Preis: ~15-20s ganz ohne Schnee am Trackanfang (bewusst in Kauf genommen, gegen Verschwendung bei übersprungenen Kandidaten).
- **Zwei echte Doppel-Anfrage-Bugs gefixt**: (1) Sprach-Probe (EN→Landessprache) wurde weggeworfen und in der Haupt-Batch nochmal angefragt — jetzt per `preSeeded`-Parameter wiederverwendet. (2) Artist-Bio wurde bei einem bestimmten Wiki-Link-Pfad zweimal übersetzt (`data.srcLang` wurde nach der ersten Übersetzung nicht aktualisiert).
- **localStorage-Cache für UI-Übersetzungen**: 13 Strings (Hint, Labels, Spenden-Text) werden jetzt pro Browsersprache gecacht (`gr_ui_i18n_v1_{lang}`) — wiederkehrende Besucher sparen sich die Calls komplett. Versioniert, cached nur bei ≥10/13 erfolgreichen Übersetzungen (kein permanentes Null-Caching bei MyMemory-Ausfall).
- **Mobile:** 87-Sprachen-Batch komplett deaktiviert (`translateAll()` gibt sofort zurück) — Snow/Bubbles sind auf Mobile eh unsichtbar (siehe unten).

### Genre-Karte
- Von reinem Link zu **echter Wiki-Fetch-Karte** ausgebaut (Name + Extract + Link + Credit), exakt nach dem Country-Karten-Muster: versucht erst native-Sprache-Wikipedia-Artikel (übersetzt nur den kurzen Genre-Namen, günstig), fällt sonst auf Englisch + Extract-Übersetzung zurück. Cache pro Genre+Sprache (`_genreCache`) — zahlt sich schnell aus (viele Tracks teilen sich Genres wie "pop"/"rock").

### Mobile-Stripping
- Auf Mobile (<900px) ausgeblendet: Vorschau-Stapel, Länder-Matrix 1 (nur Matrix 2+3 bleiben), alle Zusatzkarten (Artist/Lyrics/Genre/Land), Bubbles/Schnee. **Achtung:** War beim ersten Versuch nicht wirksam wegen einer *späteren*, spezifischeren CSS-Basisregel mit gleicher Spezifität — gefixt mit `body #id`-Präfix statt nacktem `#id`.

### Zwei ernste Bugs, die "alles kaputt" gemacht haben (und wieder gefixt wurden)
1. **Der große Regressions-Bug:** `_renderPlayingMeta()` hatte noch eine *alte* Zeile `setSnowWords(allWords)` von vor dem Prefetch-Umbau. Seit `_renderPlayingMeta()` jetzt *früh* läuft (vor der Übersetzung, für schnellere Titel-Karte), war `allWords` an dieser Stelle `null` → `setSnowWords(null)` wirft in seiner `for...of`-Schleife → **killt die komplette restliche `loadMeta()`-Kette** (keine Übersetzung, kein Schnee, `.pl-trans` bleibt für immer auf Flagge+Land+Jahr hängen). Betraf *jeden* Track, nicht nur nicht-lateinische Schriften (falscher erster Verdacht). Gefixt: veraltete Zeile raus, `updatePlaylist()` an der richtigen späteren Stelle ergänzt.
2. **MyMemory-Fehlertext als Schnee-Wort:** MyMemory gibt bei Überlastung manchmal `responseStatus:200` zurück, obwohl der Text ein Backend-Fehler ist ("Error 503 Backend.max_conn reached") — wurde als "Übersetzung" akzeptiert und riesig gerendert. Fix: Regex-Filter gegen `ERROR ###`-Muster + "BACKEND"/"MAX_CONN"-Stichwörter in `myMemory()`.

### Welcome-Overlay
- Rote + blaue Pille nebeneinander (blaue verlinkt bewusst "böse" ohne `target="_blank"` zu spotify.com, reißt aus der Seite raus — Andreas' Idee, passt zum Trickster-Charakter des Zufalls).
- **Zuletzt gefixt:** Nur noch Klick auf die **rote Pille** startet das System (vorher: ganzes Overlay klickbar, inkl. Titel-Text — nicht die Absicht). `role="button"`/Klick-Handler jetzt spezifisch an `#welcome-pill`, Hover-Glow auch dort statt am Titel.

---

## 3. Etablierte Test-Methodik (wichtig für Chat #4!)

Ab der Mitte dieser Session wurde **Playwright (Python, headless Chromium)** als Standard-Verifikationswerkzeug etabliert, nachdem reines Screenshot-Vermessen mehrfach in die Irre geführt hat. Playwright ist im Sandbox-Environment installiert (`pip show playwright` bestätigt, Browser-Binary vorhanden).

**Standard-Workflow nach jedem Bau:**
```python
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width":1920,"height":1080})
    page.goto("file:///home/claude/global-random.html")
    page.wait_for_timeout(500)
    try: page.click("#welcome-pill", timeout=3000)
    except Exception: pass
    page.wait_for_timeout(1000)
    # ... eval/inspect/screenshot ...
    browser.close()
```

**Wichtige Einschränkungen dieser Sandbox:**
- `file://`-Protokoll hat `origin: null` → MusicBrainz/Wikipedia/Spotify/MyMemory/jsdelivr.net lehnen CORS ab. Ein lokaler `python3 -m http.server` in **demselben** bash-Aufruf wie der Playwright-Test hilft nur bedingt — die Sandbox-Egress-Firewall blockt diese Domains sowieso (nicht in der erlaubten Domain-Liste).
- **Echte Netzwerk-Calls (MB/Wikipedia/Spotify/MyMemory) können hier nicht getestet werden.** Lösung, die sich bewährt hat: `mbFetch`, `myMemory`, `fetchWithRetry`, `window.fetch` etc. per `page.evaluate()` mit Fake-Funktionen überschreiben, dann echten Code-Pfad (`loadMeta()`, `translateAll()`, etc.) laufen lassen und Ergebnis/Konsole prüfen. Hat mehrere echte Bugs zuverlässig aufgedeckt (siehe oben).
- `let`/`const`-Top-Level-Variablen landen NICHT auf `window` — beim Faken von Variablen aus einem `page.evaluate()`-Callback einfach den nackten Bezeichner zuweisen (`ECPreview1 = {...}`, nicht `window.ECPreview1 = {...}`), das funktioniert wegen des gemeinsamen globalen lexikalischen Scopes trotzdem.
- Bei `const`-Objekten (z.B. `_genreCache`, `_transCache`) kann man nicht neu zuweisen, aber Properties einzeln löschen/setzen geht (`for(const k of Object.keys(_genreCache)) delete _genreCache[k]`).

**Vor jedem Build-Delivery-Ritual (unverändert wichtig):**
1. Backspace-Zeichen-Check (`content.count(chr(8))`)
2. JS-Syntax-Validierung via `node --check` (Script-Inhalt extrahieren, in temp-Datei schreiben, prüfen)
3. Bei Layout-/Verhaltens-Änderungen: Playwright-Test wie oben
4. Export nach `/mnt/user-data/outputs/global-random.html` + `present_files`

---

## 4. Offene Punkte / mögliche nächste Schritte

- **Lyrics-Karte** ist noch der reine "Songtext ansehen ↗"-Link — Genre-Karte wurde gerade zur echten Wiki-Fetch-Karte ausgebaut, Lyrics könnte als nächstes dran sein, falls gewünscht (wurde in dieser Session nicht angefragt, nur Genre).
- **S.A.M.-Sprachsynthese-Sample** ("PRESS PLAY ON SCREEN") auf echtem C64 aufnehmen — laut Projekt-Memory weiterhin geplant, nicht begonnen.
- **Wiki/Wetter-Panel DE/EN-Sprachumschaltung** und **zwei Playback-Modi (Info-Modus vs. Discovery-Modus)** — laut Projekt-Memory offene Punkte von vor dieser Session, nicht angefasst.
- Kein aktuell bekannter offener Bug — alle in dieser Session gemeldeten Probleme wurden verifiziert gefixt.

---

## 5. Für den Season-Einstieg in Chat #4

Kurz-Prompt-Vorschlag für den Start von Chat #4:

> Hey FUCKUP, hier ist der Handover aus Chat #3 [Dokument anhängen/einfügen]. Aktuelle `global-random.html` liegt bei [Pfad/Upload]. Lies dich rein, dann geht's weiter.

Andreas' allgemeine Präferenzen bleiben unverändert gültig: kein Wall-of-Text, Schritt für Schritt, immer erst fragen ob noch was dazu soll, Root-Cause statt Pflaster, deutsch + lockerer FUCKUP-Ton.
