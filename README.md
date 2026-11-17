# Shop Analytics Project (PostgreSQL + dbt)

# About the project

I built this project to understand how data moves from a database into tables that can be used for analysis.

I used PostgreSQL to store the raw data and dbt to clean and transform it. I divided the dbt models into three layers: Bronze, Silver and Gold.

The data is based on a small shop/order management example. It includes customers, products, orders and order items.

This is a learning project where I tried to apply the database and data engineering concepts I had studied.

# Tools I used

- **PostgreSQL** – To store the data.
- **Docker** – To run PostgreSQL locally.
- **pgAdmin 4** – To connect to the database and run SQL queries.
- **dbt Core** – To transform the data and create models.
- **Python virtual environment** – To manage the Python packages.
- **Git and GitHub** – To manage and share the project.

# Project structure

```text
dbt-medallion-project/
│
├── docker-compose.yml
│
├── init/
│   ├── 01_create_raw_tables.sql
│   └── 02_load_mock_data.sql
│
├── scripts/
│   └── add_new_orders.sql
│
├── queries/
│   └── analysis.sql
│
└── dbt_project/
    ├── dbt_project.yml
    ├── profiles.yml.example
    │
    ├── macros/
    │   ├── clean_text.sql
    │   └── line_total.sql
    │
    └── models/
        ├── bronze/
        ├── silver/
        └── gold/
```

# How the project works

I followed a simple flow:

**Raw Data → Bronze → Silver → Gold**

1. Raw: The original data is stored in PostgreSQL in separate tables for customers, products, orders and order items.
2. Bronze: I created models to bring the raw data into the dbt project.
3. Silver: I used this layer to clean the data and apply some basic transformations.
4. Gold: I created tables that can be used for analysis.

I used separate schemas for the layers: `public_bronze`, `public_silver` and `public_gold`.

# Database design

The raw tables follow a relational database structure. For example, customers and orders are stored separately, and the order table connects to the customer table using a customer ID.

For the Gold layer, I created a star schema.

The main fact table is `fact_order_items`, and the dimension tables are:

- `dim_customers`
- `dim_products`

The fact table contains order-item information, while the dimension tables provide details about customers and products.

I learned that 3NF is useful for storing data without unnecessary duplication, while a star schema makes it easier to write analytical queries.

# dbt models

I organised the models into three folders:

| Layer | What I did |
|---|---|
| Bronze | Brought the raw data into dbt models |
| Silver | Cleaned and transformed the data |
| Gold | Created fact and dimension tables for analysis |

I used views for some models and tables for models where I wanted the transformed data to be stored.

# Running the project locally

These are the steps I followed to run the project on my Windows machine.

# 1. Clone the repository

```bash
git clone https://github.com/yash1850/dbt-medallion-project.git
cd dbt-medallion-project
```

# 2. Start PostgreSQL using Docker

```bash
docker compose up -d
```

Check whether the container is running:

```bash
docker compose ps
```

# 3. Connect through pgAdmin

I used these connection details:

- Host: `localhost`
- Port: `5433`
- Database: `analytics_db`
- Username: `postgres`
- Password: Your PostgreSQL password

If the raw tables and mock data have not been created automatically, run the SQL files inside the `init` folder using pgAdmin's Query Tool. Do not load the mock data again if it is already present.

# 4. Create and activate the virtual environment

From the project root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Install the requirements:

```powershell
pip install -r requirements.txt
```

# 5. Configure dbt

Move into the dbt project folder:

```powershell
cd dbt_project
```

Create your local profile file:

```powershell
Copy-Item profiles.yml.example profiles.yml
```

Set your PostgreSQL password in the current PowerShell session:

```powershell
$env:DBT_PASSWORD = "your_postgres_password"
```

The actual `profiles.yml` file is kept locally and is not uploaded to GitHub.

# 6. Check the dbt connection

```powershell
dbt debug --profiles-dir .
```

If the connection is configured correctly, the checks should pass.

# 7. Check source freshness and run the models

```powershell
dbt source freshness --profiles-dir .
```

Then run the models and tests:

```powershell
dbt build --profiles-dir .
```

# Testing in dbt

I added basic tests to check whether the data is correct.

Some of the tests I used are:

- `not_null` – Checks that important columns do not contain NULL values.
- `unique` – Checks that IDs are not repeated.
- `relationships` – Checks whether IDs in one table exist in the related table.

I also configured source freshness checks.

For the source tables, I used:

- Warning after 24 hours.
- Error after 48 hours.

This helped me understand how dbt can check both data quality and how recently source data was loaded.

# Incremental model

I configured `fact_order_items` as an incremental model.

The idea is to avoid rebuilding the complete table every time new records arrive. Instead, dbt processes new records based on the incremental logic in the model.

To test this, I initially had 24 rows in the fact table.

I then ran the SQL script:

```text
scripts/add_new_orders.sql
```

This script added 3 new orders and 5 new order items.

After running the dbt model again, the row count increased from 24 to 29.

I also tried running a full refresh:

```powershell
dbt run --select fact_order_items --full-refresh --profiles-dir .
```

For a backfill run, I used:

```powershell
dbt run --select fact_order_items --vars "{backfill_date: '2026-10-01'}" --profiles-dir .
```

This helped me understand the difference between incremental runs, backfills and full refreshes.

# Macros

I created two basic macros to avoid repeating SQL logic.

**1. clean_text**

I used this macro for basic text cleaning, such as trimming extra spaces.

**2. line_total**

I used this macro to calculate the total amount for an order item using quantity and unit price.

# SQL analysis

I also wrote some SQL queries in `queries/analysis.sql` to understand the data.

A few examples:

- Total revenue and total orders.
- Number of orders by status.
- Revenue by product category.
- Revenue by customer city.
- Customers spending more than the average.
- Customers who have not placed any orders.

I used joins, aggregations and subqueries while writing these queries.

# Results

After running the project, I got the following results from the analytical queries:

| Metric | Result |
|---|---:|
| Total orders | 18 |
| Total units sold | 56 |
| Total revenue | 266750.00 |
| Average line total | 12125.00 |

I also tested the incremental model and source freshness checks separately.

# What I learned

While working on this project, I got practical experience with:

- Connecting PostgreSQL with Docker and pgAdmin.
- Writing SQL queries and working with relational tables.
- Understanding the Bronze, Silver and Gold layers.
- Creating dbt models, tests and macros.
- Understanding the difference between views and tables.
- Creating a basic star schema with fact and dimension tables.
- Working with incremental models and source freshness.
- Using Git and GitHub to manage a project.

There is still a lot more I need to learn about data engineering, but this project helped me understand the basic workflow of building a small analytics pipeline.

# GitHub

[View the project repository](https://github.com/yash1850/dbt-medallion-project)