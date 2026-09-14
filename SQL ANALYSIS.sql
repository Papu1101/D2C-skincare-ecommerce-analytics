CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    gender VARCHAR(20),
    age_group VARCHAR(20),
    signup_date DATE,
    acquisition_channel VARCHAR(50)
);

SELECT * FROM customers;

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(50),
    concern VARCHAR(100),
    skin_type VARCHAR(100),
    key_ingredient VARCHAR(100),
    size VARCHAR(20),
    mrp NUMERIC(10,2),
    cost_price NUMERIC(10,2),
    stock_qty INTEGER,
    launch_date DATE
);

SELECT * FROM products;

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    order_date DATE,
    order_status VARCHAR(30),
    payment_method VARCHAR(30),
    sales_channel VARCHAR(50),
    final_amount NUMERIC(10,2),
    discount_amount NUMERIC(10,2),
    shipping_fee NUMERIC(10,2),
    total_amount NUMERIC(10,2),
    delivered_date DATE,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);


SELECT * FROM orders;


CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    quantity INTEGER,
    unit_price NUMERIC(10,2),
    discount_pct NUMERIC(5,2),
    item_total NUMERIC(10,2),
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

SELECT * FROM order_items;

CREATE TABLE returns (
    return_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    return_date DATE,
    return_reason VARCHAR(100),
    refund_status VARCHAR(30),
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

SELECT * FROM returns;

CREATE TABLE reviews (
    review_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    product_id VARCHAR(20),
    order_id VARCHAR(20),
    rating NUMERIC(2,1),
    review_date DATE,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

SELECT * FROM reviews;


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
Revenue & Growth
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--1::How has monthly revenue changed over time, and what are the month-over-month (MoM) revenue growth rates?

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(final_amount) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

--2::Which sales channels are driving revenue growth, and how has each channel's contribution changed over time?

WITH monthly_channel_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        sales_channel,
        SUM(final_amount) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY
        DATE_TRUNC('month', order_date),
        sales_channel
),
channel_growth AS (
    SELECT
        month,
        sales_channel,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY sales_channel
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_channel_revenue
)
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    sales_channel,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_pct,
    ROUND(
        revenue / SUM(revenue) OVER (PARTITION BY month) * 100,
        2
    ) AS revenue_contribution_pct
FROM channel_growth
ORDER BY month, sales_channel;

--3::What are the top-performing product categories by revenue, gross profit, and gross margin percentage?

WITH category_performance AS (
    SELECT
        p.category,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue,
        SUM(oi.quantity * p.cost_price) AS cogs
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category
)
SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue - cogs, 2) AS gross_profit,
    ROUND(
        (revenue - cogs) / NULLIF(revenue, 0) * 100,
        2
    ) AS gross_margin_pct
FROM category_performance
ORDER BY revenue DESC;

--4::Which products consistently rank among the top performers, and how has their revenue rank changed over time?

WITH monthly_product_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        p.product_id,
        p.product_name,
        SUM(oi.item_total) AS revenue
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        DATE_TRUNC('month', o.order_date),
        p.product_id,
        p.product_name
),
ranked_products AS (
    SELECT
        month,
        product_id,
        product_name,
        revenue,
        RANK() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM monthly_product_revenue
)
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    product_id,
    product_name,
    ROUND(revenue, 2) AS revenue,
    revenue_rank
FROM ranked_products
ORDER BY month, revenue_rank;

--5::How do discounts impact revenue and gross profitability across products and categories?

WITH product_discount_analysis AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS gross_revenue,
        SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100) AS discount_amount,
        SUM(oi.item_total) AS net_revenue,
        SUM(oi.quantity * p.cost_price) AS cogs
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)
SELECT
    product_id,
    product_name,
    category,
    ROUND(gross_revenue, 2) AS gross_revenue,
    ROUND(discount_amount, 2) AS discount_amount,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(net_revenue - cogs, 2) AS gross_profit,
    ROUND(
        (net_revenue - cogs) / NULLIF(net_revenue, 0) * 100,
        2
    ) AS gross_margin_pct
FROM product_discount_analysis
ORDER BY discount_amount DESC;

-------------------------------------------------------------------------
-------------------------------------------------------------------------
%%%% Customer Behavior & Retention %%%%%
-------------------------------------------------------------------------
-------------------------------------------------------------------------

--6:: What percentage of customers are repeat customers, and how much revenue do repeat customers contribute compared with one-time customers?
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(final_amount) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        order_count,
        revenue,
        CASE
            WHEN order_count > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS customer_type
    FROM customer_orders
)
SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(
        SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (),
        2
    ) AS revenue_contribution_percentage
FROM customer_segments
GROUP BY customer_type
ORDER BY revenue DESC;

--7::What is the average time between purchases for repeat customers, and which customer groups have the shortest repurchase cycles?
WITH customer_purchases AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM orders
    WHERE order_status = 'Delivered'
),
purchase_gaps AS (
    SELECT
        customer_id,
        order_date,
        previous_order_date,
        order_date - previous_order_date AS days_between_purchases
    FROM customer_purchases
    WHERE previous_order_date IS NOT NULL
)
SELECT
    ROUND(AVG(days_between_purchases), 2) AS avg_days_between_purchases,
    MIN(days_between_purchases) AS shortest_repurchase_cycle,
    MAX(days_between_purchases) AS longest_repurchase_cycle
FROM purchase_gaps;

--8::Which acquisition channels generate the highest proportion of repeat customers?

WITH customer_orders AS (
    SELECT
        o.customer_id,
        c.acquisition_channel,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        o.customer_id,
        c.acquisition_channel
),
channel_repeat_rate AS (
    SELECT
        acquisition_channel,
        COUNT(*) AS total_customers,
        COUNT(*) FILTER (
            WHERE order_count > 1
        ) AS repeat_customers
    FROM customer_orders
    GROUP BY acquisition_channel
)
SELECT
    acquisition_channel,
    total_customers,
    repeat_customers,
    ROUND(
        repeat_customers * 100.0
        / NULLIF(total_customers, 0),
        2
    ) AS repeat_customer_percentage
FROM channel_repeat_rate
ORDER BY repeat_customer_percentage DESC;

--9::How does customer purchasing behavior differ across age groups, gender, and geographic regions?

SELECT
    c.age_group,
    c.gender,
    c.state,
    COUNT(DISTINCT o.customer_id) AS customers,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(o.final_amount), 2) AS revenue,
    ROUND(
        SUM(o.final_amount)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS AOV
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.age_group,
    c.gender,
    c.state
ORDER BY revenue DESC;

--10::Which customers have significantly increased or decreased their spending over their most recent purchases?
WITH customer_purchases AS (
    SELECT
        customer_id,
        order_date,
        final_amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC
        ) AS purchase_rank
    FROM orders
    WHERE order_status = 'Delivered'
),
recent_purchases AS (
    SELECT
        customer_id,
        MAX(CASE WHEN purchase_rank = 1 THEN final_amount END) AS latest_purchase,
        MAX(CASE WHEN purchase_rank = 2 THEN final_amount END) AS previous_purchase
    FROM customer_purchases
    WHERE purchase_rank <= 2
    GROUP BY customer_id
)
SELECT
    customer_id,
    ROUND(latest_purchase, 2) AS latest_purchase,
    ROUND(previous_purchase, 2) AS previous_purchase,
    ROUND(latest_purchase - previous_purchase, 2) AS spending_change,
    ROUND(
        (latest_purchase - previous_purchase)
        / NULLIF(previous_purchase, 0) * 100,
        2
    ) AS spending_change_pct
FROM recent_purchases
WHERE previous_purchase IS NOT NULL
ORDER BY spending_change_pct DESC;

---------------------------------------------------------------
---------------------------------------------------------------
%%%% Product & Profitability %%%%
---------------------------------------------------------------
---------------------------------------------------------------
--11::Which products generate high revenue but low gross margins, potentially creating profitability risk?

WITH product_profitability AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.item_total) AS revenue,
        SUM(oi.quantity * p.cost_price) AS cogs
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)
SELECT
    product_id,
    product_name,
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue - cogs, 2) AS gross_profit,
    ROUND(
        (revenue - cogs) / NULLIF(revenue, 0) * 100,
        2
    ) AS gross_margin_pct
FROM product_profitability
WHERE revenue > (
    SELECT AVG(revenue)
    FROM product_profitability
)
ORDER BY gross_margin_pct ASC;

--12::Which products have strong gross margins but low sales volume and may represent growth opportunities?

WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.item_total) AS revenue,
        SUM(oi.quantity * p.cost_price) AS cogs
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),
calculated_metrics AS (
    SELECT
        product_id,
        product_name,
        category,
        units_sold,
        revenue,
        revenue - cogs AS gross_profit,
        (revenue - cogs) / NULLIF(revenue, 0) * 100 AS gross_margin_pct
    FROM product_performance
)
SELECT
    product_id,
    product_name,
    category,
    units_sold,
    ROUND(revenue, 2) AS revenue,
    ROUND(gross_profit, 2) AS gross_profit,
    ROUND(gross_margin_pct, 2) AS gross_margin_pct
FROM calculated_metrics
WHERE gross_margin_pct > (
    SELECT AVG(gross_margin_pct)
    FROM calculated_metrics
)
ORDER BY units_sold ASC, gross_margin_pct DESC;

--13::Which product categories contribute disproportionately to total profit compared with their share of revenue?

WITH category_performance AS (
    SELECT
        p.category,
        SUM(oi.item_total) AS revenue,
        SUM(oi.quantity * p.cost_price) AS cogs
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category
),
category_metrics AS (
    SELECT
        category,
        revenue,
        revenue - cogs AS gross_profit
    FROM category_performance
),
totals AS (
    SELECT
        SUM(revenue) AS total_revenue,
        SUM(gross_profit) AS total_profit
    FROM category_metrics
)
SELECT
    cm.category,
    ROUND(cm.revenue, 2) AS revenue,
    ROUND(cm.gross_profit, 2) AS gross_profit,
    ROUND(
        cm.revenue / NULLIF(t.total_revenue, 0) * 100,
        2
    ) AS revenue_share_pct,
    ROUND(
        cm.gross_profit / NULLIF(t.total_profit, 0) * 100,
        2
    ) AS profit_share_pct,
    ROUND(
        (
            cm.gross_profit / NULLIF(t.total_profit, 0)
        ) -
        (
            cm.revenue / NULLIF(t.total_revenue, 0)
        ),
        4
    ) AS profit_vs_revenue_share
FROM category_metrics cm
CROSS JOIN totals t
ORDER BY profit_vs_revenue_share DESC;

--14::What are the most frequently purchased product combinations, and what bundling opportunities can be identified?


WITH product_pairs AS (
    SELECT
        oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(DISTINCT oi1.order_id) AS order_count
    FROM order_items oi1
    JOIN order_items oi2
        ON oi1.order_id = oi2.order_id
       AND oi1.product_id < oi2.product_id
    JOIN orders o
        ON oi1.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        oi1.product_id,
        oi2.product_id
)
SELECT
    pp.product_a,
    p1.product_name AS product_a_name,
    pp.product_b,
    p2.product_name AS product_b_name,
    pp.order_count
FROM product_pairs pp
JOIN products p1
    ON pp.product_a = p1.product_id
JOIN products p2
    ON pp.product_b = p2.product_id
ORDER BY pp.order_count DESC
LIMIT 15;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
%%%% Returns & Customer Experience %%%
------------------------------------------------------------------------
------------------------------------------------------------------------

---15:: Which products have the highest return rates after accounting for their sales volume?

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS units_sold
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),
product_returns AS (
    SELECT
        product_id,
        COUNT(DISTINCT return_id) AS return_count
    FROM returns
    GROUP BY product_id
)
SELECT
    ps.product_id,
    ps.product_name,
    ps.category,
    ps.units_sold,
    COALESCE(pr.return_count, 0) AS return_count,
    ROUND(
        COALESCE(pr.return_count, 0) * 100.0
        / NULLIF(ps.units_sold, 0),
        2
    ) AS return_rate_pct
FROM product_sales ps
LEFT JOIN product_returns pr
    ON ps.product_id = pr.product_id
WHERE ps.units_sold >= 10
ORDER BY return_rate_pct DESC;

--16:: What are the primary return reasons, and which products or categories are most affected by each reason?

WITH return_analysis AS (
    SELECT
        r.return_reason,
        r.product_id,
        p.product_name,
        p.category,
        COUNT(*) AS return_count
    FROM returns r
    JOIN products p
        ON r.product_id = p.product_id
    GROUP BY
        r.return_reason,
        r.product_id,
        p.product_name,
        p.category
),
reason_totals AS (
    SELECT
        return_reason,
        SUM(return_count) AS total_returns
    FROM return_analysis
    GROUP BY return_reason
),
ranked_products AS (
    SELECT
        ra.return_reason,
        ra.product_id,
        ra.product_name,
        ra.category,
        ra.return_count,
        ROW_NUMBER() OVER (
            PARTITION BY ra.return_reason
            ORDER BY ra.return_count DESC
        ) AS product_rank
    FROM return_analysis ra
)
SELECT
    rp.return_reason,
    rt.total_returns,
    rp.product_name,
    rp.category,
    rp.return_count
FROM ranked_products rp
JOIN reason_totals rt
    ON rp.return_reason = rt.return_reason
WHERE rp.product_rank <= 3
ORDER BY
    rt.total_returns DESC,
    rp.return_reason,
    rp.return_count DESC;


--17::Which products combine high return rates with low customer ratings, indicating potential product quality or expectation issues?


WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS units_sold
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),
product_returns AS (
    SELECT
        product_id,
        COUNT(DISTINCT return_id) AS return_count
    FROM returns
    GROUP BY product_id
),
product_ratings AS (
    SELECT
        product_id,
        ROUND(AVG(rating), 2) AS avg_rating
    FROM reviews
    GROUP BY product_id
),
product_metrics AS (
    SELECT
        ps.product_id,
        ps.product_name,
        ps.category,
        ps.units_sold,
        COALESCE(pr.return_count, 0) AS return_count,
        ROUND(
            COALESCE(pr.return_count, 0) * 100.0
            / NULLIF(ps.units_sold, 0),
            2
        ) AS return_rate_pct,
        COALESCE(pra.avg_rating, 0) AS avg_rating
    FROM product_sales ps
    LEFT JOIN product_returns pr
        ON ps.product_id = pr.product_id
    LEFT JOIN product_ratings pra
        ON ps.product_id = pra.product_id
)
SELECT
    product_id,
    product_name,
    category,
    units_sold,
    return_count,
    return_rate_pct,
    avg_rating
FROM product_metrics
WHERE return_rate_pct > (
    SELECT AVG(return_rate_pct)
    FROM product_metrics
)
AND avg_rating < (
    SELECT AVG(avg_rating)
    FROM product_metrics
)
ORDER BY
    return_rate_pct DESC,
    avg_rating ASC;

--18:: How do return rates vary across sales channels, and are certain channels associated with higher return risk?

WITH channel_sales AS (
    SELECT
        sales_channel,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY sales_channel
),
channel_returns AS (
    SELECT
        o.sales_channel,
        COUNT(DISTINCT r.return_id) AS return_count
    FROM returns r
    JOIN orders o
        ON r.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.sales_channel
)
SELECT
    cs.sales_channel,
    cs.total_orders,
    COALESCE(cr.return_count, 0) AS return_count,
    ROUND(
        COALESCE(cr.return_count, 0) * 100.0
        / NULLIF(cs.total_orders, 0),
        2
    ) AS return_rate_pct
FROM channel_sales cs
LEFT JOIN channel_returns cr
    ON cs.sales_channel = cr.sales_channel
ORDER BY return_rate_pct DESC;

---19:: How can customers be segmented using Recency, Frequency, and Monetary value to identify Champions, Loyal Customers, At-Risk Customers, and Lost Customers?

WITH customer_rfm AS (
    SELECT
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.final_amount) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
    GROUP BY
        c.customer_id,
        c.customer_name
),
rfm_scores AS (
    SELECT
        *,
        CURRENT_DATE - last_purchase_date AS recency_days,
        NTILE(5) OVER (
            ORDER BY last_purchase_date DESC
        ) AS recency_score,
        NTILE(5) OVER (
            ORDER BY frequency
        ) AS frequency_score,
        NTILE(5) OVER (
            ORDER BY monetary
        ) AS monetary_score
    FROM customer_rfm
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    recency_score,
    frequency_score,
    monetary_score,
    CASE
        WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
            THEN 'Champions'
        WHEN frequency_score >= 4
             AND monetary_score >= 3
            THEN 'Loyal Customers'
        WHEN recency_score <= 2
             AND frequency_score >= 3
             AND monetary_score >= 3
            THEN 'At-Risk Customers'
        WHEN recency_score <= 2
             AND frequency_score <= 2
             AND monetary_score <= 2
            THEN 'Lost Customers'
        ELSE 'Other'
    END AS customer_segment
FROM rfm_scores
ORDER BY
    customer_segment,
    monetary DESC;

--20:: How much revenue does each RFM segment contribute, and what retention or marketing action should the business prioritize for each segment?

WITH customer_rfm AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(final_amount) AS monetary,
        MAX(order_date) AS last_purchase_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        *,
        CURRENT_DATE - last_purchase_date AS recency_days,
        NTILE(5) OVER (ORDER BY last_purchase_date DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary) AS monetary_score
    FROM customer_rfm
),
segmented_customers AS (
    SELECT
        *,
        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'Champions'
            WHEN frequency_score >= 4
                 AND monetary_score >= 3
                THEN 'Loyal Customers'
            WHEN recency_score <= 2
                 AND frequency_score >= 3
                 AND monetary_score >= 3
                THEN 'At-Risk Customers'
            WHEN recency_score <= 2
                 AND frequency_score <= 2
                 AND monetary_score <= 2
                THEN 'Lost Customers'
            ELSE 'Other'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS revenue,
    ROUND(
        SUM(monetary) * 100.0
        / SUM(SUM(monetary)) OVER (),
        2
    ) AS revenue_contribution_pct,
    CASE
        WHEN customer_segment = 'Champions'
            THEN 'Reward and nurture with exclusive offers and early access'
        WHEN customer_segment = 'Loyal Customers'
            THEN 'Increase repeat purchases through loyalty and cross-selling'
        WHEN customer_segment = 'At-Risk Customers'
            THEN 'Prioritize win-back campaigns before customers become Lost'
        WHEN customer_segment = 'Lost Customers'
            THEN 'Use reactivation campaigns with targeted incentives'
        ELSE 'Monitor and develop based on customer behavior'
    END AS recommended_action
FROM segmented_customers
GROUP BY customer_segment
ORDER BY revenue DESC;