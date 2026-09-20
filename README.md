# Divvy Bikeshare Analytics: Ridership, Network Activity & Access

**End-to-end SQL and Tableau analysis of 14.8M+ Divvy Bikeshare trips across Chicago from 2016–2019.**

`PostgreSQL` · `SQL` · `Tableau` · `Data Cleaning` · `Data Quality` · `Data Visualisation` · `Geospatial Analysis`

---

## Project Overview

This project explores four years of Divvy Bikeshare activity to understand how
ridership changes over time, how different rider groups use the network, where
station demand is concentrated, and how access to the network relates to the
wider demographic and transport characteristics of Chicago communities.

The project involved building a SQL workflow to investigate and clean millions
of trip records before creating analysis-ready datasets for an interactive
Tableau dashboard.

The final analytical pipeline contains **14,819,061 valid trips from
2016–2019**.

### Key Questions

The analysis was designed around several questions:

- How does Divvy ridership vary by month, season and year?
- At what times of day is demand highest?
- How do customers and subscribers use the network differently?
- Which age groups account for the largest share of journeys?
- Which stations experience the greatest departure and arrival pressure?
- How evenly is Divvy infrastructure distributed across Chicago communities?
- Does network access align with areas where alternative transport options
  may be most important?

---

## Dashboard 1 — Divvy Network Overview

![Divvy Network Overview](images/divvy_network_overview.png)

The primary dashboard provides an interactive overview of network activity
between 2016 and 2019, combining temporal, demographic and spatial analysis.

It includes:

- monthly ridership and seasonal demand
- average trip duration
- customer share
- peak travel hour
- rider age profiles
- hourly demand by rider type
- station-level departures and arrivals
- net station flow across the Chicago network

The dashboard can be filtered by month, allowing changes in demand and network
behaviour to be explored over time.

### Ridership Patterns

Monthly ridership displays a pronounced seasonal pattern, with usage increasing
through spring and summer before declining during the colder months.

The temporal analysis also allows year-to-year changes in network demand to be
compared across the four-year period.

### Rider Behaviour

Customers and subscribers exhibit different hourly usage patterns.

Subscriber activity is concentrated more strongly around traditional commuting
periods, while customer activity shows a different daily profile. This provides
useful context for distinguishing regular transport use from more occasional
journeys.

### Station Activity

Station-level analysis compares departures and arrivals to calculate **net
station flow**.

This highlights areas where bicycles accumulate or are depleted and provides a
simple way of identifying potential network pressure and redistribution needs.

---

## Dashboard 2 — Network Access & Community Context

![Network Access and Community Context](images/network_access_context.png)

The second dashboard extends the trip analysis beyond individual journeys to
consider the geographical distribution of Divvy infrastructure across Chicago.

Community-level indicators are used alongside station availability to explore
how network access relates to characteristics including:

- population
- median household income
- households without access to a vehicle
- public-transit commuting
- walking and cycling commuting
- station availability per 10,000 residents

The dashboard combines a community-area map with a population-scaled scatter
plot to support comparison between transport need and Divvy station access.

Rather than treating station count alone as a measure of accessibility,
normalising station availability by population provides additional context for
differences between communities.

---

## Data Quality Assessment

Before analysis, the four annual datasets were profiled separately to identify
data-quality issues and structural inconsistencies.

The investigation included checks for:

- duplicate trip IDs
- missing trip identifiers
- invalid timestamps
- non-positive trip durations
- unusually long journeys
- missing station identifiers
- missing demographic information
- implausible birth years
- differences in data completeness between years

These checks informed the final cleaning rules rather than removing records
without first investigating their frequency and distribution.

---

## Data Cleaning & Transformation

A reproducible PostgreSQL pipeline was developed to combine and standardise the
2016–2019 datasets.

The final analytical dataset:

- removes duplicate trip IDs
- excludes journeys with invalid timestamps
- removes non-positive trip durations
- applies a **4-hour maximum trip-duration threshold**
- standardises rider and demographic fields
- derives temporal features
- creates age groups for demographic analysis
- retains station information required for spatial analysis

The resulting dataset contains:

**14,819,061 valid trips**

Additional SQL transformations then produce separate datasets optimised for
Tableau rather than exporting the full trip-level table.

---

## Tableau Data Pipeline

Two purpose-built analytical datasets were generated from PostgreSQL.

### Temporal & Demographic Dataset

Used for:

- monthly ridership
- seasonal trends
- hourly demand
- rider-type comparison
- age-group analysis
- trip-duration metrics

### Station Activity Dataset

Used for:

- station departures
- station arrivals
- total station activity
- net station flow
- geographical network analysis

Pre-aggregating the data in SQL substantially reduces the amount of data that
needs to be processed by Tableau while retaining the dimensions required for
the dashboard.

```text
Raw Divvy Data (2016–2019)
            │
            ▼
     PostgreSQL Tables
            │
            ▼
   Data Quality Profiling
            │
            ▼
 Cleaning & Standardisation
            │
            ▼
    Feature Engineering
            │
            ▼
       14.8M Valid Trips
            │
       ┌────┴────┐
       ▼         ▼
   Temporal    Station
   Aggregate   Aggregate
       │         │
       └────┬────┘
            ▼
          Tableau
            │
            ▼
 Interactive Dashboards
```

---

## SQL Workflow

The SQL implementation is separated into six stages:

| File | Purpose |
|---|---|
| `01_dataset_exploration.sql` | Initial profiling of the four yearly datasets |
| `02_data_quality_assessment.sql` | Duplicate, timestamp, duration, demographic and station-quality checks |
| `03_cleaning_transformation.sql` | Final cleaning rules and creation of the unified analytical dataset |
| `04_tableau_temporal_export.sql` | Aggregation for temporal and demographic Tableau analysis |
| `05_tableau_station_export.sql` | Station-level aggregation and net-flow calculation |
| `06_validation_checks.sql` | Validation of the final cleaned dataset |

The complete SQL workflow is available in the [`sql/`](sql/) directory.

---

## Repository Structure

```text
divvy-bikeshare-analysis/
│
├── sql/
│   ├── 01_dataset_exploration.sql
│   ├── 02_data_quality_assessment.sql
│   ├── 03_cleaning_transformation.sql
│   ├── 04_tableau_temporal_export.sql
│   ├── 05_tableau_station_export.sql
│   └── 06_validation_checks.sql
│
├── data/
│   └── README.md
│
├── workbook/
│   └── [Tableau workbook]
│
├── images/
│   ├── divvy_network_overview.png
│   └── network_access_context.png
│
├── README.md
└── .gitignore
```

---

## Data

The project uses Divvy Bikeshare trip data covering **2016–2019**.

The full raw and processed CSV datasets are not stored in this repository due
to their size. The SQL scripts document the transformations used to create the
analysis-ready Tableau datasets.

See [`data/README.md`](data/README.md) for further information.

---

## Tools & Technologies

**Database & Querying**
- PostgreSQL
- SQL
- pgAdmin

**Data Preparation**
- data profiling
- data cleaning
- validation
- feature engineering
- aggregation

**Visualisation**
- Tableau
- interactive dashboard design
- geospatial analysis
- demographic segmentation

---

## Skills Demonstrated

This project demonstrates experience working across the full analytical
workflow:

**Large-scale data processing** — working with approximately 14.8 million
cleaned trip records across multiple yearly datasets.

**Data quality** — investigating duplicates, missing values, timestamp
validity, duration anomalies and demographic inconsistencies before defining
cleaning rules.

**SQL transformation** — building reusable CTE-based pipelines for cleaning,
feature engineering and aggregation.

**Analytical data modelling** — designing separate datasets around the
requirements of downstream visualisations rather than passing raw data
directly into Tableau.

**Data visualisation** — translating large-scale trip and community data into
interactive dashboards covering temporal, demographic and spatial patterns.

---

## Author

**Nick Belemet**  
Mathematics & Data Science Graduate/Micro-niche celebrity
