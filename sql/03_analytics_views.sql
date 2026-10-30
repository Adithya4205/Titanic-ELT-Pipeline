-- Survival rate grouped by passenger class and sex.
CREATE OR REPLACE VIEW vw_survival_by_class_sex AS
SELECT
    passenger_class,
    CASE WHEN sex = 1 THEN 'female'
         WHEN sex = 0 THEN 'male'
         ELSE 'unknown' END AS sex,
    COUNT(*) AS passenger_count,
    SUM(survived) AS survivors,
    ROUND(AVG(survived) * 100, 2) AS survival_rate_percent
FROM clean_passengers
GROUP BY passenger_class, sex;

-- Survival rate grouped by age group.
CREATE OR REPLACE VIEW vw_survival_by_age_group AS
SELECT
    age_group,
    COUNT(*) AS passenger_count,
    SUM(survived) AS survivors,
    ROUND(AVG(survived) * 100, 2) AS survival_rate_percent
FROM clean_passengers
WHERE age_group IS NOT NULL
GROUP BY age_group;

-- Top three fares in each passenger class.
CREATE OR REPLACE VIEW vw_top_3_fares_by_class AS
SELECT passenger_class, source_row_id, fare, fare_rank
FROM (
    SELECT
        passenger_class,
        source_row_id,
        fare,
        RANK() OVER (
            PARTITION BY passenger_class ORDER BY fare DESC
        ) AS fare_rank
    FROM clean_passengers
    WHERE fare IS NOT NULL
) ranked_fares
WHERE fare_rank <= 3;
