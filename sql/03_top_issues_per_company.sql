-- Q3: For each of the 5 biggest companies, what are their top 3 issues?
-- CTE 1 finds the top 5 companies. CTE 2 counts issues per company.
-- ROW_NUMBER() OVER (PARTITION BY company ORDER BY n DESC) ranks issues inside each company.
WITH top_companies AS (
    SELECT company FROM complaints GROUP BY company ORDER BY COUNT(*) DESC LIMIT 5
),
issue_counts AS (
    SELECT c.company, c.issue, COUNT(*) AS n
    FROM complaints c
    JOIN top_companies t ON t.company = c.company   -- INNER JOIN keeps only the top 5
    GROUP BY c.company, c.issue
),
ranked AS (
    SELECT company, issue, n,
           ROW_NUMBER() OVER (PARTITION BY company ORDER BY n DESC) AS rnk
    FROM issue_counts
)
SELECT company, rnk, issue, n
FROM ranked
WHERE rnk <= 3
ORDER BY company, rnk;
