SQL Sales Funnel & Revenue Analysis
End-to-end Funnel Analysis using SQL (Views → Cart → Checkout → Payment → Orders)

This project analyzes a complete e-commerce sales funnel entirely using SQL.
It helps understand where users drop off, which cities and categories convert best, and which products generate the highest revenue opportunity.

Business Problem

The company is experiencing high traffic but low order completion.

Leadership wants to know:

Where are users dropping off in the funnel?
(Views → Add to Cart → Checkout → Payment → Orders)
Which cities have the strongest and weakest performance?
Which product categories convert best?
Which products contribute the most revenue but suffer from funnel drop-offs?
What are the key opportunities to improve revenue?

Dataset Overview

File	Rows	Description
customers.csv	1000	User demographics (city, gender, signup_date)
products.csv	100	Product catalog with category + price
funnel_events.csv	5000	All user actions across the funnel

Funnel event types:

view
add_to_cart
checkout
payment
order_placed

Tools Used:

SQL Server (MSSQL) for all analysis
GitHub for project documentation
CSV files for dataset storage
No BI tools, Python, or Excel — 100% SQL analysis.

Project Workflow
1️⃣ Create tables & load data

You created 3 tables:

salesfunnel_customers

salesfunnel_products

salesfunnel_events

Then imported CSVs into MSSQL.

2️⃣ Compute funnel conversion metrics

Using CTEs + GROUP BY + JOINs, you calculated:

Unique users per stage

View → Cart

Cart → Checkout

Checkout → Payment

Payment → Order

View → Order (overall conversion)

3️⃣ Insights by City

You analyzed funnel behavior across 6 major cities to identify strong and weak markets.

4️⃣ Insights by Product Category

Which category attracts traffic?
Which converts to orders?
Where do users drop off?

5️⃣ Insights by Individual Product

Identify:

High-view, low-order products
Hidden revenue opportunities
Inventory or UX issues impacting specific products

Key Business Insights:

1. Funnel Drop-off Analysis

1000 views → only 163 final orders
Overall View → Order = 16.3%

Biggest drop-offs:
View → Add to Cart (only ~39%)
Payment → Order (small drop but impactful)

Interpretation: Users are browsing but not motivated to add items to cart — pricing, product pages, or discounts might be an issue.

2. City-level Insights

Top-performing cities based on View → Order conversion:

City	    View→Order %	  Observation
Jaipur	  20.19%	        Strongest overall funnel
Pune	    19.64%	        Consistent across all stages
Lucknow	  19.72%	        Great checkout completion

Lowest conversions:
Chennai (15.63%)
Delhi (15.96%)

Interpretation: Delhi & Chennai may need local promotions or UX improvements.

3. Category-level Insights

Top-performing categories:

Category	  View→Order %	  Reason
Beauty      (7.8%)	        High demand, strong conversion	
Footwear    (6.3%)	        Good funnel consistency	

Lowest:
Sports (3.49%)
Home (4.27%)

Interpretation: Home & Sports have major funnel leaks between Cart → Checkout.

4. Product-level Insights

Top products by View → Order conversion (approx):

Product	        Conversion %
Product_539	    16.67%
Product_520	    16.0%
Product_558	    13.95%

Interpretation: These may deserve more marketing spend or visibility.

SQL Concepts Used:
CTEs
Window functions (for percentiles)
Joins
Pivoting
Aggregation
COALESCE / NULL handling
Conversion metrics
Ranking & ordering

How to Run This Project:

Clone the repo
Import the CSV files into your SQL Server
Run funnel_analysis.sql
Explore insights

Add complete project documentation for SQL Sales Funnel Analysis
