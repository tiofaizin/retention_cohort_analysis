-- Data Context:
-- The data is a daily customer transaction data from a market place company. The data only consists user_id (unique id for each user), order_id (unique id for each purchase transaction made), created_date (user registration date), and trx_date (user transaction date).

-- Goal:
-- To create a monthly and quarterly user retention heat map. Business team need to know monthly retention rate of users since their registeration.

-- Definition:
-- Based on the context and goal above, we need to define several things, such as:

-- Cohort: is a group of users who share common characteristics around a time period. In this, the cohort is: users who register their account in every month of 2022
-- Retention: is a measure of how well your platform retains users. In this case if 100 people sign ups for the market place on first month, but only 20 of them have transaction in the next month, your "retention rate" is 20%.

-- !! Please pay attention to every comment!!

WITH

-- Calculate monthly cohort size. 
-- Cohort size is a number of users that belong into each cohort. In this case we need to calculate the number of users who registered their account in each month of 2022.
cohort_size_monthly AS
(
  SELECT  
    DATE_TRUNC(created_date, MONTH) AS cohort
    , COUNT(DISTINCT user_id) AS cohort_size
  FROM table
  GROUP BY 1
),

-- Calculate quarterly cohort size (if you wish to create quarterly user retention analysis)
cohort_size_quarterly AS
(
  SELECT  
    DATE_TRUNC(created_date, QUARTER) AS cohort
    , COUNT(DISTINCT user_id) AS cohort_size
  FROM table
  GROUP BY 1
),

-- Truncate the data column of data. Find the time (month/quarter) difference between the transaction time and created account time
customer_transaction AS
(
  SELECT
    user_id
    , cohort_month
    , cohort_qtr
    , DATE_DIFF(trx_at_month, cohort_month, MONTH) AS month_diff
    , DATE_DIFF(trx_at_qtr, cohort_qtr, QUARTER) AS qtr_diff
  FROM
  (
    SELECT DISTINCT -- DISTINCT since a user is a retained user when they at least have 1 transaction in the period (month/quarter)
      user_id
      , DATE_TRUNC(created_date, MONTH) AS cohort_month
      , DATE_TRUNC(created_date, QUARTER) AS cohort_qtr
      , DATE_TRUNC(trx_date, MONTH) AS trx_at_month
      , DATE_TRUNC(trx_date, QUARTER) AS trx_at_qtr
    FROM table
  )
),

-- PIVOT monthly with time diff as columns and created_month as rows
pivot_monthly AS
(
  SELECT
    * 
  FROM
  (
    SELECT
      * EXCEPT(cohort_qtr, qtr_diff) 
    FROM customer_transaction
  )
  PIVOT(COUNT(DISTINCT user_id) FOR month_diff IN (0,1,2,3,4,5,6,7,8,9,10,11))
),

-- PIVOT quarterly with time diff as columns and quarterly created_month as rows
pivot_quarterly AS
(
  SELECT
    * 
  FROM
  (
    SELECT
      * EXCEPT(cohort_month, month_diff) 
    FROM customer_transaction
  )
  PIVOT(COUNT(DISTINCT user_id) FOR qtr_diff IN (0,1,2,3))
),

-- Join monthly cohort size with monthly pivot
join_cohort_size_monthly AS
(
  SELECT
    pm.cohort_month
    , cm.cohort_size
    , _0,_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11
  FROM pivot_monthly pm
  JOIN cohort_size_monthly cm
  ON pm.cohort_month = cm.cohort
),

-- Join quarterly cohort size with quarterly pivot
join_cohort_size_quarterly AS
(
  SELECT
    pq.cohort_qtr
    , cq.cohort_size
    , _0,_1,_2,_3
  FROM pivot_quarterly pq
  JOIN cohort_size_quarterly cq
  ON pq.cohort_qtr = cq.cohort
)

-- run and export this to excel/csv and draw the monthly retention cohort heatmap
SELECT
  *
FROM join_cohort_size_monthly
ORDER BY cohort_month

---- run and export this to excel/csv and draw the quarterly retention cohort heatmap
-- SELECT
--   *
-- FROM join_cohort_size_quarterly
-- ORDER BY cohort_qtr