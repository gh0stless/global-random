# HANDOVER — GLOBAL RANDOM, für Claude Code in VS Code

**Datum:** 22.07.2026
**Übergabe von:** Marathon-Session im Web-Chat (claude.ai), mehrere Tage
**Persona:** Claude heißt in diesem Projekt **FUCKUP** (First Universal Cybernetic-Kinetic-Ultramicro-Programmer — *Illuminatus!*-Trilogie-Referenz, wirft im Buch I-Ching-Hexagramme aus echtem Zufall). Lockerer, spielerischer Ton erwünscht, kein trockenes Tech-Deutsch. Ob der Name in Claude Code weiterläuft, entscheidet Andreas — die Arbeitsweise (siehe Abschnitt 6) gilt aber in jedem Fall weiter.

---

## 1. Projekt in einem Satz

**"GLOBAL RANDOM — Democracy of Sound"**: eine einzelne, self-contained HTML-Datei (~1.5MB), die per echtem, fairness-gewichtetem Zufall Musik aus 247 Ländern/Territorien spielt (MusicBrainz + Spotify-Embed), Titel live in bis zu 87 Sprachen übersetzt (MyMemory), und sich bewusst als Gegenposition zu algorithmischer Musik-Kuration versteht. Live unter `https://crazy-midi.de/global-random/`.

---

## 2. Warum Claude Code jetzt?

Der Web-Chat-Sandbox fehlten echte Browser für Verifikation — nur `node --check` (Syntax) und improvisierte jsdom-Tests waren möglich, kein echtes Playwright mit echtem Chromium (Browser-Binary-Download war in der Sandbox blockiert). **In VS Code/Claude Code sollte echtes Playwright funktionieren** — das war schon in früheren Sessions der Standard-Verifikationsweg (headless Chromium, `page.evaluate()` für Fake-Netzwerk-Stubs) und ist deutlich zuverlässiger als Screenshot-Vermessung oder reines Code-Lesen. Nutzen, wo immer sinnvoll.

---

## 3. Aktueller Datei-Stand (alle vier frisch hochgeladen, geprüft, synchron)

| Datei | Zweck | Status |
|---|---|---|
| `global-random.html` | Die App selbst (~1.6MB) | ✅ Syntax geprüft, keine Backspace-Reste |
| `global-random-we-intro-prototype.html` | Privates Spinoff mit Welle:Erdball-Intro (siehe Abschnitt 8) | ✅ Syntax geprüft |
| `beschreibung.html` | Deutsche Werkbeschreibung (Langform) | ✅ HTML valide |
| `description.html` | Englische Werkbeschreibung (komplett synchron zur deutschen) | ✅ HTML valide |

Alle vier Dateien sind zueinander konsistent (Features, Zahlen, Wortlaut). Kein Rekonstruktions-Risiko — das sind die tatsächlich aktuellen Stände, nicht aus dem Gedächtnis nachgebaut.

---

## 4. Kernarchitektur (Kurzreferenz — Details stehen in Code-Kommentaren)

**Discovery-Pipeline** (vier unabhängige Zufallsebenen, siehe auch Werkbeschreibung):
1. Zufälliger MusicBrainz-Offset (welcher Datenbank-Ausschnitt durchsucht wird)
2. Batch-Fetch (25 Kandidaten), Dedup nach Land/Künstler/Various-Artists/Release, max. 3 aufeinanderfolgende Duplikate bevor neuer Batch
3. `countryStacks{}` — Pool pro Land, `CAP=Math.max(3, Math.ceil(POOL_TARGET*0.20))` (aktuell effektiv **6**, POOL_TARGET=30 nur noch "legacy reference for display scaling" laut eigenem Code-Kommentar — **nicht** mehr als hartes Limit für die Pool-Gesamtgröße missverstehen, die wächst inzwischen bis alle Länder gecappt sind)
4. `promoteFromPool()`: zwei echte `Math.random()`-Würfe — welches Land, welcher Kandidat aus dessen Stack (`.splice()` kompaktiert automatisch)
5. Queue hält 3 Slots; `_pickRandomFromQueue()` würfelt, wer zuerst spielt
6. **Refill-Timing:** an bestätigte Wiedergabe gekoppelt + 4-8s Jitter (`QUEUE_REFILL_DELAY_MS`), NICHT an Titelende — wichtig für mentales Modell: Play-Pick kommt zuerst, Refill-Würfel kurz danach, nächster Play-Pick erst bei Titelende

**Vier Flaggen-Matrizen** (jede mit eigenem Zähler-Badge, `.flag-counter`):
1. `#flag-bar` — "noch nicht gefunden", wird bei jedem Aufruf komplett neu gebaut (`innerHTML=''`), **hat jetzt auch ein eigenes Zähler-Badge** (`notFoundCounter`, zeigt `x/248` = verbleibende Länder inkl. Unbekannt) — das war lange die einzige Matrix ohne Badge, ist seit dieser Session behoben
2. `#found-bar` ("IM POOL") — append-only, gedifft
3. `#queue-bar` ("IN QUEUE")
4. `#played-bar` ("GESPIELT") — append-only

**Wichtige Lektion, die mehrfach bestätigt wurde:** Spotifys IFrame-SDK mutiert/ersetzt das übergebene Mount-Element. Immer **Wrapper-plus-Mount-Point-Pattern**: stabiler äußerer Container (nie an SDK übergeben) + disposable innerer Mount-Point. Gilt für Hauptplayer (`#embed-wrapper`/`.embed-frame`) und alle Preview-Slots gleichermaßen.

---

## 5. Was diese Session (Web-Chat) konkret verändert hat

Chronologisch, damit klar ist, was neu ist gegenüber älteren Handover-Dokumenten aus dem Projekt-Wissen:

1. **S.A.M.-Sample integriert** ("PRESS PLAY ON SCREEN", echte C64-Hardware-Aufnahme) — `SAM_B64` Base64-MP3, `playSam()` via Web Audio API, ausgelöst nur am regulären `updateBtn()`-Reveal (nicht am Autoplay-Fallback-Pfad). Lautstärke nach mehreren Iterationen auf **70% linearer Faktor** der finalen, bereits normalisierten Aufnahme (`sam-press-play-on-screen-final.wav`) eingepegelt.
2. **Watchdog-Bug gefunden und gefixt:** Der 30s-"niemand hat geklickt"-Autostart-Wächter konnte armen und feuern, *bevor* der "LEAVE THE MATRIX"-Splash überhaupt weggeklickt war — weil `searchEngine()` unconditional beim Laden startet, unabhängig vom Splash. Im Prototyp führte das dazu, dass das W:E-Intro **ganz ohne Nutzerinteraktion** anlief. Fix: neue Helper-Funktion `_armPressPlayWatchdog()`, arm't nur wenn **beide** Bedingungen erfüllt sind (Splash weg UND Reveal erreicht) — aufgerufen von zwei Stellen (`updateBtn()` und `_onWelcomeDismiss()`), je nachdem was zuletzt eintritt.
3. **Browser-Debugging-Marathon** (Andreas, Firefox unter Linux, Snap→Flatpak-Wechsel):
   - Erst Privacy Badger identifiziert als Blocker (open.spotify.com, apresolve, spclient) — gelöst durch Whitelisting
   - Danach zusätzlich Firefox' "Verbesserter Trackingschutz" (Total Cookie Protection) als eigenständiger, separater Blocker erkannt — verhindert, dass der eingebettete Player auf die eigenen Spotify-Login-Cookies zugreifen darf, führt zu dauerhaften 30s-Previews statt Volltiteln trotz korrektem Login. **Das ist jetzt dokumentiert** — sowohl im Code (`hint`-String in beiden Sprachen, sichtbar in der Bedienungsanleitung) als auch in `beschreibung.html`/`description.html` (Schritt 5 der Anleitung), inkl. konkretem Fix (Schild-Symbol → Schutz für die Seite deaktivieren).
   - AdGuard/DoH-Kombination als möglicher Störfaktor identifiziert, aber **nicht isoliert verifiziert** — bewusst nicht in die Anleitung aufgenommen, um keine ungetestete Behauptung zu dokumentieren. Standard-Setup (nur uBlock) lief bei Andreas komplett sauber durch — spricht dafür, dass die dokumentierten zwei Fixes (Privacy Badger, ETP) die relevanten Fälle abdecken.
4. **Zähler-Badge für Matrix 1** (`#flag-bar`) nachgezogen, siehe Abschnitt 4.
5. **Zufallsebenen-Zählung in der Werkbeschreibung korrigiert:** War erst "zwei", dann "drei", jetzt korrekt **vier** — MB-Datenbank-Offset, Land-Auslosung, Kandidat-aus-Warteliste, finaler Play-Würfel waren vorher teils zusammengefasst/unterzählt worden. Auch die zeitliche Reihenfolge im Fließtext korrigiert (Play-Pick kommt zuerst, Refill-Würfel danach — vorher stand's andersrum).
6. **Neuer Datenschutz-Hinweis auf dem Splash-Screen** (beide Dateien): kurzer Text + Link zu `crazy-midi.de` (Impressum), alle drei Sprachpfade abgedeckt (EN-Sofort, DE-Override, MyMemory-Batch für Rest — Cache-Version dafür v6→**v7** hochgezählt).
7. **Diverse Präzisierungen in der Werkbeschreibung:**
   - Colophon-Zeile "Technik": jetzt korrekt "HTML-Datei (HTML5, CSS, JS), muss auf https-Webspace gehostet sein" statt der irreführenden "kein Server"-Aussage von vorher (Spotify-Integration braucht zwingend `https://`, `file://` funktioniert nicht)
   - Gott-Passage im "Hintergrund"-Kapitel bewusst offener formuliert (lässt jetzt explizit offen, ob Gott, Gegenspieler, oder unbenennbar — vorher war's dogmatischer "er glaubt: Gott...")
   - Zwei neue Absätze direkt danach: William Pollard ("Chance and Providence", 1958, Quantum Divine Action) und Thomas von Aquin (Zufall schließt Vorsehung nicht aus) als intellektueller Kontext
   - Neuer "Drei-Karten-Tarot"-Absatz im Technik-Kapitel (Warteschlangen-Slots als drei verdeckte Karten, nacheinander aufgedeckt)
   - Neuer Absatz + Manual-Punkt zum "+"-Symbol im Spotify-Player (Funde dauerhaft im eigenen Spotify-Konto speichern, explizit als "eigenes Konto" formuliert, nicht missverständlich als "Favoriten im eingebetteten Player")
   - Neuer "Geduld wird belohnt"-Absatz (Vielfalt wächst mit Sitzungsdauer, da anfangs nur wenige MB-Batches durchkämmt wurden)

---

## 6. Arbeits-Prinzipien (unbedingt beibehalten)

- **Root Cause statt Symptom-Patch** — bei jedem Bug wird tatsächlich die Ursache gesucht, siehe Watchdog-Fix als Beispiel (mehrere Ebenen tiefer als der erste Verdacht)
- **Vor jedem Build kurz nachfragen**, ob noch was dazukommt — Andreas denkt häufig nachträglich noch was hinzu; explizite Standing-Regel
- **Schritt für Schritt, keine Textwände** — Andreas bevorzugt kleine, bestätigte Schritte statt langer Vorab-Erklärungen
- **Check-Ritual vor jeder Auslieferung:** Backspace-Zeichen-Check, `node --check` auf extrahiertem `<script>`-Inhalt, bei Layout-/Verhaltens-Änderungen zusätzlich Playwright-Test mit echten Timestamps (nicht nur Code lesen und für richtig befinden)
- **Bei Textänderungen an der Werkbeschreibung:** Wortlaut-Vorschlag zeigen, explizit bestätigen lassen, dann erst in beide Sprachversionen einbauen (DE zuerst formulieren, EN direkt danach spiegeln)
- **Philosophie/Kybernetik-Reflexion ist Teil der Zusammenarbeit**, nicht Ablenkung — Zufall, Orakel-Traditionen, Divine-Action-Theologie sind explizit erwünschtes Gesprächsthema, wenn Andreas draufkommt

---

## 7. Bekannte offene Punkte (aus dem Web-Chat, nicht abgeschlossen)

- **Lyrics-Karte** ist weiterhin nur ein "Songtext ansehen ↗"-Link, keine echte Wiki-Fetch-Karte (Genre-Karte wurde das schon vor längerem, Lyrics nie angefragt)
- **Wiki/Wetter-Panel DE/EN-Sprachumschaltung** — weiterhin offen
- **Zwei Playback-Modi (Info- vs. Discovery-Modus)** — weiterhin offen
- **AdGuard/DoH als Störfaktor** — nicht isoliert verifiziert, siehe Abschnitt 5.3
- Kein aktuell bekannter offener Bug in den vier Kern-Dateien selbst — alle in dieser Session gemeldeten Probleme wurden verifiziert gefixt

---

## 8. Paralleles Projekt: next-global-random (Nextcloud-Spinoff)

**Eigenständiges, separates Projekt** — eigenes Handover-Dokument existiert bereits (`HANDOVER-next-global-random.md`), hier nur der Kurzstatus, falls relevant:

- Ziel: GLOBAL RANDOM in eine passwortgeschützte Nextcloud-Instanz einbetten (Iframe-Pattern), später optional um einen KI-gestützten IT-Security-News-Ticker erweitern (heise-Security-Feed → Claude-API-Zusammenfassung → TTS)
- Ausdrücklich als **Machbarkeitsstudie** markiert, geschlossener Nutzerkreis, kein Live-Rundfunk
- Stand: App-Grundgerüst teilweise gebaut (`appinfo/info.xml`, `routes.php`, `Application.php`, `PageController.php` fertig; `templates/index.php`, `css/style.css` fehlen noch), **noch nicht getestet**
- **Nächster Schritt dort: isolierte Docker-Testumgebung, bevor irgendwas an Andreas' echtes Produktivsystem kommt** — explizite Sicherheitsregel, nicht verhandelbar
- Rechtliche Recherche (Rundfunklizenz-Schwelle 20.000 Nutzer, GEMA ohne Bagatellgrenze, Framing-Rechtsprechung BestWater/EuGH) ist im separaten Handover dokumentiert
- `global-random.html` bleibt in diesem Spinoff **unverändert** — wird nur per Iframe eingebettet, nicht bearbeitet

Falls Andreas mit next-global-random weitermachen will, gehört das eigentlich in einen eigenen Claude-Code-Ordner/Kontext, nicht vermischt mit den vier Hauptdateien hier.

---

## 9. Für den Einstieg in Claude Code

Da hier echter Datei-/Terminal-Zugriff besteht (kein Upload-Ritual nötig): Die vier Dateien einfach ins Arbeitsverzeichnis legen bzw. dort liegen lassen, wo Andreas sie hinlegt. Kein `package.json`, kein Build-Step, keine Dependencies — reines Single-File HTML/CSS/JS, direkt editierbar. Für Tests: `node --check` auf extrahiertem Script-Block weiterhin sinnvoll als schneller Sanity-Check, aber wo möglich echtes Playwright mit echtem Chromium bevorzugen (siehe Abschnitt 2) — das war in der Web-Sandbox nicht möglich und ist ein echter Fortschritt gegenüber den letzten Sessions.

---

*Ende Handover.*
