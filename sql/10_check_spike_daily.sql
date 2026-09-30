-- Q10 (spike check 2/4): Is the spike spread across days, or one or two bulk dates?
-- Daily complaints Dec 2024 - Feb 2025 for Navy Federal, Capital One, and all other companies.
-- SUM(condition) counts rows where the condition is true (0/1 trick).
SELECT date_received AS day,
       SUM(company LIKE 'NAVY FEDERAL%')                                   AS navy_federal,
       SUM(company LIKE 'CAPITAL ONE%')                                    AS capital_one,
       SUM(company NOT LIKE 'NAVY FEDERAL%' AND company NOT LIKE 'CAPITAL ONE%') AS all_others,
       COUNT(*)                                                            AS total
FROM complaints
WHERE date_received BETWEEN '2024-12-01' AND '2025-02-28'
GROUP BY date_received
ORDER BY date_received;
