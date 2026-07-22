# GLOBAL RANDOM — Handover für Chat #5

**Von:** Chat #4 (Marathon-Session)
**Persona:** Claude arbeitet als **FUCKUP** (First Universal Cybernetic-Kinetic-Ultramicro-Programmer, *Illuminatus!*-Referenz) — lockerer, spaßiger Ton, Deutsch, Philosophie zum Zufall willkommen.
**Feste Regel:** Vor jedem Build erst rückfragen, ob noch was dazukommen soll — Andreas denkt oft nachträglich noch was hinzu.

---

## Projekt in einem Satz

`global-random.html` — eine einzelne, self-contained HTML-Datei (~1.5MB), die per echtem Zufall Musik aus 247 Ländern spielt, bewusst als Gegenentwurf zu algorithmischer Kuratierung. Live unter https://crazy-midi.de/global-random/

## Dateien

| Datei | Zweck |
|---|---|
| `/mnt/user-data/outputs/global-random.html` | **Aktueller Arbeitsstand, ausgeliefert** |
| `/home/claude/global-random.html` | Arbeitskopie (identisch mit oben, Stand Ende Chat #4) |
| `global-random-stable-v1/v2/v3.html` | Ältere Backup-Snapshots |
| `beschreibung.html` / `description.html` | DE/EN Langbeschreibung |
| `honey-antwort-bereinigt.md` | Korrigierte Mail an Honey (Welle:Erdball) |

**Erster Schritt in Chat #5:** `/home/claude/global-random.html` aus dem Output kopieren (falls die Sandbox neu ist) und Check-Ritual laufen lassen, bevor irgendwas verändert wird.

---

## Was in Chat #4 passiert ist (chronologisch)

### 1. Tooltip-Erweiterung (alle 4 Flaggen-Matrizen)
Zentrale Funktion `_countryTipText(code)` eingeführt — zeigt einheitlich: Poolfüllung, Play-Zähler, Pool-Frische, "zuletzt gespielt". Wichtige Design-Entscheidung: `_bindFlagTip()` nimmt jetzt auch eine **Funktion** (lazy) statt nur String, damit Tooltips bei lange bestehenden Slots nicht einfrieren.

Neue globale Tracker:
- `_playCountByCountry{}` — echter Play-Zähler pro Land (nicht `countSeen`, das zählt nur Queue-Ziehungen)
- `_playCountedIds` Set — verhindert Doppelzählung bei mehrfachen `_renderPlayingMeta()`-Durchläufen
- `_poolLastUpdate{}` — Timestamp pro Land-Pool
- `_lastPlayedByCountry{}` — Timestamp "zuletzt gespielt" pro Land

### 2. Preview-Slot-Architektur-Bugs (mehrstufig, wichtig!)
**Ursprüngliches Problem:** Der 4. Slot (Hauptplayer) verschwand nicht sofort, sondern erst mit Verzögerung — und manchmal gar nicht zuverlässig.

**Root Causes gefunden (mehrere übereinander):**
1. Preview-Slots waren nach **roher Array-Position** gemappt (`queue[0]/[1]/[2]`), aber `Array.splice()` beim Ziehen verschiebt nachfolgende Einträge — das leerte fast immer den falschen Slot. **Fix:** Jeder Queue-Eintrag bekommt jetzt eine stabile `.slot`-Eigenschaft (0/1/2), unabhängig von Array-Position. Siehe `_queueItem()`, `_syncPreviewSlots()`, `_pickRandomFromQueue()`.
2. Der Sync-Aufruf für die leere Markierung kollidierte zeitlich mit der laufenden Würfel-Animation (`_animateDiceRoll()`), je nach Zufalls-Timing sichtbar oder nicht. **Fix:** Sync passiert jetzt fest **nach** `await _diceAnim`, nicht synchron direkt nach dem Splice.
3. Hauptplayer (`#embed-container`) hatte gar keine "leer"-Behandlung. **Fix:** `.empty`-Klasse analog zu Preview-Slots, gesetzt am Anfang von `playReady()`, entfernt nach der Würfel-Animation beim `loadUri()`.

### 3. Queue-Nachzug-Timing (Kosten sparen + UX)
- Queue-Nachzug (`promoteFromPool()`, der 2. Würfelwurf) feuerte ursprünglich sofort (~150ms) — Fix: **an bestätigte Wiedergabe gekoppelt** + 4-8s Verzögerung danach (`QUEUE_REFILL_DELAY_MS` + Jitter), NICHT an den reinen Ziehzeitpunkt. Wichtig: Wenn ein Track **still hängt** (nie bestätigt abspielt), wird der Nachzug gar nicht erst geplant — kein irreführendes Hintergrund-Aktivität-Gefühl während der Hauptplayer leer dasteht.
- **PLAY NEXT-Button-Bug gefunden:** `updateBtn()` hob den "loading…"-Zustand von `playReady()` sofort wieder auf. Fix: Button bleibt jetzt disabled bis der Queue-Nachzug tatsächlich abgeschlossen ist (`promoteFromPool()`-Callback ruft `updateBtn()` auf), nicht schon bei bloß bestätigter Wiedergabe.
- `detectSilentTrack()` (12s Stille-Timeout, unverändert) und Queue-Nachzug sind zwei **komplett unabhängige** Timer — beide durch Playwright-Tests mit echten Timestamps verifiziert.

### 4. Dedup-Verbesserungen (drei Ebenen, komplementär)
1. **Artist-Dedup (SpongeBob-Fall):** `_artistDedupKey()` — dedupliziert nach **erstem Namensteil** im Credit-String statt Vollstring, da Compilation-/Soundtrack-Credits oft "Franchise, Nickelodeon, wechselnder Composer" listen.
2. **Various-Artists-Dedup (Tekkno-Voom-Fall):** `_isVariousArtistsCredit()` erkennt "Various Artists"/"VA"/"V.A." als Platzhalter-Credit → fällt dann auf **Titel-Vergleich** zurück statt Künstlername. **Sessionweites** Set `_vaTitlesEverUsed` (nicht nur pro Batch!), weil MusicBrainz denselben Sampler-Track oft mehrfach mit unterschiedlicher Recording-ID katalogisiert.
3. **Release-Dedup (gleiches Cover-Bild-Fall):** `found.release` wird jetzt **kostenlos** mitgeholt (`inc=artist-credits+releases` statt nur `+artist-credits`, gleicher API-Call). Neues `_batchReleasesUsed`-Set, max. 1 Kandidat pro Release **pro Batch** (nicht sessionweit — bewusst anders als Various-Artists-Dedup, siehe Kommentar im Code).

**Bewusst NICHT geändert:** Der Länder-Diversitäts-Check (`_batchCountriesUsed`) bleibt, obwohl er teilweise redundant mit dem neuen Release-Check wirkt — sein eigentlicher Zweck (Länder-Diversität pro Batch, Kern der Projekt-These) ist NICHT redundant.

### 5. Kritischer Crash-Fix: `$('embed-container')` war `null`
**Symptom:** Klick auf PLAY/PLAY NEXT tat nichts mehr, Konsole zeigte `Uncaught TypeError: can't access property "classList", $(...) is null` in `playReady()`.

**Ursache:** `IFrameAPI.createController($('embed-container'), ...)` übergab das Element direkt — Spotifys SDK mutiert/ersetzt das übergebene Mount-Element, wodurch die ID danach weg war. Die Preview-Slots hatten dieses Problem schon vorher clever umschifft (`#preview-slot-1` außen stabil, `.preview-frame` innen als Mount-Ziel) — beim Hauptplayer wurde das nicht konsequent nachgezogen, als die `.empty`-Erweiterung gebaut wurde.

**Fix:** `#embed-container` → `#embed-wrapper` (stabil, außen) + `.embed-frame` (innerer Mount-Punkt, darf von Spotify mutiert werden). Alle drei Stellen angepasst: `createController()`-Aufruf, `.empty`-Klasse hinzufügen, `.empty`-Klasse entfernen. Mit Playwright verifiziert, inklusive simulierter kompletter DOM-Ersetzung des inneren Mount-Punkts.

**Wichtige Lektion für Chat #5:** Wenn in Zukunft NEUE DOM-Elemente an `IFrameAPI.createController()` übergeben werden sollen, IMMER das Preview-Slot-Muster verwenden (stabiler Wrapper + innerer Mount-Punkt), nicht direkt das Element mit der ID, die man später noch braucht.

---

## Offene/angerissene Punkte (nicht abgeschlossen)

- **Discover Lyrics Card** — aus Chat #3 übernommen, noch nicht umgesetzt (Genius/Musixmatch/songtexte.com Links)
- **S.A.M.-Sprachsample** ("PRESS PLAY ON SCREEN") — bei Honey (Welle:Erdball) angefragt, Antwort noch ausstehend. Optional: offizielle W:E-Variante "Hallo, hier spricht..." exklusiv für Hörerclub
- **Wiki/Wetter-Panel DE/EN-Umschaltung** — offen
- **Zwei Playback-Modi (Info- vs. Discovery-Modus)** — offen
- Kommentar im Code (`_batchCountriesUsed`-Bereich) könnte laut Andreas noch präzisiert werden (Länder- vs. Klassik-Klumpen-Zweck klarer trennen) — **nicht** umgesetzt, nur angeboten

---

## Etablierte Arbeits-Prinzipien (unbedingt beibehalten)

- **Root Cause statt Symptom-Patch** — bei jedem der obigen Bugs wurde tatsächlich die Ursache gesucht (z.B. Array-Splice-Verschiebung, SDK-Mutation), nicht nur das Symptom kaschiert
- **Check-Ritual vor jeder Auslieferung:** Backspace-Zeichen-Check (`chr(8)` Vorkommen = 0) + `node --check` auf extrahiertem Script-Block
- **Playwright-Verifikation** statt bloßer Behauptung — bei zeitkritischen Bugs (Timing, Race Conditions) wurde grundsätzlich mit echten Timestamps gemessen, nicht nur Code gelesen und für richtig befunden. Mehrfach hat das Testen tatsächlich einen zweiten, tieferliegenden Bug aufgedeckt, der durch bloßes Code-Lesen übersehen worden wäre
- **Ehrlichkeit bei Unsicherheit:** Mehrfach explizit zugegeben, wenn ein Fix nicht zu 100% als Ursache verifiziert war
- **Vor jedem Build rückfragen** ob noch was dazukommt (explizite Regel von Andreas)
- Sprache: komplett Deutsch, lockerer FUCKUP-Ton, Philosophie-Reflexion über Zufall/Kybernetik ist Teil der Zusammenarbeit, keine Ablenkung

---

## Direkter Einstieg für Chat #5

1. Datei aus Output laden, Check-Ritual laufen lassen
2. Falls Andreas mit einem neuen Feature startet: kurz rückfragen ob noch was dazukommt (Standard-Regel)
3. Bei allem was mit Timing/Reihenfolge zu tun hat: nicht auf Code-Lesen verlassen, sondern mit Playwright + echten Timestamps nachmessen — das hat sich in Chat #4 mehrfach ausgezahlt
