-- Q13 (follow-up to Q9): How big are the "twin" groups (rows identical on every field but the id)?
-- Coincidence among thousands of similar complaints gives many SMALL groups (2-3 rows).
-- A bulk duplicate upload would give a few HUGE groups. We list group sizes for Navy Jan 2025.
-- Two CTEs: one builds each fingerprint group with its size; the other counts how many groups
-- exist at each size.
WITH groups AS (
    SELECT COUNT(*) AS group_size
    FROM complaints
    WHERE company LIKE 'NAVY FEDERAL%' AND date_received LIKE '2025-01%'
    GROUP BY company, date_received, date_sent, product, sub_product, issue, sub_issue,
             state, zip_code, tags, submitted_via, company_public_response,
             company_response, timely_response
)
SELECT group_size,
       COUNT(*)                  AS n_groups,
       COUNT(*) * group_size     AS complaints_covered
FROM groups
GROUP BY group_size
ORDER BY group_size;
