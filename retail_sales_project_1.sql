--SQL RETAIL SALES ANALYSIS 
--CREATE TABLE 
DROP TABLE IF EXISTS retail_sales
CREATE TABLE retail_sales(
		transactions_id INT PRIMARY KEY ,
		sale_date DATE,
		sale_time TIME , 	
		customer_id	INT ,
		gender VARCHAR(50),
		age	INT ,
		category VARCHAR(20),	
		quantity	INT,
		price_per_unit FLOAT,	
		cogs FLOAT,
		total_sale FLOAT
)


-- truncate the table first
TRUNCATE TABLE dbo.retail_sales;
GO 
-- import the file
BULK INSERT dbo.retail_sales
FROM "C:\Users\Admin\Desktop\project\sql projects\sql project 1\Retail Sales Analysis_utf.csv"
WITH
(
        FORMAT='CSV',
        FIRSTROW=2
)
GO
--DATA CLEANING 

--CHECKING OUT FIRST 1000 ROWS OF THE TABLE
SELECT TOP (1000) [transactions_id]
      ,[sale_date]
      ,[sale_time]
      ,[customer_id]
      ,[gender]
      ,[age]
      ,[category]
      ,[quantity]
      ,[price_per_unit]
      ,[cogs]
      ,[total_sale]
  FROM [Sql_project_p1 ].[dbo].[retail_sales]

  --SELECTING THE ROWS WITH NULL VALUES 
  SELECT * FROM dbo.retail_sales
  WHERE 
        quantity	IS NULL 
		OR 
		price_per_unit IS NULL	
		OR 
		cogs IS NULL	
		OR 
		total_sale IS NULL ;

-- DELETING THE RECORDS WITH NULL VALUES BECAUSE THE COUNT IS 3 ONLY 
DELETE FROM dbo.retail_sales 
WHERE transactions_id IN (679,746,1225);

--DATA EXPLORATION 
--Calculate Average Purchase Value in each year made by each customer .

WITH avg_purchase_value AS 
	(SELECT customer_id , YEAR(sale_date)AS year,  ROUND(AVG(total_sale),2) AS avg_purchase_value
	FROM [dbo].[retail_sales]
	GROUP BY customer_id, YEAR(sale_date)
	)
 SELECT * FROM avg_purchase_value pv
 ORDER BY pv.customer_id, pv.year;



 --Calculate the number of purchases made by each customer in each year 
 WITH purchase_frequency AS 
	(SELECT customer_id, YEAR(sale_date) AS year,  COUNT(customer_id) AS purchase_count
	 FROM retail_sales
	 GROUP BY YEAR(sale_date) , customer_id  
	 )

 SELECT pf.customer_id , pf.year , pf.purchase_count
 FROM purchase_frequency pf
 ORDER BY pf.customer_id ,pf.year; 

-- Calculate customer lifespan ie. the number of days between a customer's first and last purchase in each year .

WITH customer_lifespan_2022 AS
	(SELECT customer_id , DATEDIFF(DAY, MIN(sale_date), MAX(sale_date)) AS customer_lifespan_2022
	FROM retail_sales
	WHERE YEAR(sale_date)=2022 
	GROUP BY customer_id   ) ,
 customer_lifespan_2023 AS 
 (		SELECT customer_id , DATEDIFF(DAY, MIN(sale_date), MAX(sale_date)) AS customer_lifespan_2023
		FROM retail_sales
		WHERE YEAR(sale_date)=2023
		GROUP BY customer_id)

SELECT cl1.*, cl2.*
FROM customer_lifespan_2022 cl1
JOIN customer_lifespan_2023 cl2 ON cl1.customer_id = cl2.customer_id;


/*Calculate cltv (Customer Livetime Value : The net profit a customer is expected to bring during the entire customer relationship )
in each year  : CLTV = Average Purchase Value * Purchase Frequency * Customer Lifespan.
*/

 WITH avg_purchase_value AS 
	 (SELECT customer_id , YEAR(sale_date)AS year,ROUND(AVG(total_sale),2) AS avg_purchase_value , COUNT(customer_id) AS purchase_count
	 FROM [dbo].[retail_sales]
	 WHERE YEAR(sale_date) = 2022
	 GROUP BY customer_id ,YEAR(sale_date)
	 ),
  MonthlyLifespan AS (
		SELECT customer_id,
			   MONTH(sale_date) AS month,
			   DATEDIFF(DAY, MIN(sale_date), MAX(sale_date)) AS customer_lifespan
		FROM retail_sales
		WHERE YEAR(sale_date) = 2022
		GROUP BY customer_id, MONTH(sale_date)
	),
	customer_lifespan_2022 AS
			(SELECT mp.customer_id, SUM(mp.customer_lifespan) AS customer_lifespan_2022
				FROM MonthlyLifespan mp
				GROUP BY customer_id)

SELECT apv.customer_id, apv.avg_purchase_value ,apv.purchase_count , cl.customer_lifespan_2022 ,
(apv.avg_purchase_value *apv.purchase_count * cl.customer_lifespan_2022)AS clvt_2022
FROM avg_purchase_value apv
JOIN customer_lifespan_2022 cl ON apv.customer_id=cl.customer_id 
WHERE apv.year=2022 ; 


--Clvt2023
 
WITH avg_purchase_value AS (
		SELECT customer_id, YEAR(sale_date) AS year, ROUND(AVG(total_sale), 2) AS avg_purchase_value, COUNT(customer_id) AS purchase_count
		FROM retail_sales
		WHERE YEAR(sale_date) = 2023
		GROUP BY customer_id, YEAR(sale_date)
	),
		   MonthlyLifespan AS (
			SELECT customer_id,
				   MONTH(sale_date) AS month,
				   DATEDIFF(DAY, MIN(sale_date), MAX(sale_date)) AS customer_lifespan
			FROM retail_sales
			WHERE YEAR(sale_date) = 2023
			GROUP BY customer_id, MONTH(sale_date)
		),
		customer_lifespan_2023 AS
		(SELECT mp.customer_id, SUM(mp.customer_lifespan) AS customer_lifespan_2023
				FROM MonthlyLifespan mp
				GROUP BY customer_id)

SELECT apv.customer_id, apv.avg_purchase_value, apv.purchase_count, cl1.customer_lifespan_2023,
(apv.avg_purchase_value * apv.purchase_count * cl1.customer_lifespan_2023) AS clvt_2023
FROM avg_purchase_value apv
JOIN customer_lifespan_2023 cl1 ON apv.customer_id = cl1.customer_id
WHERE apv.year = 2023
;

--Top 10 customers with highest clvt in 2023 year

WITH avg_purchase_value AS (
		SELECT customer_id, YEAR(sale_date) AS year, ROUND(AVG(total_sale), 2) AS avg_purchase_value, COUNT(customer_id) AS purchase_count
		FROM retail_sales
		WHERE YEAR(sale_date) = 2023
		GROUP BY customer_id, YEAR(sale_date)
),
   MonthlyLifespan AS (
		SELECT customer_id,
		MONTH(sale_date) AS month,
		DATEDIFF(DAY, MIN(sale_date), MAX(sale_date)) AS customer_lifespan
		FROM retail_sales
		WHERE YEAR(sale_date) = 2023
		GROUP BY customer_id, MONTH(sale_date)
), 
customer_lifespan_2023 AS (
		SELECT mp.customer_id, SUM(mp.customer_lifespan) AS customer_lifespan_2023
		FROM MonthlyLifespan mp
		GROUP BY customer_id)

SELECT apv.customer_id,
(apv.avg_purchase_value * apv.purchase_count * cl1.customer_lifespan_2023) AS clvt_2023
FROM avg_purchase_value apv
JOIN customer_lifespan_2023 cl1 ON apv.customer_id = cl1.customer_id
WHERE apv.year = 2023
ORDER BY (apv.avg_purchase_value * apv.purchase_count * cl1.customer_lifespan_2023) DESC;


--Retrieve customers who made purchases in the multiple category

WITH CustomerCategoryPurchases AS (
    SELECT customer_id, category
    FROM dbo.retail_sales
    GROUP BY customer_id, category
    HAVING COUNT(*) > 2
)
SELECT customer_id
FROM CustomerCategoryPurchases
GROUP BY customer_id;

-- Count the days when the total sale revenue generated was more than 1000  

WITH year_22 AS 
			(SELECT  MONTH(x.sale_date) AS month , 
			count(x.per_day_revenue) AS revenue_2022
			FROM (
			SELECT  sale_date ,  SUM(total_sale) AS per_day_revenue 
			FROM retail_sales 
			WHERE YEAR(sale_date)=2022
			GROUP BY sale_date
			HAVING SUM(total_sale)>1000
			)x
			GROUP BY MONTH(x.sale_date)),

year_23 AS 
			(SELECT  MONTH(x.sale_date) AS month,
			count(x.per_day_revenue) AS revenue_2023
			FROM (
			SELECT  sale_date ,  SUM(total_sale) AS per_day_revenue 
			FROM retail_sales 
			WHERE YEAR(sale_date)=2023
			GROUP BY sale_date
			HAVING SUM(total_sale)>1000
			)x
			GROUP BY MONTH(x.sale_date))

SELECT cte1.revenue_2022 , cte2.revenue_2023
FROM year_22 cte1
JOIN year_23 cte2 ON cte1.month= cte2.month 
;

--Calculate the avg sales of each month for each year , find the top 3 months in which the sales are highest 
--2023
SELECT 
MONTH(sale_date) AS month ,
ROUND(AVG(x.per_day_revenue) ,4) AS avg_revenue
FROM ( SELECT  sale_date ,  SUM(total_sale)AS per_day_revenue 
		FROM retail_sales 
		WHERE YEAR(sale_date)=2023
		GROUP BY sale_date 
		 )x
GROUP BY MONTH(sale_date) 
ORDER BY avg_revenue DESC ;

--2022
SELECT 
MONTH(sale_date) AS month ,
ROUND(AVG(x.per_day_revenue) ,4) AS avg_revenue
FROM ( SELECT  sale_date ,  SUM(total_sale)AS per_day_revenue 
		FROM retail_sales 
		WHERE YEAR(sale_date)=2022
		GROUP BY sale_date 
			)x
GROUP BY MONTH(sale_date) 
ORDER BY avg_revenue DESC ;

---customers who made purchase in 2022 but didn't make a single purchase in 2023
SELECT customer_id 
FROM retail_sales
WHERE customer_id NOT IN (SELECT customer_id
FROM retail_sales
WHERE YEAR(sale_date)=2022);

--CUSTOMER LOYALTY ANALYSIS 

--identify the number of non_repeater customers 
 SELECT COUNT(customer_id) AS non_repeater 
 FROM retail_sales
 WHERE customer_id NOT IN (
 SELECT x.customer_id 
FROM (
SELECT customer_id, YEAR(sale_date) AS year,  COUNT(customer_id) AS purchase_count , 
ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY customer_id ) AS rn
 FROM retail_sales
 GROUP BY YEAR(sale_date) , customer_id  )x
 WHERE x.rn=2
 )

-- Identify the number of repeat customers
SELECT COUNT(DISTINCT x.customer_id)
FROM (
		SELECT customer_id, YEAR(sale_date) AS year,  COUNT(customer_id) AS purchase_count 
		FROM retail_sales
		GROUP BY YEAR(sale_date) , customer_id )x

--Identify high value repeat customers in 2022 
SELECT customer_id , YEAR(sale_date)AS year,ROUND(AVG(total_sale),2) AS avg_purchase_value , COUNT(customer_id) AS purchase_count
	 FROM [dbo].[retail_sales]
	 WHERE YEAR(sale_date) = 2022 
	 GROUP BY customer_id ,YEAR(sale_date)
	 HAVING COUNT(customer_id)>1 
	 ORDER BY avg_purchase_value DESC;

--Identify high value repeat customers in 2023
SELECT customer_id , YEAR(sale_date)AS year,ROUND(AVG(total_sale),2) AS avg_purchase_value , COUNT(customer_id) AS purchase_count
	 FROM [dbo].[retail_sales]
	 WHERE YEAR(sale_date) = 2023 
	 GROUP BY customer_id ,YEAR(sale_date)
	 HAVING COUNT(customer_id)>1 
	 ORDER BY avg_purchase_value DESC;

--SALES ANALYSIS : 
-- which category is selling more in which month . 
SELECT MONTH(sale_date) AS month , category , SUM(quantity) AS quantity_sold , SUM(total_sale) AS revenue
FROM retail_sales
WHERE YEAR(sale_date)=2022
GROUP BY  category , MONTH(sale_date)
ORDER BY MONTH(sale_date),SUM(quantity); 

-- Calculate total quantity purchased by each gender category and the total revenue generated by the quantity sold in the year 2022
SELECT category , gender ,COUNT(gender)AS gender_count, SUM(quantity)AS total_quantity , SUM(total_sale) AS revenue
FROM retail_sales
WHERE YEAR(sale_date)=2022
GROUP BY category , gender;

-- which category is selling more in which month (2023).
SELECT MONTH(sale_date) AS month , category , SUM(quantity) AS quantity_sold , SUM(total_sale) AS revenue
FROM retail_sales
WHERE YEAR(sale_date)=2023
GROUP BY  category , MONTH(sale_date)
ORDER BY MONTH(sale_date),SUM(quantity); 

-- Calculate total quantity purchased by each gender category and the total revenue generated by the quantity sold in the year 2023 
SELECT category , gender ,COUNT(gender)AS gender_count ,  SUM(quantity)AS total_quantity , SUM(total_sale) AS revenue
FROM retail_sales
WHERE YEAR(sale_date)=2023
GROUP BY category , gender;


--which category sales the most units
SELECT category , YEAR(sale_date) , SUM(quantity) AS total_units , SUM(total_sale)
, ROW_NUMBER()OVER(PARTITION BY category ORDER BY YEAR(sale_date))rn
FROM retail_sales
GROUP BY category , YEAR(sale_date)
; 

-- Avg purchase frequency during different hrs of a day in a month 

SELECT  x.month , x.sale_hour , AVG(x.purchase_frequency) AS avg_purchase_frequency 
FROM (SELECT MONTH(sale_date) month , DATEPART(hour, sale_time) AS sale_hour, COUNT(*) AS purchase_frequency
FROM retail_sales
WHERE YEAR(sale_date)=2022
GROUP BY DATEPART(hour, sale_time) , MONTH(sale_date)
)x
GROUP BY x.month , x.sale_hour ;

--Added a new column profit in the table 
ALTER TABLE retail_sales
ADD net_profit AS quantity*(price_per_unit-cogs) PERSISTED;

--Calculate the profit made on each category  
SELECT category , SUM(net_profit) AS categorical_profit 
FROM retail_sales
GROUP BY category ;

--Customers who generated the most profit in the year 2022 
SELECT customer_id , SUM(net_profit) AS categorical_profit 
FROM retail_sales
WHERE YEAR(sale_date) = 2022
GROUP BY customer_id
ORDER BY SUM(net_profit) DESC ;

--Customers who generated the most profit in the year 2023
SELECT customer_id , SUM(net_profit) AS categorical_profit 
FROM retail_sales
WHERE YEAR(sale_date) = 2023
GROUP BY customer_id
ORDER BY SUM(net_profit) DESC ;



















