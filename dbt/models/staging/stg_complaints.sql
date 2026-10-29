-- Staging: one row per complaint with proper types and derived flags.
-- No filtering here, so row counts can be reconciled with the source.
with source as (
    select * from {{ source('raw', 'complaints') }}
)

select
    complaint_id,
    cast(date_received as date)                         as date_received,
    cast(date_sent as date)                             as date_sent,
    date_diff('day', cast(date_received as date), cast(date_sent as date)) as days_to_company,
    date_trunc('month', cast(date_received as date))    as month_received,
    product,
    coalesce(sub_product, 'Not provided')               as sub_product,
    coalesce(issue, 'Not provided')                     as issue,
    company,
    state,
    submitted_via,
    coalesce(tags, 'None')                              as tags,
    company_response,
    company_response = 'Closed with monetary relief'    as is_monetary_relief,
    company_response = 'Closed with non-monetary relief' as is_non_monetary_relief,
    -- 'In progress' and 'Untimely response' have no final outcome yet
    company_response not in ('In progress', 'Untimely response') as has_final_outcome,
    timely_response = 1                                 as is_timely,
    -- Credit bureaus appear under these bank products (README limitation)
    company in (
        'EQUIFAX, INC.',
        'TRANSUNION INTERMEDIATE HOLDINGS, INC.',
        'Experian Information Solutions Inc.'
    )                                                   as is_credit_bureau
from source
