-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_id,product_name,product_size,product_category_id, product_qty_type,
       CASE
         WHEN INSTR(product_name, '-') > 0 THEN
           -- Description exists (hyphen found)
           TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
         ELSE NULL
       END AS product_description
FROM product;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_id,
       product_name,
       product_size,
       product_category_id,
       product_qty_type,
       CASE
         WHEN INSTR(product_name, '-') > 0 THEN
           -- Description exists (hyphen found)
           TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
         ELSE NULL
       END AS product_description
FROM product
WHERE product_size REGEXP '[0-9]+';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

WITH TotalSales AS (
    SELECT 
        market_date,
        SUM(quantity * cost_to_customer_per_qty) AS total_sales
    FROM 
        customer_purchases
    GROUP BY 
        market_date
),
MaxSales AS (
    SELECT 
        market_date,
        total_sales
    FROM 
        TotalSales
    ORDER BY 
        total_sales DESC
    LIMIT 1
),
MinSales AS (
    SELECT 
        market_date,
        total_sales
    FROM 
        TotalSales
    ORDER BY 
        total_sales ASC
    LIMIT 1
)
SELECT 
    market_date,
    total_sales
FROM 
    MaxSales
UNION
SELECT 
    market_date,
    total_sales
FROM 
    MinSales;

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

WITH CustomerCount AS (
    SELECT COUNT(*) AS total_customers
    FROM customer
),
VendorProductSales AS (
    SELECT 
        vi.vendor_id,
        vi.product_id,
        v.vendor_name,
        p.product_name,
        vi.original_price,
        cc.total_customers * 5 AS total_units_sold
    FROM 
        vendor_inventory vi
    CROSS JOIN 
        CustomerCount cc
    JOIN 
        vendor v ON vi.vendor_id = v.vendor_id
    JOIN 
        product p ON vi.product_id = p.product_id
)
SELECT 
    vendor_name,
    product_name,
    SUM(total_units_sold * original_price) AS total_revenue
FROM 
    VendorProductSales
GROUP BY 
    vendor_name, 
    product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TABLE product_units (
  product_id int(11) NOT NULL,
  product_name varchar(45) DEFAULT NULL,
  product_size varchar(45) DEFAULT NULL,
  product_category_id int(11) NOT NULL,
  product_qty_type varchar(45) DEFAULT NULL,
  snapshot_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id, product_category_id),
  FOREIGN KEY (product_category_id) REFERENCES product_category (product_category_id)
);

INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
SELECT 
  product_id,
  product_name,
  product_size,
  product_category_id,
  product_qty_type,
  CURRENT_TIMESTAMP
FROM 
  product
WHERE 
  product_qty_type = 'unit';


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

-- This is the approach :
-- Insert the new product into the product table
INSERT INTO product (product_id, product_name, product_size, product_category_id, product_qty_type)
VALUES (24, 'Tomatillo - Organic', '1 pound', 1, 'unit');

--Now update the product_units table by inserting rows from the product table that are not already present in product_units

INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
SELECT 
    p.product_id, 
    p.product_name, 
    p.product_size, 
    p.product_category_id, 
    p.product_qty_type, 
    CURRENT_TIMESTAMP
FROM 
    product p
WHERE 
    p.product_qty_type = 'unit' 
    AND NOT EXISTS (
        SELECT 1
        FROM product_units pu
        WHERE pu.product_id = p.product_id 
          AND pu.product_category_id = p.product_category_id
    );

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_id IN (
  SELECT product_id
  FROM product_units
  ORDER BY snapshot_timestamp DESC
  LIMIT 1
);

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.


ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = (
SELECT current_quantity
FROM (
SELECT p.product_id, COALESCE(quantity,0) as current_quantity

	FROM product_units p
	LEFT JOIN (
		SELECT *
		,ROW_NUMBER() OVER( PARTITION BY vi.product_id ORDER BY market_date DESC) AS rn
		FROM vendor_inventory vi 
	) vi ON p.product_id  = vi.product_id

	WHERE rn = 1 
	OR rn IS NULL
) p
WHERE product_units.product_id = p.product_id);




