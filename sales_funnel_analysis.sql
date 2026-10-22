-- =====================================================================
-- Sales Funnel Analysis — BigQuery (GoogleSQL)
-- Dataset : sql_practice.user_events (practice e-commerce event data)
-- Window  : 30 days ending 2026-02-03 (latest event_date in the table)
-- Author  : Ezra (github.com/farrasezra05)
-- =====================================================================

-- Analysis window. Change end_date to re-run on a different period.
-- end_date was taken from: SELECT MAX(event_date) FROM user_events
DECLARE end_date DATE DEFAULT DATE '2026-02-03';
DECLARE start_ts TIMESTAMP DEFAULT TIMESTAMP(DATE_SUB(end_date, INTERVAL 30 DAY));


-- ---------------------------------------------------------------------
-- (1) Funnel stages: unique users reaching each stage
-- Note: each stage counts users who fired that event in the window,
-- independently of earlier stages (not a strictly sequential funnel).
-- ---------------------------------------------------------------------
WITH funnel_stages AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'      THEN user_id END) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'    THEN user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info'   THEN user_id END) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'       THEN user_id END) AS stage_5_purchase
  FROM `sales-funnel-analysis-20261022.sql_practice.user_events`
  WHERE event_date >= start_ts
)
SELECT * FROM funnel_stages;


-- ---------------------------------------------------------------------
-- (2) Step-by-step conversion rates (%)
-- ---------------------------------------------------------------------
WITH funnel_stages AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'      THEN user_id END) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'    THEN user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info'   THEN user_id END) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'       THEN user_id END) AS stage_5_purchase
  FROM `sales-funnel-analysis-20261022.sql_practice.user_events`
  WHERE event_date >= start_ts
)
SELECT
  stage_1_views,
  stage_2_cart,
  ROUND(SAFE_DIVIDE(stage_2_cart, stage_1_views) * 100, 1)     AS view_to_cart_rate,
  stage_3_checkout,
  ROUND(SAFE_DIVIDE(stage_3_checkout, stage_2_cart) * 100, 1)  AS cart_to_checkout_rate,
  stage_4_payment,
  ROUND(SAFE_DIVIDE(stage_4_payment, stage_3_checkout) * 100, 1) AS checkout_to_payment_rate,
  stage_5_purchase,
  ROUND(SAFE_DIVIDE(stage_5_purchase, stage_4_payment) * 100, 1) AS payment_to_purchase_rate,
  ROUND(SAFE_DIVIDE(stage_5_purchase, stage_1_views) * 100, 1)   AS overall_conversion_rate
FROM funnel_stages;


-- ---------------------------------------------------------------------
-- (3) Funnel by traffic source, with each channel's share of
--     total traffic and total purchases (window function OVER ())
-- ---------------------------------------------------------------------
WITH source_funnel AS (
  SELECT
    traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'   THEN user_id END) AS views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'    THEN user_id END) AS purchases
  FROM `sales-funnel-analysis-20261022.sql_practice.user_events`
  WHERE event_date >= start_ts
  GROUP BY traffic_source
)
SELECT
  traffic_source,
  views,
  carts,
  purchases,
  ROUND(SAFE_DIVIDE(views, SUM(views) OVER ()) * 100, 1)         AS traffic_share,
  ROUND(SAFE_DIVIDE(purchases, SUM(purchases) OVER ()) * 100, 1) AS purchase_share,
  ROUND(SAFE_DIVIDE(carts, views) * 100, 1)                      AS cart_conversion_rate,
  ROUND(SAFE_DIVIDE(purchases, views) * 100, 1)                  AS purchase_conversion_rate,
  ROUND(SAFE_DIVIDE(purchases, carts) * 100, 1)                  AS cart_to_purchase_rate
FROM source_funnel
ORDER BY purchases DESC;


-- ---------------------------------------------------------------------
-- (4) Time to conversion (buyers only), in minutes
-- ---------------------------------------------------------------------
WITH user_journey AS (
  SELECT
    user_id,
    MIN(CASE WHEN event_type = 'page_view'   THEN event_date END) AS view_time,
    MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
    MIN(CASE WHEN event_type = 'purchase'    THEN event_date END) AS purchase_time
  FROM `sales-funnel-analysis-20261022.sql_practice.user_events`
  WHERE event_date >= start_ts
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)
SELECT
  COUNT(*) AS converted_users,
  ROUND(AVG(TIMESTAMP_DIFF(cart_time, view_time, MINUTE)), 2)     AS avg_view_to_cart_minutes,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, cart_time, MINUTE)), 2) AS avg_cart_to_purchase_minutes,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time, MINUTE)), 2) AS avg_total_journey_minutes
FROM user_journey;


-- ---------------------------------------------------------------------
-- (5) Revenue funnel: AOV, revenue per buyer, revenue per visitor
-- ---------------------------------------------------------------------
WITH funnel_revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'  THEN user_id END) AS total_buyers,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END)              AS total_revenue,
    COUNTIF(event_type = 'purchase')                                    AS total_orders
  FROM `sales-funnel-analysis-20261022.sql_practice.user_events`
  WHERE event_date >= start_ts
)
SELECT
  total_visitors,
  total_buyers,
  total_orders,
  ROUND(total_revenue, 2)                                  AS total_revenue,
  ROUND(SAFE_DIVIDE(total_revenue, total_orders), 2)       AS avg_order_value,
  ROUND(SAFE_DIVIDE(total_revenue, total_buyers), 2)       AS revenue_per_buyer,
  ROUND(SAFE_DIVIDE(total_revenue, total_visitors), 2)     AS revenue_per_visitor
FROM funnel_revenue;
