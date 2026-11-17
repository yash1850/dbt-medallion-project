-- Raw tables (like the tables of a shop app)
create schema raw;

create table raw.customers (
    customer_id int,
    first_name text,
    last_name text,
    email text,
    city text,
    created_at date,
    loaded_at timestamptz default now()
);

create table raw.products (
    product_id int,
    product_name text,
    category text,
    unit_price numeric(10,2),
    loaded_at timestamptz default now()
);

create table raw.orders (
    order_id int,
    customer_id int,
    order_date date,
    status text,
    loaded_at timestamptz default now()
);

create table raw.order_items (
    order_item_id int,
    order_id int,
    product_id int,
    quantity int,
    unit_price numeric(10,2),
    loaded_at timestamptz default now()
);
