"""Cleaning functions: raw CFPB CSV row -> row matching the SQLite schema."""
import re
from datetime import datetime


def to_iso_date(value: str) -> str:
    """'2024-01-01T00:45:14.000Z' -> '2024-01-01' (SQLite date functions need this form)."""
    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").strftime("%Y-%m-%d")
    except (ValueError, TypeError) as e:
        raise ValueError(f"bad date: {value!r}") from e


def clean_state(value):
    """Two-letter US state code, uppercased; anything else becomes None (unknown)."""
    if not value:
        return None
    value = value.strip().upper()
    return value if re.fullmatch(r"[A-Z]{2}", value) else None


def yes_no_to_int(value: str) -> int:
    if value == "Yes":
        return 1
    if value == "No":
        return 0
    raise ValueError(f"expected Yes/No, got {value!r}")


def _blank_to_none(value):
    return value if value not in ("", None) else None


def clean_row(raw: dict) -> dict:
    return {
        "complaint_id": int(raw["Complaint ID"]),
        "date_received": to_iso_date(raw["Date received"]),
        "date_sent": to_iso_date(raw["Date sent to company"]),
        "product": raw["Product"],
        "sub_product": _blank_to_none(raw["Sub-product"]),
        "issue": _blank_to_none(raw["Issue"]),
        "sub_issue": _blank_to_none(raw["Sub-issue"]),
        "company": raw["Company"],
        "state": clean_state(raw["State"]),
        "zip_code": _blank_to_none(raw["ZIP code"]),
        "tags": _blank_to_none(raw["Tags"]),
        "submitted_via": raw["Submitted via"],
        "company_public_response": _blank_to_none(raw["Company public response"]),
        "company_response": raw["Company response to consumer"],
        "timely_response": yes_no_to_int(raw["Timely response?"]),
    }
