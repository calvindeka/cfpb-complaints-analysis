-- One row per CFPB complaint. Dates are 'YYYY-MM-DD' text because SQLite
-- has no date type and its date functions (strftime, date) need that form.
CREATE TABLE IF NOT EXISTS complaints (
    complaint_id            INTEGER PRIMARY KEY,   -- unique: a second load fails loudly instead of doubling counts
    date_received           TEXT NOT NULL CHECK (date_received GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
    date_sent               TEXT NOT NULL CHECK (date_sent GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
    product                 TEXT NOT NULL,
    sub_product             TEXT,                  -- NULL = not provided
    issue                   TEXT,
    sub_issue               TEXT,
    company                 TEXT NOT NULL,
    state                   TEXT,                  -- 2-letter code, NULL = unknown
    zip_code                TEXT,                  -- text: keeps leading zeros; many are masked like '441XX'
    tags                    TEXT,
    submitted_via           TEXT NOT NULL,
    company_public_response TEXT,
    company_response        TEXT NOT NULL,
    timely_response         INTEGER NOT NULL CHECK (timely_response IN (0, 1))
);

CREATE INDEX IF NOT EXISTS idx_complaints_date    ON complaints (date_received);
CREATE INDEX IF NOT EXISTS idx_complaints_company ON complaints (company);
CREATE INDEX IF NOT EXISTS idx_complaints_product ON complaints (product);
