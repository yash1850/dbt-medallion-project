-- SQL queries on the gold tables
-- revenue means line_total of orders that are not cancelled

-- AGGREGATIONS

-- 1. total orders, units and revenue
select
    count(distinct order_id) as total_orders,
    sum(quantity) as total_units,
    sum(line_total) as total_revenue,
    avg(line_total) as avg_line_total
from public_gold.fact_order_items
where order_status <> 'cancelled';

-- 2. number of orders for each status
select order_status, count(distinct order_id) as total_orders
from public_gold.fact_order_items
group by order_status;

-- JOINS

-- 3. revenue for each category
select p.category, sum(f.line_total) as revenue
from public_gold.fact_order_items f
join public_gold.dim_products p on f.product_id = p.product_id
where f.order_status <> 'cancelled'
group by p.category
order by revenue desc;

-- 4. revenue for each city
select c.city, sum(f.line_total) as revenue
from public_gold.fact_order_items f
join public_gold.dim_customers c on f.customer_id = c.customer_id
where f.order_status <> 'cancelled'
group by c.city
order by revenue desc;

-- SUBQUERIES

-- 5. customers who spent more than the average customer
select c.full_name, sum(f.line_total) as total_spent
from public_gold.fact_order_items f
join public_gold.dim_customers c on f.customer_id = c.customer_id
where f.order_status <> 'cancelled'
group by c.full_name
having sum(f.line_total) > (
    select sum(line_total) / count(distinct customer_id)
    from public_gold.fact_order_items
    where order_status <> 'cancelled'
)
order by total_spent desc;

-- 6. customers who never ordered anything
select customer_id, full_name, city
from public_gold.dim_customers
where customer_id not in (select customer_id from public_gold.fact_order_items);
