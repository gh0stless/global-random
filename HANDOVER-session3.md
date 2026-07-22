# HANDOVER — GLOBAL RANDOM, Stand Ende Session 3

**Datum:** 5. Juli 2026
**Hauptdatei:** `/mnt/user-data/outputs/global-random.html` (aktuellster Stand) — live unter `https://crazy-midi.de/global-random/`
**Weitere Dateien:** `global-random-landingpage.html` (Werk-Landingpage), `werkbeschreibung-lang.md`, `werkbeschreibung-kurz.md` — alle synchron gehalten (siehe Abschnitt 7)

Diese Datei ersetzt eine frühere, mitten in dieser Session geschriebene Zwischenversion — seitdem ist noch sehr viel passiert (drittes Flaggen-Matrix-System, STOP-Button, Werkbeschreibungs-Sync, Joomla-Deployment). Diese Fassung ist der vollständige, aktuelle Stand.

---

## 1. Projekt in einem Satz

Browserbasierte Netzinstallation ("GLOBAL RANDOM — Democracy of Sound"): eine einzelne HTML-Datei, kein Server, spielt echte Zufallsmusik aus 221 Ländern/Territorien via MusicBrainz + Spotify-Embed, übersetzt Titel live in bis zu 87 Sprachen (MyMemory), zeigt Land/Künstler/Genre/Lyrics-Infos (Wikipedia/Wikidata/Open-Meteo). Kernthese: bewusste Gegenposition zu algorithmischer Kuration — echter, fairness-korrigierter Zufall statt Empfehlungsalgorithmus.

Kommunikation mit Andreas: **immer Deutsch**, Schritt-für-Schritt, Root-Cause-Analyse bevorzugt, keine Symptom-Pflaster. Der Nutzer nennt Claude in diesem Projekt **"FUCKUP"** — Referenz auf den Rechner aus Robert Shea/Robert Anton Wilsons *Illuminatus!*-Trilogie (First Universal Cybernetic-Kinetic-Ultramicro-Programmer, wirft I-Ching-Hexagramme aus echtem Zufall). Im Code-Kommentar-Header bewusst **unerklärt** gelassen ("wer's kennt, kennt's"); in der öffentlichen Werkbeschreibung dagegen mit ausgeschriebenem Akronym als "KI-assistiert von Claude (FUCKUP — ...)" — zwei bewusst unterschiedliche Framings für zwei unterschiedliche Zielgruppen.

---

## 2. Kernarchitektur

**Discovery-Pipeline:** `discoverCandidates()` -> `mbRandomSearch()` (MB URL-Suche, offset-basiert, Obergrenze ~650.000 empirisch bestätigt, Start bei 600.000) -> Batch-Dedup (max. 1 pro Land/Künstler pro 25er-Batch, Abbruch nach 3 Duplikaten -- beide Zähler-Pfade jetzt korrekt, siehe Abschnitt 8) -> `countryStacks{}` (Pool, Cap=6 pro Land, FIFO-Eviction) -> `promoteFromPool()` (async, Lock, Diversitäts-Gate: erster Promote wartet auf >=3 unterschiedliche Pools) -> `queue[]` (Ziel: BUFFER_SIZE=3) -> `_pickRandomFromQueue()` (zweite Zufallsebene beim tatsächlichen Play, jetzt hörbar via Würfelsound, siehe Abschnitt 5).

**Whitelist:** `COUNTRIES` = 221 Einträge (193 UN-Mitgliedsstaaten + 28 bewusst aufgenommene Nicht-UN-Entitäten: Taiwan, Hongkong, Macau, Palästina, Kosovo, Puerto Rico, Vatikanstadt, Grönland, Färöer, Westsahara, Gibraltar, Bermuda, Kaimaninseln, Isle of Man, Guernsey, Jersey, Amerikanisch-Samoa, Guam, US-Jungferninseln, Neukaledonien, Französisch-Polynesien, Réunion, Martinique, Guadeloupe, Französisch-Guayana, Cookinseln, Niue, Åland). Bewusst ausgeschlossen: Nordzypern, Somaliland (keine sauberen offiziellen ISO-Codes). Alle vier Tabellen (`COUNTRIES`, `CAPITALS`, `COUNTRY_DE`, `COUNTRY_LANG`) müssen bei künftigen Erweiterungen konsistent gemeinsam gepflegt werden.

**Sprachen:** `TRANSLATE_TO` = 87 Zielsprachen (Latein für Vatikanstadt ergänzt, bestätigt von MyMemory unterstützt). Jede Sprache hat eine feste, einzelne Farbe (Wiedererkennungswert) -- keine Zufallszuweisung. `PASTEL`-Palette (10 Töne + 1 theme-abhängige Zusatzfarbe: Knallgelb im Dark-Mode, Dunkelblau im Light-Mode) wird nur für den seltenen Fallback-Fall genutzt (komplett fehlgeschlagene Übersetzung), nicht für die normalen Sprach-Bubbles -- das war ein Missverständnis, das im Gespräch aufgeklärt wurde; blieb am Ende bewusst so (keine Änderung an der Kernfarblogik).

---

## 3. Flaggen-System -- jetzt DREI Matrizen

Das ist die größte strukturelle Neuerung dieser Session, in zwei Ausbaustufen gebaut:

**Matrix 1 (`#flag-bar`)** -- "noch nicht gefunden". Wird bei jedem relevanten Ereignis komplett neu aufgebaut (`innerHTML=''`), zeigt nur Länder, die noch nie einen Pool-Fund hatten. Alle Flaggen in voller Farbe (Abdunkelung für "Pool leer" wurde entfernt, da Matrix 2 diese Erinnerungsfunktion übernommen hat). Schrumpft im Lauf der Session.

**Matrix 2 (`#found-bar`, Label "GEFUNDEN")** -- "gefunden, aber noch nicht gespielt". Append-only, feste Reihenfolge nach Fundzeitpunkt, nie umsortiert. Zeigt Flagge + Fill-Balken (aktueller Pool-Füllstand 0-100%) + gedimmt/aktiv-Zustand. Ein Land verschwindet aus Matrix 1, sobald es hier zum ersten Mal auftaucht (`_poolSeen`-Set steuert den Filter in `updateFlagBar()`).

**Matrix 3 (`#played-bar`, Label "GESPIELT")** -- "tatsächlich abgespielt". Analog zu Matrix 2 gebaut (copy/scale, wie vom Nutzer angeregt), aber mit einem wichtigen Unterschied: Da Matrix 2 selbst append-only ist (kein automatischer Neuaufbau wie Matrix 1), musste der Umzug 2->3 explizit einen bestehenden DOM-Knoten aus `#found-bar` suchen und entfernen (`_registerPlayed()`), statt sich auf einen Render-Filter zu verlassen. Ausgelöst über `_playedCountries`-Set, das an der richtigen Stelle aktualisiert wird -- nicht beim Play-Start (wo `countryCode` manchmal noch nicht final ist), sondern nach dem bestehenden "Backfill"-Mechanismus in `_renderPlayingMeta()`, wenn der Country-Code garantiert final ist.

**Zwei Zähler-Badges** (`.flag-counter`, "X/222" inkl. Unknown), je einer am Ende von Matrix 2 und Matrix 3 -- append-only-freundlich implementiert (`_updateFoundCounter()`/`_updatePlayedCounter()` erstellen das Badge einmalig, aktualisieren danach nur den Text; neue Länder-Slots werden über `insertBefore` vor dem Badge eingefügt, damit es zuverlässig das letzte Element bleibt).

**Footer-Zähler** ("discovered: X songs · Y countries · Zm Ws") nutzt `_playedCountries.size` -- bewusst getrennt von `countSeen` (Session-Cap-Logik in Discovery) und `_poolSeen` (Matrix-1->2-Übergang). Drei unterschiedliche Zähl-Zeitpunkte für drei unterschiedliche Zwecke, nicht verwechseln bei künftigen Änderungen.

**Laufzeit-Uhr im Footer**: reine tickende Uhr ab erstem Play (`_firstPlayAt`), keine Summierung/Pausen-Erkennung, eigener 1-Sekunden-Timer.

---

## 4. Neue Anzeige-Features (Cards)

- **Genre-Tag** unter dem Titel (`#t-genre`), aus `inc=genres` im ohnehin nötigen Artist-Fetch, kein Zusatz-Call.
- **Komponisten-Heuristik** als Fallback im selben Feld: Text-Matching gegen Titel/Release-Titel und den (jetzt vollständigen) Artist-String gegen eine 20-Namen-Liste, plus Opus-Nummer-Muster als generischer "Classical"-Fallback. Beschriftet als "vermutlich:"/"possibly:". Bei erkannter Klassik wird der Titel zusätzlich am ersten Komma/Doppelpunkt gekürzt (z.B. "Elektra, Op. 58, TrV 223: ..." -> "Elektra") -- nur wenn Klassik schon erkannt wurde, sonst würden normale Pop-Titel mit Komma (z.B. "Hello, Goodbye") kaputt gekürzt.
- **Lyrics-Card**, eigenständig, erscheint nur bei MB `type==='lyrics'`-Relationship (aus demselben `url-rels`-Call wie Social-Links).
- **Genre-Wikipedia-Card**: Link direkt aus dem Genre-String konstruiert, Case-Normalisierung vor dem URL-Bau (`_wikiTitleCase()`, behebt einen realen Bug: MB liefert manche Genres in ALL CAPS wie "HIP HOP", was ohne Normalisierung zu einer toten Wikipedia-URL führte). Bei deutscher Browsersprache zusätzlich en->de-Übersetzung via MyMemory (MyMemory unterstützt kein "auto" als Quellsprache, offiziell bestätigt -- daher die Annahme "Quelle ist meist Englisch" als Kompromiss). Race-Condition-Schutz falls der Track wechselt, während die Übersetzung noch läuft.
- **Artist-Feld vervollständigt**: nutzt jetzt alle `artist-credit`-Einträge (mit MBs `joinphrase`), nicht nur den ersten -- vorher gingen Dirigent/Orchester/weitere Solisten bei klassischen Aufnahmen verloren (Beispielfund: "Richard Strauss" fehlte, nur "Iréne Theorin" wurde gezeigt).

Bewusst nicht gebaut: Genius-API-Integration (erwogen, aber verworfen -- würde einen geheimen Client-Access-Token brauchen, der in einer clientseitigen Ein-Datei-Anwendung für jeden im Quelltext sichtbar wäre).

---

## 5. Sound-Design

- **Radio-Tune** (94,8s, Base64) läuft ausschließlich während der allerersten "SEARCHING..."-Phase, nicht mehr zwischen Songs (frühere Iteration hatte das versehentlich anders gebaut, wieder korrigiert).
- **Würfelbecher-Sound** (`playDiceSound()`), komplett synthetisiert über Web Audio API (gefiltertes Rauschen, keine Aufnahme, kein Lizenzproblem) -- spielt bei jedem Play/Skip genau im Moment des Zufallszugs. Zwei-Phasen-Struktur: langes Schütteln (14-20 Impulse, trägt die Länge, ~1-1,4s) + kurzes knackiges Ausrollen (3-4 eng getaktete, schnell abklingende Treffer, ~0,2-0,3s) -- bewusst NICHT gleichmäßig gestreckt. Drei Zufalls-"Charakter"-Parameter pro Wurf (Grundtonhöhe, Lautstärke, Tempo).
- **Timing-Fix**: `stopSearchTune()` muss vor `playDiceSound()` stehen (nicht danach), sonst kurze Überlappung beim allerersten Play, falls der Radio-Tune noch mitten in seiner Wiedergabe war.
- **Geplant, noch nicht gebaut:** Andreas nimmt gerade mit einem echten, entstaubten C64 einen S.A.M.-Sprachsynthese-Sample für "PRESS PLAY ON SCREEN" auf -- noch keine Datei vorhanden, Einbau folgt sobald verfügbar (analog zum Radio-Tune: Base64-eingebettet, ausgelöst an der Stelle wo `term('PRESS PLAY ON SCREEN')` läuft).

---

## 6. STOP-Button (neu diese Session)

Rechts neben PLAY-NEXT, rot, im Verhältnis 2:1 (Flexbox, `#btn-row`). `handleStop()`: pausiert Spotify, stoppt alle Timer, setzt neues Flag `_userStopped=true`. Wichtig beim Debuggen: Zwei bestehende Mechanismen hätten einen Stopp sonst automatisch wieder rückgängig gemacht -- der 10-Sekunden-Heartbeat und der `visibilitychange`-Handler (Tab-Wechsel-Erkennung) -- beide jetzt gegen `_userStopped` abgesichert. Flag wird bei jedem erneuten PLAY/PLAY-NEXT-Klick zurückgesetzt. Kein Reload nötig zum Fortsetzen -- verifiziert, dass `playReady()` nur `queue.length>0 && EC` prüft, beides bleibt nach STOP unverändert bestehen.

---

## 7. Werkbeschreibung & Landingpage -- synchronisiert

Alle drei Dokumente (`werkbeschreibung-lang.md`, `werkbeschreibung-kurz.md`, `global-random-landingpage.html`) wurden diese Session aktualisiert und synchron gehalten:
- Länderzahl 193->221, Sprachenzahl-Widerspruch behoben (war 86 in Statistik vs. "siebzig" im Fließtext -- jetzt einheitlich 87)
- Signatur: "Konzept, künstlerische Idee: Andreas S. (gh0stless) - KI-assistiert von Claude (FUCKUP -- First Universal Cybernetic-Kinetic-Ultramicro-Programmer)" -- nur Akronym-Ausschreibung, keine Illuminatus-Erklärung im öffentlichen Text (anders als ursprünglich von Claude vorgeschlagen, vom Nutzer korrigiert)
- Lizenz ergänzt: CC BY-NC-SA 4.0 -- Weitergabe frei, nicht-kommerziell, Namensnennung erforderlich (exakter Wortlaut vom Nutzer vorgegeben)
- Hinweis zu Konzept/Idee-Schutz: bewusst rechtlich ehrlich formuliert (Ideen selbst sind nicht urheberrechtlich schützbar, nur ihre Umsetzung -- die Zeile hält trotzdem die Urheberschaft fest)
- Kurzversion bewusst schlanker (keine FUCKUP-Erklärung, würde das 85-Wort-Format sprengen)

Code-Kommentar in `global-random.html` selbst bewusst NICHT verändert -- sollte laut explizitem Wunsch des Nutzers knapp/unerklärt bleiben ("2026 Andreas S. & FUCKUP (First Universal Cybernetic-Kinetic-Ultramicro-Programmer)"), anders als die öffentliche Werkbeschreibung.

---

## 8. Diese Session gefundene und gefixte Bugs (Auswahl, für Root-Cause-Bewusstsein)

- **Batch-Abbruch-Zähler**: Zwei unabhängige Lücken (Unknown-Pool-Funde, Artist-Duplikate ohne Länderfeld) erhöhten den Skip-Zähler nie -- ein "kaputter" Batch (z.B. ein ASMR-Kanal ohne Länderinfo) konnte dadurch endlos durchlaufen. Beide gefixt.
- **cleanTitle() hängender Bindestrich**: Titel wie "Hey You - " (mit nichts danach) wurden nicht bereinigt, da die Versions-Tag-Erkennung nur auf erkannte Schlüsselwörter prüfte, nicht auf einen leeren Rest.
- **Flag-Tooltip hardcoded Deutsch**: zeigte immer deutsche Ländernamen, unabhängig von der Browsersprache -- jetzt korrekt sprachsensitiv wie der Rest des Systems.
- **Sound-Überlappung**: Würfelsound und Radio-Tune liefen ohne Verzögerung gleichzeitig; später wurde der Radio-Tune zwischen Songs komplett entfernt (nur noch Würfelsound), was das Problem strukturell auflöste.
- **Pool-Zähler "Reset auf 0"**: kein Bug, sondern irreführende Definition -- `candidates.length` fällt legitim auf 0 sobald alles frisch promoted wurde. Zähler zeigt jetzt `candidates.length+queue.length`.
- **STOP-Button-Versatz**: `margin` saß am einzelnen `#btn` statt am gemeinsamen Wrapper -- nach Einbau des STOP-Buttons daneben entstand ein 10px-Höhenversatz. Margin auf `#btn-row` verschoben.
- **`#played-bar` fehlendes CSS**: JS-Logik komplett kopiert, aber die Container-CSS-Regel (`display:flex` etc.) vergessen -- Slots rendierten als volle Block-Elemente statt kompakter Flex-Items.
- **Genre-Wikipedia-Link Case-Sensitivity**: MB liefert manche Genres in ALL CAPS ("HIP HOP"), Wikipedia-Artikeltitel sind aber jenseits des ersten Buchstabens case-sensitiv -- ohne Normalisierung lief der Link ins Leere.
- **Discovered-Countries-Zähler zählte zu früh**: nutzte `countSeen` (zählt bei Queue-Promotion), sollte aber nur tatsächlich gespielte Länder zeigen. Neuer `_playedCountries`-Set, und wichtig: der Zähler-Aufruf musste an eine spätere Stelle verschoben werden (nach dem Country-Backfill), da `countryCode` beim Play-Start manchmal noch nicht final ist.

---

## 9. Bekannte offene Punkte

- **iPhone-Kompatibilität**: Stiefschwester-Report, nie im Detail diagnostiziert. Weiterhin offen.
- **Sticky-Footer auf Mobile**: gilt aktuell global, nicht Mobile-spezifisch eingeschränkt -- noch nicht gegengecheckt ob das auf kleinen Screens zu viel Platz wegnimmt.
- **S.A.M.-Sprachsample**: Aufnahme noch nicht fertig, Einbau folgt.
- **Joomla-Deployment**: Datei liegt bereits unter `crazy-midi.de/global-random/`, Andreas baut gerade einen Menüpunkt in seinem bestehenden Joomla-3.10.12-Auftritt (`crazy-midi.de/joomla/`) -- empfohlener Weg: externe URL im Menü, kein iframe (Verschachtelung mit Spotifys eigenem iframe könnte Autoplay/Login-Verhalten stören). Sicherheitshinweis gegeben: Joomla 3 ist seit Februar 2025 komplett ohne Sicherheitspatches (eLTS ausgelaufen), zusätzlich aktuelle aktiv ausgenutzte Lücke in der JCE-Erweiterung (CVE-2026-48907, Juni 2026) -- Andreas sollte prüfen ob JCE installiert ist, und einen Umstieg auf Joomla 4/5 mittelfristig in Betracht ziehen (nicht akut, aber nicht ewig aufschiebbar).

---

## 10. Separates, zukünftiges Projekt (NICHT Teil von GLOBAL RANDOM)

Webcam/Gesichts- bzw. Lippenerkennung als interaktive Eingabequelle für algorithmische Musik -- eigenständige neue Idee, thematisch verwandt (echte physikalische Entropie/ausdrucksvolle Steuerung statt Pseudozufall), aber bewusst als separates Werk markiert. Explizit besprochen: MediaPipe Face Mesh (WASM-basiert). Andreas hat klargestellt: Für dieses neue Projekt gelten andere Regeln als für GLOBAL RANDOM -- die "eine Datei, keine Abhängigkeiten"-Philosophie muss hier nicht gelten, WASM-Bibliotheken sind akzeptabel. Reines Brainstorming-Stadium, noch nichts gebaut.

---

## 11. Testtools (aus früheren Sessions, weiterhin gültig)

- `mb-offset-ceiling-test.html` -- bestätigte die reale MB-Offset-Grenze (~650.000).
- `wiki-bio-country-test.html`, `mb-country-test-all-un.html` -- Stand ggf. nicht mehr synchron mit aktuellem Hauptcode, nicht in dieser Session genutzt.

---

*Ende Handover.*
