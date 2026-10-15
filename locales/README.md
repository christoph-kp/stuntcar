# Texte im Spiel

Godot lädt `en.po` direkt. Die Datei enthält alle festen Texte im Spiel.
Jeder Text hat einen festen Schlüssel mit dem Anfang `I18N_`.
Der Code ruft `tr("I18N_MENU_START")` auf.
Statische Funktionen nutzen `TranslationServer.translate()`.

`project.godot` legt Englisch als Startsprache und Ersatzsprache fest.
Damit erscheint das Spiel auch auf einem deutschen Rechner auf Englisch.
Die Sprache der Spracherkennung bleibt davon unabhängig. Vosk erkennt derzeit Englisch.

## Gespeicherte Einstellungen

Der sichtbare Projektname lautet `Stuntcar`. Der Datenordner behält seinen bisherigen Namen. `application/config/custom_user_dir_name` legt diesen Ordner fest. Ändere ihn nicht mit einer Übersetzung. Sonst findet das Spiel die vorhandenen Einstellungen nicht mehr.

## Texte ändern

Ändere den Wert hinter `msgstr` in `en.po`.
Lass den Schlüssel hinter `msgid` unverändert.
Lass Platzhalter wie `%s`, `%d` und `%%` unverändert.
`\n` erzeugt einen Zeilenumbruch.
Nutze vollständige Sätze. Setze übersetzte Satzteile nicht im Code zusammen.

Die mitgelieferten Strecken speichern Schlüssel für `name` und `description`.
Eigene Strecken können diese Felder weiterhin als normalen Text angeben.
Der Streckenkatalog übersetzt bekannte Schlüssel. Unbekannten Text zeigt er unverändert an.

Das Sprachprogramm sendet Fehlercodes. Godot übersetzt diese Codes.
Bei einem unbekannten Fehler zeigt Godot eine allgemeine Mikrofonmeldung.
Gerätenamen, Dateinamen und gehörte Wörter stammen aus der Laufzeit. Der Katalog enthält sie nicht.

## Eine weitere Sprache ergänzen

Kopiere `en.po`, zum Beispiel nach `de.po`.
Ändere `Language: en` im Kopf der Kopie zu `Language: de`.
Übersetze die Werte hinter `msgstr`.
Füge die neue Datei unter `locale/translations` in `project.godot` hinzu.
Ändere die feste Startsprache unter `locale/test`, wenn das Spiel die andere Sprache anzeigen soll.
Ein Sprachmenü während der Fahrt gehört noch nicht zum Spiel.

## Prüfen

Im Projektordner:

```sh
python3 tests/test_localization_catalog.py
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_i18n_tests.gd
```

Die Prüfung erkennt fehlende Textschlüssel und prüft die Anzeige in den verschiedenen Menüs.
Sie prüft auch Zahlen, Prozentzeichen, eigene Streckennamen und Fehler des Sprachprogramms.

Die Godot-Anleitung beschreibt das Format:
https://docs.godotengine.org/en/4.5/tutorials/i18n/localization_using_gettext.html
