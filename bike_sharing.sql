-- =====================================================
-- BIKE SHARING ANALYSIS: DATABASE SETUP (PostgreSQL)
-- Run the blocks in order. Do not re-run a CREATE TABLE
-- block that has already been executed ("already exists" error).
-- =====================================================

-- -----------------------------------------------------
-- 1. FACT TABLE
-- Create the table, then import day.csv with
-- pgAdmin: right-click table > Import/Export Data
-- (Format: csv, Header: on, Delimiter: ,)
-- -----------------------------------------------------
CREATE TABLE day (
    instant     INT PRIMARY KEY,  -- record index
    dteday      DATE,             -- calendar date
    season      INT,              -- 1 winter, 2 spring, 3 summer, 4 fall
    yr          INT,              -- 0 = 2011, 1 = 2012
    mnth        INT,              -- month (1-12)
    holiday     INT,              -- 1 if the day is a holiday
    weekday     INT,              -- day of the week (0 = Sunday)
    workingday  INT,              -- 1 if neither weekend nor holiday
    weathersit  INT,              -- weather situation (1-4)
    temp        FLOAT,            -- normalized temperature (0-1)
    atemp       FLOAT,            -- normalized "feels like" temperature (0-1)
    hum         FLOAT,            -- normalized humidity (0-1)
    windspeed   FLOAT,            -- normalized wind speed (0-1)
    casual      INT,              -- casual (non-registered) users
    registered  INT,              -- registered users
    cnt         INT               -- total rentals (casual + registered)
);

-- Check: should return 731
SELECT COUNT(*) FROM day;

-- -----------------------------------------------------
-- 2. SEASON DIMENSION
-- -----------------------------------------------------
CREATE TABLE dim_season (
    season_id   INT PRIMARY KEY,
    season_name VARCHAR(20)
);

INSERT INTO dim_season VALUES
(1, 'Winter'),
(2, 'Spring'),
(3, 'Summer'),
(4, 'Fall');

-- -----------------------------------------------------
-- 3. WEATHER DIMENSION
-- -----------------------------------------------------
CREATE TABLE dim_weather (
    weather_id   INT PRIMARY KEY,
    weather_name VARCHAR(40)
);

INSERT INTO dim_weather VALUES
(1, 'Clear / Few clouds'),
(2, 'Mist / Cloudy'),
(3, 'Light rain / Light snow'),
(4, 'Heavy rain / Snow / Fog');

-- -----------------------------------------------------
-- 4. WEEKDAY DIMENSION
-- -----------------------------------------------------
CREATE TABLE dim_weekday (
    weekday_id   INT PRIMARY KEY,
    weekday_name VARCHAR(20)
);

INSERT INTO dim_weekday VALUES
(0, 'Sunday'),
(1, 'Monday'),
(2, 'Tuesday'),
(3, 'Wednesday'),
(4, 'Thursday'),
(5, 'Friday'),
(6, 'Saturday');

-- -----------------------------------------------------
-- 5. DATE DIMENSION
-- First check the date range: expect 2011-01-01 to 2012-12-31
-- -----------------------------------------------------
SELECT MIN(dteday), MAX(dteday) FROM day;

CREATE TABLE dim_date (
    date_id    DATE PRIMARY KEY,  -- one row per day
    year_no    INT,
    month_no   INT,
    month_name VARCHAR(20),
    day_no     INT,
    quarter_no INT                -- quarter (1-4)
);

-- generate_series produces one row per day (731 rows)
INSERT INTO dim_date
SELECT
    d::date,
    EXTRACT(YEAR FROM d),
    EXTRACT(MONTH FROM d),
    (ARRAY['January','February','March','April','May','June',
           'July','August','September','October','November','December'])
           [EXTRACT(MONTH FROM d)::int],
    EXTRACT(DAY FROM d),
    EXTRACT(QUARTER FROM d)
FROM generate_series('2011-01-01'::date, '2012-12-31'::date, '1 day') AS d;

-- Check: should return 731
SELECT COUNT(*) FROM dim_date;

-- -----------------------------------------------------
-- 6. RELATIONSHIPS (foreign keys)
-- -----------------------------------------------------
ALTER TABLE day
ADD FOREIGN KEY (season) REFERENCES dim_season (season_id);

ALTER TABLE day
ADD FOREIGN KEY (weathersit) REFERENCES dim_weather (weather_id);

ALTER TABLE day
ADD FOREIGN KEY (weekday) REFERENCES dim_weekday (weekday_id);

ALTER TABLE day
ADD FOREIGN KEY (dteday) REFERENCES dim_date (date_id);

-- -----------------------------------------------------
-- 7. VALIDATION QUERIES
-- -----------------------------------------------------

-- Do the joins work? Total rentals by season and weather
SELECT s.season_name, w.weather_name, SUM(d.cnt) AS total_rentals
FROM day d
JOIN dim_season  s ON d.season     = s.season_id
JOIN dim_weather w ON d.weathersit = w.weather_id
GROUP BY s.season_name, w.weather_name
ORDER BY s.season_name;

-- Is weekday 0 = Sunday? weekday and actual_dow should match
SELECT dteday, weekday, EXTRACT(DOW FROM dteday) AS actual_dow
FROM day
LIMIT 5;

-- -----------------------------------------------------
-- 8. OPTIONAL: temperature in Celsius
-- Approximate conversion (temp is normalized; 41 = assumed max).
-- Not needed if you compute it as a Power BI measure instead.
-- -----------------------------------------------------
ALTER TABLE day ADD COLUMN temp_c FLOAT;
UPDATE day SET temp_c = temp * 41;

-- -----------------------------------------------------
-- 9. EXPORT TO CSV (for Power BI Service via Excel)
-- Run each query, then export the result (F8 / fn+F8 in pgAdmin)
-- -----------------------------------------------------
-- SELECT * FROM day;
-- SELECT * FROM dim_season;
-- SELECT * FROM dim_weather;
-- SELECT * FROM dim_weekday;
-- SELECT * FROM dim_date;
