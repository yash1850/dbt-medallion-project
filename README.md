# Shop Analytics Project (PostgreSQL + dbt)

An end-to-end analytical data pipeline for a small shop. This project ingests raw shop data into PostgreSQL, transforms it using dbt through Bronze, Silver and Gold layers, and exposes analytics-ready tables using dimensional modeling.

## 1. Technology Stack

- **PostgreSQL 16** – Relational database
- **Docker** – Runs PostgreSQL locally
- **pgAdmin 4** – GUI for database management and SQL execution
- **dbt Core 1.9.11** – Data transformation and testing
- **Python 3.13** – dbt environment
- **Git and GitHub** – Version control

## 2. Project Structure

```text
dbt-medallion-project/
│
├── docker-compose.yml
├── requirements.txt
├── README.md
├── .gitignore
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
        │   ├── bronze_customers.sql
        │   ├── bronze_products.sql
        │   ├── bronze_orders.sql
        │   ├── bronze_order_items.sql
        │   └── sources.yml
        │
        ├── silver/
        │   ├── silver_customers.sql
        │   ├── silver_products.sql
        │   ├── silver_orders.sql
        │   ├── silver_order_items.sql
        │   └── schema.yml
        │
        └── gold/
            ├── dim_customers.sql
            ├── dim_products.sql
            ├── fact_order_items.sql
            └── schema.yml
```

## 3. Data Lifecycle

```text
Raw PostgreSQL Tables
        |
        v
     Bronze
        |
        v
      Silver
        |
        v
       Gold
        |
        v
 Analytical SQL Queries
```

### Raw Layer
Contains four OLTP-style source tables:

- customers
- products
- orders
- order_items

Mock data includes intentionally dirty records such as extra spaces, inconsistent capitalization and negative quantities.

### Bronze Layer
- Reads directly from raw source tables.
- Preserves the original source data.
- Implemented as views.

### Silver Layer
- Cleans inconsistent text and whitespace.
- Removes invalid negative-quantity records.
- Calculates line totals.
- Stores cleaned data as tables.

### Gold Layer
Provides analytics-ready dimensional models:

- `dim_customers`
- `dim_products`
- `fact_order_items`

The fact table contains order-item-level transactional data, while dimensions provide descriptive customer and product information.

## 4. Dimensional Data Model

The Gold layer follows a Star Schema.

```text
       dim_customers                 dim_products
      +----------------+           +----------------+
      | customer_id PK |           | product_id PK  |
      | full_name      |           | product_name   |
      | email          |           | category       |
      | city           |           | unit_price      |
      | signup_date    |           +-------+--------+
      +-------+--------+                   |
              |                            |
              +-------------+--------------+
                            |
                   fact_order_items
                  +-------------------+
                  | order_item_id PK  |
                  | order_id          |
                  | customer_id FK    |
                  | product_id FK     |
                  | order_date        |
                  | order_status      |
                  | quantity          |
                  | unit_price        |
                  | line_total        |
                  +-------------------+
```

**Fact table:** `fact_order_items`

**Dimension tables:** `dim_customers`, `dim_products`

The grain of the fact table is one row per order item.

## 5. Star Schema vs 3NF

**3NF (Third Normal Form):**
- Organizes data into multiple normalized tables.
- Minimizes redundant data.
- Suitable for transactional systems (OLTP).
- Used in the raw shop database structure.

**Star Schema:**
- Organizes data around a central fact table and dimension tables.
- Makes analytical queries easier to understand.
- Reduces the number of joins required for common reporting queries.
- Suitable for analytical systems (OLAP).

I chose Star Schema for the Gold layer because the objective is analytical reporting, such as revenue by customer city, product category and order status.

## 6. Medallion Architecture Implementation

| Layer | dbt folder | Materialization | PostgreSQL schema |
|---|---|---|---|
| Bronze | models/bronze | View | public_bronze |
| Silver | models/silver | Table | public_silver |
| Gold | models/gold | Table / Incremental | public_gold |

The schema and materialization configurations are defined in `dbt_project.yml`.

dbt's `source()` references raw tables, while `ref()` connects downstream models and manages execution dependencies.

## 7. Setup and Installation

### Prerequisites

- Docker Desktop
- Python 3.13
- pgAdmin 4
- Git

### Step 1: Clone the repository

```powershell
git clone https://github.com/yash1850/dbt-medallion-project.git

cd dbt-medallion-project
```

### Step 2: Start PostgreSQL

Make sure Docker Desktop is running.

```powershell
docker compose up -d
docker compose ps
```

PostgreSQL runs locally on port `5433`.

### Step 3: Connect through pgAdmin 4

Open pgAdmin 4 and register a new server.

Use the following connection details:

| Setting | Value |
|---|---|
| Name | DBT Medallion Project |
| Host | localhost |
| Port | 5433 |
| Maintenance database | analytics_db |
| Username | postgres |
| Password | Your PostgreSQL password |

Connect to the `analytics_db` database.

### Step 4: Initialize raw tables

In pgAdmin:

1. Open `analytics_db`.
2. Open Query Tool.
3. Execute `init/01_create_raw_tables.sql`.
4. Execute `init/02_load_mock_data.sql`.

This creates and populates the raw source tables.

### Step 5: Set up Python and dbt

Return to the project root in VS Code terminal.

```powershell
python -m venv .venv

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\.venv\Scripts\Activate.ps1

pip install -r requirements.txt
```

### Step 6: Configure dbt profile

Navigate to the dbt project:

```powershell
cd dbt_project
```

Create your local profile:

```powershell
Copy-Item profiles.yml.example profiles.yml
```

Set the PostgreSQL password using an environment variable:

```powershell
$env:DBT_PASSWORD = "your_postgres_password"
```

The actual `profiles.yml` is excluded from Git to avoid publishing credentials.

### Step 7: Validate and build the project

Run the following commands in the VS Code terminal, from inside `dbt_project`:

```powershell
dbt debug --profiles-dir .

dbt source freshness --profiles-dir .

dbt build --profiles-dir .
```

The successful full build produced 29 passing model/test results.

## 8. dbt Testing

The project implements three important data quality tests:

| Test | Purpose |
|---|---|
| not_null | Checks required columns are not NULL |
| unique | Checks that key columns contain no duplicates |
| relationships | Checks foreign-key references exist in related tables |

These tests help validate the quality and consistency of the transformed data.

## 9. Incremental Model

The `fact_order_items` model uses dbt incremental materialization.

- Initial execution loads all available records.
- Subsequent executions process new records according to the incremental filter.
- `unique_key` uses `order_item_id` to identify records and avoid duplicate inserts during incremental processing.

### Incremental testing

**Step 1:** In pgAdmin Query Tool, execute:

```sql
-- Execute the contents of scripts/add_new_orders.sql
```

This adds three new orders and five new order items.

**Step 2:** In the VS Code terminal, from `dbt_project`, run:

```powershell
dbt run --profiles-dir .
```

**Step 3:** Verify the fact table in pgAdmin:

```sql
SELECT COUNT(*)
FROM public_gold.fact_order_items;
```

Expected result:

- Initial records: 24
- After incremental load: 29

## 10. Backfill Strategy

Backfill allows older data to be reprocessed.

The project supports a `backfill_date` variable for the incremental fact model.

Run:

```powershell
dbt run --select fact_order_items --vars "{backfill_date: '2026-10-01'}" --profiles-dir .
```

To rebuild the entire fact table:

```powershell
dbt run --select fact_order_items --full-refresh --profiles-dir .
```

The full-refresh command recreates the incremental model from the available source data.

## 11. Source Freshness Monitoring

Freshness checks are configured in:

`models/bronze/sources.yml`

The configuration uses the `loaded_at` column to monitor source data freshness:

- Warning threshold: 24 hours
- Error threshold: 48 hours

Run:

```powershell
dbt source freshness --profiles-dir .
```

### Testing stale data detection

In pgAdmin Query Tool, execute:

```sql
UPDATE raw.orders
SET loaded_at = NOW() - INTERVAL '3 days';
```

Run the freshness command again.

dbt should report the `raw.orders` source as stale.

Restore the timestamps afterward:

```sql
UPDATE raw.orders
SET loaded_at = NOW();
```

Run the freshness check again to confirm that all sources pass.

## 12. dbt Macros

The project uses two reusable macros:

| Macro | Purpose |
|---|---|
| clean_text | Cleans text by trimming whitespace and standardizing capitalization |
| line_total | Calculates quantity multiplied by unit price |

Macros reduce repetitive SQL and make transformations easier to maintain.

## 13. Analytical SQL Queries

The file `queries/analysis.sql` contains six analytical queries.

They demonstrate:

**Aggregations**
- Total revenue and total orders.
- Orders grouped by status.

**Joins**
- Revenue by product category.
- Revenue by customer city.

**Subqueries**
- Customers spending above average.
- Customers with no orders.

Execute these queries using pgAdmin 4 Query Tool against the Gold layer.

## 14. Expected Analytical Results

One verified analytical output from the project:

| Metric | Result |
|---|---:|
| Total orders | 18 |
| Total units | 56 |
| Total revenue | ₹266,750.00 |
| Average line total | ₹12,125.00 |

These figures correspond to the dataset at the time of that analysis.

## 15. Version Control

GitHub repository:

https://github.com/yash1850/dbt-medallion-project

The repository excludes local environment files, generated dbt artifacts and the actual local `profiles.yml`.

---

## Project Summary

This project demonstrates an end-to-end ELT workflow using PostgreSQL and dbt.

It covers:

- Raw data ingestion.
- Medallion Architecture.
- Data cleaning and transformation.
- Dimensional modeling using Star Schema.
- Fact and dimension tables.
- dbt data quality testing.
- Incremental processing.
- Backfill strategy.
- Source freshness monitoring.
- Reusable dbt macros.
- Analytical SQL queries.
