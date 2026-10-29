-- Relief rate by product and issue: the pattern the R model picks up
-- (fee and purchase disputes end in monetary relief far more often).
select
    product,
    issue,
    count(*)                                                        as complaints,
    sum(has_final_outcome)                                          as final_outcomes,
    round(100.0 * sum(is_monetary_relief) / nullif(sum(has_final_outcome), 0), 2) as monetary_relief_pct
from {{ ref('fct_complaints') }}
group by product, issue
having count(*) >= 200
