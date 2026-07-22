# HANDOVER — next-global-random (Nextcloud-Spinoff)

**Datum:** 17.07.2026 (Abends, aus dem GLOBAL-RANDOM-Hauptchat heraus abgezweigt)
**Persona:** Offen — FUCKUP (First Universal Cybernetic-Kinetic-Ultramicro-Programmer, *Illuminatus!*-Referenz) ist die Persona im GLOBAL-RANDOM-Hauptprojekt; ob sie hier weiterläuft, entscheidet Andreas beim Start des neuen Chats. Lockerer Ton, Root-Cause-Denken und "vor jedem Build kurz nachfragen" gelten in jedem Fall weiter, unabhängig vom Namen.
**Wichtig:** Dies ist ein **eigenständiges Spinoff-Projekt**, keine Änderung an GLOBAL RANDOM selbst. Die Haupt-App (`global-random.html`) bleibt unverändert — sie wird hier nur *umhüllt*, nicht bearbeitet.

---

## 1. Projekt in einem Satz

Eine **Nextcloud-App**, die (a) die bestehende GLOBAL-RANDOM-Installation in einer eigenen, passwortgeschützten Nextcloud-Instanz zugänglich macht, und (b) perspektivisch um ein KI-gestütztes IT-Security-News-Ticker-Feature erweitert werden soll ("zur vollen Stunde vorgelesene, von Claude aus Volltexten destillierte Kurzmeldungen zur Cybersicherheitslage"). **Ausdrücklich als Machbarkeitsstudie geplant**, nicht als Live-Produkt — geschlossener Nutzerkreis (Andreas + Freunde), Nextcloud-Login als natürlicher Passwortschutz.

---

## 2. Wie wir hierher kamen (Kontext aus dem Hauptchat)

Der Gedankengang, komprimiert:
1. Gespräch über KI-gestütztes Mining von Usenet-Archiven (Andreas postet selbst in `de.sci.theologie`/`t.origins`, hat dort tiefe philosophische Threads zu Zufall/Gott/freiem Willen laufen)
2. Daraus die Idee: sowas Ähnliches (KI liest viele Quellen, destilliert eine knappe Zusammenfassung) auch für aktuelle News bauen — zuerst als "Radio"-Idee mit wählbarer politischer Ausrichtung (links/rechts/konservativ) angedacht
3. **Diese politische Variante wurde verworfen** — Begründung: (a) widerspricht der Zufalls-/Anti-Kurations-These von GLOBAL RANDOM strukturell, (b) regulatorisch heikel (siehe Abschnitt 4)
4. Stattdessen: **IT-/Cybersicherheits-News** — unpolitisch, passt zum FUCKUP-Cybernetics-Geist des Hauptprojekts, easy Quellenlage (heise Security Alert-Feed, s.u.)
5. Erkenntnis: ein "echtes Radio" (fester Sendeplan, läuft unabhängig vom offenen Tab) bräuchte zwingend einen echten Server/Cron-Job — **damit ist das kein Teil von GLOBAL RANDOM mehr** (das lebt von "eine Datei, kein eigenes Backend"), sondern ein eigenständiges Projekt. Genau wie schon früher das Webcam/Gesichtserkennungs-Projekt aus einer anderen Session als separates Ding markiert wurde.
6. Andreas hat eigene Nextcloud-Instanz am Laufen → Idee: Nextcloud als Backend/Hosting-Basis nutzen, weil Cron-Jobs, PHP-Backend und Passwortschutz eh schon eingebaut sind
7. **Schritt 1 (heute begonnen):** GLOBAL RANDOM unverändert in eine minimale Nextcloud-App-Hülle packen, nur um zu sehen, ob's grundsätzlich läuft — noch **kein** News-Feature, noch keine KI-Anbindung
8. Andreas bekam **berechtigte Bauchschmerzen**, das an seinem laufenden Produktivsystem zu testen → **nächster Schritt laut Empfehlung: erst in isolierter Docker-Instanz testen, niemals direkt am Live-System**
9. "Heute ist zu spät" → Handover für neuen Chat angefordert

---

## 3. Aktueller Datei-Stand

Liegt (Stand Chat-Ende) unter `/home/claude/globalrandom-app/` in der Sandbox dieses Chats — **noch nicht als Download exportiert, noch nicht gezippt, noch nicht getestet.** Erster Schritt im neuen Chat: diese Dateien erneut anlegen (Inhalte unten vollständig dokumentiert) oder — falls die Sandbox persistent ist — direkt weiterverwenden.

| Datei | Zweck | Status |
|---|---|---|
| `appinfo/info.xml` | App-Manifest (ID `globalrandom`, Name, Version 0.1.0, Nextcloud-Kompatibilität 28-34) | ✅ fertig |
| `appinfo/routes.php` | Zwei Routen: `page#index` (umrahmte Seite) und `page#globalRandom` (roher HTML-Passthrough) | ✅ fertig |
| `lib/AppInfo/Application.php` | Standard-Bootstrap-Klasse, keine eigene Logik | ✅ fertig |
| `lib/Controller/PageController.php` | Zwei Methoden: `index()` liefert Template mit Iframe, `globalRandom()` liest `global-random.html` roh aus und gibt sie mit korrektem Content-Type + `X-Frame-Options: SAMEORIGIN` zurück | ✅ fertig |
| `templates/index.php` | Nextcloud-Seite mit Vollbild-Iframe, der auf die `globalRandom`-Route zeigt | ❌ **fehlt noch** |
| `css/style.css` | Sorgt dafür, dass der Iframe wirklich vollflächig sitzt (Nextclouds `#app-content`/`#content`-Padding auf 0) | ❌ **fehlt noch** |
| `global-random.html` (App-Root) | Die eigentliche, unveränderte GLOBAL-RANDOM-Datei — muss noch in den App-Ordner kopiert werden | ❌ **fehlt noch** |

**Architektur-Entscheidung, die dahintersteckt:** GLOBAL RANDOM wird bewusst **per Iframe** eingebunden, nicht das Markup direkt ins Nextcloud-Template kopiert. Grund: GLOBAL RANDOM bringt komplett eigene globale CSS-Regeln mit (eigene Fonts, C64-Terminal-Optik, Vollbild-Anspruch) — die würden mit Nextclouds eigenen globalen Styles kollidieren, wenn beide im selben Dokument-Kontext liefen. Der Iframe hält beide Welten sauber getrennt, **ohne dass an `global-random.html` selbst irgendwas verändert werden muss** — wichtig, weil die Datei ja parallel im Hauptprojekt weiterlebt und synchron gehalten werden soll.

---

## 4. Rechtliche Recherche aus dem Hauptchat (bereits erledigt, hier nur zusammengefasst)

Relevant für dieses Spinoff-Projekt, falls es je über "nur für mich und Freunde" hinauswächst:

- **Rundfunklizenz (Medienstaatsvertrag):** Pflicht ab durchschnittlich **20.000 gleichzeitigen Nutzern** über 6 Monate, UND/ODER wenn Angebot "live oder zu bestimmten Zeitpunkten" (Sendeplan) läuft. Ein fester stündlicher News-Slot wäre ein Sendeplan-Kandidat.
- **GEMA/GVL:** **Keine Bagatellgrenze** — Pflicht besteht unabhängig von der Hörerzahl, sobald "öffentlich zugänglich" (nicht hinter Passwort/geschlossenem Kreis). Bei geschlossenem, passwortgeschütztem Nextcloud-Kreis vermutlich nicht einschlägig, aber nicht zu 100% wasserdicht ohne Anwalt.
- **Framing/Embedding-Rechtsprechung (BestWater, EuGH 2014; bestätigt durch BGH):** Einbetten fremder, offiziell bereitgestellter Inhalte (wie Spotifys eigenes IFrame-API) ist grundsätzlich **keine eigene "öffentliche Wiedergabe"** — die Lizenzpflicht liegt bei Spotify, nicht bei GLOBAL RANDOM/next-global-random. Wichtige Einschränkung: 2021 (VG Bild-Kunst) dürfen Rechteinhaber unter bestimmten Umständen technische Schutzmaßnahmen gegen Framing verlangen — betraf aber einen Fall ohne offizielles Embed-Angebot, andere Ausgangslage als bei Spotify.
- **heise-RSS-Nutzungsbedingungen:** Erlauben freie Weiterverwendung von **Titel + Teaser + Link**, nicht Volltext, widerruflich. Für die spätere News-Funktion wichtig: **Volltext lesen/verarbeiten ist unkritisch** (macht jeder Browser), nur die **Ausgabe** muss eigene, destillierte Zusammenfassung sein, kein 1:1-Volltext-Reproduzieren — deckt sich mit den ohnehin geltenden Copyright-Grundsätzen (paraphrasieren statt zitieren).
- **Fazit:** Für die Machbarkeitsstudie (geschlossener Kreis, kein Sendeplan-Radio, kein Live-Rundfunk) ist rechtlich erstmal nichts Kritisches im Weg. Bei echtem Ausbau (Sendeplan, größerer Kreis) wär ein IT-Anwalt für eine verbindliche Einschätzung sinnvoll — bisher nur eingeordnete Fakten, keine Rechtsberatung.

---

## 5. Offene Punkte / nächste Schritte (in Reihenfolge)

1. **Fehlende Dateien fertigstellen:** `templates/index.php`, `css/style.css`, `global-random.html` in den App-Ordner kopieren (aktuellste Version aus dem Hauptprojekt-Chat oder von Andreas frisch hochgeladen holen — **nicht** aus dem Gedächtnis rekonstruieren, immer die tatsächlich aktuelle Datei verwenden)
2. **App als ZIP verpacken**, damit Andreas sie lokal hat
3. **Docker-Compose-Testumgebung bauen** — offizielles `nextcloud`-Image, komplett isoliert vom Produktivsystem, wegwerfbar. **Das ist der empfohlene nächste Schritt, bevor irgendwas am echten System passiert.**
4. In der Docker-Instanz: App in `apps/` einhängen, `occ app:enable globalrandom`, testen ob GLOBAL RANDOM im Iframe sauber lädt (inkl. Spotify-Player — Achtung, CORS/Iframe-Verschachtelung könnte hier nochmal eigene Überraschungen bringen, analog zu den Firefox/Privacy-Badger-Débogage-Sessions aus dem Hauptchat)
5. Erst wenn Docker-Test sauber läuft: Übertragung aufs echte System erwägen, mit Backup vorher
6. **Später, eigene Phase:** News-Ticker-Feature. Dafür vermutlich **ExApp-Architektur** statt klassischer PHP-App sinnvoller (siehe unten) — eigener Python/Node-Prozess statt PHP, für die Claude-API- und TTS-Anbindung

---

## 6. Für später: News-Ticker-Feature (noch nicht begonnen, nur Konzept)

**Ziel:** Zur vollen Stunde (oder täglich) automatisiert IT-Security-Lage zusammenfassen und optional per TTS vorlesbar machen.

**Geplante Quelle (bereits verifiziert):**
- `https://www.heise.de/security/rss/alert-news-atom.xml` (heise Security "Alert"-Kategorie, offizieller Feed)
- Optional ergänzen: Golem Security (`rss.golem.de/rss.php`), BSI/CERT-Bund WID-Feed, evtl. NVD/CVE-Feeds

**Geplante Pipeline:**
```
Cron (stündlich/täglich)
  → RSS-Feed(s) abrufen
  → pro Meldung: verlinkte Volltext-Artikelseite laden
  → Volltexte gebündelt an Claude-API: "fasse diese Artikel als knappe Lage zusammen"
  → Ergebnis als Text speichern + optional TTS-Audio generieren
  → In Nextcloud-App-Oberfläche anzeigen/abspielbar machen
```

**Architektur-Empfehlung (aus Recherche im Hauptchat):** Nextcloud hat neben klassischen PHP-Apps inzwischen auch **"ExApps"** — laufen als komplett eigener Prozess/Container, beliebige Sprache, Kommunikation über HTTP via "AppAPI"/Reverse-Tunnel. Explizit der empfohlene Weg für KI-lastige Nextcloud-Apps (Beispiele: `context_chat`, `llm2`, `stt_whisper2`, `Visionatrix` sind alle ExApps) — vermeidet, "den PHP-Server mit nativen Abhängigkeiten zu verschmutzen". Für Schritt 1 (nur Iframe-Hülle) unnötig, für Schritt 2 (Claude-API + TTS) vermutlich die sauberere Wahl als klassisches PHP.

**TTS-Optionen (noch nicht entschieden):**
- Client-seitig: Browser-`SpeechSynthesis`-API, kostenlos, einfach, Standard-Stimme
- Server-seitig: externe TTS (ElevenLabs) oder lokal (Piper/Coqui), bessere Stimme, mehr Aufwand, ließe sich in ExApp-Architektur sauber unterbringen

**Bewusst verworfen:** Politische Ausrichtungswahl (links/rechts/konservativ) — siehe Abschnitt 2, Punkt 3.

---

## 7. Wichtige Prinzipien, die aus dem Hauptprojekt mitgelten

- **Root Cause statt Symptom-Patch** — bei jedem Bug erst die tatsächliche Ursache finden
- **Vor jedem Build kurz nachfragen**, ob noch was dazukommt — Andreas denkt oft nachträglich noch was hinzu
- **Sicherheit vor Tempo:** Bei allem, was das Produktivsystem berühren könnte, immer zuerst isoliert testen (siehe Docker-Empfehlung oben)
- **GLOBAL RANDOM selbst bleibt unangetastet** von diesem Spinoff — falls an der Haupt-App noch was zu tun ist, gehört das *in diesen* Chat (next-global-random), aber als Änderung an der eingebetteten Datei, nicht als Vermischung der beiden Projekte

---

## 8. Für den Einstieg in den neuen Chat

Kurz-Prompt-Vorschlag:

> Hey, hier ist der Handover aus dem GLOBAL-RANDOM-Hauptchat für next-global-random [Dokument anhängen]. Aktuelle global-random.html liegt bei [Pfad/Upload]. Lies dich rein, dann bauen wir erstmal die Docker-Testumgebung, bevor irgendwas ans echte System kommt.

---

*Ende Handover.*
