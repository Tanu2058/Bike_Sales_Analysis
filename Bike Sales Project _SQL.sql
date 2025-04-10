create database Bike;
use Bike;

Create table customers(
customer_id int,
first_name char(10),
last_name char(10),
phone int,
email varchar(20),
street varchar(20),
city char(10),
state Char(5),
zip_code int,
primary key (customer_id)
);

CREATE TABLE stores(
    store_id INT,
    store_name VARCHAR(50), -- Increased size for longer store names
    phone VARCHAR(15), -- Phone numbers should be VARCHAR to accommodate formatting
    email VARCHAR(50), -- Increased size for longer email addresses
    street VARCHAR(100), -- Increased size for longer street addresses
    city CHAR(30), -- Increased size for city names
    state CHAR(10),
    zip_code INT,
    PRIMARY KEY (store_id)
);


drop table store;

CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT, -- Auto-increment for unique staff IDs
    first_name VARCHAR(50) NOT NULL, -- Adjust length as needed
    last_name VARCHAR(50) NOT NULL, -- Adjust length as needed
    email VARCHAR(100) NOT NULL UNIQUE, -- Ensure email addresses are unique
    phone VARCHAR(15), -- Phone numbers stored as VARCHAR
    active BOOLEAN DEFAULT TRUE, -- To indicate whether the staff is active (1 or 0)
    store_id INT, -- Foreign key to reference the store table
    manager_id INT, -- Self-referencing foreign key for the manager
    PRIMARY KEY (staff_id), -- Set staff_id as the primary key
    FOREIGN KEY (store_id) REFERENCES stores(store_id), -- Foreign key to the store table
    FOREIGN KEY (manager_id) REFERENCES staff(staff_id) -- Self-referencing foreign key
);

CREATE TABLE orders (
    order_id INT, -- Unique identifier for each order
    customer_id INT NOT NULL, -- Reference to the customer placing the order
    order_status VARCHAR(20) NOT NULL, -- Status like 'Pending', 'Shipped', etc.
    order_date DATE NOT NULL, -- Date the order was placed
    required_date DATE NOT NULL, -- Date the order is required
    shipped_date DATE, -- Date the order was shipped (can be NULL if not shipped yet)
    store_id INT NOT NULL, -- Reference to the store fulfilling the order
    staff_id INT NOT NULL, -- Reference to the staff member handling the order
    PRIMARY KEY (order_id), -- Primary key for the table
    FOREIGN KEY (store_id) REFERENCES stores(store_id), -- Link to the store table
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) -- Link to the staff table
);

CREATE TABLE brand (
    brand_id INT AUTO_INCREMENT,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (brand_id)
);
CREATE TABLE category (
    category_id INT AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (category_id)
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT, -- Unique identifier for each product
    product_name VARCHAR(100) NOT NULL, -- Name of the product
    brand_id INT NOT NULL, -- Reference to the brand table
    category_id INT NOT NULL, -- Reference to the category table
    model_year YEAR NOT NULL, -- Year of the product's model
    list_price DECIMAL(10, 2) NOT NULL CHECK (list_price >= 0), -- Product price
    PRIMARY KEY (product_id), -- Primary key for the table
    FOREIGN KEY (brand_id) REFERENCES brand(brand_id), -- Link to the brand table
    FOREIGN KEY (category_id) REFERENCES category(category_id) -- Link to the category table
);

CREATE TABLE order_items (
    order_id INT NOT NULL, -- References the orders table
    item_id INT , -- Unique identifier for each item in an order
    product_id INT NOT NULL, -- References the products table
    quantity INT NOT NULL, -- Quantity of the product ordered
    list_price DECIMAL(10, 2), -- Price per unit of the product
    discount DECIMAL(5, 2) NOT NULL, -- Discount percentage
    FOREIGN KEY (order_id) REFERENCES orders(order_id), -- Link to the orders table
    FOREIGN KEY (product_id) REFERENCES products(product_id) -- Link to the products table
);

CREATE TABLE stocks (
    store_id INT NOT NULL, -- References the store table
    product_id INT NOT NULL, -- References the products table
    quantity INT NOT NULL CHECK (quantity >= 0), -- Quantity of the product in stock
    PRIMARY KEY (store_id, product_id), -- Composite primary key to uniquely identify a product in a specific store
    FOREIGN KEY (store_id) REFERENCES stores(store_id), -- Link to the store table
    FOREIGN KEY (product_id) REFERENCES products(product_id) -- Link to the products table
);

SELECT * FROM  category;

SELECT * FROM  customers LIMIT 10;

SELECT * FROM  order_items LIMIT 10;

SELECT * FROM  orders LIMIT 10;

SELECT * FROM  products LIMIT 10;

SELECT * FROM  staff;

SELECT * FROM  stocks LIMIT 10;

SELECT * FROM  stores;

-- Which store has more sales 
with total_revenue AS
             (SELECT oi.order_id,  
                     ot.store_id,
                     s.store_name,
                     ot.order_date, 
                     oi.product_id,
                     oi.quantity, 
                     oi.list_price, 
                     oi.discount, 
                    ((oi.quantity * oi.list_price) * (1-oi.discount)) AS total_sale_product
              FROM order_items as oi
              LEFT JOIN orders as ot
              ON oi.order_id = ot.order_id 
              LEFT JOIN stores as s
              ON ot.store_id = s.store_id)          
        SELECT store_name, 
               SUM(total_sale_product) as revenue,
               ROUND((SUM(total_sale_product) / ((SELECT SUM(total_sale_product) FROM total_revenue))*100),2) as percentage
        FROM total_revenue
        GROUP BY store_id
        ORDER BY revenue DESC;

-- Most valuable costumer
 with total_spent AS
                (SELECT oi.order_id,
                     ot.customer_id,
                     c.first_name,
                     c.last_name,
                     ot.order_date, 
                     oi.product_id,
                     oi.quantity, 
                     oi.list_price, 
                     oi.discount, 
                     ((oi.quantity * oi.list_price) * (1-oi.discount)) AS total_sale_product
              FROM order_items as oi
              LEFT JOIN orders as ot
              ON oi.order_id = ot.order_id
              LEFT JOIN customers as c
              ON ot.customer_id = c.customer_id) 
              
SELECT customer_id, first_name, last_name, ROUND(SUM(total_sale_product),2) AS total_spent
FROM total_spent
GROUP BY customer_id, first_name, last_name
ORDER BY total_spent DESC
LIMIT 10 ;

-- Year and Month with most revenue
WITH total_sale AS (
    SELECT 
        ot.order_date, 
        oi.product_id,
        oi.quantity, 
        oi.list_price, 
        oi.discount, 
        ((oi.quantity * oi.list_price) * (1 - oi.discount)) AS total_sale_product
    FROM order_items AS oi
    LEFT JOIN orders AS ot ON oi.order_id = ot.order_id
)
SELECT 
    YEAR(order_date) AS year, -- Extract year from the order date
    SUM(total_sale_product) AS total_revenue -- Calculate total revenue for the year
FROM total_sale
GROUP BY year
ORDER BY total_revenue DESC; -- Order results by total revenue in descending order

-- 
WITH total_sale AS (
    SELECT 
        ot.order_date, 
        oi.product_id,
        oi.quantity, 
        oi.list_price, 
        oi.discount, 
        ((oi.quantity * oi.list_price) * (1 - oi.discount)) AS total_sale_product
    FROM order_items AS oi
    LEFT JOIN orders AS ot ON oi.order_id = ot.order_id
)
SELECT 
    MONTH(order_date) AS month, -- Extract the month from the order_date
    SUM(total_sale_product) AS total_revenue -- Calculate total revenue for the month
FROM total_sale
GROUP BY month
ORDER BY total_revenue DESC; -- Order by total revenue in descending order

-- Most selled products
WITH total_sales AS (
                    SELECT ot.order_date,
                           oi.product_id,
                           p.product_name,
                           oi.quantity, 
                           oi.list_price, 
                           oi.discount, 
                           ((oi.quantity * oi.list_price) * (1 - oi.discount)) AS total_sale_product
                    FROM order_items AS oi
                    LEFT JOIN products AS p 
                    ON oi.product_id = p.product_id
                    LEFT JOIN orders as ot
                    ON oi.order_id = ot.order_id 
)


SELECT  product_name,
        SUM(quantity) AS quantity_sell ,
        SUM(total_sale_product) AS total_revenue
FROM   total_sales
WHERE  order_date <= '2016-12-31'
GROUP BY product_name
ORDER BY  total_revenue DESC
LIMIT 10;

-- -2017
WITH total_sales AS (
                    SELECT ot.order_date,
                           oi.product_id,
                           p.product_name,
                           oi.quantity, 
                           oi.list_price, 
                           oi.discount, 
                           ((oi.quantity * oi.list_price) * (1 - oi.discount)) AS total_sale_product
                    FROM order_items AS oi
                    LEFT JOIN products AS p 
                    ON oi.product_id = p.product_id
                    LEFT JOIN orders as ot
                    ON oi.order_id = ot.order_id 
)


SELECT  product_name,
        SUM(quantity) AS quantity_sell ,
        SUM(total_sale_product) AS total_revenue
FROM   total_sales
WHERE  (order_date >= '2017-01-01') AND (order_date <= '2017-12-31')
GROUP BY product_name
ORDER BY  total_revenue DESC
LIMIT 10;

-- 2018
WITH total_sales AS (
                    SELECT ot.order_date,
                           oi.product_id,
                           p.product_name,
                           oi.quantity, 
                           oi.list_price, 
                           oi.discount, 
                           ((oi.quantity * oi.list_price) * (1 - oi.discount)) AS total_sale_product
                    FROM order_items AS oi
                    LEFT JOIN products AS p 
                    ON oi.product_id = p.product_id
                    LEFT JOIN orders as ot
                    ON oi.order_id = ot.order_id 
)


SELECT  product_name,
        SUM(quantity) AS quantity_sell ,
        SUM(total_sale_product) AS total_revenue
FROM   total_sales
WHERE  (order_date >= '2018-01-01') AND (order_date <= '2018-12-31')
GROUP BY product_name
ORDER BY  total_revenue DESC
LIMIT 10;        

--  Best staff seller
WITH subquery AS (
    SELECT 
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.list_price,
        oi.discount,
        ROUND(((oi.quantity * oi.list_price) * (1 - oi.discount)), 2) AS final_price,
        s.staff_id,
        s.first_name,
        s.last_name
    FROM order_items AS oi
    JOIN orders AS ot ON oi.order_id = ot.order_id
    JOIN staff AS s ON ot.staff_id = s.staff_id
)
SELECT 
    staff_id,
    first_name,
    last_name,
    SUM(final_price) AS staff_revenue
FROM subquery
GROUP BY staff_id, first_name, last_name
ORDER BY staff_revenue DESC;

-- Customer segmentation
WITH customer_stats AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent,
        COUNT(DISTINCT o.order_id) AS total_orders,
        DATEDIFF('2018-12-29', MAX(o.order_date)) AS days_since_last_purchase
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT 
    customer_id,
    CASE 
        WHEN total_orders > 1 THEN 'repeat buyer'
        ELSE 'one-time buyer'
    END AS purchase_frequency,
    CASE 
        WHEN days_since_last_purchase < 90 THEN 'recent buyer'
        ELSE 'not recent buyer'
    END AS purchase_recency
FROM customer_stats;


SELECT
    product_a,
    product_b,
    co_purchase_count
FROM (
     SELECT
         p1.product_name AS product_a,
         p2.product_name AS product_b,
         COUNT(*) AS co_purchase_count
     FROM
         order_items s1
     INNER JOIN
         order_items s2 ON s1.order_id = s2.order_id AND s1.product_id <> s2.product_id
     INNER JOIN
         products p1 ON s1.product_id = p1.product_id
     INNER JOIN
         products p2 ON s2.product_id = p2.product_id
     GROUP BY
         p1.product_id, p2.product_id
    ) subquery
ORDER BY
    co_purchase_count DESC;
