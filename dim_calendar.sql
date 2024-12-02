-- Databricks notebook source
-- MAGIC %md
-- MAGIC ## Lakehouse Calendar Dimension
-- MAGIC This notebook creates a calendar dimension (Also known as date dimension) for the lakehouse. It is intended to be reloaded daily, and defaults to loading data using a rolling 5 year period.
-- MAGIC 
-- MAGIC ### Directions
-- MAGIC - Set catalog and schema
-- MAGIC - Update the table location
-- MAGIC - Modify the date range as necessary by updating the dates CTE
-- MAGIC - Add/modify/remove columns as necessary
-- MAGIC - Schedule to run daily using Workflows
-- MAGIC 
-- MAGIC ### References
-- MAGIC - [Five Simple Steps for Implementing a Star Schema in Databricks With Delta Lake](https://www.databricks.com/blog/2022/05/20/five-simple-steps-for-implementing-a-star-schema-in-databricks-with-delta-lake.html)
-- MAGIC - [Datetime Patterns for Formatting and Parsing](https://spark.apache.org/docs/latest/sql-ref-datetime-pattern.html)

-- COMMAND ----------

-- DBTITLE 1,Set Catalog & Schema
use default

-- COMMAND ----------

-- DBTITLE 1,Load dim_calendar
create or replace table dim_calendar
using delta
comment 'Calendar dimension'
tblproperties ('quality' = 'gold', 'delta.targetFileSize' = '67108864')
location 'dbfs:/tmp/dim_calendar'
as
--Set the date range in the dates CTE below
with dates as (
  select explode(sequence(current_date() - interval 5 years, current_date(), interval 1 day)) AS calendar_date
)
select
  year(calendar_date) * 10000 + month(calendar_date) * 100 + day(calendar_date) as date_int,
  calendar_date,
  year(calendar_date) AS calendar_year,
  date_format(calendar_date, 'MMMM') as calendar_month,
  month(calendar_date) as month_of_year,
  date_format(calendar_date, 'EEEE') as calendar_day,
  dayofweek(calendar_date) AS day_of_week,
  weekday(calendar_date) + 1 as day_of_week_start_monday,
  case
    when weekday(calendar_date) < 5 then 'Y'
    else 'N'
  end as is_week_day,
  dayofmonth(calendar_date) as day_of_month,
  case
    when calendar_date = last_day(calendar_date) then 'Y'
    else 'N'
  end as is_last_day_of_month,
  dayofyear(calendar_date) as day_of_year,
  weekofyear(calendar_date) as week_of_year_iso,
  quarter(calendar_date) as quarter_of_year,
  /* Use fiscal periods needed by organization fiscal calendar */
  case
    when month(calendar_date) >= 10 then year(calendar_date) + 1
    else year(calendar_date)
  end as fiscal_year_oct_to_sep,
  (month(calendar_date) + 2) % 12 + 1 AS fiscal_month_oct_to_sep,
  case
    when month(calendar_date) >= 7 then year(calendar_date) + 1
    else year(calendar_date)
  end as fiscal_year_jul_to_jun,
  (month(calendar_date) + 5) % 12 + 1 AS fiscal_month_jul_to_jun
from
  dates
order by
  calendar_date

-- COMMAND ----------

-- DBTITLE 1,Optimize
optimize dim_calendar zorder by (calendar_date)

-- COMMAND ----------

-- DBTITLE 1,Vacuum
vacuum dim_calendar
