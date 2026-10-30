-- Save the results of each data quality check.
CREATE TABLE IF NOT EXISTS dq_results (
    check_name VARCHAR(150),
    status VARCHAR(10),
    checked_at DATETIME
);

DELETE FROM dq_results;

INSERT INTO dq_results
SELECT
    'Raw row count equals clean row count',
    CASE WHEN (SELECT COUNT(*) FROM raw_titanic) =
              (SELECT COUNT(*) FROM clean_passengers)
         THEN 'PASS' ELSE 'FAIL' END,
    NOW();

INSERT INTO dq_results
SELECT
    'No NULL values in age',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    NOW()
FROM clean_passengers
WHERE age IS NULL;

INSERT INTO dq_results
SELECT
    'No NULL values in embarked',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    NOW()
FROM clean_passengers
WHERE embarked IS NULL;

-- seaborn Titanic has no passenger ID. source_row_id identifies each input row;
-- it cannot prove whether two rows describe the same real-world passenger.
INSERT INTO dq_results
SELECT
    'No duplicate source row IDs',
    CASE WHEN COUNT(*) = COUNT(DISTINCT source_row_id)
         THEN 'PASS' ELSE 'FAIL' END,
    NOW()
FROM clean_passengers;

INSERT INTO dq_results
SELECT
    'Age is between 0 and 100',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    NOW()
FROM clean_passengers
WHERE age < 0 OR age > 100 OR age IS NULL;

INSERT INTO dq_results
SELECT
    'Sex contains only 0 or 1',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    NOW()
FROM clean_passengers
WHERE sex NOT IN (0, 1) OR sex IS NULL;
