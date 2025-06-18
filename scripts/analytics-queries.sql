/*
Create a temporary table that joins the orders, order_products, and products tables to get information about each order,
including the products that were purchased and their department and aisle information.
*/
CREATE TEMPORARY TABLE order_info AS
    SELECT o.order_id, o.order_number, o.order_dow, o.order_hour_of_day, o.days_since_prior_order,
           op.product_id, op.add_to_cart_order, op.reordered,
           p.product_name, p.aisle_id, p.department_id
    FROM orders AS o
    JOIN order_products AS op ON o.order_id = op.order_id
    JOIN products AS p ON op.product_id = p.product_id

/*
Create a temporary table that groups the orders by product and finds the total number of times each product was purchased, 
the total number of times each product was reordered, and the average number of times each product was added to a cart.
*/
CREATE TEMPORARY TABLE product_order_summary AS
    SELECT p.product_id, p.product_name,
		   COUNT(op.order_id) AS total_orders,
           SUM(op.reordered) AS total_reordered,
           AVG(op.add_to_cart_order) AS avg_add_to_cart
    FROM order_products AS op
	JOIN  products AS p ON op.product_id = p.product_id
    GROUP BY p.product_id, p.product_name

/*
Create a temporary table that groups the orders by department and finds the total number of products purchased,
the total number of unique products purchased, the total number of products purchased on weekdays vs weekends,
and the average time of day that products in each department are ordered.
*/
CREATE TEMPORARY TABLE department_order_summary AS
SELECT 
    d.department_id,
    d.department,
    COUNT(*) AS total_products_purchased,
    COUNT(DISTINCT p.product_id) AS unique_products_purchased,
    COUNT(CASE WHEN o.order_dow < 6 THEN 1 ELSE NULL END) AS weekday_purchases,
    COUNT(CASE WHEN o.order_dow >=6 THEN 1 ELSE NULL END) AS weekend_purchases,
    AVG(o.order_hour_of_day) AS avg_order_hour
FROM 
    order_products op
JOIN 
    products p ON op.product_id = p.product_id
JOIN 
    departments d ON p.department_id = d.department_id
JOIN 
    orders o ON op.order_id = o.order_id
GROUP BY 
    d.department_id, d.department;

/*
Create a temporary table that groups the orders by aisle and finds the top 10 most popular aisles,
including the total number of products purchased and the total number of unique products purchased from each aisle.
*/
CREATE TEMPORARY TABLE top_10_aisles AS
SELECT 
    a.aisle_id,
    a.aisle,
    COUNT(*) AS total_products_purchased,
    COUNT(DISTINCT p.product_id) AS unique_products_purchased
FROM 
    order_products op
JOIN 
    products p ON op.product_id = p.product_id
JOIN 
    aisles a ON p.aisle_id = a.aisle_id
GROUP BY 
    a.aisle_id, a.aisle
ORDER BY 
    total_products_purchased DESC LIMIT 10;

/*
Combine the information from the previous temporary tables into a final table that shows the product ID,
product name, department ID, department name, aisle ID, aisle name, total number of times purchased, 
total number of times reordered, average number of times added to cart, total number of products purchased,
total number of unique products purchased, total number of products purchased on weekdays,
total number of products purchased on weekends, and average time of day products are ordered in each department.
*/
CREATE TEMPORARY TABLE final_product_summary AS
SELECT 
    p.product_id,
    p.product_name,
    d.department_id,
    d.department AS department_name,
    a.aisle_id,
    a.aisle AS aisle_name,

    -- From product_order_summary
    pos.total_orders AS total_times_purchased,
    pos.total_reordered AS total_times_reordered,
    pos.avg_add_to_cart AS avg_add_to_cart_order,

    -- From department_order_summary
    dos.total_products_purchased,
    dos.unique_products_purchased,
    dos.weekday_purchases,
    dos.weekend_purchases,
    dos.avg_order_hour

FROM 
    products p
JOIN 
    departments d ON p.department_id = d.department_id
JOIN 
    aisles a ON p.aisle_id = a.aisle_id
LEFT JOIN 
    product_order_summary pos ON p.product_id = pos.product_id
LEFT JOIN 
    department_order_summary dos ON d.department_id = dos.department_id;