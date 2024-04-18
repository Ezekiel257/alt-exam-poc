# Alt school Data Engineering second semester exams

--Part one
---database already setup with the data loaded into it.

--Part two
--2A Q1; Find the most ordered item.
-- This query finds the most ordered item based on the number of times it appears in successfully checked-out orders.

--- Selecting the product_id, product_name, and count of appearances in successful orders
SELECT p.id AS product_id,
       p.name AS product_name,
       COUNT(*) AS num_times_in_successful_orders
FROM ALT_SCHOOL.PRODUCTS p
--- Joining the PRODUCTS, LINE_ITEMS, and ORDERS tables
JOIN ALT_SCHOOL.LINE_ITEMS li ON p.id = li.item_id
JOIN ALT_SCHOOL.ORDERS o ON li.order_id = o.order_id
--- Filtering orders with a status of 'success'
WHERE o.status = 'success'
--- Grouping the results by product_id and product_name
GROUP BY p.id, p.name
-- Ordering the results by the count of appearances in successful orders in descending order
ORDER BY num_times_in_successful_orders DESC
-- Limiting the output to the top result
LIMIT 1;
---Anwser is Apple AirPods Pro with product_id 7, which had num_times_in_successful_orders of 735.


--2A Q2;
--This query identifies the top 5 spenders based on their total spend, along with their customer ID and location, 
--without considering currency and without using the line_items table.


-- Using a Common Table Expression (CTE) to join the events table to the customers table using the customer_id,
-- and retrieving the location and event_product_id from the events table
WITH customer_events AS (
    SELECT e.customer_id, 
           c.location, 
           (e.event_data ->> 'item_id')::int AS event_product_id -- Cast item_id as an integer for querying
    FROM ALT_SCHOOL.EVENTS e
    JOIN ALT_SCHOOL.CUSTOMERS c ON e.customer_id = c.customer_id
),

-- Joining the customer_events CTE to the products table to calculate the total spend for each customer_id
customer_spend AS (
    SELECT ce.customer_id, 
           ce.location, 
           SUM(p.price) OVER (PARTITION BY ce.customer_id) AS total_spend
    FROM customer_events ce
    JOIN ALT_SCHOOL.PRODUCTS p ON ce.event_product_id = p.id
)

-- Selecting the top 5 spenders with their customer_id, location, and total_spend
SELECT customer_id, location, total_spend
FROM (
    SELECT DISTINCT 
           customer_id, 
           location, 
           total_spend,
           RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
    FROM customer_spend
) ranked_spend
WHERE spend_rank <= 5
ORDER BY total_spend DESC;

-- Running the query we see that the customers with the highest spend resides in Dominica, Cameroon, India, New Caledonia and Norway
-- with a total spend of 19,672.81, 19,352.81, 19,079.73, 19,002.81 and 18,952.77 respectively.

--Part TWO B Question 1

-- Determine the most common location (country) where successful checkouts occurred
SELECT c.location AS location,
       COUNT(*) AS checkout_count
FROM ALT_SCHOOL.EVENTS e
JOIN ALT_SCHOOL.CUSTOMERS c ON e.customer_id = c.customer_id
WHERE e.event_data ->> 'status' = 'success' -- Filter events for successful checkouts
AND c.location IS NOT NULL -- Exclude null locations
GROUP BY c.location
ORDER BY checkout_count DESC
LIMIT 1; -- Limit the result to the most common location

--we can see that the country with the highest number of successful orders is Korea with a total checkout number of 17

--Part TWO B Question 2
-- Identify the customers who abandoned their carts and count the number of events (excluding visits) that occurred before abandonment
SELECT e.customer_id AS customer_id,
       COUNT(*) AS num_events
FROM ALT_SCHOOL.EVENTS e
WHERE e.event_data ->> 'status' = 'remove_from_cart' -- Filter events for cart abandonment
AND e.event_data ->> 'event_type' != 'visit' -- Exclude visit events
GROUP BY e.customer_id;

-- Find the average number of visits per customer, considering only customers who completed a checkout
SELECT ROUND(AVG(num_visits), 2) AS average_visits
FROM (
    SELECT e.customer_id AS customer_id,
           COUNT(*) AS num_visits
    FROM ALT_SCHOOL.EVENTS e
    JOIN ALT_SCHOOL.CUSTOMERS c ON e.customer_id = c.customer_id
    WHERE e.event_data ->> 'event_type' = 'checkout' -- Filter visit events
    AND EXISTS (
        SELECT 1
        FROM ALT_SCHOOL.EVENTS e2
        WHERE e2.customer_id = e.customer_id
        AND e2.event_data ->> 'status' = 'success' -- Filter for customers who completed a checkout
    )
    GROUP BY e.customer_id
) AS avg_visits_per_customer;






