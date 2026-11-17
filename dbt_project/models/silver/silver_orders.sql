-- silver: clean the orders data
select
    order_id,
    customer_id,
    order_date,
    lower(trim(status)) as order_status
from {{ ref('bronze_orders') }}
