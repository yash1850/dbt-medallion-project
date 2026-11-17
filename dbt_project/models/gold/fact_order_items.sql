-- fact table: one row for each order item
-- it is incremental, so after the first run only new rows are added
{{ config(materialized='incremental', unique_key='order_item_id') }}

select
    oi.order_item_id,
    oi.order_id,
    o.customer_id,
    oi.product_id,
    o.order_date,
    o.order_status,
    oi.quantity,
    oi.unit_price,
    oi.line_total
from {{ ref('silver_order_items') }} oi
join {{ ref('silver_orders') }} o on oi.order_id = o.order_id

{% if is_incremental() %}
    {% if var('backfill_date', '') != '' %}
        -- backfill: take all orders from the given date
        where o.order_date >= '{{ var("backfill_date") }}'
    {% else %}
        -- normal run: take orders from the latest date already in the table
        where o.order_date >= (select max(order_date) from {{ this }})
    {% endif %}
{% endif %}
