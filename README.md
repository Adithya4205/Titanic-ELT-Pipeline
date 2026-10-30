# Titanic ELT Pipeline

A Python and MySQL project that loads the Titanic dataset, transforms it in MySQL, creates analytics views, and runs data quality checks.

## Requirements

- Python 3.10 or newer
- MySQL 8.0 or newer
- An internet connection for the first dataset load
- A MySQL account that can create and drop tables and create views

## Project files

- `config.py` — reads MySQL connection settings from environment variables
- `extract_load.py` — loads the Titanic dataset into `raw_titanic`
- `run_elt.py` — runs the load, SQL transformations, and data quality checks
- `sql/01_create_staging.sql` — creates `stg_titanic`
- `sql/02_transform.sql` — creates and fills `clean_passengers`
- `sql/03_analytics_views.sql` — creates the analytics views
- `sql/04_data_quality.sql` — saves check results in `dq_results`

## Setup on macOS

### 1. Create the database

Start the MySQL server. In Terminal, create the database:

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS titanic_elt_db;"
```

You can also create it in MySQL Workbench:

```sql
CREATE DATABASE titanic_elt_db;
```

### 2. Create a virtual environment and install packages

From Terminal:

```bash
cd ~/Downloads/Titanic-ELT-Pipeline
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

### 3. Set the MySQL connection

In the same Terminal session, set the connection details:

```bash
export DB_HOST=localhost
export DB_PORT=3306
export DB_USER=root
export DB_NAME=titanic_elt_db
```

Then run this command by itself:

```zsh
read -s 'DB_PASSWORD?Enter your MySQL password: ' && export DB_PASSWORD
```

When prompted, type your MySQL password and press Return. The password will not appear on screen. The text after `?` is the prompt; do not put your password there.

These settings apply only to the current Terminal session. Set them again in a new session before running the pipeline.

### 4. Run the pipeline

```bash
python3 run_elt.py
```

The script loads the dataset, runs each SQL file in order, and prints the data quality results. A successful run ends with:

```text
All data quality checks passed.
```

## Tables and views

The pipeline creates these tables:

- `raw_titanic` — source data loaded from seaborn
- `stg_titanic` — staged data with standardized values and a generated `source_row_id`
- `clean_passengers` — transformed data with derived fields
- `dq_results` — data quality check results

It also creates these views:

- `vw_survival_by_class_sex`
- `vw_survival_by_age_group`
- `vw_top_3_fares_by_class`

To inspect the results in MySQL Workbench or a MySQL client:

```sql
USE titanic_elt_db;

SELECT * FROM dq_results;
SELECT * FROM vw_survival_by_class_sex;
SELECT * FROM vw_survival_by_age_group;
SELECT * FROM vw_top_3_fares_by_class;
```

## Transformations

- Missing ages are filled with the average age for the same passenger class and sex.
- Missing embarked values are filled with the most common embarked value.
- Female is encoded as `1`; male is encoded as `0`.
- Age groups, family size, alone status, and fare categories are derived in SQL.
- Fare categories are assigned with SQL `NTILE(4)`.

The dataset does not include a passenger ID. `source_row_id` identifies rows in the loaded data; it does not identify real-world passengers.

## Rerunning the pipeline

Each run replaces `raw_titanic` and rebuilds the staging and cleaned tables. It also replaces the views and clears and repopulates `dq_results`.

The first dataset load may need internet access because seaborn downloads the dataset.

## Troubleshooting

### SSL certificate error while loading the dataset

If Python reports `CERTIFICATE_VERIFY_FAILED` from `sns.load_dataset("titanic")`, install certificates for the Python.org macOS installation. For Python 3.10, run:

```bash
open "/Applications/Python 3.10/Install Certificates.command"
```

After the installer finishes, activate the project virtual environment and run the pipeline again:

```bash
source .venv/bin/activate
python3 run_elt.py
```

### MySQL connection error

Check that the MySQL server is running, the database exists, and the environment variables contain the correct host, port, user, and password.
