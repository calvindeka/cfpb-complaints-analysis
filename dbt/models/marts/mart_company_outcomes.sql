-- Outcome rates per company, limited to companies with 100+ complaints so
-- rates are not driven by a handful of cases. Rates use final outcomes only.
select
    f.company,
    d.size_band,
    d.is_credit_bureau,
    count(*)                                                        as complaints,
    sum(f.has_final_outcome)                                        as final_outcomes,
    round(100.0 * sum(f.is_monetary_relief) / nullif(sum(f.has_final_outcome), 0), 2) as monetary_relief_pct,
    round(100.0 * sum(f.is_non_monetary_relief) / nullif(sum(f.has_final_outcome), 0), 2) as non_monetary_relief_pct,
    round(100.0 * avg(f.is_timely), 2)                              as timely_pct
from {{ ref('fct_complaints') }} f
join {{ ref('dim_companies') }} d using (company)
group by f.company, d.size_band, d.is_credit_bureau
having count(*) >= 100
