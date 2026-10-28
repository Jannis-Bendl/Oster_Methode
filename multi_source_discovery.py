
import json
import os
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

import pandas as pd
import requests

# ============================================================
# CONFIGURATION
# ============================================================

START_YEAR = 2021
END_YEAR = datetime.now().year

TARGET_DOI = "10.1080/07350015.2016.1227711"

JOURNALS = [
    "American Economic Review",
    "Quarterly Journal of Economics",
    "Journal of Political Economy",
    "Econometrica",
    "Review of Economic Studies",
    "American Economic Journal: Applied Economics",
    "American Economic Journal: Economic Policy",
    "American Economic Journal: Macroeconomics",
    "American Economic Journal: Microeconomics",
]

# Optional: Set S2_API_KEY in your environment for Semantic Scholar.
SEMANTIC_SCHOLAR_API_KEY = os.getenv("S2_API_KEY")

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(exist_ok=True)

OUTPUT_FILE = DATA_DIR / "multi_source_papers.csv"
COMPARISON_FILE = DATA_DIR / "source_comparison.csv"
METADATA_FILE = DATA_DIR / "multi_source_metadata.json"

OPENALEX_URL = "https://api.openalex.org"
S2_URL = "https://api.semanticscholar.org/graph/v1"

session = requests.Session()
session.headers.update({"User-Agent": "LiteratureReview/1.0"})

if SEMANTIC_SCHOLAR_API_KEY:
    session.headers["x-api-key"] = SEMANTIC_SCHOLAR_API_KEY


# ============================================================
# COMMON HELPERS
# ============================================================


def api_get(url, params=None, retries=6):
    """
    GET request with exponential backoff.
    Respects Retry-After for HTTP 429 and 5xx responses.
    """
    for attempt in range(retries):
        try:
            response = session.get(
                url,
                params=params,
                timeout=60,
            )

            if response.status_code == 404:
                return None

            if response.status_code == 429 or response.status_code >= 500:
                if attempt == retries - 1:
                    response.raise_for_status()

                retry_after = response.headers.get("Retry-After")

                try:
                    wait = float(retry_after)
                except (TypeError, ValueError):
                    wait = min(5 * (2 ** attempt), 120)

                print(
                    f"HTTP {response.status_code}. "
                    f"Retry {attempt + 2}/{retries} "
                    f"in {wait:.0f} seconds..."
                )
                time.sleep(wait)
                continue

            response.raise_for_status()
            return response.json()

        except requests.RequestException as exc:
            if attempt == retries - 1:
                raise

            wait = min(5 * (2 ** attempt), 120)

            print(
                f"Request error: {exc}. "
                f"Retry {attempt + 2}/{retries} "
                f"in {wait:.0f} seconds..."
            )
            time.sleep(wait)

    return None



def normalize_text(value):
    if not value:
        return ""
    value = value.lower().strip()
    value = re.sub(r"^the\s+", "", value)
    return re.sub(r"[^a-z0-9]", "", value)


def normalize_doi(doi):
    if not doi:
        return ""
    doi = str(doi).strip().lower()
    doi = re.sub(r"^https?://(dx\.)?doi\.org/", "", doi)
    return doi.strip()


def extract_year(value):
    try:
        year = int(value)
        return year if 1000 <= year <= 9999 else None
    except (TypeError, ValueError):
        return None


def journal_matches(name):
    """Exact normalized journal-name match, not substring match."""
    normalized = normalize_text(name)
    return normalized in {
        normalize_text(journal) for journal in JOURNALS
    }


def in_scope(year, venue):
    year = extract_year(year)
    return (
        year is not None
        and START_YEAR <= year <= END_YEAR
        and journal_matches(venue)
    )


def request_json(url, params=None):
    data = api_get(url, params=params)
    if data is None:
        raise ValueError(f"Resource not found: {url}")
    return data


# ============================================================
# OPENALEX
# ============================================================

def resolve_openalex_work(doi):
    doi = normalize_doi(doi)
    url = f"{OPENALEX_URL}/works/https://doi.org/{doi}"
    return request_json(url)


def resolve_openalex_journals():
    """Resolve exact journal names to OpenAlex source IDs."""
    ids = {}

    for journal in JOURNALS:
        data = request_json(
            f"{OPENALEX_URL}/sources",
            params={"search": journal, "per_page": 25},
        )

        matches = [
            source for source in data.get("results", [])
            if source.get("type") == "journal"
            and normalize_text(source.get("display_name", ""))
            == normalize_text(journal)
        ]

        if len(matches) != 1:
            raise ValueError(
                f"Could not uniquely resolve journal: {journal}. "
                "Check the OpenAlex source records before continuing."
            )

        source = matches[0]
        ids[journal] = source["id"].rstrip("/").split("/")[-1]
        print(f"OpenAlex journal: {journal} -> {ids[journal]}")

    return ids


def fetch_openalex(target_id, journal_ids):
    """Retrieve citing works with year and journal filters."""
    target_id = target_id.rstrip("/").split("/")[-1]
    source_filter = "|".join(journal_ids.values())

    filters = (
        f"cites:{target_id},"
        f"publication_year:{START_YEAR}-{END_YEAR},"
        f"primary_location.source.id:{source_filter}"
    )

    cursor = "*"
    rows = []
    reported_count = None

    while cursor:
        data = request_json(
            f"{OPENALEX_URL}/works",
            params={
                "filter": filters,
                "per_page": 100,
                "cursor": cursor,
                "select": (
                    "id,doi,display_name,publication_year,"
                    "publication_date,type,authorships,"
                    "cited_by_count,open_access,primary_location"
                ),
            },
        )

        if reported_count is None:
            reported_count = data.get("meta", {}).get("count")
            print(f"OpenAlex reports {reported_count} matching records.")

        for work in data.get("results", []):
            location = work.get("primary_location") or {}
            source = location.get("source") or {}
            oa = work.get("open_access") or {}

            venue = source.get("display_name")
            year = work.get("publication_year")

            # Defensive local check in addition to API filtering.
            if not in_scope(year, venue):
                continue

            authors = [
                item.get("author", {}).get("display_name")
                for item in work.get("authorships", [])
            ]

            rows.append({
                "openalex_id": work.get("id"),
                "semantic_scholar_id": None,
                "doi": normalize_doi(work.get("doi")),
                "title": work.get("display_name"),
                "year": year,
                "publication_date": work.get("publication_date"),
                "venue": venue,
                "authors": "; ".join(a for a in authors if a),
                "abstract": None,
                "open_access_url": oa.get("oa_url"),
                "openalex_cited_by_count": work.get("cited_by_count"),
                "source_openalex": True,
                "source_semantic_scholar": False,
            })

        print(f"OpenAlex collected: {len(rows)}")
        cursor = data.get("meta", {}).get("next_cursor")

        if not data.get("results"):
            break

        time.sleep(0.1)

    return rows, reported_count, filters


# ============================================================
# SEMANTIC SCHOLAR
# ============================================================

def resolve_s2_work(doi):
    """Resolve a DOI to a Semantic Scholar paper ID."""
    doi = normalize_doi(doi)
    encoded = quote(f"DOI:{doi}", safe=":")

    data = api_get(
        f"{S2_URL}/paper/{encoded}",
        params={"fields": "paperId,title,year,externalIds"},
    )

    if data and data.get("paperId"):
        return data

    # Fallback: search and verify the returned DOI.
    search = request_json(
        f"{S2_URL}/paper/search",
        params={
            "query": doi,
            "limit": 10,
            "fields": "title,year,externalIds",
        },
    )

    for paper in search.get("data", []):
        external_ids = paper.get("externalIds") or {}
        if normalize_doi(external_ids.get("DOI")) == doi:
            return paper

    raise ValueError(
        "Semantic Scholar could not resolve the target DOI. "
        "Check the DOI or retry later."
    )


def extract_s2_venue(paper):
    """Read the journal name from available S2 fields."""
    journal = paper.get("journal")

    if isinstance(journal, dict):
        name = journal.get("name")
        if name:
            return name

    venue = paper.get("venue")
    if isinstance(venue, str):
        return venue

    if isinstance(venue, dict):
        return venue.get("name") or ""

    return ""


def fetch_semantic_scholar(target_id):
    """
    Retrieve citing papers. S2 documents a maximum of 9,999
    citations per paper through this endpoint.
    """
    offset = 0
    limit = 1000
    rows = []
    reported_total = None

    fields = (
        "contexts,isInfluential,citingPaper.title,"
        "citingPaper.year,citingPaper.abstract,"
        "citingPaper.url,citingPaper.venue,"
        "citingPaper.journal,citingPaper.authors,"
        "citingPaper.externalIds,citingPaper.openAccessPdf"
    )

    while True:
        data = request_json(
            f"{S2_URL}/paper/{target_id}/citations",
            params={
                "fields": fields,
                "offset": offset,
                "limit": limit,
            },
        )

        if reported_total is None:
            reported_total = data.get("total")

        batch = data.get("data", [])
        if not batch:
            break

        for entry in batch:
            paper = entry.get("citingPaper") or {}
            external_ids = paper.get("externalIds") or {}
            venue = extract_s2_venue(paper)
            year = paper.get("year")
            print(
                "S2 candidate:",
                paper.get("title"),
                "| Year:", year,
                "| Venue:", repr(venue)
            )

            # Exact journal and year filters.
            if not in_scope(year, venue):
                continue

            authors = paper.get("authors") or []
            pdf = paper.get("openAccessPdf") or {}

            contexts = entry.get("contexts") or []
            intents = entry.get("intents") or []

            rows.append({
                "openalex_id": None,
                "semantic_scholar_id": paper.get("paperId"),
                "doi": normalize_doi(external_ids.get("DOI")),
                "title": paper.get("title"),
                "year": year,
                "publication_date": None,
                "venue": venue,
                "authors": "; ".join(
                    a.get("name", "") for a in authors
                    if a.get("name")
                ),
                "abstract": paper.get("abstract"),
                "open_access_url": pdf.get("url"),
                "semantic_scholar_url": paper.get("url"),
                "semantic_scholar_contexts": json.dumps(
                    contexts, ensure_ascii=False
                ),
                "semantic_scholar_intents": json.dumps(
                    intents, ensure_ascii=False
                ),
                "semantic_scholar_influential": entry.get(
                    "isInfluential"
                ),
                "source_openalex": False,
                "source_semantic_scholar": True,
            })

        next_offset = data.get("next")
        if next_offset is None or next_offset <= offset:
            break

        offset = next_offset
        print(f"Semantic Scholar checked through offset {offset}.")
        time.sleep(1.0 if not SEMANTIC_SCHOLAR_API_KEY else 0.2)

        # S2 citation endpoint limit documented by the provider.
        if offset >= 9999:
            break

    return rows, reported_total


# ============================================================
# DEDUPLICATION AND COMPARISON
# ============================================================

def make_key(row):
    """Prefer DOI; fall back to normalized title and year."""
    doi = normalize_doi(row.get("doi"))
    if doi:
        return f"doi:{doi}"

    title = normalize_text(row.get("title"))
    year = extract_year(row.get("year"))

    if title and year:
        return f"title_year:{title}:{year}"

    if title:
        return f"title:{title}"

    # Avoid merging unrelated records with missing identifiers.
    return (
        f"source_id:{row.get('openalex_id') or ''}:"
        f"{row.get('semantic_scholar_id') or ''}"
    )


def merge_records(records):
    merged = {}

    for row in records:
        key = make_key(row)

        if key not in merged:
            merged[key] = dict(row)
            merged[key]["match_key"] = key
            continue

        existing = merged[key]

        # Keep source provenance from both databases.
        existing["source_openalex"] = bool(
            existing.get("source_openalex")
            or row.get("source_openalex")
        )
        existing["source_semantic_scholar"] = bool(
            existing.get("source_semantic_scholar")
            or row.get("source_semantic_scholar")
        )

        # Fill missing fields without overwriting existing values.
        for field, value in row.items():
            old = existing.get(field)

            missing = old is None or (
                isinstance(old, float) and pd.isna(old)
            ) or old == ""

            if missing and value is not None and value != "":
                existing[field] = value

        existing["match_key"] = key

    return list(merged.values())


def main():
    if START_YEAR > END_YEAR:
        raise ValueError("START_YEAR must not exceed END_YEAR.")

    print("=" * 60)
    print("MULTI-SOURCE LITERATURE DISCOVERY")
    print(f"Years: {START_YEAR}-{END_YEAR}")
    print("Journals:", ", ".join(JOURNALS))
    print("=" * 60)

    # Resolve the original publication.
    target = resolve_openalex_work(TARGET_DOI)
    print("\nTarget:", target.get("display_name"))
    print("DOI:", target.get("doi"))
    print("OpenAlex ID:", target.get("id"))

    journal_ids = resolve_openalex_journals()

    openalex_rows, openalex_count, openalex_filter = fetch_openalex(
        target["id"], journal_ids
    )

    s2_rows = []
    s2_count = None
    s2_error = None
    s2_target_id = None

    try:
        s2_target = resolve_s2_work(TARGET_DOI)
        s2_target_id = s2_target["paperId"]
        print("\nSemantic Scholar target:", s2_target_id)

        s2_rows, s2_count = fetch_semantic_scholar(s2_target_id)
        print("Semantic Scholar reported total:", s2_count)
        print("Semantic Scholar filtered records:", len(s2_rows))
        print("Semantic Scholar target ID:", s2_target_id)

    except Exception as exc:
        s2_error = str(exc)
        print("\nSemantic Scholar retrieval failed:", s2_error)
        print("OpenAlex results will still be exported.")

    all_records = openalex_rows + s2_rows
    merged_records = merge_records(all_records)

    df = pd.DataFrame(merged_records)

    if not df.empty:
        df["year"] = pd.to_numeric(df["year"], errors="coerce")
        df = df.sort_values(
            ["year", "title"], ascending=[True, True],
            na_position="last"
        )

        df["sources"] = df.apply(
            lambda row: "; ".join(
                source for source, enabled in [
                    ("OpenAlex", row.get("source_openalex")),
                    ("Semantic Scholar", row.get("source_semantic_scholar")),
                ] if bool(enabled)
            ),
            axis=1,
        )

    df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8-sig")

    # Source overlap table.
    comparison_rows = [
        {
            "category": "OpenAlex only",
            "papers": sum(
                bool(r.get("source_openalex"))
                and not bool(r.get("source_semantic_scholar"))
                for r in merged_records
            ),
        },
        {
            "category": "Semantic Scholar only",
            "papers": sum(
                bool(r.get("source_semantic_scholar"))
                and not bool(r.get("source_openalex"))
                for r in merged_records
            ),
        },
        {
            "category": "Both sources",
            "papers": sum(
                bool(r.get("source_openalex"))
                and bool(r.get("source_semantic_scholar"))
                for r in merged_records
            ),
        },
        {
            "category": "Unique combined records",
            "papers": len(merged_records),
        },
    ]

    pd.DataFrame(comparison_rows).to_csv(
        COMPARISON_FILE, index=False, encoding="utf-8-sig"
    )

    metadata = {
        "retrieved_at_utc": datetime.now(
            timezone.utc
        ).isoformat(),
        "target_doi": normalize_doi(TARGET_DOI),
        "target_title": target.get("display_name"),
        "start_year": START_YEAR,
        "end_year": END_YEAR,
        "journals": JOURNALS,
        "openalex_journal_ids": journal_ids,
        "openalex_api_filter": openalex_filter,
        "openalex_reported_count": openalex_count,
        "openalex_filtered_records": len(openalex_rows),
        "semantic_scholar_target_id": s2_target_id,
        "semantic_scholar_reported_count": s2_count,
        "semantic_scholar_filtered_records": len(s2_rows),
        "semantic_scholar_error": s2_error,
        "combined_records_before_deduplication": len(all_records),
        "combined_unique_records": len(merged_records),
        "deduplication": (
            "Normalized DOI; otherwise normalized title + year; "
            "title alone if year is missing"
        ),
        "semantic_scholar_api_key_configured": bool(
            SEMANTIC_SCHOLAR_API_KEY
        ),
        "outputs": [
            str(OUTPUT_FILE),
            str(COMPARISON_FILE),
            str(METADATA_FILE),
        ],
    }

    METADATA_FILE.write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print("\n" + "=" * 60)
    print("DISCOVERY COMPLETED")
    print(f"OpenAlex records: {len(openalex_rows)}")
    print(f"Semantic Scholar records: {len(s2_rows)}")
    print(f"Unique combined records: {len(merged_records)}")
    print(f"Results: {OUTPUT_FILE}")
    print(f"Comparison: {COMPARISON_FILE}")
    print(f"Metadata: {METADATA_FILE}")
    print("=" * 60)


if __name__ == "__main__":
    main()
