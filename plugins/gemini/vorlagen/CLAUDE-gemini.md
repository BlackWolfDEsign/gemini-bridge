## Arbeitsstandard: verifiziert, belegt, vollständig

Dieses Projekt verlangt wissenschaftliche Sorgfalt auf Enterprise-Niveau. Behaupte nichts, was du nicht geprüft hast. Unterscheide immer zwischen **[Beleg]** (geprüft, mit Quelle oder Testergebnis), **[Schlussfolgerung]** (daraus abgeleitet) und **[Annahme]** (ungeprüft). Wenn etwas nicht prüfbar ist, sag das ausdrücklich, statt es zu überspielen.

### 1. Code-Verifizierung
- Code gilt erst als fertig, wenn er ausgeführt bzw. getestet wurde. Tests schreiben oder vorhandene laufen lassen, Ergebnis nennen. „Sollte funktionieren“ ist kein Ergebnis.
- Bevor du eine Bibliotheksfunktion, API, Option oder Konfiguration verwendest, deren Existenz oder Verhalten in der verwendeten Version du nicht sicher kennst: mit `/gemini:frage` gegen die aktuelle offizielle Dokumentation prüfen (Version aus dem Projekt nennen, z. B. aus `package.json`, `pyproject.toml`).
- Bei Architektur- oder Sicherheitsentscheidungen, die schwer rückgängig zu machen sind: vor der Umsetzung `/gemini:zweitmeinung` einholen und die Einwände offen bewerten.

### 2. Informations-Validierung
- Jede externe Faktenaussage (Versionen, Limits, Preise, Standards, Normen, Verhalten fremder Systeme) braucht eine Quelle. Fehlt sie: `/gemini:frage` für Einzelfakten, `/gemini:recherche` (Intensität `mittel`) für Themen mit mehreren Quellen.
- Gemini-Ergebnisse sind Hinweise, keine Wahrheit. Bei Aussagen, auf denen eine Entscheidung ruht: die Primärquelle selbst öffnen oder als ungeprüft kennzeichnen.
- Widersprechen sich Quellen, den Widerspruch benennen statt still eine Seite zu wählen.

### 3. Abgleich mit der Realität
- Dein Trainingswissen kann veraltet sein. Bei allem, was sich ändert (Versionen, deprecated APIs, Sicherheitslücken, Gesetzeslage, Marktstand), den aktuellen Stand per `/gemini:frage` oder `/gemini:recherche` prüfen, bevor du darauf aufbaust.
- Bei Entscheidungen mit großer Tragweite (Technologie- oder Anbieterwahl, Architektur, Machbarkeit, Compliance): `/gemini:tiefenrecherche --tiefe H` vorschlagen. Plan zur Freigabe zeigen, nicht ungefragt starten.
- Annahmen über Nutzer, Daten oder Lastprofile nicht erfinden: aus dem Projekt ableiten, nachfragen oder als [Annahme] markieren.

### 4. Vollständige Logik
- Vor der Umsetzung den vollständigen Ablauf durchdenken: Normalfall, Randfälle, Fehlerfälle, leere/ungültige Eingaben, Nebenläufigkeit, Rechte, Rückwärtskompatibilität.
- Bei nicht-trivialen Plänen die Lücken aktiv suchen. Bei Unsicherheit `/gemini:zweitmeinung` mit der Frage „Welche Fälle und Annahmen fehlen?“.
- Am Ende jeder größeren Aufgabe kurz auflisten: was verifiziert ist, was nicht, und welche Risiken offen bleiben.

### 5. Design-Ausarbeitungen
- Bei neuen Oberflächen, Datenmodellen, APIs oder Systemarchitekturen: mit `/gemini:design` 2–3 echte Alternativen erarbeiten lassen, gegen das Projekt bewerten und die Wahl begründen.
- Gemini den Projektordner nur mit `--mit-projekt` lesen lassen, wenn der Nutzer das ausdrücklich will.

### Grenzen der Delegation
- Nicht delegieren, was sich aus Code, Tests oder Projektdateien beantworten lässt – das prüfst du selbst.
- Höchstens 5 Gemini-Aufrufe pro Aufgabe ohne Rückfrage. `/gemini:tiefenrecherche` und `/gemini:recherche --intensitaet hoch` immer erst nach Freigabe.
- An Gemini geht nur die abstrahierte Frage: nie Code-Auszüge, Zugangsdaten, Schlüssel, Kunden- oder Firmeninterna.
- Ergebnisse liegen unter `docs/gemini/`. Verweise in Antworten und Commits auf den jeweiligen Bericht, wenn eine Entscheidung darauf beruht.
- Schlägt ein Gemini-Aufruf fehl: Meldung weitergeben, bei Anmelde- oder Installationsfehlern auf `/gemini:setup` verweisen, und die Aussage als ungeprüft kennzeichnen statt sie aus dem Gedächtnis zu ergänzen.
