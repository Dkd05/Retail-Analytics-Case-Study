use coding_ninja;

set autocommit=0;
set sql_safe_updates=0;
-- -----------------------------------------------------------------------   EDA   -----------------------------------------------------------------------------------------------------

SELECT * FROM customer_profiles LIMIT 100;
SELECT * FROM product_inventory LIMIT 100;
SELECT * FROM sales_transaction LIMIT 100;

DESC customer_profiles;
DESC product_inventory;
DESC sales_transaction;

SELECT COUNT(*) FROM customer_profiles;       -- 1000
SELECT COUNT(*) FROM product_inventory;		  -- 200
SELECT COUNT(*) FROM sales_transaction;		  -- 5002

ALTER TABLE customer_profiles
RENAME 	COLUMN ï»¿CustomerID TO CustomerID;

ALTER TABLE product_inventory
RENAME 	COLUMN ï»¿ProductID TO ProductID;

-- ----------------------------------------------------------------------    DATA CLEANING   -----------------------------------------------------------------------------------------

-- 1. Write a query to identify the number of duplicates in "sales_transaction" table. Also, create a separate table containing the unique values and remove the the original
-- table from the databases and replace the name of the new table with the original name.


SELECT DISTINCT  Tid, COUNT(*) FROM sales_transaction
GROUP BY 1
HAVING COUNT(*)>1;			-- Two duplicates are found

CREATE TABLE ABC AS (
SELECT DISTINCT * FROM sales_transaction);

DROP TABLE sales_transaction;

ALTER TABLE ABC
RENAME TO sales_transaction;



                
         
-- 2. Write a query to identify the discrepancies in the price of the same product in "sales_transaction" and "product_inventory" tables. Also, update those discrepancies to 
-- match the price in both the tables.

SELECT st.Tid, st.price, pi.price
FROM sales_transaction st
JOIN
product_inventory pi
ON (st.ProductID=pi.ProductID)
WHERE ST.PRICE<>PI.PRICE;

UPDATE sales_transaction st
SET st.PRICE= (SELECT pi.price from product_inventory pi WHERE st.productID=pi.productID)
WHERE st.productID IN(SELECT productID from product_inventory  WHERE st.price<>product_inventory.price);


-- 3. Write a SQL query to identify the null values in the dataset and replace those by “Unknown”.

SELECT * FROM customer_profiles
WHERE CustomerID IS NULL or
		Age IS NULL OR
        Gender IS NULL or
        Location IS NULL OR
        JoinDate IS NULL;                        -- NO NULL VALUES FOUND

        
SELECT * FROM product_inventory
WHERE ProductID IS NULL or
		ProductName IS NULL OR
        Category IS NULL or
        StockLevel IS NULL OR
        Price IS NULL;   						-- NO NULL VALUE FOUND
        
        
SELECT * FROM sales_transaction
WHERE Tid IS NULL or
		CustomerID IS NULL OR
        ProductID IS NULL or
         QuantityPurchased IS NULL OR
        TransactionDate IS NULL OR
        Price  IS NULL;   						-- NO NULL VALUES FOUND



-- 4. Write a SQL query to clean the DATE column in the dataset.

DESC customer_profiles;                          -- Join Date stored as 'Text'
DESC sales_transaction;							 -- TransactionDate stored as Text

ALTER TABLE customer_profiles
MODIFY COLUMN JoinDate date;

ALTER TABLE sales_transaction
MODIFY COLUMN TransactionDate date;



-- 5. Write a SQL query to summarize the total sales and quantities sold per product by the company.

SELECT  st.productID, pi.ProductName, 
		ROUND(SUM(st.QuantityPurchased * st.Price),2) Total_Sale,
        SUM(st.QuantityPurchased) Qty_Sold
FROM sales_transaction st
JOIN
product_inventory pi 
on(st.productID=pi.productID)
GROUP BY 1,2
ORDER BY 3 DESC;


-- 6. Write a SQL query to count the number of transactions per customer to understand purchase frequency.


SELECT CustomerID, count(*) NumberOfTransactions
FROM sales_transaction
GROUP BY 1
ORDER BY 2 DESC;


-- 7. Write a SQL query to evaluate the performance of the product categories based on the total sales which 
-- help us understand the product categories which needs to be promoted in the marketing campaigns.

SELECT pi.Category,
	SUM(st.QuantityPurchased) QtySold,
    ROUND(SUM(st.QuantityPurchased*st.price),2) TotalSales
FROM sales_transaction st
JOIN product_inventory pi
ON(st.productID=pi.productID)
GROUP BY 1
ORDER BY 3 DESC;



-- 8. Write a SQL query to find the top 10 products with the highest total sales revenue 

SELECT ProductID, 
	ROUND(SUM(QuantityPurchased*price),2) TotalSales
FROM sales_transaction
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;



-- 9. Write a SQL query to find the ten products with the least amount of units sold,provided that at least one unit was sold for those products.

SELECT ProductID,
	SUM(QuantityPurchased) QtySold
FROM sales_transaction
GROUP BY 1
HAVING 2>1
ORDER BY 2
LIMIT 10;


-- 10. Write a SQL query to identify the sales trend to understand the revenue pattern of the company.

SELECT TransactionDate,
	COUNT(Tid) Transction_count,
    SUM(QuantityPurchased) QtySold,
    ROUND(SUM(QuantityPurchased*Price),2) TotalRevenue
FROM sales_transaction
GROUP BY 1
ORDER BY 1 DESC;



-- 11. Write a SQL query to understand the month on month growth rate of sales of the company which will help understand the growth trend of the company.

WITH CTE AS(
			SELECT date_format(TransactionDate,'%Y-%m') Month,
            ROUND(SUM(QuantityPurchased*Price),2) TotalSales
            FROM sales_transaction
            GROUP BY 1)

SELECT Month, 
		TotalSales,
		LAG(TotalSales,1,'No previous record') OVER (ORDER BY Month) previous_month_sale,
		ROUND(((TotalSales-LAG(TotalSales,1,'No previous record') OVER (ORDER BY Month))/
		LAG(TotalSales,1,'No previous record') OVER (ORDER BY Month)*100),2) mom_growth
FROM CTE;



-- 12. Write a SQL query that describes the number of transaction along with the total amount spent by each customer which are on the higher side and will 
-- help us understand the customers who are the high frequency purchase customers in the company. The resulting table must have number of transactions more 
-- than 10 and TotalSpent more than 1000 on those transactions by the corresponding customers.Return the result table on the “TotalSpent” in descending order.

SELECT CustomerID, 
		COUNT(Tid) No_of_transac,
        ROUND(SUM(QuantityPurchased*Price),2) Total_Amt
FROM sales_transaction
GROUP BY 1
HAVING No_of_transac>10 AND Total_Amt>1000
ORDER BY Total_Amt desc;



-- 13. Write a SQL query that describes the number of transaction along with the total amount spent by each customer. The resulting table must have number 
-- of transactions less than or equal to 2.Return the result table of “NumberOfTransactions” in ascending order and “TotalSpent” in descending order

SELECT CustomerID, 
		COUNT(Tid) NumberOfTransactions,
        SUM(QuantityPurchased*Price) Total_Amt
FROM sales_transaction
GROUP BY 1
HAVING NumberOfTransactions<= 2
ORDER BY NumberOfTransactions, Total_Amt DESC;



-- 14. Write a SQL query that describes the total number of purchases made by each customer against each productID to understand the repeat customers in the company.

SELECT CustomerID, ProductID,
		COUNT(*) No_of_Purchase
from sales_transaction
GROUP BY 1,2
HAVING No_of_Purchase>1
ORDER BY No_of_Purchase DESC;



-- 15. Write a SQL query that describes the duration between the first and the last purchase of the customer in that particular company to understand the loyalty of the customer.


SELECT CustomerID,
			MIN(TransactionDate) First_Purchase,
            MAX(TransactionDate) Last_Purchase,
            DATEDIFF(MAX(TransactionDate),MIN(TransactionDate)) DaysBetweenPurchases
FROM sales_transaction
GROUP BY 1
HAVING DaysBetweenPurchases >1
ORDER BY DaysBetweenPurchases DESC;



-- 16. Write a SQL query that segments customers based on the total quantity of products they have purchased. Also, count the number of customers in each segment 
-- Segement 'Low'= 1-10 qty purchased, 'Mid'= 10-30 qty purchased, 'High'= >30 qty purchased.


WITH CTE AS (
			SELECT CustomerID,
					SUM(QuantityPurchased) Qty_purchased
                    FROM sales_transaction
                    GROUP BY 1),
CTE2 AS (
            SELECT *,
            CASE WHEN Qty_purchased BETWEEN 1 AND 10 THEN "LOW"
				WHEN Qty_purchased BETWEEN 10 AND 30 THEN "MID"
				WHEN Qty_purchased >30 THEN "HIGH" 
                ELSE 'NONE' END Customer_Seg
			FROM CTE)
                
SELECT Customer_Seg,
		COUNT(Customer_Seg)
FROM CTE2
GROUP BY 1;


-- --------------------------------------------------------------------   END    -----------------------------------------------------------------------------------------------
                    










