-- Q9 (spike check 1/4): Are the January 2025 Navy Federal complaints duplicates?
-- Part 1: exact duplicate IDs. complaint_id is the PRIMARY KEY, so this must be 0.
--   (COUNT(*) - COUNT(DISTINCT complaint_id) is 0 when every ID appears once.)
-- Part 2: near-duplicates: rows identical on every field we have EXCEPT the id.
--   The dataset has no complaint narrative text, so this is the strongest test available.
--   The CTE tags each row with how many rows share its full "fingerprint";
--   the outer query compares Navy Jan 2025 to everything else.
WITH fingerprinted AS (
    SELECT complaint_id, company, date_received,
           COUNT(*) OVER (
               PARTITION BY company, date_received, date_sent, product, sub_product, issue,
                            sub_issue, state, zip_code, tags, submitted_via,
                            company_public_response, company_response, timely_response
           ) AS twins   -- number of rows sharing this exact fingerprint (1 = unique)
    FROM complaints
)
SELECT CASE WHEN company LIKE 'NAVY FEDERAL%' AND date_received LIKE '2025-01%'
            THEN 'Navy Federal, Jan 2025' ELSE 'everything else' END AS grp,
       COUNT(*)                                         AS complaints,
       SUM(twins > 1)                                   AS in_a_twin_group,
       ROUND(100.0 * SUM(twins > 1) / COUNT(*), 2)      AS pct_in_a_twin_group,
       (SELECT COUNT(*) - COUNT(DISTINCT complaint_id) FROM complaints) AS duplicate_ids
FROM fingerprinted
GROUP BY grp;
