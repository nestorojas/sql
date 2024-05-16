-- AGGREGATE
/* 1. Write a query that determines how many times each vendor has rented a booth 
at the farmer’s market by counting the vendor booth assignments per vendor_id. */

SELECT v.vendor_id,v.vendor_name, COUNT(vba.vendor_id) AS num_booth_rentals
FROM vendor v
INNER JOIN vendor_booth_assignments vba ON v.vendor_id = vba.vendor_id
GROUP BY v.vendor_id, v.vendor_name
ORDER BY num_booth_rentals DESC;

/* 2. The Farmer’s Market Customer Appreciation Committee wants to give a bumper 
sticker to everyone who has ever spent more than $2000 at the market. Write a query that generates a list 
of customers for them to give stickers to, sorted by last name, then first name. 

HINT: This query requires you to join two tables, use an aggregate function, and use the HAVING keyword. */
SELECT c.customer_zip,c.customer_last_name, c.customer_first_name,
  CAST(SUM(cp.cost_to_customer_per_qty * cp.quantity) AS INTEGER) AS amount_spent
FROM customer c
INNER JOIN customer_purchases cp ON c.customer_id = cp.customer_id
GROUP BY c.customer_id, c.customer_last_name, c.customer_first_name, c.customer_zip
HAVING SUM(cp.cost_to_customer_per_qty * cp.quantity) >= 2000
ORDER BY amount_spent;


--Temp Table
/* 1. Insert the original vendor table into a temp.new_vendor and then add a 10th vendor: 
Thomass Superfood Store, a Fresh Focused store, owned by Thomas Rosenthal

HINT: This is two total queries -- first create the table from the original, then insert the new 10th vendor. 
When inserting the new vendor, you need to appropriately align the columns to be inserted 
(there are five columns to be inserted, I've given you the details, but not the syntax) 

-> To insert the new row use VALUES, specifying the value you want for each column:
VALUES(col1,col2,col3,col4,col5) 
*/
--create the table from the original
CREATE TEMPORARY TABLE temp.new_vendor (
    vendor_id INTEGER PRIMARY KEY,
    vendor_name varchar(45) NOT NULL,
    vendor_type varchar(45) NOT NULL,
    vendor_owner_first_name varchar(45) NOT NULL,
    vendor_owner_last_name varchar(45) NOT NULL,
    UNIQUE (vendor_id),
    UNIQUE (vendor_name)
  );

 -- Insert data from the original vendor table
INSERT INTO temp.new_vendor (vendor_name, vendor_type, vendor_owner_first_name, vendor_owner_last_name)
SELECT vendor_name, vendor_type, vendor_owner_first_name, vendor_owner_last_name
FROM vendor;
 
 -- Insert the new 10th vendor 

INSERT INTO temp.new_vendor (vendor_name, vendor_type, vendor_owner_first_name, vendor_owner_last_name)
VALUES ('Thomass Superfood Store', 'Fresh Focused', 'Thomas', 'Rosenthal');
SELECT vendor_id, vendor_name, vendor_type, vendor_owner_first_name, vendor_owner_last_name
FROM temp.new_vendor;


-- Date
/*1. Get the customer_id, month, and year (in separate columns) of every purchase in the customer_purchases table.

HINT: you might need to search for strfrtime modifers sqlite on the web to know what the modifers for month 
and year are! */

SELECT c.customer_id,
       STRFTIME('%m', cp.market_date) AS purchase_month,
       STRFTIME('%Y', cp.market_date) AS purchase_year
FROM customer_purchases cp
INNER JOIN customer c ON cp.customer_id = c.customer_id;

/* 2. Using the previous query as a base, determine how much money each customer spent in April 2019. 
Remember that money spent is quantity*cost_to_customer_per_qty. 

HINTS: you will need to AGGREGATE, GROUP BY, and filter...
but remember, STRFTIME returns a STRING for your WHERE statement!! */

SELECT c.customer_id,
       SUM(cp.quantity * cp.cost_to_customer_per_qty) AS total_spent
FROM customer_purchases cp
INNER JOIN customer c ON cp.customer_id = c.customer_id
WHERE STRFTIME('%m', cp.market_date) = '04'  -- Filter for April
  AND STRFTIME('%Y', cp.market_date) = '2019'  -- Filter for 2019
GROUP BY c.customer_id;
