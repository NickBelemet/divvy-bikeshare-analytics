/*
 Divvy Bikeshare Analysis (2016–2019)
 PostgreSQL | Portfolio version
 Extracted from the complete project script for easier GitHub navigation.
*/

-- SECTION 5: TABLEAU STATION ACTIVITY EXPORT
-- ====================================================================
/*
Output grain:
    activity_month x station_id x user_type

Departure activity is assigned to the month of start_time.
Arrival activity is assigned to the month of end_time. This means a very small
number of trips starting on 31-Dec-2019 can produce Jan-2020 arrival records;
this is intentional and preserves the event timestamp of each station action.

Net station flow:
    arrival_count - departure_count
Positive values indicate net inflow / potential accumulation.
Negative values indicate net outflow / potential depletion.
These are operational pressure indicators, not direct measures of bike stock.
*/

WITH params AS (
    SELECT 240.0::numeric AS max_valid_duration_minutes
),
all_trips AS (
    SELECT 2016 AS source_year, * FROM divvybikes_2016
    UNION ALL
    SELECT 2017 AS source_year, * FROM divvybikes_2017
    UNION ALL
    SELECT 2018 AS source_year, * FROM divvybikes_2018
    UNION ALL
    SELECT 2019 AS source_year, * FROM divvybikes_2019
),
exact_deduplicated AS (
    SELECT
        source_year,
        trip_id,
        bikeid,
        start_time,
        end_time,
        start_station_id,
        end_station_id,
        user_type,
        gender,
        birthyear
    FROM (
        SELECT
            a.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    trip_id,
                    bikeid,
                    start_time,
                    end_time,
                    start_station_id,
                    end_station_id,
                    user_type,
                    gender,
                    birthyear
                ORDER BY source_year
            ) AS exact_duplicate_row
        FROM all_trips a
    ) d
    WHERE exact_duplicate_row = 1
),
cleaned AS (
    SELECT
        d.*,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 AS duration_minutes,
        COALESCE(NULLIF(TRIM(user_type), ''), 'Unknown') AS user_type_clean
    FROM exact_deduplicated d
    CROSS JOIN params p
    WHERE start_time IS NOT NULL
      AND end_time IS NOT NULL
      AND end_time > start_time
      AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 > 0
      AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 <= p.max_valid_duration_minutes
),
departures AS (
    SELECT
        DATE_TRUNC('month', start_time)::date AS activity_month,
        start_station_id AS station_id,
        user_type_clean AS user_type,
        COUNT(*) AS departure_count,
        ROUND(SUM(duration_minutes)::numeric, 2) AS total_departure_duration_minutes
    FROM cleaned
    WHERE start_station_id IS NOT NULL
    GROUP BY
        DATE_TRUNC('month', start_time)::date,
        start_station_id,
        user_type_clean
),
arrivals AS (
    SELECT
        DATE_TRUNC('month', end_time)::date AS activity_month,
        end_station_id AS station_id,
        user_type_clean AS user_type,
        COUNT(*) AS arrival_count
    FROM cleaned
    WHERE end_station_id IS NOT NULL
    GROUP BY
        DATE_TRUNC('month', end_time)::date,
        end_station_id,
        user_type_clean
),
combined AS (
    SELECT
        COALESCE(d.activity_month, a.activity_month) AS activity_month,
        COALESCE(d.station_id, a.station_id) AS station_id,
        COALESCE(d.user_type, a.user_type) AS user_type,
        COALESCE(d.departure_count, 0) AS departure_count,
        COALESCE(a.arrival_count, 0) AS arrival_count,
        d.total_departure_duration_minutes
    FROM departures d
    FULL OUTER JOIN arrivals a
        ON d.activity_month = a.activity_month
       AND d.station_id = a.station_id
       AND d.user_type = a.user_type
)
SELECT
    c.activity_month,
    EXTRACT(YEAR FROM c.activity_month)::int AS activity_year,
    EXTRACT(QUARTER FROM c.activity_month)::int AS quarter,
    EXTRACT(MONTH FROM c.activity_month)::int AS month_number,
    TRIM(TO_CHAR(c.activity_month, 'Month')) AS month_name,
    CASE
        WHEN EXTRACT(MONTH FROM c.activity_month) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM c.activity_month) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM c.activity_month) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Autumn'
    END AS season,
    c.station_id,
    COALESCE(s.name, 'Unknown / Historical Station') AS station_name,
    s.latitude,
    s.longitude,
    s.docks,
    c.user_type,
    c.departure_count,
    c.arrival_count,
    c.departure_count + c.arrival_count AS total_station_activity,
    c.arrival_count - c.departure_count AS net_station_flow,
    c.total_departure_duration_minutes
FROM combined c
LEFT JOIN divvy_stations s
    ON c.station_id = s.id
ORDER BY
    c.activity_month,
    c.station_id,
    c.user_type;

-- Export the result of the query above from pgAdmin as:
-- station_tableau.csv


-- ====================================================================
