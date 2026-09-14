# D2C-skincare-ecommerce-analytics
End-to-end D2C skincare e-commerce analytics project using Python, SQL, and Power BI.

## Project Overview

This project analyzes the performance of a Direct-to-Consumer (D2C) skincare e-commerce business using Python, SQL, and Power BI.

The objective is to understand sales performance, product profitability, customer behavior, acquisition channels, and customer value segments through data-driven business analysis.

The project follows an end-to-end analytics workflow:

**Data Cleaning → Exploratory Data Analysis → SQL Analysis → RFM Segmentation → Power BI Dashboard**

---

## Business Objectives

The key business questions addressed in this project are:

- How is the business performing in terms of revenue and orders?
- Which products and categories generate the highest sales?
- Which products contribute the most to gross profit?
- What is the average order value?
- Which acquisition channels bring the most customers?
- Which customers are loyal, at risk, or lost?
- How are customers distributed across age groups?
- What percentage of customers are repeat customers?
- Which customer segments contribute the most revenue?
- How can business stakeholders use these insights for decision-making?

---

## Tools and Technologies

- **Python**
  - Pandas
  - NumPy
  - Matplotlib
- **SQL**
  - PostgreSQL
  - Joins
  - CTEs
  - Window Functions
  - Aggregations
  - Business Analysis
- **Power BI**
  - Data Modelling
  - Power Query
  - DAX
  - Interactive Dashboards
  - KPI Cards
  - RFM Segmentation
- **GitHub**
  - Project Documentation
  - Version Control
  - Portfolio Presentation

---

## Dataset Description

The project contains the following datasets:

### Customers

Contains customer-level information such as:

- Customer ID
- Customer Name
- City
- State
- Gender
- Age Group
- Signup Date
- Acquisition Channel

### Products

Contains product information such as:

- Product ID
- Product Name
- Category
- Skin Concern
- Skin Type
- Key Ingredient
- Size
- MRP
- Cost Price
- Stock Quantity
- Launch Date

### Orders

Contains order-level information such as:

- Order ID
- Customer ID
- Order Date
- Order Status
- Payment Method
- Sales Channel
- Final Amount
- Discount Amount
- Shipping Fee
- Total Amount
- Delivered Date

### Order Items

Contains product-level order details such as:

- Order Item ID
- Order ID
- Product ID
- Quantity
- Unit Price
- Discount Percentage
- Item Total

### Returns

Contains return and refund information such as:

- Return ID
- Order ID
- Product ID
- Return Date
- Return Reason
- Refund Status

### Reviews

Contains customer review information such as:

- Review ID
- Customer ID
- Product ID
- Order ID
- Rating
- Review Date

---

## Project Workflow

### 1. Data Cleaning Using Python

The datasets were cleaned and prepared for analysis.

Key activities included:

- Checking missing values
- Removing duplicate records
- Validating data types
- Standardizing column names
- Checking invalid values
- Validating date columns
- Checking numerical consistency
- Preparing cleaned datasets for SQL and Power BI

---

### 2. Exploratory Data Analysis

Exploratory analysis was performed to understand:

- Revenue trends
- Order volume
- Product performance
- Category performance
- Customer distribution
- Acquisition channel performance
- Discount patterns
- Return behavior
- Customer ratings

---

### 3. SQL Business Analysis

PostgreSQL was used to answer stakeholder-level business questions.

Analysis areas included:

- Revenue by product and category
- Monthly sales performance
- Top-selling products
- Gross profit analysis
- Customer purchase behavior
- Repeat customer analysis
- Acquisition channel performance
- Return and refund analysis
- Customer ranking
- RFM-related customer analysis

SQL concepts used:

- INNER JOIN
- LEFT JOIN
- GROUP BY
- CASE statements
- Common Table Expressions
- Window Functions
- Aggregations
- Conditional Filtering
- Ranking Functions

---

### 4. RFM Customer Segmentation

Customers were segmented using the RFM framework.

#### Recency

Measures how recently a customer made a purchase.

#### Frequency

Measures how many delivered orders a customer placed.

#### Monetary

Measures the total value contributed by a customer.

The analysis classified customers into segments such as:

- Champions
- Loyal Customers
- Potential Loyalists
- At Risk
- Lost Customers
- Other

This helps the business identify valuable customers and customers who may need re-engagement campaigns.

---

## Power BI Dashboard

The Power BI report contains three main pages.

### Page 1 — Executive Overview

Key business KPIs include:

- Total Revenue
- Total Orders
- Total Customers
- Average Order Value
- Gross Profit
- Gross Margin
- Return Rate

The page provides a high-level overview of business performance.

---

### Page 2 — Sales & Product Performance

This page focuses on:

- Product revenue
- Category performance
- Units sold
- Discount analysis
- Product profitability
- Top-performing products
- Revenue and sales contribution

---

### Page 3 — Customer & RFM Analytics

This page focuses on:

- RFM segment distribution
- Revenue contribution by customer segment
- Customer acquisition channel performance
- Repeat customers by acquisition channel
- Customer distribution by age group
- New versus repeat customer trends

---

## Key Business Metrics

The project uses the following metrics:

### Total Revenue

Revenue generated from delivered orders.

### Total Orders

Distinct number of delivered orders.

### Total Customers

Distinct customers who placed delivered orders.

### Gross Profit = Revenue - Cost of Goods Sold


```text
Average Order Value = Total Revenue / Total Orders
