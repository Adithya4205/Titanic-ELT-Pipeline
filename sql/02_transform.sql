-- Fill age from the average age for the same class and sex.
-- If no matching average exists, age stays NULL and the DQ check will show FAIL.
DROP TABLE IF EXISTS clean_passengers;

CREATE TABLE clean_passengers AS
SELECT
    source_row_id,
    survived,
    passenger_class,
    CASE
        WHEN sex = 'female' THEN 1
        WHEN sex = 'male' THEN 0
        ELSE NULL
    END AS sex,
    COALESCE(
        age,
        (SELECT AVG(s2.age)
         FROM stg_titanic s2
         WHERE s2.passenger_class = s.passenger_class
           AND s2.sex = s.sex
           AND s2.age IS NOT NULL)
    ) AS age,
    sibsp,
    parch,
    fare,
    COALESCE(
        embarked,
        (SELECT s3.embarked
         FROM stg_titanic s3
         WHERE s3.embarked IS NOT NULL
         GROUP BY s3.embarked
         ORDER BY COUNT(*) DESC, s3.embarked
         LIMIT 1)
    ) AS embarked,
    passenger_class_name,
    passenger_type,
    adult_male,
    alive,
    load_timestamp,
    batch_id
FROM stg_titanic s;

-- Add the requested derived columns.
ALTER TABLE clean_passengers
    ADD COLUMN age_group VARCHAR(20),
    ADD COLUMN family_size INT,
    ADD COLUMN is_alone TINYINT,
    ADD COLUMN fare_category VARCHAR(20);

UPDATE clean_passengers
SET age_group = CASE
    WHEN age BETWEEN 0 AND 12 THEN 'Child'
    WHEN age BETWEEN 13 AND 19 THEN 'Teen'
    WHEN age BETWEEN 20 AND 59 THEN 'Adult'
    WHEN age >= 60 THEN 'Senior'
    ELSE NULL
END;

UPDATE clean_passengers
SET
    family_size = COALESCE(sibsp, 0) + COALESCE(parch, 0) + 1,
    is_alone = CASE
        WHEN COALESCE(sibsp, 0) = 0 AND COALESCE(parch, 0) = 0 THEN 1
        ELSE 0
    END;

-- NTILE(4) assigns fare quartiles, from lowest to highest.
CREATE TEMPORARY TABLE fare_groups AS
SELECT source_row_id, NTILE(4) OVER (ORDER BY fare) AS fare_quartile
FROM clean_passengers
WHERE fare IS NOT NULL;

UPDATE clean_passengers cp
JOIN fare_groups fg ON cp.source_row_id = fg.source_row_id
SET cp.fare_category = CASE fg.fare_quartile
    WHEN 1 THEN 'Low'
    WHEN 2 THEN 'Medium'
    WHEN 3 THEN 'High'
    WHEN 4 THEN 'Premium'
END;

DROP TEMPORARY TABLE fare_groups;
