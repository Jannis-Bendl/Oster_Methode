In "Paper-List" befinden sich:
  1. "List_Oster_Method_2019-2021.csv", die Paper, welche der Python-Scraper für die Jahre 2019-2021 nach den Maßstäben von Poirer/Masten(2022) finden konnte
  2. "List_Oster_Method_2021-2026.csv", die Paper, welche für den aktuellen Zeitraum gefunden worden sind. Hier wurde bereits auf Verfügbarkeit der Daten und Code geprüft
  3. "next_round.csv", die Liste der Paper, welche potenziell reproduziert werden können
  4. "AEJ_Journals.csv", nur Paper aus den AEJ Journals

In "Reproduction" befinden sich die ersten Replikationspakete der Paper aus "next_round.csv"
Hier wird differenziert, ob es ohne weiteres Möglich war, die Ergebnisse aus den Papers zu reproduzieren. In "Success" sind die Paper aufgeführt, wo dies eben möglich war. Die Reproduzierte Datei befindet sich jeweils in "REPRODUCED".

"multi_source_discovery.py" und "fetch_abstracts.py" bilden zusammen den Python-Scraper. Der Ablauf ist wie folgt:
  1. Ausführen von "multi_source_discovery.py": Es werden alle Paper gesucht, welche den im Skript eingetragenen Kriterien entsprechen. Für diese Liste wird ein Ordner ("data") angelegt.
  2. Falls benötigt kann anschließend "fetch_abstracts.py" ausgeführt werden, um die Liste mit den Abstracts der Paper zu ergänzen
