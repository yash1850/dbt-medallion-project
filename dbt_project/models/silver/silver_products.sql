-- silver: clean the products data
select
    product_id,
    {{ clean_text('product_name') }} as product_name,
    {{ clean_text('category') }} as category,
    unit_price
from {{ ref('bronze_products') }}
