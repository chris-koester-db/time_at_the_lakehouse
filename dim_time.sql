-- Databricks notebook source
-- MAGIC %md
-- MAGIC ## Lakehouse Time Dimension
-- MAGIC This notebook creates a time dimension for the lakehouse.
-- MAGIC 
-- MAGIC ### Directions
-- MAGIC - Set catalog and schema
-- MAGIC - Update the table location.
-- MAGIC - Add/modify/remove columns as necessary
-- MAGIC - Run notebook to load the table
-- MAGIC 
-- MAGIC ### References
-- MAGIC - [Five Simple Steps for Implementing a Star Schema in Databricks With Delta Lake](https://www.databricks.com/blog/2022/05/20/five-simple-steps-for-implementing-a-star-schema-in-databricks-with-delta-lake.html)
-- MAGIC - [Datetime Patterns for Formatting and Parsing](https://spark.apache.org/docs/latest/sql-ref-datetime-pattern.html)

-- COMMAND ----------

-- DBTITLE 1,Set Catalog & Schema
use default

-- COMMAND ----------

-- DBTITLE 1,Load dim_time
create or replace table dim_time
using delta
comment 'Time dimension'
tblproperties ('quality' = 'gold', 'delta.targetFileSize' = '67108864')
location 'dbfs:/tmp/dim_time'
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

-- COMMAND ----------

-- DBTITLE 1,Optimize
optimize dim_time
