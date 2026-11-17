-- dimension table: products
select
    product_id,
    product_name,
    category,
    unit_price
from {{ ref('silver_products') }}
