Shop Analytics Project (PostgreSQL + dbt)
A small-shop analytics pipeline built with PostgreSQL, Docker and dbt. Raw shop data is loaded into PostgreSQL, transformed through Bronze, Silver and Gold layers, and queried for analytics.

Tools used
- PostgreSQL 16
- Docker Desktop and Docker Compose
- dbt Core 1.9.11 with dbt-postgres 1.9.1
- Python virtual environment
- pgAdmin (database inspection and SQL query execution)
- Git and GitHub

Project structure

docker-compose.yml        PostgreSQL container configuration

init/                     SQL scripts to create raw tables and load mock data

scripts/                  SQL script to insert additional orders for incremental testing

queries/analysis.sql      Six analytics SQL queries

dbt_project/              dbt project

  macros/                 clean_text.sql and line_total.sql

  models/bronze/          Bronze models and source definitions

  models/silver/          Silver transformation models

  models/gold/            Dimension and fact models

  dbt_project.yml         dbt model configuration

  profiles.yml            Local dbt connection profile

Data lifecycle

Raw PostgreSQL tables -> Bronze -> Silver -> Gold -> Analytics SQL

1. Raw: customers, products, orders and order_items, representing the operational shop database. The mock data includes intentionally dirty values such as extra spaces, inconsistent capitalization and a negative quantity.
2. Bronze: views that expose the raw source data without changing it.
3. Silver: cleaned tables. Text is standardised, invalid negative-quantity data is removed, and line_total is calculated.
4. Gold: analytics-ready star schema containing dim_customers, dim_products and fact_order_items.
5. Analytics: SQL queries run against the Gold tables.
This is an ELT workflow: data is loaded first and transformed inside PostgreSQL by dbt.
Data model and grain
The Gold fact table, fact_order_items, has a grain of one row per order item. Its measures include quantity, unit_price and line_total. The dimension tables provide customer and product context.
3NF vs star schema
- The raw operational tables are organised in a normalised, 3NF-style structure suitable for transactional operations (OLTP).
- The Gold layer uses a star schema: one fact table connected to dimension tables. This makes reporting and analytical queries (OLAP) easier.
Medallion layer configuration
| Layer | dbt folder | Materialisation | PostgreSQL schema | Owner metadata |

|---|---|---|---|---|

| Bronze | models/bronze | View | public_bronze | ingestion team |

| Silver | models/silver | Table | public_silver | data quality team |

| Gold | models/gold | Table; fact model is incremental | public_gold | analytics team |

The schemas, materialisations and owner metadata are configured in dbt_project/dbt_project.yml. Models use ref() to define dependencies. Raw inputs are declared with source().
Setup and run (Windows PowerShell)
Run commands from the indicated folder. Open Docker Desktop first.
1. Start PostgreSQL
From the repository root (the folder containing docker-compose.yml):

docker compose up -d

docker ps

docker exec -it analytics_postgres pg_isready -U postgres

The container is named analytics_postgres. PostgreSQL is exposed on host port 5433 and listens on container port 5432. The database is analytics_db.
2. Create and activate the Python environment
Run from the repository root:

python -m venv .venv

.venv\Scripts\Activate.ps1

pip install -r requirements.txt

If PowerShell blocks activation, use the appropriate execution-policy setting for your machine or activate the environment from Command Prompt instead.
3. Configure the dbt password
The dbt profile is stored in dbt_project/profiles.yml, and it reads the password from the DBT_PASSWORD environment variable. Set it in the same PowerShell session before running dbt. For the local setup used during development, the password was postgres:

$env:DBT_PASSWORD = "postgres"

If you chose a different PostgreSQL password, use that value instead. This environment variable is session-specific; set it again in a new PowerShell session. Do not commit real passwords to GitHub.
4. Run dbt
From the repository root:

cd dbt_project

dbt debug --profiles-dir .

dbt source freshness --profiles-dir .

dbt build --profiles-dir .

- dbt debug checks the profile and database connection.
- dbt source freshness checks the four raw sources using their configured loaded_at field. The freshness thresholds are WARN after 24 hours and ERROR after 48 hours. A WARN means the source is older than the warning threshold; it does not mean the model build failed.
- dbt build runs the selected models and tests. The completed project run returned PASS=29 WARN=0 ERROR=0 SKIP=0.
The dbt project uses --profiles-dir . because profiles.yml is inside the dbt_project directory.
pgAdmin: connect to the Docker PostgreSQL database
Use pgAdmin to inspect the raw, Bronze, Silver and Gold schemas and execute SQL queries.
1. Open pgAdmin.
2. In the Browser panel, right-click Servers and choose Register > Server.
3. On the General tab, enter a name such as Shop Analytics Docker.
4. On the Connection tab, enter:
   | Setting | Value |

   |---|---|

   | Host name/address | localhost |

   | Port | 5433 |

   | Maintenance database | analytics_db |

   | Username | postgres |

   | Password | The PostgreSQL password configured for this local container |
5. Save. If prompted, choose whether pgAdmin should save the password.
6. Expand Servers > Shop Analytics Docker > Databases > analytics_db > Schemas.
7. Inspect the schemas public, public_bronze, public_silver and public_gold. Expand Tables or Views under each schema to inspect the objects.
8. To run SQL, right-click analytics_db and choose Query Tool. Execute SQL in the editor and inspect the Data Output panel.
Example row-count check for the Gold fact table:

SELECT COUNT(*)

FROM public_gold.fact_order_items;

Example duplicate-key check:

SELECT order_item_id, COUNT(*)

FROM public_gold.fact_order_items

GROUP BY order_item_id

HAVING COUNT(*) > 1;

The duplicate check should return no rows when there are no repeated order_item_id values.
Incremental model, backfill and full refresh
The fact_order_items model is configured as an incremental model. The incremental test script inserts additional mock data into the raw database. Run these commands in PowerShell.

First, from the repository root, load the additional mock rows:

Get-Content scripts\add_new_orders.sql | docker exec -i analytics_postgres psql -U postgres -d analytics_db

Then run dbt from the dbt_project directory:

cd dbt_project

dbt run --profiles-dir .

During the project walkthrough, the Gold fact table count was checked in pgAdmin and showed 29 rows. A duplicate-key query on order_item_id returned no rows. The dbt model run reported INSERT 0 3; that log line alone should not be used to infer the final net row count or the exact incremental strategy.
Backfill command
Run from dbt_project:

dbt run --profiles-dir . --select fact_order_items --vars "{backfill_date: '2026-10-01'}"

This passes the backfill_date variable to the selected model. The command completed successfully during the walkthrough. The exact filtering behaviour depends on the SQL in models/gold/fact_order_items.sql.
Full refresh command
Run from dbt_project:

dbt run --profiles-dir . --select fact_order_items --full-refresh

This rebuilds the selected incremental model from its upstream query rather than applying only an incremental update. During the walkthrough it completed successfully and the fact model contained 29 rows afterwards.
Source freshness
Freshness is configured in models/bronze/sources.yml using the source loaded_at field:
- WARN after 24 hours
- ERROR after 48 hours
Run from dbt_project:

dbt source freshness --profiles-dir .

In the walkthrough, raw.order_items and raw.orders passed, while raw.customers and raw.products returned WARN. This was a freshness status, not a dbt model/test failure. A subsequent dbt build completed with 29 PASS and zero warnings or errors.
Macros
The project contains two reusable macros in dbt_project/macros/:
- clean_text(column_name): applies trim() and initcap() to remove leading/trailing spaces and standardise capitalisation.
- line_total(quantity, price): returns the SQL expression quantity * price.
Tests
The project uses dbt data tests including:
- not_null: checks that a column has no NULL values.
- unique: checks that values are not duplicated.
- relationships: checks that a key in one model exists in the related model.
Final verification during the walkthrough:

PASS=29 WARN=0 ERROR=0 SKIP=0 TOTAL=29

Run analytics SQL
From the repository root, run the six queries in queries/analysis.sql against the Docker database:

Get-Content queries\analysis.sql | docker exec -i analytics_postgres psql -U postgres -d analytics_db

Alternatively, open pgAdmin Query Tool for analytics_db and run the SQL statements from queries/analysis.sql there.

The six queries cover:
- Aggregations: total revenue and orders, orders per status
- Joins: revenue by product category and customer city
- Subqueries: customers spending above average and customers with no orders
Reset the database (destructive)
Warning: this deletes the Docker Compose database volume and its stored data. Only use this when you intentionally want to recreate the database from scratch.

From the repository root:

docker compose down -v

docker compose up -d

Docker initialisation scripts run when the PostgreSQL data volume is first created. Restarting an existing container/volume does not rerun those initialisation scripts.