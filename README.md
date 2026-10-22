# Sales Funnel Analysis in SQL (BigQuery)

Where do e-commerce shoppers drop off, which channels bring buyers (not just visitors), and how much is each improvement worth?

A five-stage funnel analysis on 30 days of e-commerce event data, written in GoogleSQL on BigQuery.

> **Data note:** this is a practice dataset from the tutorial [Watch me Do a Data Analyst Project in minutes with SQL](https://www.youtube.com/watch?v=U-JlXWDqvco) by Lore So What. Every buyer placed exactly one order, so revenue per buyer equals average order value. The findings show the method, not a real business. See [Data](#data) for how to get it.

## Headline findings

| | |
|---|---|
| Visitors → buyers | **4,291 → 709** (16.5% overall conversion) |
| Biggest drop-off | **View → cart: only 31.2%** add anything to cart |
| Best channel | **Email: 33.9%** of visitors buy, 5× social (6.7%) |
| Journey length | **~25 min** from first view to purchase |
| Revenue | **$76,192**, $107.46 per order, **$17.76 per visitor** |

### 1. The leak is at the top of the funnel

| Stage | Users | Step conversion |
|---|---:|---:|
| Page view | 4,291 | — |
| Add to cart | 1,338 | **31.2%** |
| Checkout start | 954 | 71.3% |
| Payment info | 770 | 80.7% |
| Purchase | 709 | 92.1% |

69% of visitors leave before adding to cart. Every later step converts at 71% or more.

### 2. Channel decides intent; after the cart, channel barely matters

| Channel | Traffic share | Purchase share | View → cart | View → purchase | Cart → purchase |
|---|---:|---:|---:|---:|---:|
| Organic | 40.9% | 42.3% | 32.9% | 17.1% | 51.9% |
| Paid ads | 19.2% | 24.4% | 37.1% | 21.0% | 56.5% |
| Email | 10.5% | 21.4% | 63.0% | 33.9% | 53.7% |
| Social | 29.4% | 11.8% | 13.6% | 6.7% | 49.1% |

- Social is 29% of traffic but only 12% of buyers.
- Email is 10% of traffic but 21% of buyers.
- Cart → purchase sits between 49% and 57% for every channel, so the channel gap comes from intent at landing, not from checkout.

### 3. Buyers decide within one session

Average 11.2 min from first view to cart, then 13.4 min from cart to purchase (24.6 min total). Cart-recovery messages should fire within the hour.

### 4. What improvements are worth

Using $107.46 per order and holding the other conversion rates constant:

| Scenario | Extra buyers | Extra revenue |
|---|---:|---:|
| View → cart from 31% to 34% | ~64 | ~$6.9K (+9%) |
| Social converts like organic (6.7% → 17.1%) | ~131 | ~$14.1K (+18.5%) |

These are simple what-ifs, not forecasts.

## Recommendations

1. **Fix the top of the funnel first:** product pages, pricing clarity and the add-to-cart experience.
2. **Rethink social traffic:** send it to higher-intent landing pages, or shift budget toward channels that convert.
3. **Grow the email list:** it is the highest-intent channel.
4. **Send cart recovery within the hour**, matching how fast buyers decide.

## Data

**Source:** the dataset comes from the YouTube tutorial [Watch me Do a Data Analyst Project in minutes with SQL](https://www.youtube.com/watch?v=U-JlXWDqvco) by Lore So What. The download link is in the video description. The data isn't included in this repo because it belongs to the tutorial's creator.

**Table:** `sql_practice.user_events`, one row per user event. The columns these queries use:

| Column | Description |
|---|---|
| `user_id` | Unique identifier for each user |
| `event_type` | The funnel action: `page_view`, `add_to_cart`, `checkout_start`, `payment_info` or `purchase` |
| `event_date` | Timestamp of the event |
| `traffic_source` | Channel the user arrived from: `organic`, `paid_ads`, `email` or `social` |
| `amount` | Order value, filled in on `purchase` events |

## Queries

All queries are in [`sales_funnel_analysis.sql`](sales_funnel_analysis.sql):

1. Funnel stages (unique users per stage)
2. Step-by-step conversion rates
3. Funnel by traffic source, with traffic and purchase share
4. Time to conversion for buyers
5. Revenue funnel (AOV, revenue per buyer and per visitor)

Results are in [`results/`](results/).

## SQL techniques used

- **Conditional aggregation:** `COUNT(DISTINCT CASE WHEN event_type = '...' THEN user_id END)` to pivot event rows into funnel stages in one pass
- **CTEs** to separate counting from rate calculations
- **Window functions:** `SUM(views) OVER ()` to compute each channel's share without collapsing rows
- **`TIMESTAMP_DIFF`** with `MIN(...)` per user to measure journey timing
- **`SAFE_DIVIDE`** to avoid divide-by-zero errors
- **Script variables** (`DECLARE`) so the analysis window is set once

## Limitations

- **Not a strictly sequential funnel.** Each stage counts users who fired that event, regardless of whether they reached earlier stages. A stricter version would require each user to have completed the previous step.
- **Fixed 30-day window** ending at the latest date in the table (2026-02-03).
- **Practice data:** no repeat purchases and no product or segment detail, so the recommendations are illustrative.

## Credit

The dataset and the original project idea come from [Lore So What's tutorial](https://www.youtube.com/watch?v=U-JlXWDqvco). I extended it with channel traffic and purchase shares, revenue what-if scenarios and business recommendations.

## How to run

1. Download the dataset from the link in the [tutorial's description](https://www.youtube.com/watch?v=U-JlXWDqvco) and load it into BigQuery as a table named `user_events`.
2. Update the project and dataset name in `sales_funnel_analysis.sql`.
3. Run the script. Each numbered block returns one result set.
