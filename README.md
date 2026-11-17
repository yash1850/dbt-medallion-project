# Shop Analytics Project (PostgreSQL + dbt)

In this project I take raw data of a small shop, load it in PostgreSQL, clean it using dbt in 3 layers (bronze, silver, gold) and then write SQL queries on the final tables.

## Tools used
- PostgreSQL (database)
- Docker (to run PostgreSQL)
- dbt (to transform the data)
- Python venv (to install dbt)
- Git (version control)

## Folder structure
```
docker-compose.yml        runs PostgreSQL in Docker
init/                     creates raw tables and inserts fake data
scripts/                  sql file to add new orders (to test incremental model)
queries/analysis.sql      my SQL queries
dbt_project/              the dbt project
    macros/               2 macros
    models/bronze         bronze models + sources
    models/silver         silver models
    models/gold           dimension and fact tables
```

## Data lifecycle
```
raw tables  ->  bronze  ->  silver  ->  gold  ->  SQL queries
```
1. **Raw**: 4 tables (customers, products, orders, order_items) like a shop app database. Some rows are dirty on purpose (extra spaces, wrong capital letters, negative quantity).
2. **Bronze**: same data as raw, no changes (views).
3. **Silver**: cleaned data. Spaces and capitals are fixed and the negative quantity row is removed. line_total is calculated.
4. **Gold**: final tables for analysis (star schema).
5. **Analytics**: SQL queries run on the gold tables.

This is ELT. Data is loaded first and then transformed inside the database using dbt.

## Data model (star schema)
```
   dim_customers                    dim_products
  +---------------+                +---------------+
  | customer_id   |                | product_id    |
  | full_name     |                | product_name  |
  | email         |                | category      |
  | city          |                | unit_price    |
  | signup_date   |                +-------+-------+
  +-------+-------+                        |
          |         fact_order_items       |
          |      +-------------------+     |
          +------| order_item_id     |-----+
                 | order_id          |
                 | customer_id  (FK) |
                 | product_id   (FK) |
                 | order_date        |
                 | order_status      |
                 | quantity          |
                 | unit_price        |
                 | line_total        |
                 +-------------------+
```
The fact table has one row for each order item. Quantity, unit_price and line_total are the numbers we add up. The dimension tables tell who and what.

## Star schema vs 3NF
- 3NF splits data in many small tables so nothing is repeated. It is good for the shop app (OLTP). My raw tables are like this.
- Star schema has one fact table and some dimension tables. It needs fewer joins and is easier for reports (OLAP).
- I used star schema in gold because the goal is analysis, for example revenue by city or category.

## How medallion layers are done
| Layer | Folder | Type | Schema in PostgreSQL |
|---|---|---|---|
| Bronze | models/bronze | view | public_bronze |
| Silver | models/silver | table | public_silver |
| Gold | models/gold | table (fact is incremental) | public_gold |

The type and schema of each layer are set in `dbt_project/dbt_project.yml`. Models use `ref()` to call each other, so dbt runs them in the correct order.

## How to run
Docker Desktop should be open. Run these in the project folder.

```
docker compose up -d
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
cd dbt_project
dbt debug
dbt source freshness
dbt build
```
- `docker compose up -d` starts PostgreSQL (port 5433) and creates the raw tables with data.
- `dbt build` runs all models and tests. Result should be PASS=29.

Run the queries: open psql inside the Docker container with
```
docker exec -it analytics_postgres psql -U postgres -d analytics_db
```
Then copy the queries from `queries/analysis.sql` and paste them in the terminal. Use `\q` to exit psql.

To start again from zero: `docker compose down -v` and then `docker compose up -d`.

## Tests
I used 3 dbt tests: `not_null`, `unique` and `relationships` (checks the foreign key exists in the other table).

## Stretch goals
**1. Incremental model**: `fact_order_items` is incremental. First run loads everything, next runs load only new data. `unique_key` stops duplicate rows.
1. In psql, paste the content of `scripts/add_new_orders.sql` (adds 3 new orders).
2. In another terminal, inside dbt_project: `dbt run`
3. In psql: `select count(*) from public_gold.fact_order_items;`

Fact table goes from 24 rows to 29 rows. (Run all models because silver also needs to refresh.)

**2. Backfill**: to load old data again.
```
dbt run --select fact_order_items --vars "{backfill_date: '2026-10-01'}"
dbt run --select fact_order_items --full-refresh
```
The first one reloads data from that date, the second one rebuilds the whole table.

**3. Freshness check**: in `models/bronze/sources.yml` it gives warning after 24 hours and error after 48 hours using the loaded_at column.
```
dbt source freshness
```
To see it fail, run this in psql and then run the command again:
`update raw.orders set loaded_at = now() - interval '3 days';`

**4. Folders and owners**: every layer has its own folder and an owner written in `dbt_project.yml` (meta owner).

**5. Macros**: `clean_text` (trim + capital letters) and `line_total` (quantity * price) so the same SQL is not repeated.

## SQL queries
`queries/analysis.sql` has 6 queries:
- Aggregations: total revenue and orders, orders per status
- Joins: revenue per category, revenue per city
- Subqueries: customers above average spending, customers with no orders
