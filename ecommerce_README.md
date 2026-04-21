# E-Commerce Data Analysis — SQL & Python

**Author:** Aleena Anam  
**Contact:** anamaleena0@gmail.com  
**LinkedIn:** [linkedin.com/in/aleena-anam-2056a4368](https://linkedin.com/in/aleena-anam-2056a4368)

---

## Project Overview

A complete data analytics project on e-commerce data covering customer behaviour, sales trends, retention analysis, and business KPIs — using **PostgreSQL (advanced SQL)** and **Python (Pandas, NumPy, Matplotlib, Seaborn)**.

This project demonstrates the exact skills required for a Data Analyst role:
- Complex SQL queries (window functions, CTEs, aggregations, joins)
- Python-based EDA and data visualisation
- Business metrics: LTV, CAC, ROAS, churn, retention, AOV
- Funnel analysis and customer segmentation

---

## Project Structure

```
ecommerce-data-analysis/
│
├── ecommerce_analysis.sql    # All SQL queries — PostgreSQL
├── eda_analysis.py           # Python EDA — Pandas, Seaborn
├── requirements.txt          # Python dependencies
└── README.md
```

---

## SQL Analysis Covers

| Section | Topics |
|---|---|
| Basic Exploration | Monthly revenue, top products, category breakdown |
| Customer Analysis | LTV, segmentation, acquisition by channel |
| Retention & Churn | MoM retention, cohort analysis, churn rate |
| Funnel Analysis | Order completion, AOV trends, repeat purchase rate |
| Marketing KPIs | CAC by channel, ROAS by channel |
| Window Functions | RANK, DENSE_RANK, LAG, running totals, rolling averages |
| CTEs | Multi-step CTE: at-risk high-value customers, contribution margin |

### Key SQL Concepts Used
- `WINDOW FUNCTIONS` — RANK, DENSE_RANK, LAG, running SUM, rolling AVG
- `CTEs` — multi-step WITH clauses for complex business logic
- `Complex JOINs` — INNER, LEFT joins across 5 tables
- `Aggregations` — GROUP BY, HAVING, PERCENTILE_CONT
- `Query Optimisation` — filtering early, avoiding nested subqueries where possible

---

## Python EDA Covers

- **Data cleaning** — null checks, duplicate detection, data type validation
- **Revenue analysis** — monthly trends, MoM growth, AOV
- **Category & channel** — revenue breakdown, acquisition channel performance
- **Customer segmentation** — one-time, occasional, loyal customer tiers
- **LTV analysis** — distribution, averages by segment
- **Retention & churn** — monthly retention rate, churn rate trends
- **KPI dashboard** — all key business metrics in one summary

---

## Business KPIs Analysed

| Metric | Description |
|---|---|
| **AOV** | Average Order Value |
| **LTV** | Customer Lifetime Value |
| **CAC** | Customer Acquisition Cost by channel |
| **ROAS** | Return on Ad Spend by channel |
| **Retention Rate** | % customers who return next month |
| **Churn Rate** | % customers who don't return next month |
| **Repeat Purchase Rate** | % customers with 2+ orders |
| **Contribution Margin** | Revenue minus product cost by category |

---

## How to Run

### SQL (PostgreSQL)
```bash
# Connect to your PostgreSQL instance
psql -U your_username -d your_database

# Run the analysis
\i ecommerce_analysis.sql
```

### Python
```bash
# Install dependencies
pip install -r requirements.txt

# Run EDA
python eda_analysis.py
```

---

## Requirements

```
pandas>=2.0.0
numpy>=1.24.0
matplotlib>=3.7.0
seaborn>=0.12.0
```

---

## Sample Outputs

The Python script generates 4 charts:
- `monthly_revenue.png` — Monthly revenue bar chart + AOV trend line
- `category_channel_analysis.png` — Revenue by category + channel pie chart
- `customer_segmentation.png` — LTV by segment + LTV distribution
- `retention_churn.png` — Monthly retention vs churn rate trend

---

## Skills Demonstrated

`PostgreSQL` `Window Functions` `CTEs` `Python` `Pandas` `NumPy` `Matplotlib` `Seaborn` `EDA` `Customer Segmentation` `Cohort Analysis` `Retention Analysis` `Business Intelligence` `KPI Reporting` `Data Visualisation`

---

*This project is part of my data analytics portfolio. Feel free to fork, use, or reach out if you have questions.*
