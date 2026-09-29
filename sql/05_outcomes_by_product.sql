-- Q5: How do complaints end? Share of each company_response outcome within each product.
-- Window function SUM(COUNT(*)) OVER (PARTITION BY product) gives the product total on every row.
SELECT product,
       company_response,
       COUNT(*)                                                                AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY product), 1)  AS pct_of_product
FROM complaints
GROUP BY product, company_response
ORDER BY product, n DESC;
