-- Fake data for the raw tables.
-- A few rows are dirty on purpose (marked DIRTY) so silver can clean them.

insert into raw.customers (customer_id, first_name, last_name, email, city, created_at) values
 (1, 'Aarav',   'Sharma', 'aarav@example.com',  'Delhi',   '2026-01-10'),
 (2, ' priya ', 'VERMA',  'Priya@Example.com',  'Mumbai',  '2026-02-05'),   -- DIRTY: extra spaces and wrong capital letters
 (3, 'Rohan',   'Gupta',  'rohan@example.com',  'Pune',    '2026-02-20'),
 (4, 'Sneha',   'Singh',  'sneha@example.com',  'Delhi',   '2026-03-15'),
 (5, 'Vikram',  'Patel',  'vikram@example.com', 'Chennai', '2026-04-01'),
 (6, 'Anjali',  'Reddy',  'anjali@example.com', 'Mumbai',  '2026-05-12'),
 (7, 'Karan',   'Iyer',   'karan@example.com',  'Pune',    '2026-06-30'),
 (8, 'Neha',    'Khan',   'neha@example.com',   'Delhi',   '2026-07-18');   -- this customer has no orders

insert into raw.products (product_id, product_name, category, unit_price) values
 (1, 'Laptop',       'Electronics', 55000.00),
 (2, 'Headphones',   'Electronics',  3000.00),
 (3, 'Office Chair', 'Furniture',    7500.00),
 (4, 'Study Desk',   'Furniture',    6000.00),
 (5, 'Notebook Pack','Stationery',    250.00),
 (6, 'Backpack',     'Accessories',  1500.00);

insert into raw.orders (order_id, customer_id, order_date, status) values
 (1,  1, '2026-10-01', 'completed'),
 (2,  2, '2026-10-02', 'completed'),
 (3,  3, '2026-10-03', 'shipped'),
 (4,  4, '2026-10-05', 'completed'),
 (5,  5, '2026-10-06', 'cancelled'),
 (6,  6, '2026-10-08', 'completed'),
 (7,  1, '2026-10-09', '  Completed '),   -- DIRTY: extra spaces and capital C
 (8,  2, '2026-10-11', 'shipped'),
 (9,  3, '2026-10-12', 'completed'),
 (10, 4, '2026-10-14', 'completed'),
 (11, 5, '2026-10-15', 'completed'),
 (12, 6, '2026-10-17', 'cancelled'),
 (13, 7, '2026-10-18', 'completed'),
 (14, 1, '2026-10-20', 'completed'),
 (15, 2, '2026-10-22', 'shipped'),
 (16, 3, '2026-10-24', 'completed'),
 (17, 7, '2026-10-26', 'completed'),
 (18, 4, '2026-10-28', 'completed'),
 (19, 5, '2026-10-30', 'completed'),
 (20, 6, '2026-10-31', 'completed');

insert into raw.order_items (order_item_id, order_id, product_id, quantity, unit_price) values
 (1,  1,  1, 1, 55000.00),
 (2,  1,  2, 1,  3000.00),
 (3,  2,  3, 1,  7500.00),
 (4,  3,  5, 10,  250.00),
 (5,  4,  6, 2,  1500.00),
 (6,  5,  2, 1,  3000.00),
 (7,  6,  4, 1,  6000.00),
 (8,  6,  5, -4,  250.00),    -- DIRTY: negative quantity
 (9,  7,  2, 2,  3000.00),
 (10, 8,  6, 1,  1500.00),
 (11, 9,  1, 1, 55000.00),
 (12, 10, 3, 2,  7500.00),
 (13, 11, 4, 1,  6000.00),
 (14, 11, 5, 5,   250.00),
 (15, 12, 6, 1,  1500.00),
 (16, 13, 2, 1,  3000.00),
 (17, 13, 6, 3,  1500.00),
 (18, 14, 3, 1,  7500.00),
 (19, 15, 5, 8,   250.00),
 (20, 16, 1, 1, 55000.00),
 (21, 17, 4, 2,  6000.00),
 (22, 18, 2, 3,  3000.00),
 (23, 19, 6, 2,  1500.00),
 (24, 20, 3, 1,  7500.00),
 (25, 20, 5, 6,   250.00);
