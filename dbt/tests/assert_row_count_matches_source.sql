-- Fails (returns a row) if the fact table lost or duplicated complaints.
select (select count(*) from {{ source('raw', 'complaints') }}) as source_rows,
       (select count(*) from {{ ref('fct_complaints') }})       as fact_rows
where source_rows != fact_rows
