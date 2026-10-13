<?php

/**
 * GLOBAL RANDOM — eigener Ziehungs-Endpunkt
 *
 * Ersetzt die MusicBrainz-Suche (ws/2/url?query=open.spotify.com/track) als
 * Quelle für mbRandomSearch(). Grund: MusicBrainz beantwortet Suchanfragen
 * nur noch bis offset+limit <= 500 (siehe HANDOVER/Memory), der erreichbare
 * Pool dort ist praktisch auf ~500 Titel geschrumpft. Diese Datei zieht
 * stattdessen aus einer eigenen Tabelle (gr_tracks), gebaut aus einem
 * MusicBrainz-Datenbank-Spiegel (Stand siehe gr_tracks selbst, kein Live-
 * Abgleich). Dieselbe Datenbank wie der Joomla-Download-Zähler, eigene
 * Tabellen mit gr_-Präfix, keine Berührung mit den jos_-Tabellen.
 *
 * Fairness: zuerst ein Land GLEICHVERTEILT unter allen Ländern mit
 * mindestens einem Titel ziehen, danach zufällige Titel aus genau diesem
 * Land. Das entspricht demselben Fairness-Prinzip wie die bisherige
 * Länder-Pool-Logik in global-random.html — kein Land wird durch die
 * schiere Menge seiner Titel bevorzugt.
 *
 * Antwortform bewusst nah an dem gehalten, was mbRandomSearch() bisher aus
 * MusicBrainz baute (Liste von {id, title, artist, country}), damit
 * discoverCandidates()/loadMeta() in global-random.html mit minimalen
 * Änderungen auskommen.
 *
 * Statistik (gr_country_stats): zählt nur, aus welchem LAND die gezogenen
 * TITEL stammen — das ist eine Aussage über den Inhalt, nicht über die
 * Hörer. Eine echte Herkunfts-Statistik der NUTZER (per IP -> Land, IP
 * selbst nie gespeichert) ist vorbereitet, aber noch nicht angeschlossen —
 * dafür fehlt noch die MaxMind-GeoLite2-Country-Datei samt Lizenzschlüssel
 * (siehe Projektnotizen). TODO sobald vorhanden: resolveVisitorCountry()
 * unten ausfüllen.
 */

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
/* Open on purpose: public, non-sensitive music metadata (Spotify ID,
   title, artist, country), nothing per-user. Needed because the Nextcloud
   deployment (a different host entirely) calls this genuinely cross-
   origin — see global-random.html's _grApiBase() comment. */
header('Access-Control-Allow-Origin: *');

require __DIR__ . '/../joomla/configuration.php';
$config = new JConfig();

// host kann "host:port" enthalten (wie in configuration.php), mysqli will das getrennt
$hostParts = explode(':', $config->host, 2);
$dbHost = $hostParts[0];
$dbPort = isset($hostParts[1]) ? (int) $hostParts[1] : 3306;

$mysqli = @mysqli_connect($dbHost, $config->user, $config->password, $config->db, $dbPort);

if (!$mysqli) {
    http_response_code(503);
    echo json_encode(['error' => 'db unreachable']);
    exit;
}
$mysqli->set_charset('utf8mb4');

/* Default dropped from 9 to 1 (13.10.2026): discoverCandidates()'s own
   per-batch dedup only ever accepts the FIRST of a batch anyway (max 1
   candidate per country per batch, see global-random.html), and all N
   rows from one call share the same country — so every call past the
   first inside a batch gets skipped on arrival, and the abandon-after-
   3-consecutive-skips logic throws the rest away unused well before N=9
   is ever exhausted. One row per request does the same job with less
   DB sorting work (ORDER BY RAND() over fewer wasted rows), same
   request count either way. ?n= still accepted for anyone who wants a
   bigger batch for some other purpose. */
$n = isset($_GET['n']) ? max(1, min(25, (int) $_GET['n'])) : 1;

/* TODO (wartet auf MaxMind-Lizenzschlüssel): liest die Besucher-IP NUR
   innerhalb dieser Funktion, gibt ausschließlich den ISO-Ländercode zurück,
   die IP selbst wird nirgends geloggt oder zurückgegeben. */
function resolveVisitorCountry(): ?string
{
    return null; // noch nicht angeschlossen
}

// 1) Ein Land gleichverteilt unter allen vorhandenen Ländern ziehen
$countryResult = $mysqli->query('SELECT DISTINCT country FROM gr_tracks');
$countries = [];
while ($row = $countryResult->fetch_row()) {
    $countries[] = $row[0];
}
if (!$countries) {
    http_response_code(500);
    echo json_encode(['error' => 'no data']);
    exit;
}
$country = $countries[array_rand($countries)];

// 2) Zufällige Titel aus genau diesem Land
$stmt = $mysqli->prepare(
    'SELECT spotify_id, title, artist, country FROM gr_tracks WHERE country = ? ORDER BY RAND() LIMIT ?'
);
$stmt->bind_param('si', $country, $n);
$stmt->execute();
$res = $stmt->get_result();

$tracks = [];
while ($row = $res->fetch_assoc()) {
    $tracks[] = [
        'id' => $row['spotify_id'],
        'title' => $row['title'],
        'artist' => $row['artist'],
        'country' => $row['country'],
    ];
}

// 3) Inhalts-Statistik: welches Land wurde gezogen (kein Bezug zum Hörer)
try {
    $stat = $mysqli->prepare(
        'INSERT INTO gr_country_stats (country, hits) VALUES (?, 1)
         ON DUPLICATE KEY UPDATE hits = hits + 1'
    );
    $stat->bind_param('s', $country);
    $stat->execute();
} catch (\Throwable $e) {
    // Statistik ist best-effort, darf die Ziehung nie verhindern
}

echo json_encode($tracks, JSON_UNESCAPED_UNICODE);
