-- Adds 3 new orders (a new day of data) to test the incremental model.
insert into raw.orders (order_id, customer_id, order_date, status) values
 (21, 3, '2026-11-01', 'completed'),
 (22, 7, '2026-11-02', 'shipped'),
 (23, 1, '2026-11-02', 'completed');

insert into raw.order_items (order_item_id, order_id, product_id, quantity, unit_price) values
 (26, 21, 1, 1, 55000.00),
 (27, 21, 2, 2,  3000.00),
 (28, 22, 3, 1,  7500.00),
 (29, 23, 5, 5,   250.00),
 (30, 23, 6, 1,  1500.00);
