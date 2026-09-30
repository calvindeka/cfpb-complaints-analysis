-- Q14: Modeling table for "which complaints end in monetary relief?" (used by r/model.R).
--
-- OUTCOME: relief = 1 if company_response = 'Closed with monetary relief', else 0.
-- Two rows are dropped because the outcome isn't final: 'In progress' (2) and
-- 'Untimely response' (405) -- the company hadn't (properly) responded.
--
-- FEATURES: only what is known when the consumer FILES the complaint:
--   product, sub_product, issue, state, channel (submitted_via), tags, month, and a
--   company-size proxy (how many complaints the company had in 2024).
--
-- DELIBERATELY LEFT OUT (would leak the outcome or identify the row):
--   company_response      -- this IS the outcome
--   company_public_response, timely_response, date_sent -- set only AFTER the company responds
--   complaint_id, company, zip_code -- identifiers / very high-cardinality; company size is
--                                      captured by company_volume_2024 instead
--
-- company_volume_2024 is a LEFT JOIN so companies with no 2024 complaints get 0 (COALESCE).
WITH vol AS (
    SELECT company, COUNT(*) AS company_volume_2024
    FROM complaints
    WHERE date_received < '2025-01-01'
    GROUP BY company
)
SELECT CAST(substr(c.date_received, 1, 4) AS INTEGER)  AS year,
       CAST(substr(c.date_received, 6, 2) AS INTEGER)  AS month,
       c.product,
       COALESCE(c.sub_product, 'Unknown')              AS sub_product,
       COALESCE(c.issue, 'Unknown')                    AS issue,
       COALESCE(c.state, 'Unknown')                    AS state,
       c.submitted_via,
       COALESCE(c.tags, 'None')                        AS tags,
       COALESCE(v.company_volume_2024, 0)              AS company_volume_2024,
       (c.company_response = 'Closed with monetary relief') AS relief
FROM complaints c
LEFT JOIN vol v ON v.company = c.company
WHERE c.company_response NOT IN ('In progress', 'Untimely response');
