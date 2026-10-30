from pathlib import Path
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
from extract_load import extract_and_load

BASE_DIR = Path(__file__).resolve().parent
SQL_FILES = [
    "01_create_staging.sql",
    "02_transform.sql",
    "03_analytics_views.sql",
    "04_data_quality.sql"
]

def get_engine():
    url = URL.create(
        "mysql+pymysql",
        username=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME
    )
    return create_engine(url)

def run_sql_file(connection, file_path):
    sql_text = file_path.read_text(encoding="utf-8")
    statements = [part.strip() for part in sql_text.split(";") if part.strip()]
    for statement in statements:
        connection.execute(text(statement))

def main():
    print("\nSTEP 1: EXTRACT AND LOAD")
    extract_and_load()

    print("\nSTEP 2: RUN SQL TRANSFORMATIONS")
    engine = get_engine()
    with engine.begin() as connection:
        for file_name in SQL_FILES:
            print("Running", file_name)
            run_sql_file(connection, BASE_DIR / "sql" / file_name)

    print("\nSTEP 3: DATA QUALITY RESULTS")
    with engine.connect() as connection:
        results = connection.execute(text(
            "SELECT check_name, status FROM dq_results ORDER BY checked_at, check_name"
        )).fetchall()

    all_passed = bool(results)
    for check_name, status in results:
        print(f"{status}: {check_name}")
        if status != "PASS":
            all_passed = False

    if all_passed:
        print("\nAll data quality checks passed.")
    else:
        print("\nOne or more checks failed. Review dq_results.")
        sys.exit(1)

if __name__ == "__main__":
    main()
