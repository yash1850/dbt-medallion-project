-- silver: clean the customers data
select
    customer_id,
    {{ clean_text('first_name') }} as first_name,
    {{ clean_text('last_name') }} as last_name,
    lower(trim(email)) as email,
    {{ clean_text('city') }} as city,
    created_at as signup_date
from {{ ref('bronze_customers') }}
