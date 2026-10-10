/* =====================================================================
   STOCK MARKET ANALYSIS  |  SQL (SQLite 3.25+ dialect, uses window functions)
   Companies : Bajaj Auto, Eicher Motors, Hero MotoCorp, Infosys, TCS, TVS Motors
   Period    : 2015-01-01 to 2018-07-31 (889 trading days per stock)

   Source tables (one per stock, loaded from the CSV files):
     bajaj_auto, eicher_motors, hero_motocorp, infosys, tcs, tvs_motors
   Columns: date (YYYY-MM-DD), open_price, high_price, low_price, close_price,
            wap, no_of_shares, no_of_trades, total_turnover, deliverable_qty,
            pct_deli_qty, spread_high_low, spread_close_open

   NOTE: The CSVs list dates newest-first, so every window function below
   uses ORDER BY date ASC explicitly. Never rely on row order.
   NOTE: Signals are historical, SQL-generated crossovers, NOT investment advice.
   ===================================================================== */


/* =====================================================================
   MODULE 1 - UNDERSTAND THE DATA
   ===================================================================== */

-- 1.1 Columns and data types of one table (all six share the same layout)
PRAGMA table_info(bajaj_auto);

-- 1.2 Row count, date range and distinct dates for every stock
SELECT 'Bajaj Auto' AS stock, COUNT(*) AS total_rows, COUNT(DISTINCT date) AS distinct_dates, MIN(date) AS first_date, MAX(date) AS last_date FROM bajaj_auto
UNION ALL
SELECT 'Eicher Motors', COUNT(*), COUNT(DISTINCT date), MIN(date), MAX(date) FROM eicher_motors
UNION ALL
SELECT 'Hero MotoCorp', COUNT(*), COUNT(DISTINCT date), MIN(date), MAX(date) FROM hero_motocorp
UNION ALL
SELECT 'Infosys', COUNT(*), COUNT(DISTINCT date), MIN(date), MAX(date) FROM infosys
UNION ALL
SELECT 'TCS', COUNT(*), COUNT(DISTINCT date), MIN(date), MAX(date) FROM tcs
UNION ALL
SELECT 'TVS Motors', COUNT(*), COUNT(DISTINCT date), MIN(date), MAX(date) FROM tvs_motors;

-- 1.3 Basic sanity check on prices (high >= low, close inside the day range)
SELECT 'Bajaj Auto' AS stock,
       SUM(CASE WHEN high_price < low_price THEN 1 ELSE 0 END) AS high_below_low,
       SUM(CASE WHEN close_price > high_price OR close_price < low_price THEN 1 ELSE 0 END) AS close_outside_range,
       MIN(close_price) AS min_close, MAX(close_price) AS max_close
FROM bajaj_auto
UNION ALL
SELECT 'Eicher Motors', SUM(CASE WHEN high_price < low_price THEN 1 ELSE 0 END), SUM(CASE WHEN close_price > high_price OR close_price < low_price THEN 1 ELSE 0 END), MIN(close_price), MAX(close_price) FROM eicher_motors
UNION ALL
SELECT 'Hero MotoCorp', SUM(CASE WHEN high_price < low_price THEN 1 ELSE 0 END), SUM(CASE WHEN close_price > high_price OR close_price < low_price THEN 1 ELSE 0 END), MIN(close_price), MAX(close_price) FROM hero_motocorp
UNION ALL
SELECT 'Infosys', SUM(CASE WHEN high_price < low_price THEN 1 ELSE 0 END), SUM(CASE WHEN close_price > high_price OR close_price < low_price THEN 1 ELSE 0 END), MIN(close_price), MAX(close_price) FROM infosys
UNION ALL
SELECT 'TCS', SUM(CASE WHEN high_price < low_price THEN 1 ELSE 0 END), SUM(CASE WHEN close_price > high_price OR close_price < low_price THEN 1 ELSE 0 END), MIN(close_price), MAX(close_price) FROM tcs
UNION ALL
SELECT 'TVS Motors', SUM(CASE WHEN high_price < low_price THEN 1 ELSE 0 END), SUM(CASE WHEN close_price > high_price OR close_price < low_price THEN 1 ELSE 0 END), MIN(close_price), MAX(close_price) FROM tvs_motors;


/* =====================================================================
   MODULE 2 - DATA QUALITY / MISSING VALUES
   Count NULLs in every column of every table.
   ===================================================================== */

SELECT 'Bajaj Auto' AS stock,
       SUM(date IS NULL) AS date_nulls, SUM(open_price IS NULL) AS open_nulls, SUM(high_price IS NULL) AS high_nulls,
       SUM(low_price IS NULL) AS low_nulls, SUM(close_price IS NULL) AS close_nulls, SUM(wap IS NULL) AS wap_nulls,
       SUM(no_of_shares IS NULL) AS shares_nulls, SUM(no_of_trades IS NULL) AS trades_nulls,
       SUM(total_turnover IS NULL) AS turnover_nulls, SUM(deliverable_qty IS NULL) AS deliverable_qty_nulls,
       SUM(pct_deli_qty IS NULL) AS pct_deli_nulls
FROM bajaj_auto
UNION ALL
SELECT 'Eicher Motors', SUM(date IS NULL), SUM(open_price IS NULL), SUM(high_price IS NULL), SUM(low_price IS NULL), SUM(close_price IS NULL), SUM(wap IS NULL), SUM(no_of_shares IS NULL), SUM(no_of_trades IS NULL), SUM(total_turnover IS NULL), SUM(deliverable_qty IS NULL), SUM(pct_deli_qty IS NULL) FROM eicher_motors
UNION ALL
SELECT 'Hero MotoCorp', SUM(date IS NULL), SUM(open_price IS NULL), SUM(high_price IS NULL), SUM(low_price IS NULL), SUM(close_price IS NULL), SUM(wap IS NULL), SUM(no_of_shares IS NULL), SUM(no_of_trades IS NULL), SUM(total_turnover IS NULL), SUM(deliverable_qty IS NULL), SUM(pct_deli_qty IS NULL) FROM hero_motocorp
UNION ALL
SELECT 'Infosys', SUM(date IS NULL), SUM(open_price IS NULL), SUM(high_price IS NULL), SUM(low_price IS NULL), SUM(close_price IS NULL), SUM(wap IS NULL), SUM(no_of_shares IS NULL), SUM(no_of_trades IS NULL), SUM(total_turnover IS NULL), SUM(deliverable_qty IS NULL), SUM(pct_deli_qty IS NULL) FROM infosys
UNION ALL
SELECT 'TCS', SUM(date IS NULL), SUM(open_price IS NULL), SUM(high_price IS NULL), SUM(low_price IS NULL), SUM(close_price IS NULL), SUM(wap IS NULL), SUM(no_of_shares IS NULL), SUM(no_of_trades IS NULL), SUM(total_turnover IS NULL), SUM(deliverable_qty IS NULL), SUM(pct_deli_qty IS NULL) FROM tcs
UNION ALL
SELECT 'TVS Motors', SUM(date IS NULL), SUM(open_price IS NULL), SUM(high_price IS NULL), SUM(low_price IS NULL), SUM(close_price IS NULL), SUM(wap IS NULL), SUM(no_of_shares IS NULL), SUM(no_of_trades IS NULL), SUM(total_turnover IS NULL), SUM(deliverable_qty IS NULL), SUM(pct_deli_qty IS NULL) FROM tvs_motors;

-- 2.2 Where exactly are the NULLs? (6 rows in total, on two dates)
SELECT 'Bajaj Auto' AS stock, date, close_price, deliverable_qty FROM bajaj_auto WHERE deliverable_qty IS NULL
UNION ALL SELECT 'Eicher Motors', date, close_price, deliverable_qty FROM eicher_motors WHERE deliverable_qty IS NULL
UNION ALL SELECT 'Hero MotoCorp', date, close_price, deliverable_qty FROM hero_motocorp WHERE deliverable_qty IS NULL
UNION ALL SELECT 'Infosys', date, close_price, deliverable_qty FROM infosys WHERE deliverable_qty IS NULL
UNION ALL SELECT 'TCS', date, close_price, deliverable_qty FROM tcs WHERE deliverable_qty IS NULL
UNION ALL SELECT 'TVS Motors', date, close_price, deliverable_qty FROM tvs_motors WHERE deliverable_qty IS NULL
ORDER BY date, stock;

/* Decision: the NULLs are left as they are (not replaced with 0 or an average).
   They sit only in deliverable_qty / pct_deli_qty. Every analysis below uses
   close_price, which has zero NULLs, so the missing values do not affect results.
   SQL aggregates such as AVG() / COUNT(column) already ignore NULLs. */


/* =====================================================================
   MODULE 3 - BASIC SQL PRACTICE
   ===================================================================== */

-- 3.1 Eicher Motors: top 5 highest closing prices
SELECT date, close_price
FROM eicher_motors
ORDER BY close_price DESC
LIMIT 5;

-- 3.2 TCS: yearly average closing price (2018 covers Jan-Jul only)
SELECT strftime('%Y', date) AS year,
       COUNT(*)                     AS trading_days,
       ROUND(AVG(close_price), 2)   AS avg_close_price
FROM tcs
GROUP BY strftime('%Y', date)
ORDER BY year;
/* Caution: TCS prices before 31-May-2018 are not bonus-adjusted, so the 2018
   average mixes two price scales. See Modules 10-11 for the adjusted version. */


/* =====================================================================
   MODULE 4 - MOVING AVERAGES (BAJAJ AUTO)
   MA20 = average of today + previous 19 trading days
   MA50 = average of today + previous 49 trading days
   The MA is NULL until a full window exists (first 19 / 49 days), so that
   a partial window can never create a fake crossover.
   ===================================================================== */

DROP TABLE IF EXISTS bajaj1;

CREATE TABLE bajaj1 AS
WITH ranked AS (
    SELECT date,
           close_price,
           ROW_NUMBER() OVER (ORDER BY date) AS rn,
           AVG(close_price) OVER (ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS avg20,
           AVG(close_price) OVER (ORDER BY date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS avg50
    FROM bajaj_auto
)
SELECT date,
       close_price,
       CASE WHEN rn >= 20 THEN avg20 END AS ma20,
       CASE WHEN rn >= 50 THEN avg50 END AS ma50
FROM ranked;

-- 4.1 Preview (rounded for display only)
SELECT date, close_price, ROUND(ma20, 2) AS ma20, ROUND(ma50, 2) AS ma50
FROM bajaj1
ORDER BY date DESC
LIMIT 10;


/* =====================================================================
   MODULE 5 - BUY / SELL / HOLD (BAJAJ AUTO)
   BUY : yesterday MA20 <= MA50  AND  today MA20 >  MA50
   SELL: yesterday MA20 >= MA50  AND  today MA20 <  MA50
   else HOLD.   LAG() fetches yesterday's values.
   ===================================================================== */

DROP TABLE IF EXISTS bajaj_signals;

CREATE TABLE bajaj_signals AS
WITH lagged AS (
    SELECT date, close_price, ma20, ma50,
           LAG(ma20) OVER (ORDER BY date) AS prev_ma20,
           LAG(ma50) OVER (ORDER BY date) AS prev_ma50
    FROM bajaj1
)
SELECT date, close_price, ma20, ma50, prev_ma20, prev_ma50,
       CASE WHEN prev_ma20 <= prev_ma50 AND ma20 > ma50 THEN 'BUY'
            WHEN prev_ma20 >= prev_ma50 AND ma20 < ma50 THEN 'SELL'
            ELSE 'HOLD' END AS signal
FROM lagged;

-- 5.1 Count of each signal for Bajaj
SELECT signal, COUNT(*) AS days FROM bajaj_signals GROUP BY signal ORDER BY days DESC;

-- 5.2 Every BUY / SELL crossover for Bajaj
SELECT date, close_price, ROUND(ma20, 2) AS ma20, ROUND(ma50, 2) AS ma50, signal
FROM bajaj_signals
WHERE signal <> 'HOLD'
ORDER BY date;


/* =====================================================================
   MODULE 6 - APPLY THE LOGIC TO ALL 6 STOCKS
   UNION ALL -> PARTITION BY stock -> MA20 + MA50 -> LAG() -> signal
   ===================================================================== */

DROP VIEW IF EXISTS all_prices;

CREATE VIEW all_prices AS
SELECT 'Bajaj Auto'    AS stock, date, close_price FROM bajaj_auto
UNION ALL
SELECT 'Eicher Motors' AS stock, date, close_price FROM eicher_motors
UNION ALL
SELECT 'Hero MotoCorp' AS stock, date, close_price FROM hero_motocorp
UNION ALL
SELECT 'Infosys'       AS stock, date, close_price FROM infosys
UNION ALL
SELECT 'TCS'           AS stock, date, close_price FROM tcs
UNION ALL
SELECT 'TVS Motors'    AS stock, date, close_price FROM tvs_motors;

-- 6.1 Check: 6 x 889 = 5,334 rows
SELECT stock, COUNT(*) AS rows_per_stock FROM all_prices GROUP BY stock ORDER BY stock;

DROP TABLE IF EXISTS stock_signals;

CREATE TABLE stock_signals AS
WITH ma AS (
    SELECT stock, date, close_price,
           ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date) AS rn,
           AVG(close_price) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS avg20,
           AVG(close_price) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS avg50
    FROM all_prices
),
full_window AS (
    SELECT stock, date, close_price,
           CASE WHEN rn >= 20 THEN avg20 END AS ma20,
           CASE WHEN rn >= 50 THEN avg50 END AS ma50
    FROM ma
),
lagged AS (
    SELECT stock, date, close_price, ma20, ma50,
           LAG(ma20) OVER (PARTITION BY stock ORDER BY date) AS prev_ma20,
           LAG(ma50) OVER (PARTITION BY stock ORDER BY date) AS prev_ma50
    FROM full_window
)
SELECT stock, date, close_price, ma20, ma50, prev_ma20, prev_ma50,
       CASE WHEN prev_ma20 <= prev_ma50 AND ma20 > ma50 THEN 'BUY'
            WHEN prev_ma20 >= prev_ma50 AND ma20 < ma50 THEN 'SELL'
            ELSE 'HOLD' END AS signal
FROM lagged;

-- 6.2 Preview: latest 3 rows per stock
SELECT stock, date, close_price, ROUND(ma20, 2) AS ma20, ROUND(ma50, 2) AS ma50, signal
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS r FROM stock_signals)
WHERE r <= 3
ORDER BY stock, date DESC;


/* =====================================================================
   MODULE 7 - SIGNAL ANALYSIS
   Buy / Sell / Hold counts and the latest signal for each stock
   ===================================================================== */

-- 7.1 Signal counts + latest crossover signal (last BUY/SELL event) + current trend
WITH counts AS (
    SELECT stock,
           SUM(signal = 'BUY')  AS buy_signals,
           SUM(signal = 'SELL') AS sell_signals,
           SUM(signal = 'HOLD') AS hold_signals
    FROM stock_signals
    GROUP BY stock
),
last_cross AS (
    SELECT stock, date AS latest_signal_date, signal AS latest_signal
    FROM (SELECT stock, date, signal,
                 ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS r
          FROM stock_signals
          WHERE signal <> 'HOLD')
    WHERE r = 1
),
last_day AS (
    SELECT stock, date AS last_trading_day, signal AS signal_on_last_day,
           CASE WHEN ma20 > ma50 THEN 'MA20 above MA50 (bullish)'
                ELSE 'MA20 below MA50 (bearish)' END AS current_trend
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS r FROM stock_signals)
    WHERE r = 1
)
SELECT c.stock, c.buy_signals, c.sell_signals, c.hold_signals,
       l.latest_signal, l.latest_signal_date,
       d.signal_on_last_day, d.current_trend
FROM counts c
JOIN last_cross l ON l.stock = c.stock
JOIN last_day   d ON d.stock = c.stock
ORDER BY c.stock;

-- 7.2 Full list of crossover events, all stocks
SELECT stock, date, close_price, ROUND(ma20, 2) AS ma20, ROUND(ma50, 2) AS ma50, signal
FROM stock_signals
WHERE signal <> 'HOLD'
ORDER BY stock, date;


/* =====================================================================
   MODULE 8 - STOCK PERFORMANCE (first vs last close)
   % Change = (Last Close - First Close) / First Close * 100
   ===================================================================== */

WITH bounds AS (
    SELECT stock, MIN(date) AS first_date, MAX(date) AS last_date
    FROM all_prices
    GROUP BY stock
)
SELECT b.stock,
       f.close_price AS first_close,
       l.close_price AS last_close,
       ROUND((l.close_price - f.close_price) * 100.0 / f.close_price, 2) AS pct_change
FROM bounds b
JOIN all_prices f ON f.stock = b.stock AND f.date = b.first_date
JOIN all_prices l ON l.stock = b.stock AND l.date = b.last_date
ORDER BY pct_change DESC;
/* Answer: the stock at the top rose the most, the bottom fell the most.
   Careful: TCS and Infosys look worse than they are, see Modules 10-11. */


/* =====================================================================
   MODULE 9 - WORST TRADING DAY (biggest one-day fall) for each stock
   ===================================================================== */

DROP VIEW IF EXISTS daily_change;

CREATE VIEW daily_change AS
SELECT stock, date, close_price,
       LAG(close_price) OVER (PARTITION BY stock ORDER BY date) AS prev_close,
       ROUND((close_price - LAG(close_price) OVER (PARTITION BY stock ORDER BY date)) * 100.0
             / LAG(close_price) OVER (PARTITION BY stock ORDER BY date), 2) AS pct_change
FROM all_prices;

SELECT stock, date AS worst_day, prev_close, close_price, pct_change
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY stock ORDER BY pct_change ASC) AS r
      FROM daily_change
      WHERE pct_change IS NOT NULL)
WHERE r = 1
ORDER BY pct_change;
/* Two values near -50% (Infosys 2015-06-15, TCS 2018-05-31) are suspicious.
   Real companies rarely lose half their value in a day. Investigated next. */


/* =====================================================================
   MODULE 10 - INVESTIGATE UNUSUAL PRICE MOVEMENTS (TCS, Infosys)
   Test: if it is a 1:1 bonus issue, the price should roughly halve (ratio ~0.5)
   AND the number of shares traded should roughly double.
   ===================================================================== */

-- 10.1 Price ratio and volume ratio on the suspicious dates
WITH x AS (
    SELECT 'Infosys' AS stock, date, close_price, no_of_shares, total_turnover,
           LAG(close_price)    OVER (ORDER BY date) AS prev_close,
           LAG(no_of_shares)   OVER (ORDER BY date) AS prev_shares,
           LAG(total_turnover) OVER (ORDER BY date) AS prev_turnover
    FROM infosys
    UNION ALL
    SELECT 'TCS', date, close_price, no_of_shares, total_turnover,
           LAG(close_price)    OVER (ORDER BY date),
           LAG(no_of_shares)   OVER (ORDER BY date),
           LAG(total_turnover) OVER (ORDER BY date)
    FROM tcs
)
SELECT stock, date, prev_close, close_price,
       ROUND(close_price * 1.0 / prev_close, 3)       AS price_ratio,
       prev_shares, no_of_shares,
       ROUND(no_of_shares * 1.0 / prev_shares, 2)     AS share_volume_ratio,
       ROUND(total_turnover * 1.0 / prev_turnover, 2) AS turnover_ratio
FROM x
WHERE (stock = 'Infosys' AND date = '2015-06-15')
   OR (stock = 'TCS'     AND date = '2018-05-31');

-- 10.2 Five trading days around each event
SELECT 'Infosys' AS stock, date, open_price, close_price, no_of_shares FROM infosys
WHERE date BETWEEN '2015-06-10' AND '2015-06-18'
UNION ALL
SELECT 'TCS', date, open_price, close_price, no_of_shares FROM tcs
WHERE date BETWEEN '2018-05-28' AND '2018-06-04'
ORDER BY stock, date;

/* Finding: both events are 1:1 BONUS ISSUES (1 free share for every 1 held).
     - Infosys: ex-bonus date 15-Jun-2015 (record date 17-Jun-2015)
     - TCS    : ex-bonus date 31-May-2018 (record date 02-Jun-2018)
   Evidence in the data:
     - Price ratio is ~0.50 for both (a real crash is never exactly half).
     - Opening price on the ex-date is also ~half of the previous close.
     - TCS: share volume doubled (2.03x) and turnover stayed flat (1.01x).
     - Infosys: share volume did not double on the day in this dataset, so the
       price cliff plus the published corporate-action dates are the evidence.
   Shareholders did not lose 50 percent of their wealth: they own twice as many
   shares at half the price. A bonus issue changes the price per share, not the
   value of the company. (Dates confirmed from NSE circulars and exchange filings.)
   Context for the next-worst Infosys day (2017-08-18, -9.60 percent): CEO Vishal
   Sikka resigned that day. That one IS a genuine market sell-off. */


/* =====================================================================
   MODULE 11 - ADJUST HISTORICAL PRICES FOR THE BONUS EVENTS
   Before the event -> divide by 2. On/after the event -> unchanged.
   ===================================================================== */

DROP TABLE IF EXISTS corporate_events;

CREATE TABLE corporate_events (
    stock       TEXT,
    event_date  TEXT,
    event_type  TEXT,
    ratio       TEXT,
    factor      REAL     -- divide pre-event prices by this
);

INSERT INTO corporate_events VALUES
    ('Infosys', '2015-06-15', 'Bonus issue', '1:1', 2.0),
    ('TCS',     '2018-05-31', 'Bonus issue', '1:1', 2.0);

DROP TABLE IF EXISTS adj_prices;

CREATE TABLE adj_prices AS
SELECT p.stock, p.date, p.close_price,
       CASE WHEN e.event_date IS NOT NULL AND p.date < e.event_date
            THEN p.close_price / e.factor
            ELSE p.close_price END AS adj_close
FROM all_prices p
LEFT JOIN corporate_events e ON e.stock = p.stock;

-- 11.1 Adjusted performance (first vs last) next to the raw numbers
WITH bounds AS (
    SELECT stock, MIN(date) AS first_date, MAX(date) AS last_date FROM adj_prices GROUP BY stock
)
SELECT b.stock,
       f.close_price AS raw_first_close,
       f.adj_close   AS adj_first_close,
       l.adj_close   AS last_close,
       ROUND((l.close_price - f.close_price) * 100.0 / f.close_price, 2) AS raw_pct_change,
       ROUND((l.adj_close   - f.adj_close)   * 100.0 / f.adj_close,   2) AS adj_pct_change
FROM bounds b
JOIN adj_prices f ON f.stock = b.stock AND f.date = b.first_date
JOIN adj_prices l ON l.stock = b.stock AND l.date = b.last_date
ORDER BY adj_pct_change DESC;

-- 11.2 Worst one-day fall again, using adjusted prices (the -50 percent cliffs disappear)
WITH d AS (
    SELECT stock, date, adj_close,
           LAG(adj_close) OVER (PARTITION BY stock ORDER BY date) AS prev_adj_close
    FROM adj_prices
),
chg AS (
    SELECT stock, date, prev_adj_close, adj_close,
           ROUND((adj_close - prev_adj_close) * 100.0 / prev_adj_close, 2) AS pct_change
    FROM d WHERE prev_adj_close IS NOT NULL
)
SELECT stock, date AS worst_day_adjusted, ROUND(prev_adj_close, 2) AS prev_adj_close,
       ROUND(adj_close, 2) AS adj_close, pct_change
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY stock ORDER BY pct_change ASC) AS r FROM chg)
WHERE r = 1
ORDER BY pct_change;

-- 11.3 TCS yearly average close, raw vs adjusted
SELECT strftime('%Y', date) AS year,
       ROUND(AVG(close_price), 2) AS raw_avg_close,
       ROUND(AVG(adj_close), 2)   AS adj_avg_close
FROM adj_prices
WHERE stock = 'TCS'
GROUP BY strftime('%Y', date)
ORDER BY year;

-- 11.4 BONUS: re-run MA20/MA50 signals on ADJUSTED prices and compare with raw
DROP TABLE IF EXISTS stock_signals_adj;

CREATE TABLE stock_signals_adj AS
WITH ma AS (
    SELECT stock, date, adj_close AS close_price,
           ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date) AS rn,
           AVG(adj_close) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS avg20,
           AVG(adj_close) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS avg50
    FROM adj_prices
),
full_window AS (
    SELECT stock, date, close_price,
           CASE WHEN rn >= 20 THEN avg20 END AS ma20,
           CASE WHEN rn >= 50 THEN avg50 END AS ma50
    FROM ma
),
lagged AS (
    SELECT stock, date, close_price, ma20, ma50,
           LAG(ma20) OVER (PARTITION BY stock ORDER BY date) AS prev_ma20,
           LAG(ma50) OVER (PARTITION BY stock ORDER BY date) AS prev_ma50
    FROM full_window
)
SELECT stock, date, close_price, ma20, ma50,
       CASE WHEN prev_ma20 <= prev_ma50 AND ma20 > ma50 THEN 'BUY'
            WHEN prev_ma20 >= prev_ma50 AND ma20 < ma50 THEN 'SELL'
            ELSE 'HOLD' END AS signal
FROM lagged;

SELECT r.stock,
       r.buy_signals  AS raw_buy,  a.buy_signals  AS adj_buy,
       r.sell_signals AS raw_sell, a.sell_signals AS adj_sell
FROM (SELECT stock, SUM(signal='BUY') AS buy_signals, SUM(signal='SELL') AS sell_signals FROM stock_signals     GROUP BY stock) r
JOIN (SELECT stock, SUM(signal='BUY') AS buy_signals, SUM(signal='SELL') AS sell_signals FROM stock_signals_adj GROUP BY stock) a
  ON a.stock = r.stock
ORDER BY r.stock;

-- 11.5 Which crossover signals change because of the bonus adjustment?
SELECT r.stock, r.date, r.signal AS raw_signal, a.signal AS adjusted_signal
FROM stock_signals r
JOIN stock_signals_adj a ON a.stock = r.stock AND a.date = r.date
WHERE r.signal <> a.signal
ORDER BY r.stock, r.date;


-- 11.6 BONUS: latest crossover per stock on ADJUSTED prices
SELECT stock, date AS latest_signal_date, signal AS latest_signal
FROM (SELECT stock, date, signal,
             ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS r
      FROM stock_signals_adj
      WHERE signal <> 'HOLD')
WHERE r = 1
ORDER BY stock;
/* TCS 2018-06-05 SELL in the raw data is an artefact of the bonus cliff. On adjusted
   prices TCS's latest real crossover is the BUY on 2018-04-20 and TCS is
   still in an uptrend on the last day (MA20 1954.82 > MA50 1858.60), whereas the raw
   data wrongly shows MA20 below MA50 (bearish) because of the unadjusted history. */


/* =====================================================================
   MODULE 12 - MASTER TABLE USING JOIN
   One row per date, one column per stock. INNER JOIN is safe because all six
   tables share the same 889 dates (verified below).
   ===================================================================== */

DROP TABLE IF EXISTS master_prices;

CREATE TABLE master_prices AS
SELECT b.date,
       b.close_price AS bajaj,
       t.close_price AS tcs,
       v.close_price AS tvs,
       i.close_price AS infosys,
       e.close_price AS eicher,
       h.close_price AS hero
FROM bajaj_auto b
INNER JOIN tcs           t ON t.date = b.date
INNER JOIN tvs_motors    v ON v.date = b.date
INNER JOIN infosys       i ON i.date = b.date
INNER JOIN eicher_motors e ON e.date = b.date
INNER JOIN hero_motocorp h ON h.date = b.date
ORDER BY b.date;

-- 12.1 Validation: expect 889 rows and 7 columns
SELECT (SELECT COUNT(*) FROM master_prices)                           AS row_count,
       (SELECT COUNT(*) FROM pragma_table_info('master_prices'))      AS column_count,
       (SELECT COUNT(*) FROM bajaj_auto)                              AS bajaj_rows;

-- 12.2 Preview
SELECT * FROM master_prices ORDER BY date DESC LIMIT 10;

-- 12.3 BONUS: master table with bonus-adjusted prices (like-for-like comparison)
DROP TABLE IF EXISTS master_prices_adj;

CREATE TABLE master_prices_adj AS
SELECT m.date,
       m.bajaj,
       CASE WHEN m.date < '2018-05-31' THEN m.tcs     / 2.0 ELSE m.tcs     END AS tcs,
       m.tvs,
       CASE WHEN m.date < '2015-06-15' THEN m.infosys / 2.0 ELSE m.infosys END AS infosys,
       m.eicher,
       m.hero
FROM master_prices m;

SELECT * FROM master_prices_adj ORDER BY date DESC LIMIT 5;

/* ===================== END OF ANALYSIS ===================== */
