import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

sns.set(style="whitegrid")
pd.set_option("display.max_columns", None)

# connect to MySQL
engine = create_engine(
    "mysql+mysqlconnector://root:123456@localhost:3306/BANK"
)

print("Connected to database")

# load one CSV ONLY (test)
customers = pd.read_csv("customers.csv")
order_items  = pd.read_csv("order_items.csv")
orders    = pd.read_csv("orders.csv")
products  = pd.read_csv("products.csv")
payments  = pd.read_csv("payments.csv")

print("CSV loaded")

# save to SQL
customers.to_sql(
    name="customers",
    con=engine,
    if_exists="replace",
    index=False
)
order_items.to_sql(
    name="order_items" ,
    con=engine,
    if_exists="replace",
    index=False
)
orders.to_sql(
    name="orders" ,
    con=engine,
    if_exists="replace",
    index=False
)
payments.to_sql(
    name="payments" ,
    con=engine,
    if_exists="replace",
    index=False
)
products.to_sql(
    name="products" ,
    con=engine,
    if_exists="replace",
    index=False
)
# merge dataset
order_customers = pd.merge(
    orders,
    customers,
    on="customer_id",
    how="left"
)
orders_items = pd.merge(
    order_customers,
    order_items,
    on="order_id",
    how="left"
)
orders_items_products = pd.merge(
    orders_items,
    products,
    on="product_id",
    how="left"
)
final_data = pd.merge(
    orders_items_products,
    payments,
    on="order_id",
    how="left"
)


print("Table saved to SQL")
#remove white space
for i in final_data.select_dtypes(include=[object]).columns:
    final_data[i] = final_data[i].astype(str).str.strip()

print(final_data.columns.str.strip().str.lower().str.replace(" ","_"))    

values = ["na", "null", "n/a", "none", " "]
for i in final_data.columns:
    if (final_data[i] == "object").all():
        final_data[i] = final_data[i].replace(to_replace=values , value=np.nan)

# STANDARDRIZING DATETIME COLUMNS
dates = [i for i in final_data.columns
         if any(j in i for j in["date", "time", "dt", "timestamp"])]
for cols in dates:
    try:
        final_data[cols] =pd.to_datetime(final_data[cols])  
    except:
        pass          

# check table from SQL
df = pd.read_sql("SELECT * FROM customers LIMIT 5;", engine)
print(df)
print(final_data.columns)

# PYTHON KPI CALCULATION
total_orders = final_data['order_id'].nunique()
print("Total orders =",total_orders)
total_customers = final_data['customer_id'].nunique()
print("Total customers =",total_customers)

# CUSTOMER LIFETIME VALUE 

clv = (
    final_data
    .groupby('customer_id')['amount_paid']
    .sum()
    .reset_index()
    .rename(columns={'amount_paid': 'customer_lifetime_value'})
    .sort_values(by='customer_lifetime_value', ascending=False)
)
print("customer lifetime values\n",clv)


# Total Revenue
final_data['net_revenue'] = final_data['amount_paid'] - final_data['transaction_fee']
print("Total Revenue",final_data['net_revenue'].sum())

final_data['cost'] = final_data['quantity'] * final_data['cost']
final_data['profit'] = final_data['net_revenue'] - final_data['cost']
print("profit", final_data['profit'].sum())

# monthly revenue
orders['order_date'] = pd.to_datetime(
    orders['order_date'],
    errors='coerce'
)

orders['order_month'] = orders['order_date'].dt.strftime('%m')
print(orders[['order_date', 'order_month']].head())

monthly_revenue = (
    final_data
    .groupby('order_date')['total_amount']
    .sum()
    .reset_index()
)
print("monthly revenue\n ", monthly_revenue)

plt.figure(figsize=(10,5))
plt.plot(monthly_revenue['order_date'],
         monthly_revenue['total_amount'])
plt.xticks(rotation=45)
plt.title("Monthly Revenue Trend")
plt.xlabel("Month")
plt.ylabel("Revenue")
plt.show()

# Revenue by Customer segment
segment_revenue = (
    final_data
    .groupby('customer_segment')['net_revenue']
    .sum()
    .sort_values(ascending=False)
    .reset_index()
)

plt.figure(figsize=(8,5))
sns.barplot(data=segment_revenue, x='customer_segment', y='net_revenue')
plt.title("Revenue by Customer Segment")
plt.show()


# Category by revenue
category_revenue = (
    final_data
    .groupby('category')['net_revenue']
    .sum()
    .sort_values(ascending=False)
    .reset_index()
)
plt.figure(figsize=(10,5))
sns.barplot(data=category_revenue, x='category', y='net_revenue')
plt.xticks(rotation=45)
plt.title("Revenue by Product Category")
plt.show()


