import uuid
from datetime import datetime
import seaborn as sns
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME

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

def extract_and_load():
    # Extract the dataset. No cleaning is performed in Python.
    raw_df = sns.load_dataset("titanic")
    raw_df["load_timestamp"] = datetime.now()
    raw_df["batch_id"] = str(uuid.uuid4())

    engine = get_engine()

    # Replace the raw table on each run to avoid appending duplicate rows.
    with engine.begin() as connection:
        connection.execute(text("DROP TABLE IF EXISTS raw_titanic"))

    raw_df.to_sql(
        "raw_titanic", con=engine, if_exists="replace",
        index=False, chunksize=100, method="multi"
    )

    with engine.connect() as connection:
        row_count = connection.execute(
            text("SELECT COUNT(*) FROM raw_titanic")
        ).scalar()

    print(f"Raw records loaded: {row_count}")
    return row_count

if __name__ == "__main__":
    extract_and_load()
