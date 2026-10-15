# Bike Sharing Analysis: PostgreSQL + Power BI

An end-to-end analytics project on daily bike rental data: a star-schema data model built by hand in PostgreSQL (SQL written manually) and an interactive Power BI report on top of it.

## Overview

Dashboard Link: https://app.powerbi.com/reportEmbed?reportId=76af4960-e4ee-4f58-8bfe-8bb148f5bf3e

The goal is to understand how time, season, weather and user type affect bike rental demand.

- Model raw CSV data as a **star schema** (one fact table, four dimension tables)
- Write all DDL and validation queries manually in **SQL**
- Build a **Power BI** report with DAX measures

## Dataset

[Bike Sharing Dataset](https://archive.ics.uci.edu/dataset/275/bike+sharing+dataset) (UCI Machine Learning Repository), `day.csv`:

- 731 rows, one per day, from 2011-01-01 to 2012-12-31
- Source: Capital Bikeshare system, Washington D.C.
- Citation: Fanaee-T, H. and Gama, J. (2013). *Event labeling combining ensemble detectors and background knowledge*. Progress in Artificial Intelligence.

| Column | Description |
|---|---|
| `instant` | Record index (primary key) |
| `dteday` | Date |
| `season` | 1 winter, 2 spring, 3 summer, 4 fall |
| `yr` | 0 = 2011, 1 = 2012 |
| `mnth` | Month (1-12) |
| `holiday` | 1 if holiday |
| `weekday` | Day of the week (0 = Sunday) |
| `workingday` | 1 if neither weekend nor holiday |
| `weathersit` | Weather situation (1 clear to 4 heavy rain/snow) |
| `temp`, `atemp`, `hum`, `windspeed` | Normalized values (0-1) |
| `casual`, `registered` | Rentals by user type |
| `cnt` | Total rentals (`casual + registered`) |

## Data Model

```
dim_season  --\
dim_weather ---\
                >-- day (fact)
dim_weekday ---/
dim_date    --/
```

| Table | Type | Key |
|---|---|---|
| `day` | Fact | `instant` |
| `dim_season` | Dimension | `season_id` |
| `dim_weather` | Dimension | `weather_id` |
| `dim_weekday` | Dimension | `weekday_id` |
| `dim_date` | Dimension | `date_id` |

Relationships (all one-to-many, single direction, dimension to fact):

- `dim_season.season_id` -> `day.season`
- `dim_weather.weather_id` -> `day.weathersit`
- `dim_weekday.weekday_id` -> `day.weekday`
- `dim_date.date_id` -> `day.dteday`

`dim_date` is generated with `generate_series`, so it contains one row per day with year, month number, month name, day and quarter.

## Repository Structure

```
.
├── README.md
├── bike_sharing.sql      # tables, dimensions, foreign keys, validation queries
├── data/
│   └── day.csv           # source dataset
└── powerbi/              # Power BI report (.pbix) and screenshots
```

## Getting Started

### 1. Set up the database

Requirements: PostgreSQL and pgAdmin.

1. Create a database and open the Query Tool.
2. Run the first block of `bike_sharing.sql` (`CREATE TABLE day`).
3. Import `data/day.csv` into `day`: right-click the table, choose **Import/Export Data**, format `csv`, header **on**, delimiter `,`.
4. Run the remaining blocks in order.
5. Confirm both `SELECT COUNT(*)` checks return **731**.

### 2. Load the data into Power BI

- **Power BI Desktop (Windows):** Get Data, PostgreSQL database, select the five tables.
- **Power BI Service (web, e.g. on macOS):** export each table to CSV, combine them into one Excel workbook (one sheet per table), then upload it with **New > Upload a file**.

Then create the relationships listed above in the Model view (one-to-many, single direction). Both join columns must be of type **Date**.

## DAX Measures

```dax
Total Rentals     = SUM('day'[cnt])
Avg Daily Rentals = AVERAGE('day'[cnt])
Registered Share  = DIVIDE(SUM('day'[registered]), SUM('day'[cnt]))
Avg Temp (C)      = AVERAGE('day'[temp]) * 41
```

`temp` is normalized, so `Avg Temp (C)` is an approximate conversion using 41 as the assumed maximum temperature.

## Dashboard

Planned report page:

- KPI cards: total rentals, average daily rentals, registered share, average temperature
- Line chart: monthly rentals by year
- Column charts: rentals by season, weather and weekday
- Donut chart: casual vs registered users
- Slicers: year, season

Use averages (not totals) when comparing weather types or weekdays, since the number of days in each category differs.

_Add dashboard screenshots to `powerbi/` and link them here._

## Tools

PostgreSQL, pgAdmin, SQL, Power BI, DAX


## License

_Add a license of your choice (for example MIT). The dataset has its own terms; see the UCI page above._
