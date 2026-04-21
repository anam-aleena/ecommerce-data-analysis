"""
E-Commerce Data Analysis — Python EDA
======================================
Author: Aleena Anam
GitHub: github.com/anam-aleena
Email:  anamaleena0@gmail.com

Description:
    Exploratory Data Analysis (EDA) on e-commerce data using
    Python (Pandas, NumPy, Matplotlib, Seaborn).
    Covers customer behaviour, sales trends, retention,
    and business KPIs — complementing the SQL analysis.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# ── Plotting style ──────────────────────────────────────────
sns.set_theme(style="whitegrid", palette="muted")
plt.rcParams['figure.figsize'] = (12, 5)
plt.rcParams['font.family']    = 'DejaVu Sans'


# ============================================================
# SECTION 1: GENERATE SYNTHETIC E-COMMERCE DATA
# ============================================================
# In a real role this section is replaced by:
#   df = pd.read_csv('data.csv')  or
#   df = pd.read_sql(query, connection)

np.random.seed(42)
N = 2000

channels   = ['organic', 'paid', 'referral', 'social']
categories = ['Electronics', 'Clothing', 'Home & Kitchen', 'Books', 'Beauty']
cities     = ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Pune', 'Chennai']
statuses   = ['completed', 'cancelled', 'refunded']

df = pd.DataFrame({
    'order_id':      range(1, N + 1),
    'customer_id':   np.random.randint(1, 401, N),
    'order_date':    pd.date_range('2024-01-01', periods=N, freq='4h'),
    'category':      np.random.choice(categories, N, p=[0.25, 0.20, 0.25, 0.15, 0.15]),
    'channel':       np.random.choice(channels,   N, p=[0.35, 0.30, 0.20, 0.15]),
    'city':          np.random.choice(cities,      N),
    'status':        np.random.choice(statuses,    N, p=[0.78, 0.12, 0.10]),
    'total_amount':  np.round(np.random.lognormal(mean=5.5, sigma=0.8, size=N), 2),
    'discount':      np.round(np.random.uniform(0, 30, N), 2),
    'units':         np.random.randint(1, 6, N),
})

df['order_date']   = pd.to_datetime(df['order_date'])
df['month']        = df['order_date'].dt.to_period('M')
df['net_amount']   = df['total_amount'] - df['discount']

completed = df[df['status'] == 'completed'].copy()

print("=" * 55)
print("E-COMMERCE DATASET OVERVIEW")
print("=" * 55)
print(f"Total orders   : {len(df):,}")
print(f"Completed      : {len(completed):,}  ({len(completed)/len(df)*100:.1f}%)")
print(f"Date range     : {df['order_date'].min().date()} → {df['order_date'].max().date()}")
print(f"Unique customers: {df['customer_id'].nunique():,}")
print(f"Avg order value : ₹{completed['total_amount'].mean():,.2f}")
print(f"Total revenue   : ₹{completed['total_amount'].sum():,.2f}")
print()


# ============================================================
# SECTION 2: DATA CLEANING & VALIDATION
# ============================================================

print("=" * 55)
print("DATA QUALITY CHECK")
print("=" * 55)
print("Missing values:\n", df.isnull().sum())
print(f"\nNegative amounts : {(df['total_amount'] < 0).sum()}")
print(f"Duplicate orders : {df['order_id'].duplicated().sum()}")
print(f"Data types:\n{df.dtypes}")
print()


# ============================================================
# SECTION 3: REVENUE ANALYSIS
# ============================================================

print("=" * 55)
print("MONTHLY REVENUE SUMMARY")
print("=" * 55)

monthly = (completed.groupby('month')
           .agg(
               orders        = ('order_id',     'count'),
               gross_revenue = ('total_amount', 'sum'),
               net_revenue   = ('net_amount',   'sum'),
               aov           = ('total_amount', 'mean'),
               discounts     = ('discount',     'sum'),
           )
           .reset_index())
monthly['mom_growth_pct'] = monthly['gross_revenue'].pct_change() * 100
print(monthly.round(2).to_string(index=False))
print()

# Plot: Monthly Revenue
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

axes[0].bar(monthly['month'].astype(str), monthly['gross_revenue'],
            color='#2D7A50', alpha=0.85)
axes[0].set_title('Monthly Gross Revenue', fontweight='bold')
axes[0].set_xlabel('Month')
axes[0].set_ylabel('Revenue (₹)')
axes[0].tick_params(axis='x', rotation=45)

axes[1].plot(monthly['month'].astype(str), monthly['aov'],
             marker='o', color='#0A6E3F', linewidth=2)
axes[1].fill_between(monthly['month'].astype(str), monthly['aov'],
                     alpha=0.15, color='#0A6E3F')
axes[1].set_title('Average Order Value (AOV) Trend', fontweight='bold')
axes[1].set_xlabel('Month')
axes[1].set_ylabel('AOV (₹)')
axes[1].tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('monthly_revenue.png', dpi=150, bbox_inches='tight')
plt.show()
print("Chart saved: monthly_revenue.png\n")


# ============================================================
# SECTION 4: CATEGORY & CHANNEL ANALYSIS
# ============================================================

print("=" * 55)
print("REVENUE BY CATEGORY")
print("=" * 55)

cat_rev = (completed.groupby('category')
           .agg(orders=('order_id','count'), revenue=('total_amount','sum'))
           .sort_values('revenue', ascending=False)
           .reset_index())
cat_rev['revenue_pct'] = (cat_rev['revenue'] / cat_rev['revenue'].sum() * 100).round(2)
print(cat_rev.to_string(index=False))
print()

print("REVENUE BY ACQUISITION CHANNEL")
print("=" * 55)
chan_rev = (completed.groupby('channel')
            .agg(orders=('order_id','count'), revenue=('total_amount','sum'),
                 customers=('customer_id','nunique'))
            .sort_values('revenue', ascending=False)
            .reset_index())
chan_rev['avg_ltv'] = (chan_rev['revenue'] / chan_rev['customers']).round(2)
print(chan_rev.to_string(index=False))
print()

# Plot: Category + Channel
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

colors = ['#0A6E3F', '#2D7A50', '#4A9166', '#67A87C', '#84C092']
axes[0].barh(cat_rev['category'], cat_rev['revenue'], color=colors)
axes[0].set_title('Revenue by Product Category', fontweight='bold')
axes[0].set_xlabel('Revenue (₹)')

axes[1].pie(chan_rev['revenue'], labels=chan_rev['channel'],
            autopct='%1.1f%%', colors=colors, startangle=90)
axes[1].set_title('Revenue Share by Acquisition Channel', fontweight='bold')

plt.tight_layout()
plt.savefig('category_channel_analysis.png', dpi=150, bbox_inches='tight')
plt.show()
print("Chart saved: category_channel_analysis.png\n")


# ============================================================
# SECTION 5: CUSTOMER SEGMENTATION & LTV
# ============================================================

print("=" * 55)
print("CUSTOMER SEGMENTATION")
print("=" * 55)

customer_stats = (completed.groupby('customer_id')
                  .agg(
                      total_orders  = ('order_id',     'count'),
                      lifetime_value= ('total_amount', 'sum'),
                      avg_order_val = ('total_amount', 'mean'),
                      first_purchase= ('order_date',   'min'),
                      last_purchase = ('order_date',   'max'),
                  )
                  .reset_index())

def segment(row):
    if row['total_orders'] == 1:       return 'One-time buyer'
    elif row['total_orders'] <= 4:     return 'Occasional buyer'
    else:                              return 'Loyal customer'

customer_stats['segment'] = customer_stats.apply(segment, axis=1)
customer_stats['lifespan_days'] = (
    customer_stats['last_purchase'] - customer_stats['first_purchase']
).dt.days

seg_summary = (customer_stats.groupby('segment')
               .agg(
                   count   = ('customer_id',    'count'),
                   avg_ltv = ('lifetime_value', 'mean'),
                   avg_orders = ('total_orders','mean'),
               )
               .round(2)
               .reset_index())
print(seg_summary.to_string(index=False))
print()

# Plot: LTV distribution
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

axes[0].bar(seg_summary['segment'], seg_summary['avg_ltv'],
            color=['#0A6E3F','#2D7A50','#84C092'])
axes[0].set_title('Average LTV by Customer Segment', fontweight='bold')
axes[0].set_ylabel('Average LTV (₹)')

sns.histplot(customer_stats['lifetime_value'], bins=30,
             color='#0A6E3F', alpha=0.7, ax=axes[1])
axes[1].set_title('Customer LTV Distribution', fontweight='bold')
axes[1].set_xlabel('Lifetime Value (₹)')

plt.tight_layout()
plt.savefig('customer_segmentation.png', dpi=150, bbox_inches='tight')
plt.show()
print("Chart saved: customer_segmentation.png\n")


# ============================================================
# SECTION 6: RETENTION & CHURN ANALYSIS
# ============================================================

print("=" * 55)
print("MONTHLY RETENTION ANALYSIS")
print("=" * 55)

completed['purchase_month'] = completed['order_date'].dt.to_period('M')

monthly_buyers = (completed.groupby(['purchase_month', 'customer_id'])
                  .size().reset_index()[['purchase_month','customer_id']])

months = sorted(monthly_buyers['purchase_month'].unique())
retention_data = []

for i, month in enumerate(months[:-1]):
    current  = set(monthly_buyers[monthly_buyers['purchase_month'] == month]['customer_id'])
    next_m   = set(monthly_buyers[monthly_buyers['purchase_month'] == months[i+1]]['customer_id'])
    retained = len(current & next_m)
    churned  = len(current - next_m)
    retention_data.append({
        'month':            str(month),
        'active_customers': len(current),
        'retained':         retained,
        'churned':          churned,
        'retention_rate':   round(retained / len(current) * 100, 1) if current else 0,
        'churn_rate':       round(churned  / len(current) * 100, 1) if current else 0,
    })

retention_df = pd.DataFrame(retention_data)
print(retention_df.to_string(index=False))
print()

# Plot: Retention vs Churn
fig, ax = plt.subplots(figsize=(13, 5))
x = range(len(retention_df))
ax.plot(x, retention_df['retention_rate'], marker='o',
        color='#0A6E3F', linewidth=2, label='Retention Rate %')
ax.plot(x, retention_df['churn_rate'],     marker='s',
        color='#E53E3E', linewidth=2, label='Churn Rate %')
ax.set_xticks(x)
ax.set_xticklabels(retention_df['month'], rotation=45)
ax.set_title('Monthly Retention vs Churn Rate', fontweight='bold')
ax.set_ylabel('Rate (%)')
ax.legend()
plt.tight_layout()
plt.savefig('retention_churn.png', dpi=150, bbox_inches='tight')
plt.show()
print("Chart saved: retention_churn.png\n")


# ============================================================
# SECTION 7: KEY BUSINESS KPIs SUMMARY
# ============================================================

print("=" * 55)
print("KEY BUSINESS KPIs")
print("=" * 55)

repeat_customers = (customer_stats['total_orders'] > 1).sum()
total_customers  = len(customer_stats)

kpis = {
    'Total Revenue (₹)':          f"{completed['total_amount'].sum():,.2f}",
    'Total Orders':                f"{len(completed):,}",
    'Unique Customers':            f"{total_customers:,}",
    'Average Order Value (₹)':     f"{completed['total_amount'].mean():,.2f}",
    'Avg Customer LTV (₹)':        f"{customer_stats['lifetime_value'].mean():,.2f}",
    'Repeat Purchase Rate':        f"{repeat_customers/total_customers*100:.1f}%",
    'Order Completion Rate':       f"{len(completed)/len(df)*100:.1f}%",
    'Avg Retention Rate':          f"{retention_df['retention_rate'].mean():.1f}%",
    'Avg Churn Rate':              f"{retention_df['churn_rate'].mean():.1f}%",
    'Top Revenue Category':        cat_rev.iloc[0]['category'],
    'Top Revenue Channel':         chan_rev.iloc[0]['channel'],
}

for k, v in kpis.items():
    print(f"  {k:<35} {v}")

print()
print("=" * 55)
print("Analysis complete. Charts saved to project folder.")
print("Author: Aleena Anam | github.com/anam-aleena")
print("=" * 55)
