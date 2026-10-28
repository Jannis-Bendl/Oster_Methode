
import csv
import os
import re
import time
import requests
from pathlib import Path
from urllib.parse import quote

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

INPUT_FILE = DATA_DIR / "multi_source_papers.csv"
OUTPUT_FILE = DATA_DIR / "papers_with_abstracts.csv"

S2_API_KEY = os.getenv("S2_API_KEY")

session = requests.Session()
session.headers.update({"User-Agent": "LiteratureReview/1.0"})
if S2_API_KEY:
    session.headers["x-api-key"] = S2_API_KEY


def find_column(fields, candidates):
    def norm(s):
        return re.sub(r"[^a-z0-9]", "", s.lower())

    lookup = {norm(f): f for f in fields}
    for candidate in candidates:
        if norm(candidate) in lookup:
            return lookup[norm(candidate)]
    return None


def clean_doi(value):
    value = (value or "").strip()
    value = re.sub(r"^https?://doi\.org/", "", value, flags=re.I)
    value = re.sub(r"^doi:\s*", "", value, flags=re.I)
    return value.strip()


def normalize_title(value):
    return re.sub(r"\W+", "", (value or "").lower())


def reconstruct_openalex_abstract(inverted_index):
    """Rekonstruiert OpenAlex' positionsbasiertes Abstract."""
    if not isinstance(inverted_index, dict):
        return ""

    words = []
    for word, positions in inverted_index.items():
        for position in positions:
            words.append((position, word))

    words.sort(key=lambda item: item[0])
    return " ".join(word for _, word in words)


def get_json(url, params=None, attempts=3):
    for attempt in range(attempts):
        try:
            response = session.get(
                url, params=params, timeout=25
            )

            if response.status_code == 404:
                return None

            if response.status_code == 429:
                wait = min(15 * (attempt + 1), 45)
                print(f"  Rate limit; warte {wait} Sekunden.")
                time.sleep(wait)
                continue

            response.raise_for_status()
            return response.json()

        except requests.RequestException as exc:
            print(f"  Anfrage fehlgeschlagen: {exc}")
            if attempt < attempts - 1:
                time.sleep(3 * (attempt + 1))

    return None


def find_openalex_abstract(doi, title):
    data = None

    if doi:
        data = get_json(
            "https://api.openalex.org/works",
            params={
                "filter": f"doi:https://doi.org/{doi}",
                "per-page": 1,
            },
        )

        results = data.get("results", []) if data else []
        if results:
            abstract = reconstruct_openalex_abstract(
                results[0].get("abstract_inverted_index")
            )
            if abstract:
                return abstract, "OpenAlex"

    # Fallback: Suche über den Titel
    if title:
        data = get_json(
            "https://api.openalex.org/works",
            params={"search": title, "per-page": 5},
        )

        results = data.get("results", []) if data else []
        target = normalize_title(title)

        for item in results:
            if normalize_title(item.get("title")) == target:
                abstract = reconstruct_openalex_abstract(
                    item.get("abstract_inverted_index")
                )
                if abstract:
                    return abstract, "OpenAlex (Titelsuche)"

    return "", ""


def find_semantic_scholar_abstract(doi, title):
    paper = None

    if doi:
        paper = get_json(
            "https://api.semanticscholar.org/graph/v1/paper/"
            + "DOI:" + quote(doi, safe=""),
            params={"fields": "title,abstract,year,externalIds"},
        )

    if not paper or not paper.get("abstract"):
        if title:
            data = get_json(
                "https://api.semanticscholar.org/graph/v1/paper/search",
                params={
                    "query": title,
                    "limit": 5,
                    "fields": "title,abstract,year,externalIds",
                },
            )

            target = normalize_title(title)
            for item in (data or {}).get("data", []):
                if normalize_title(item.get("title")) == target:
                    paper = item
                    break

    if paper and paper.get("abstract"):
        return paper["abstract"], "Semantic Scholar"

    return "", ""


if not INPUT_FILE.exists():
    raise FileNotFoundError(
        f"Datei nicht gefunden: {INPUT_FILE}"
    )

with INPUT_FILE.open(
    "r", encoding="utf-8-sig", newline=""
) as file:
    reader = csv.DictReader(file)
    rows = list(reader)
    fields = reader.fieldnames or []

if not rows:
    raise ValueError("Die Eingabe-CSV enthält keine Paper.")

title_col = find_column(
    fields, ["title", "paper_title", "name"]
)
doi_col = find_column(fields, ["doi", "paper_doi"])
abstract_col = find_column(
    fields, ["abstract", "abstract_text", "summary"]
)

if not title_col:
    raise ValueError(
        f"Titelspalte nicht gefunden. Vorhanden: {fields}"
    )

# Fehlende Abstract-Spalte bei Bedarf ergänzen
if not abstract_col:
    abstract_col = "abstract"
    fields.append(abstract_col)

for column in ["abstract_source", "abstract_status"]:
    if column not in fields:
        fields.append(column)

found = 0
missing = 0
already_present = 0

for number, row in enumerate(rows, start=1):
    title = row.get(title_col, "")
    doi = clean_doi(row.get(doi_col, "")) if doi_col else ""
    abstract = (row.get(abstract_col) or "").strip()

    if abstract:
        row["abstract_status"] = "Bereits vorhanden"
        row.setdefault("abstract_source", "")
        already_present += 1
        continue

    print(f"[{number}/{len(rows)}] {title}")

    abstract, source = find_openalex_abstract(doi, title)

    if not abstract:
        # Semantic Scholar langsamer abfragen
        time.sleep(2)
        abstract, source = find_semantic_scholar_abstract(
            doi, title
        )

    if abstract:
        row[abstract_col] = abstract
        row["abstract_source"] = source
        row["abstract_status"] = "Gefunden"
        found += 1
        print(f"  Abstract gefunden: {source}")
    else:
        row["abstract_source"] = ""
        row["abstract_status"] = "Nicht gefunden"
        missing += 1
        print("  Kein Abstract gefunden.")

    time.sleep(1)

DATA_DIR.mkdir(parents=True, exist_ok=True)

with OUTPUT_FILE.open(
    "w", encoding="utf-8-sig", newline=""
) as file:
    writer = csv.DictWriter(
        file, fieldnames=fields, extrasaction="ignore"
    )
    writer.writeheader()
    writer.writerows(rows)

print("\nABGESCHLOSSEN")
print(f"Paper insgesamt:       {len(rows)}")
print(f"Bereits mit Abstract:  {already_present}")
print(f"Neu gefunden:          {found}")
print(f"Nicht gefunden:        {missing}")
print(f"Ergebnis: {OUTPUT_FILE}")
