use ecommerce;


-- Basic Queries
-- 1. List all unique cities where customers are located.

SELECT 
    distinct(customer_city)
FROM
    customers ;

-- 2. Count the number of orders placed in 2017.

SELECT count(order_id) FROM orders 
where year(order_purchase_timestamp) = "2017";
    



-- 3. Find the total sales per category.

SELECT 
    products.product_category, 
    SUM(payments.payment_value) AS total_payment_value
FROM 
    payments 
JOIN 
    order_items ON payments.order_id = order_items.order_id 
JOIN 
    products ON products.product_id = order_items.product_id 
GROUP BY 
    products.product_category LIMIT 2;



-- 4. Calculate the percentage of orders that
--  were paid in installments.
SELECT 
    ((SUM(CASE
        WHEN payment_installments >= 1 THEN 1
        ELSE 0
    END)) / COUNT(*)) * 100 as order_installments
FROM
    payments;



-- 5. Count the number of customers from each state. 
SELECT 
    COUNT(customer_id), customer_state
FROM
    customers
GROUP BY customer_state;
 
