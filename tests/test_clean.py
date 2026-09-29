import pytest

from src.clean import to_iso_date, clean_state, yes_no_to_int, clean_row


def test_to_iso_date_trims_timestamp():
    assert to_iso_date("2024-01-01T00:45:14.000Z") == "2024-01-01"


def test_to_iso_date_rejects_garbage():
    with pytest.raises(ValueError):
        to_iso_date("not a date")


def test_clean_state_uppercases_and_blanks_become_none():
    assert clean_state("oh") == "OH"
    assert clean_state("") is None
    assert clean_state(None) is None


def test_clean_state_rejects_non_two_letter_codes():
    assert clean_state("Ohio") is None


def test_yes_no_to_int():
    assert yes_no_to_int("Yes") == 1
    assert yes_no_to_int("No") == 0
    with pytest.raises(ValueError):
        yes_no_to_int("Maybe")


def test_clean_row_maps_raw_columns_to_schema():
    raw = {
        "Complaint ID": "123", "Date received": "2024-02-03T00:00:00.000Z",
        "Date sent to company": "2024-02-05T00:00:00.000Z",
        "Product": "Mortgage", "Sub-product": "", "Issue": "Closing on a mortgage",
        "Sub-issue": "", "Company": "ACME BANK", "State": "oh", "ZIP code": "44022",
        "Tags": "Older American", "Submitted via": "Web",
        "Company public response": "", "Company response to consumer": "Closed with explanation",
        "Timely response?": "Yes",
    }
    row = clean_row(raw)
    assert row["complaint_id"] == 123
    assert row["date_received"] == "2024-02-03"
    assert row["date_sent"] == "2024-02-05"
    assert row["state"] == "OH"
    assert row["timely_response"] == 1
    assert row["sub_product"] is None
