-- Fact table: one row per complaint, the grain the semantic model is built on.
select
    c.complaint_id,
    c.date_received,
    c.month_received,
    c.product,
    c.sub_product,
    c.issue,
    c.company,
    d.size_band                                     as company_size_band,
    c.state,
    c.submitted_via,
    c.tags,
    c.company_response,
    c.days_to_company,
    cast(c.is_monetary_relief as integer)           as is_monetary_relief,
    cast(c.is_non_monetary_relief as integer)       as is_non_monetary_relief,
    cast(c.has_final_outcome as integer)            as has_final_outcome,
    cast(c.is_timely as integer)                    as is_timely,
    c.is_credit_bureau
from {{ ref('stg_complaints') }} c
left join {{ ref('dim_companies') }} d using (company)
