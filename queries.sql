1. Which product has the highest price? Only return a single row.
SELECT product_name FROM products
ORDER BY price DESC
LIMIT 1;

2. Which customer has made the most orders?
SELECT 
CONCAT (first_name,' ',last_name) as Customer,
count(o.customer_id) as order_count
FROM customers c
JOIN orders o
ON c.customer_id= o.customer_id
GROUP BY Customer
HAVING count(o.customer_id) > 1;
-----------------------------------------------
with rank_cte AS
(
SELECT 
CONCAT (first_name,' ',last_name) as Customer,
rank() over(order by COUNT(o.customer_id) DESC) as rank_num
FROM customers c
JOIN orders o
ON c.customer_id= o.customer_id
GROUP BY Customer
)
SELECT customer
FROM rank_cte
WHERE rank_num = 1

3. How many orders were placed in May, 2023?

with cte as (
SELECT 
order_id,
EXTRACT(MONTH from order_date) as mon,
EXTRACT(YEAR from order_date) as yr,
order_date
FROM orders 
)
SELECT 
COUNT(order_id) as order_count
FROM cte
WHERE (mon = 5) AND (yr = 2023)
-- NOTE : & operator does not work in PostgreSQL. use AND instead
--      use the above format to get MONTH & YEAR.


4) What’s the total revenue per product?

SELECT 
p.product_name, 
SUM(oi.quantity*p.price) AS revenue
FROM order_items oi
JOIN products p
USING (product_id)
GROUP by product_name
order by product_name

5. Find the date with the highest revenue.

SELECT 
o.order_date,
SUM(oi.quantity*p.price) AS revenue
FROM order_items oi
JOIN products p
USING (product_id)
JOIN orders o
USING (order_id)
GROUP by order_date
order by revenue DESC
LIMIT 1
---------------------------
--using rank 5. Find the date with the highest revenue.

SELECT 
o.order_date,
SUM(oi.quantity*p.price) as revenue,
rank() over(order by(SUM(oi.quantity*p.price))desc) as rnk
FROM order_items oi
JOIN products p
USING (product_id)
JOIN orders o
USING (order_id)
GROUP by order_date
LIMIT 1

6. Find the product that has seen the biggest increase in sales quantity over the previous month.
with cte as(
SELECT 
order_date as date,
split_part(product_name,'t',2) as name,
quantity as qty,
lag(quantity,1,0)OVER(order by order_date)as prev,
quantity-(lag(quantity,1)OVER(PARTITION by product_id
                              order by order_date))as diff
FROM products p
JOIN order_items oi
USING (product_id)
JOIN orders o
USING (order_id))
SELECT name,diff,date,qty,prev
from cte
where diff is NOT NULL
order by diff desc
Limit 1

--7. Find the first order (by date) for each customer.
with CTE as(
SELECT 
first_name,last_name,
customer_id,
order_date,
rank() over(PARTITION by customer_id order by order_date asc) as rank_no
from orders o
join customers c
USING (customer_id)
)
SELECT 
concat(first_name,' ',last_name) as name,
order_date as first_order_date
from cte
WHERE rank_no = 1

--8. Find the top 3 customers who have ordered 
--the most distinct products
with CTE as(
SELECT 
first_name,last_name,
c.customer_id,
COUNT(DISTINCT product_id) as distinct_prod_count
from orders o
join customers c
  USING (customer_id)
join order_items oi
  using (order_id)
GROUP by c.customer_id,1,2 
)
SELECT 
concat(first_name,' ',last_name) as name,distinct_prod_count
from cte
order by customer_id
LIMIT 3

--9. What is the median order total?

with cte as(
SELECT 
order_id, 
SUM(oi.quantity*p.price) AS order_total
FROM order_items oi
JOIN products p
USING (product_id)
GROUP by order_id
),
cte2 as(
SELECT *,
rank() over(order by order_total asc) as rn_asc,
rank() over(order by order_total desc) as rn_desc
from cte
)
SELECT round(avg(order_total),2) as median_order_total from cte2
WHERE abs(rn_asc-rn_desc) <=1

--10. For each order, determine if it was 'Expensive' (total over 300), 'Affordable' (total over 100), or 'Cheap'.

with cte as(
SELECT 
order_id, 
SUM(oi.quantity*p.price) AS order_total
FROM order_items oi
JOIN products p
USING (product_id)
GROUP by order_id
)
SELECT *,
case when (order_total > 300) THEN 'Expensive'
  when (order_total > 100) THEN 'Affordable'
  else 'Cheap'
  END
from cte
order by order_id--)

--11. Find customers who have ordered the product with the highest price.

with cte as(
SELECT 
first_name,last_name,
rank() over(order by price DESC) as rn
from orders o
join customers c
  USING (customer_id)
join order_items oi
  using (order_id)
JOIN products p
  using (product_id)
)
select 
concat(first_name,' ',last_name) as name
from cte
where rn =1

--12. Which product has been bought the least in terms of quantity?
with cte as(
SELECT 
product_name,
sum(quantity) as total_qty
from products
join order_items oi
  using (product_id)
 GROUP by product_id 
)
select 
*
from cte
order by total_qty DESC
LIMIT 1

