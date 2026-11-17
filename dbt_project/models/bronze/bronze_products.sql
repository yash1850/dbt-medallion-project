-- bronze: same data as raw, no changes
select * from {{ source('raw', 'products') }}
