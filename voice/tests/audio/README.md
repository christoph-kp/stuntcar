# Künstliche Sprachproben

Diese Dateien enthalten ausschließlich künstlich erzeugte Sprache. Sie enthalten keine Mikrofonaufnahmen.

Die Stimmen Anna und Samantha aus macOS sprechen die Wörter mit 150 Wörtern pro Minute. Die Dateien nutzen einen Kanal, 16 kHz und 16 Bit.

`manifest.json` nennt das gesprochene Wort und den erwarteten Befehl. Ein leerer erwarteter Befehl bedeutet: Das Spiel darf nichts tun.

Die Prüfungen nutzen auch die laufende Erkennung des Mikrofons. Sie ersetzen keinen Test mit Stefans Stimme.

Der Unterordner `continuous` enthält ganze Wortfolgen. Anna und Samantha sprechen fünf schnelle Wiederholungen mit 200 Wörtern pro Minute. `mixed.wav` enthält „links links rechts rechts links“. `links-fast.wav` nutzt 280 Wörter pro Minute. `links-long.wav` enthält 15 Wiederholungen. Die Dateien enthalten keine eingefügten Pausen zwischen den Wörtern.

Die Dateien `schneller-five`, `langsamer-five`, `faster-five` und `slower-five` enthalten jeweils fünf Tempobefehle. `speed-mixed` enthält „schneller schneller langsamer langsamer“ mit 200 Wörtern pro Minute. `speed-fast` enthält dieselbe Folge mit 280 Wörtern pro Minute. Alle Dateien nutzen dieselben künstlichen Stimmen.

Der Unterordner `english` enthält zusätzliche englische Prüfungen. Samantha spricht diese Wörter und Sätze mit 150 Wörtern pro Minute. Die Datei `english/manifest.json` nennt die erwarteten Befehle. Verneinungen und fremde Sätze dürfen keinen Befehl auslösen.
