-- Databricks notebook source
-- MAGIC %md
-- MAGIC ## Lakehouse Time Dimension for Delta Live Tables (DLT)
-- MAGIC This notebook creates a time dimension for the lakehouse.
-- MAGIC 
-- MAGIC ### Directions
-- MAGIC - Add/modify/remove columns as necessary
-- MAGIC - Add to Delta Live Tables (DLT) Pipeline
-- MAGIC 
-- MAGIC ### References
-- MAGIC - [Five Simple Steps for Implementing a Star Schema in Databricks With Delta Lake](https://www.databricks.com/blog/2022/05/20/five-simple-steps-for-implementing-a-star-schema-in-databricks-with-delta-lake.html)
-- MAGIC - [Datetime Patterns for Formatting and Parsing](https://spark.apache.org/docs/latest/sql-ref-datetime-pattern.html)

-- COMMAND ----------

create or refresh live table dim_time
comment 'Time dimension'
tblproperties (
  "quality" = "gold",
  "delta.targetFileSize" = "67108864"
)
as
with times as (
  select explode(sequence(to_timestamp('1900-01-01 00:00'), to_timestamp('1900-01-01 23:59'), interval 1 minute)) as time
)
select
  cast(date_format(time, 'HHmm') as int) as id,
  date_format(time, 'hh:mm a') as time,
  date_format(time, 'hh') as hour,
  date_format(time, 'HH:mm') as time_24,
  date_format(time, 'kk') as hour_24,
  date_format(time, 'a') as am_pm
from
  times
