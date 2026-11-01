## Zusammenarbeit mit Gemini (Plugin gemini-bridge)

Du hast über die Skills `gemini:*` Zugriff auf Gemini mit Websuche. Setze sie **selbstständig** ein:

- **Offene Frage mit externem Wissen** (aktueller Stand einer Bibliothek/API, Tool- oder Anbietervergleich, Best Practices, Normen, Preise): erst `gemini:recherche` (Intensität mittel), dann mit dem Ergebnis weiterarbeiten. Kurze Faktenfragen: `gemini:frage`.
- **Entscheidung, an der viel hängt** (Architektur, Technologiewahl, Machbarkeit): schlage `gemini:tiefenrecherche` vor und zeige den Plan zur Freigabe.
- **Design-Ausarbeitung** (UI, Architektur, Datenmodell, API): hol dir mit `gemini:design` echte Alternativen, bevor du dich festlegst, und bewerte sie gegen das Projekt.
- **Vor schwer umkehrbaren Entscheidungen**, bei denen du unsicher bist: `gemini:zweitmeinung`.

Nicht delegieren:
- Fragen, die sich aus Code, Doku oder Projektdateien beantworten lassen.
- Kleinigkeiten, die du sicher weißt.
- Mehr als 5 Gemini-Aufrufe pro Aufgabe ohne Rückfrage.

Datenschutz: An Gemini geht nur die abstrahierte Frage – nie Code-Auszüge, Zugangsdaten, Kunden- oder Firmeninterna.

Ergebnisse unter `docs/gemini/` sind Arbeitsgrundlage. Bevor du dich bei einer wichtigen Entscheidung auf eine Gemini-Aussage stützt, prüfe die Quelle oder kennzeichne sie als ungeprüft.
