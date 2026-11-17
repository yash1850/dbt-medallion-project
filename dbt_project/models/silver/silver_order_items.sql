-- silver: clean the order items data
-- rows with quantity 0 or less are wrong, so we remove them
select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    {{ line_total('quantity', 'unit_price') }} as line_total
from {{ ref('bronze_order_items') }}
where quantity > 0
