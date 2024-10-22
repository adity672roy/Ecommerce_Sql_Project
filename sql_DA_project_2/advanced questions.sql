use ecommerce;
-- Advanced Queries
-- 1. Calculate the moving average of order 
-- values for each customer over their order history.
SELECT 
    a.customer_id, 
    a.order_purchase_timestamp, 
    a.payment,
    AVG(a.payment) OVER (
        PARTITION BY a.customer_id 
        ORDER BY a.order_purchase_timestamp 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg
FROM 
    (SELECT 
        orders.customer_id,
        orders.order_purchase_timestamp,
        payments.payment_value AS payment 
     FROM 
        payments 
     JOIN 
        orders ON payments.order_id = orders.order_id
    ) AS a;

 
 





-- 2. Calculate the cumulative sales per 
-- month for each year.
select  order_year,
    order_month,
    total_revenue,
    SUM(total_revenue) OVER (
        PARTITION BY order_year 
        ORDER BY order_month
    ) AS cumulative_sales
from 
(SELECT YEAR(orders.order_purchase_timestamp) AS order_year,
    MONTHNAME(orders.order_purchase_timestamp) AS order_month,
    SUM(payments.payment_value) AS total_revenue
FROM payments JOIN orders ON payments.order_id = orders.order_id
GROUP BY YEAR(orders.order_purchase_timestamp),
    MONTHNAME(orders.order_purchase_timestamp)
ORDER BY YEAR(orders.order_purchase_timestamp) ASC,
    MONTHNAME(orders.order_purchase_timestamp) ASC) AS sales ;



-- 3. Calculate the year-over-year growth rate
--  of total sales.
select years, payment ,
 lag(payment ,1) 
 over (order by years ) as previous_year
 from 
(select YEAR(orders.order_purchase_timestamp) as years
 , sum(payments.payment_value) as payment from payments join
orders ON payments.order_id = orders.order_id
group by years
order by years asc )as a;

-- OR-- 

WITH a AS (SELECT YEAR(orders.order_purchase_timestamp) 
AS years, ROUND(SUM(payments.payment_value),1) AS payment 
FROM payments JOIN orders ON payments.order_id = orders.order_id
GROUP BY years order by years asc )
select years, payment , lag(payment ,1) over (order by years )
as previous_year,
ROUND(((payment - LAG(payment ,1) OVER (ORDER BY years)) /
 LAG(payment ,1) OVER (ORDER BY years )) *100 ,2) AS YOY_growth
 from a ;



-- 4. Calculate the retention rate of customers,
--  defined as the percentage of customers who make 
--  another purchase within 6 months of their first purchase.
WITH first_orders AS (
    SELECT 
        customers.customer_id,
        MIN(orders.order_purchase_timestamp) AS first_order
    FROM 
        customers
    JOIN 
        orders ON customers.customer_id = orders.customer_id
    GROUP BY 
        customers.customer_id
),
subsequent_purchases AS (
    SELECT 
        a.customer_id,
        COUNT(DISTINCT orders.order_purchase_timestamp) AS additional_purchases
    FROM 
        first_orders a
    JOIN 
        orders ON a.customer_id = orders.customer_id
    WHERE 
        orders.order_purchase_timestamp > a.first_order
        AND orders.order_purchase_timestamp < DATE_ADD(a.first_order, INTERVAL 6 MONTH)
    GROUP BY 
        a.customer_id
),
total_customers AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customer_count
    FROM first_orders
),
retained_customers AS (
    SELECT COUNT(DISTINCT customer_id) AS retained_customer_count
    FROM subsequent_purchases
)
SELECT 
    (retained_customer_count / total_customer_count) * 100 AS retention_rate
FROM 
    total_customers, retained_customers;


-- 5. Identify the top 3 customers who spent
--  the most money in each year.
with a as (
select year(orders.order_purchase_timestamp) as years ,orders.customer_id,
sum(payments.payment_value) as payment,dense_rank() over 
(partition by year(orders.order_purchase_timestamp) order by 
sum(payments.payment_value) desc) as d_rank
 from orders join payments on 
orders.order_id = payments.order_id
group by year(orders.order_purchase_timestamp) ,orders.customer_id
) 
select  years ,orders.customer_id,payment ,d_rank 
from a where d_rank <=3 ;
