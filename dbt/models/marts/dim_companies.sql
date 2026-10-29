-- One row per company with lifetime volume and a size band for slicing.
select
    company,
    bool_or(is_credit_bureau)                       as is_credit_bureau,
    count(*)                                        as total_complaints,
    min(date_received)                              as first_complaint_date,
    max(date_received)                              as last_complaint_date,
    case
        when count(*) >= 10000 then 'Large (10,000+)'
        when count(*) >= 1000  then 'Mid (1,000-9,999)'
        when count(*) >= 100   then 'Small (100-999)'
        else 'Very small (<100)'
    end                                             as size_band
from {{ ref('stg_complaints') }}
group by company
