"""SQL Playground for the Stock Market Analysis project (Streamlit + SQLite)."""
import re, sqlite3, shutil
from pathlib import Path
import pandas as pd
import streamlit as st

HERE = Path(__file__).parent
DB = HERE / "stocks.db"
SQL_FILE = HERE / "stock_market_analysis.sql"

st.set_page_config(page_title="Stock SQL Playground", page_icon="📈", layout="wide")

# ---------- one private in-memory DB copy per browser session ----------
def fresh_connection():
    src = sqlite3.connect(DB)
    mem = sqlite3.connect(":memory:", check_same_thread=False)
    src.backup(mem)
    src.close()
    return mem

if "con" not in st.session_state:
    st.session_state.con = fresh_connection()
    st.session_state.history = []
con = st.session_state.con

def split_statements(sql: str):
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.S)
    sql = re.sub(r"--[^\n]*", "", sql)
    return [s.strip() for s in sql.split(";") if s.strip()]

def run(sql: str):
    """Run every statement, return (last result DataFrame or None, log lines)."""
    last, log = None, []
    for stmt in split_statements(sql):
        cur = con.execute(stmt)
        if cur.description:
            last = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
            log.append(f"SELECT returned {len(last)} rows")
        else:
            log.append(f"OK: {stmt.split()[0].upper()} ({cur.rowcount if cur.rowcount >= 0 else 0} rows affected)")
    con.commit()
    return last, log

# ---------- parse the project SQL file into named example queries ----------
@st.cache_data
def load_examples():
    text = SQL_FILE.read_text()
    parts = re.split(r"/\* =+\s*\n\s*(MODULE \d+[^\n]*)", text)
    ex = {}
    for i in range(1, len(parts), 2):
        module = re.sub(r"\s+", " ", parts[i]).strip()
        body = parts[i + 1]
        body = body.split("===", 1)[-1] if body.lstrip().startswith("=") else body
        blocks = re.split(r"\n(?=-- \d+\.\d+)", "\n" + body)
        for b in blocks:
            m = re.match(r"\s*-- (\d+\.\d+)([^\n]*)\n(.*)", b, flags=re.S)
            if m:
                code = re.sub(r"/\*.*?\*/", "", m.group(3), flags=re.S).strip()
                if code:
                    ex[f"{m.group(1)}  {m.group(2).strip()[:60]}  ({module.split(' - ')[0]})"] = code
        # modules without numbered blocks (e.g. 4, 5, 6 setup) -> whole body
    return ex

examples = load_examples()

# ---------- sidebar ----------
with st.sidebar:
    st.title("📈 Stock SQL Playground")
    st.caption("SQLite, 6 stocks, 889 trading days each (Jan 2015 – Jul 2018).")
    st.subheader("Tables")
    tables = pd.read_sql("SELECT name, type FROM sqlite_master WHERE type IN ('table','view') ORDER BY type, name", con)
    for _, r in tables.iterrows():
        with st.expander(f"{'🗂' if r.type=='table' else '👁'} {r['name']}"):
            cols = pd.read_sql(f"PRAGMA table_info({r['name']})", con)[["name", "type"]]
            st.dataframe(cols, hide_index=True, width="stretch")
    st.divider()
    if st.button("♻️ Reset database", width="stretch", help="Drops every table/view you created and reloads the original data"):
        st.session_state.con = fresh_connection(); st.session_state.history = []; st.rerun()
    st.caption("Your changes live only in your session's memory copy. The original data is never modified.")
    st.info("Historical SQL signals only, not investment advice.")

# ---------- main ----------
st.title("SQL Playground: Stock Market Analysis")
tab_play, tab_chart, tab_guide = st.tabs(["🧪 Query editor", "📊 Quick charts", "📘 About / cheat-sheet"])

with tab_play:
    c1, c2 = st.columns([3, 1])
    choice = c1.selectbox("Load an example from the project", ["(blank)"] + list(examples), index=0)
    default = examples.get(choice, "SELECT * FROM master_prices\nORDER BY date DESC\nLIMIT 10;") if choice != "(blank)" else "SELECT * FROM tcs ORDER BY date DESC LIMIT 5;"
    if c2.button("▶ Run full project script", width="stretch", help="Runs stock_market_analysis.sql top to bottom (rebuilds all analysis tables)"):
        try:
            last, log = run(SQL_FILE.read_text()); st.success(f"Ran the full script ({len(log)} statements)."); st.session_state.last = last
        except Exception as e:
            st.error(f"{type(e).__name__}: {e}")
    sql = st.text_area("SQL (multiple statements allowed, separated by `;`)", value=default, height=260, key=f"sql_{choice}")
    run_btn = st.button("▶ Run query", type="primary")
    if run_btn:
        try:
            last, log = run(sql)
            st.session_state.last = last
            st.session_state.history.insert(0, sql.strip())
            st.caption(" | ".join(log))
        except Exception as e:
            st.error(f"{type(e).__name__}: {e}")
    last = st.session_state.get("last")
    if last is not None:
        st.write(f"**Result:** {len(last):,} rows × {len(last.columns)} columns")
        st.dataframe(last, width="stretch", hide_index=True, height=min(520, 40 + 35 * len(last)))
        st.download_button("⬇ Download CSV", last.to_csv(index=False), "query_result.csv", "text/csv")
    if st.session_state.history:
        with st.expander(f"History ({len(st.session_state.history)})"):
            for h in st.session_state.history[:10]:
                st.code(h, language="sql")

with tab_chart:
    st.write("Pick a stock and see its price with the MA20 / MA50 and BUY/SELL signals (read from the `stock_signals` table; run the full project script first if it is missing).")
    try:
        stocks = pd.read_sql("SELECT DISTINCT stock FROM stock_signals ORDER BY stock", con)["stock"].tolist()
        a, b = st.columns(2)
        stock = a.selectbox("Stock", stocks)
        adjusted = b.toggle("Use bonus-adjusted prices (TCS, Infosys)", value=True)
        tbl = "stock_signals_adj" if adjusted else "stock_signals"
        df = pd.read_sql(f"SELECT date, close_price, ma20, ma50, signal FROM {tbl} WHERE stock=? ORDER BY date", con, params=(stock,))
        df["date"] = pd.to_datetime(df["date"])
        st.line_chart(df.set_index("date")[["close_price", "ma20", "ma50"]])
        ev = df[df.signal != "HOLD"][["date", "close_price", "signal"]]
        m1, m2, m3 = st.columns(3)
        m1.metric("BUY signals", int((df.signal == "BUY").sum())); m2.metric("SELL signals", int((df.signal == "SELL").sum()))
        m3.metric("Latest crossover", f"{ev.iloc[-1].signal} {ev.iloc[-1].date:%Y-%m-%d}" if len(ev) else "n/a")
        with st.expander("All crossover events"):
            st.dataframe(ev, hide_index=True, width="stretch")
    except Exception as e:
        st.warning(f"Signals table not available yet ({e}). Go to the editor and click 'Run full project script'.")

with tab_guide:
    st.markdown("""
**Tables:** `bajaj_auto`, `eicher_motors`, `hero_motocorp`, `infosys`, `tcs`, `tvs_motors` (columns: `date, open_price, high_price, low_price, close_price, wap, no_of_shares, no_of_trades, total_turnover, deliverable_qty, pct_deli_qty, spread_high_low, spread_close_open`).
Dates are `YYYY-MM-DD` text. Created by the project script: `all_prices`, `bajaj1`, `bajaj_signals`, `stock_signals`, `daily_change`, `corporate_events`, `adj_prices`, `stock_signals_adj`, `master_prices`, `master_prices_adj`.

**Try these**
```sql
-- 20-day moving average with a window function
SELECT date, close_price,
       AVG(close_price) OVER (ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS ma20
FROM hero_motocorp ORDER BY date DESC LIMIT 5;

-- Biggest daily moves (up) across all stocks
SELECT * FROM daily_change WHERE pct_change IS NOT NULL ORDER BY pct_change DESC LIMIT 10;
```
**Notes:** SQLite dialect (`strftime('%Y', date)`, `LIMIT`, no `CORR`). The `SUM(signal = 'BUY')` trick counts rows because a true comparison equals 1.
""")
