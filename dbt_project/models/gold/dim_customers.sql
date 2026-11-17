-- dimension table: customers
select
    customer_id,
    first_name || ' ' || last_name as full_name,
    email,
    city,
    signup_date
from {{ ref('silver_customers') }}
