/*
1. 	The objective of this SQL project is to present a report (newsletter style) of some BASIC Exploratory Data Analysis (EDA)
	of a fictional Telecommunications Company.
2.	The datasets was taken from Data playground of Maven Analytics  (LINK).
3.	The SQL codes used in this project are to be run in SQL-server.
4.	The server is hosted on a localhost and a database named "TelecomCustomerChurn" is created using SSMS GUI.
5.	The two csv files are imported into this database as tables and created two corresponding tables named:
	 "telecom_customer_churn" and "telecom_zipcode_population.“
6.	Also, the names of Counties are extracted from web (LINK) which corresponds to given relevant zip-codes
	in one of the data sets as follows:
		Get data > From Other Sources> From Web 
7.	For better understanding of the outputs, they are visualized in Power BI
	by extracting the outputs as follows:
		Get data > SQL Server > import (Advanced Options:SQL Statements) > OK 
8.	Finally the codes and their respective visuals are organized in powerpoint and then, saved as pdf file.
9.	Feedbacks and suggestions are always appreciated. THANK YOU.
*/


-- Select the database on which our queries are to be run/executed
USE TelecomCustomerChurn;


-- Display the top 5 records of table
SELECT TOP 5 *
FROM dbo.telecom_customer_churn
;


-- Check the number of total records
SELECT COUNT(*) 
FROM dbo.telecom_customer_churn
;
-- Output : 7043


-- Check if there is(are) a duplicate customer(s)
SELECT COUNT(DISTINCT Customer_ID)
FROM dbo.telecom_customer_churn
;
-- Output: 7043    (no duplicates)


-- What are the distinct initial customer status
SELECT DISTINCT Customer_Status
FROM dbo.telecom_customer_churn
;


-- list the customer status of all old customers and new customers
-- Old Customer -> whose tenure in months is <= 3 (who started subscription in latest quarter - Q2)
-- New Customer -> whose tenure in months is > 3 (who started subscription before latest quarter - Q2)
SELECT
	Customer_ID,Customer_Status
	,CASE
		WHEN Tenure_in_Months <= 3 THEN 'New Customer'
		WHEN Tenure_in_Months > 3 THEN 'Old Customer'
	END AS new_or_old_cust
FROM dbo.telecom_customer_churn
;


-- Count the customer with status further categorised by both status and 'Old Customer'/'New Customer'
-- New Customer -> whose tenure in months is <= 3 (who started subscription in latest quarter - Q2)
-- Old Customer -> whose tenure in months is > 3 (who started subscription before latest quarter - Q2)
WITH category AS (
	SELECT
	Customer_ID,Customer_Status
	,CASE
		WHEN Tenure_in_Months <= 3 THEN 'New Customer'
		WHEN Tenure_in_Months > 3 THEN 'Old Customer'
	END AS new_or_old_cust
	,CASE 
		WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'Churned New Customer'
		WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'Stayed New Customer'
		WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'Churned Old Customer'
		WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'Stayed Old Customer'
	END AS customer_status_final
FROM dbo.telecom_customer_churn
)
SELECT 
	Customer_Status,new_or_old_cust,customer_status_final
	,COUNT(Customer_ID) AS num_cust
FROM category
GROUP BY 
	Customer_Status,new_or_old_cust,customer_status_final
;


-- The percentage distribution of stayed and churned NEW customers 
SELECT
	ROUND(
		100.0 * COUNT(CASE WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN Tenure_in_Months <= 3 THEN 1 ELSE NULL END)
	,0) AS stayed_NEW_to_all_new_percent
	,ROUND(
		100.0 * COUNT(CASE WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN Tenure_in_Months <= 3 THEN 1 ELSE NULL END) 
	,0) AS churned_NEW_to_all_new_percent
FROM  dbo.telecom_customer_churn
;



-- The percentage distribution of stayed and churned OLD customers 
SELECT
	ROUND(
		100.0 * COUNT(CASE WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN Tenure_in_Months > 3 THEN 1 ELSE NULL END)
	,0) AS stayed_OLD_to_all_new_percent
	,ROUND(
		100.0 * COUNT(CASE WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN Tenure_in_Months > 3 THEN 1 ELSE NULL END) 
	,0) AS churned_OLD_to_all_new_percent
FROM  dbo.telecom_customer_churn
;


-- Find the Churn-rate of the latest quarter Q2 end
SELECT 
	ROUND(
		100.0*COUNT(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE NULL END)
		/COUNT(*)
	,2) AS churn_rate_Q2
FROM 
	dbo.telecom_customer_churn
;


-- Distribution by GENDER amongst the Stayed-OLD-Customers (initially given status = Stayed)
WITH ctetable AS (
	SELECT Gender,COUNT(Gender) AS num_customer
	FROM dbo.telecom_customer_churn
	WHERE Customer_Status = 'Stayed' AND Tenure_in_Months > 3
	GROUP BY Gender
)
SELECT *, SUM(num_customer) OVER() AS total_customer_OLD_stayed
	,ROUND(
		100.0*num_customer/SUM(num_customer) OVER()
	,1) AS percent_gender_OLD_stayed
FROM ctetable
;


-- Distribution by GENDER amongst the Churned-OLD-Customers
-- (initially given status = Churned; and Tenure_in_Months > 3)
WITH ctetable2 AS (
	SELECT Gender,COUNT(Gender) AS num_customer
	FROM dbo.telecom_customer_churn
	WHERE Customer_Status = 'Churned' AND Tenure_in_Months > 3
	GROUP BY Gender
)
SELECT *, SUM(num_customer) OVER() AS total_OLD_customer_churned
	,ROUND(
		100.0*num_customer/SUM(num_customer) OVER()
	,1) AS percent_gender_OLD_churned
FROM ctetable2
;


-- Distribution by GENDER amongst the Churned-NEW-Customers
-- (initially given status = Churned; and Tenure_in_Months <=3)
WITH ctetable1 AS (
	SELECT Gender,COUNT(Gender) AS num_customer
	FROM dbo.telecom_customer_churn
	WHERE Customer_Status = 'Churned' AND Tenure_in_Months <= 3
	GROUP BY Gender
)
SELECT *, SUM(num_customer) OVER() AS total_NEW_customer_churned
	,ROUND(
		100.0*num_customer/SUM(num_customer) OVER()
	,1) AS percent_gender_NEW_churned
FROM ctetable1
;


-- Distribution by GENDER amongst the Stayed-NEW-Customers (initially given status = Joined)
WITH ctetable AS (
	SELECT Gender,COUNT(Gender) AS num_customer
	FROM dbo.telecom_customer_churn
	WHERE Customer_Status = 'Joined' AND Tenure_in_Months <= 3
	GROUP BY Gender
)
SELECT *, SUM(num_customer) OVER() AS total_customer_joined_or_NEW_stayed
	,ROUND(
		100.0*num_customer/SUM(num_customer) OVER()
	,1) AS percent_gender_joined_or_NEW_stayed
FROM ctetable
;


-- Churn-distribution based on Age-Group (PART - 1)
WITH ctetable AS (
	SELECT
		Customer_ID
		,CASE 
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'Stayed OLD Customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'Churned OLD Customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'Churned NEW Customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'Stayed NEW Customer'
		END AS final_customer_status
		,CASE 
			WHEN Age BETWEEN 10 AND 25 THEN '5.Gen-Z'
			WHEN Age BETWEEN 26 AND 41 THEN '4.Millennials'
			WHEN Age BETWEEN 42 AND 57 THEN '3.Gen-X'
			WHEN Age BETWEEN 58 AND 76 THEN '2.Boomers'
			WHEN Age BETWEEN 77 AND 94 THEN '1.Silent'
		END AS generations
	FROM dbo.telecom_customer_churn
)
SELECT 
	generations, COUNT(Customer_ID) AS customer_count
	,COUNT(CASE WHEN final_customer_status = 'Stayed OLD Customer' THEN 1 ELSE NULL END) AS stayed_OLD_customer_count
	,COUNT(CASE WHEN final_customer_status = 'Churned OLD Customer' THEN 1 ELSE NULL END) churned_OLD_customer_count
	,COUNT(CASE WHEN final_customer_status = 'Churned NEW Customer' THEN 1 ELSE NULL END) AS churned_NEW_customer_count
	,COUNT(CASE WHEN final_customer_status = 'Stayed NEW Customer' THEN 1 ELSE NULL END) AS stayed_NEW_customer_count
FROM ctetable
GROUP BY generations
ORDER BY generations
;


-- Churn-distribution based on Age-Group (PART - 2)
WITH ctetable AS (
	SELECT
		Customer_ID,Customer_Status
		,CASE 
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'Stayed OLD Customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'Churned OLD Customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'Churned NEW Customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'Stayed NEW Customer'
		END AS final_customer_status
		,CASE 
			WHEN Age BETWEEN 10 AND 25 THEN '5.Gen-Z'
			WHEN Age BETWEEN 26 AND 41 THEN '4.Millennials'
			WHEN Age BETWEEN 42 AND 57 THEN '3.Gen-X'
			WHEN Age BETWEEN 58 AND 76 THEN '2.Boomers'
			WHEN Age BETWEEN 77 AND 94 THEN '1.Silent'
		END AS generations
	FROM dbo.telecom_customer_churn
)
SELECT 
	generations, COUNT(Customer_ID) AS total_customer_count
	,COUNT(CASE WHEN Customer_Status = 'Stayed' OR Customer_Status = 'Joined' THEN 1 ELSE NULL END) AS total_stayed_customer
	,COUNT(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE NULL END) AS total_churned_customer
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'Stayed OLD Customer' THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN final_customer_status = 'Stayed OLD Customer' OR final_customer_status = 'Churned OLD Customer' THEN 1 ELSE NULL END)
	,0) AS stayed_OLD_percent 
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'Churned OLD Customer' THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN final_customer_status = 'Stayed OLD Customer' OR final_customer_status = 'Churned OLD Customer' THEN 1 ELSE NULL END)
	,0) AS churned_OLD_percent 
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'Stayed NEW Customer' THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN final_customer_status = 'Stayed NEW Customer' OR final_customer_status = 'Churned NEW Customer' THEN 1 ELSE NULL END)
	,0) AS stayed_NEW_percent 
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'Churned NEW Customer' THEN 1 ELSE NULL END)
		/COUNT(CASE WHEN final_customer_status = 'Stayed NEW Customer' OR final_customer_status = 'Churned NEW Customer' THEN 1 ELSE NULL END)
	,0) AS churned_NEW_percent 
FROM ctetable
GROUP BY generations
ORDER BY generations
;


-- Churn-analysis based on marital status
WITH ctetable AS (
	SELECT 
		Customer_ID, Gender, Married,Number_of_Dependents,Tenure_in_Months,Customer_Status
		,CASE
			WHEN Tenure_in_Months > 3 AND Customer_Status = 'Stayed' THEN 'Stayed OLD Customer'
			WHEN Tenure_in_Months > 3 AND Customer_Status = 'Churned' THEN 'Churned OLD Customer'
			WHEN Tenure_in_Months <= 3 AND Customer_Status = 'Joined' THEN 'Stayed NEW Customer'
			WHEN Tenure_in_Months <= 3 AND Customer_Status = 'Churned' THEN 'Churned NEW Customer'
		END AS final_customer_status
	FROM dbo.telecom_customer_churn
)
SELECT Customer_Status, final_customer_status
	,SUM(CASE WHEN Married = 1 THEN 1 ELSE NULL END) AS married
	,SUM(CASE WHEN Married = 0 THEN 1 ELSE NULL END) AS unmarried
	,ROUND(100.0 * SUM(CASE WHEN Married = 1 THEN 1 ELSE NULL END)/COUNT(Customer_ID)
		,0) AS married_percent
	,ROUND(100.0 * SUM(CASE WHEN Married = 0 THEN 1 ELSE NULL END)/COUNT(Customer_ID)
		,0) AS unmarried_percent
FROM ctetable
GROUP BY Customer_Status, final_customer_status
;


-- Churn rate analysis based on referrals made or not
-- overall
SELECT  
	COUNT(CASE WHEN Number_of_Referrals <> 0 THEN Customer_ID ELSE NULL END) AS customers_who_made_referrals,
	COUNT(Customer_ID) AS total_customers
	,100.0*COUNT(CASE WHEN Number_of_Referrals <> 0 THEN Customer_ID ELSE NULL END)
		/COUNT(Customer_ID) AS percent_customers_who_made_referrals
FROM dbo.telecom_customer_churn
;

-- category wise
WITH ctetable AS (
	SELECT 
		CASE 
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed OLD customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned OLD customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned NEW customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed NEW customer'
			ELSE NULL 
		END AS final_customer_status,
		CASE 
			WHEN Number_of_Referrals = 0 THEN NULL ELSE Number_of_Referrals
		END AS referrals
	FROM dbo.telecom_customer_churn
)
SELECT 
	final_customer_status, COUNT(referrals) AS customer_who_made_referrals
	,COUNT(final_customer_status) AS total_customers
	,ROUND(100.0*COUNT(referrals)/COUNT(final_customer_status)
		,2) AS percent_customers_who_made_referrals
FROM ctetable
GROUP BY final_customer_status
;













-- Start point of churn analysis based on phone-services
-- Customers who subscribed to phone services
WITH ctetable AS (
	SELECT	Phone_Service,COUNT(DISTINCT Customer_ID) AS num_customer
		,SUM(COUNT(DISTINCT Customer_ID)) OVER() AS total_customer
	FROM dbo.telecom_customer_churn
	GROUP BY Phone_Service
)
SELECT
	Phone_Service,num_customer,total_customer
	,ROUND(100.0*num_customer/total_customer,1) AS PERCENT_
FROM ctetable
;

-- Percentage of multiple line phone services subscriptions
DROP TABLE IF EXISTS #phone_service_table; -- drop if exists a temporary table
WITH ctetable AS 
	(SELECT  Customer_ID,Customer_Status
		,CASE
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed OLD customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned OLD customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned NEW customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed NEW customer'
			ELSE NULL
		END AS final_customer_status,Phone_Service,Avg_Monthly_Long_Distance_Charges,Multiple_Lines
	FROM dbo.telecom_customer_churn
	WHERE Phone_Service <> 'No')
SELECT 
	ctetable.final_customer_status,Multiple_Lines,COUNT(Customer_ID) AS num_customer_phone_service_yes
INTO #phone_service_table			-- create temporary table
FROM ctetable
GROUP BY final_customer_status,Multiple_Lines
ORDER BY final_customer_status,Multiple_Lines
;

SELECT *			-- final query for getting the desired result from the temporary table
	,ROUND(100.0*num_customer_phone_service_yes
		/SUM(num_customer_phone_service_yes) OVER(PARTITION BY final_customer_status)
	,1) as percent_multiple_lines_within_status
FROM #phone_service_table;
												-- End point of churn analysis based on phone-services



-- analysis of Avg_Monthly_Long_Distance_Charges based on final status
WITH ctetable AS 
	(SELECT  Customer_ID,Customer_Status
		,CASE
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed OLD customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned OLD customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned NEW customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed NEW customer'
			ELSE NULL
		END AS final_customer_status,Phone_Service,Avg_Monthly_Long_Distance_Charges,Multiple_Lines
	FROM dbo.telecom_customer_churn
	WHERE Phone_Service <> 'No')
SELECT 
	ctetable.final_customer_status, ROUND(AVG(Avg_Monthly_Long_Distance_Charges),2) avg_
	,ROUND(SQRT(VAR(Avg_Monthly_Long_Distance_Charges)),2) std_, ROUND(MAX(Avg_Monthly_Long_Distance_Charges),2) max_
	,ROUND(MIN(Avg_Monthly_Long_Distance_Charges),2) min_
FROM ctetable
GROUP BY final_customer_status

UNION ALL

-- overall Avg_Monthly_Long_Distance_Charges  
SELECT 
	'All (Overall)' AS final_customer_status,ROUND(AVG(Avg_Monthly_Long_Distance_Charges),2) avg_
	,ROUND(SQRT(VAR(Avg_Monthly_Long_Distance_Charges)),2) std_, ROUND(MAX(Avg_Monthly_Long_Distance_Charges),2) max_
	,ROUND(MIN(Avg_Monthly_Long_Distance_Charges),2) min_
FROM dbo.telecom_customer_churn
;



-- Internet Services subscriptions
SELECT	Internet_Service,COUNT(Customer_ID) AS num_customer,SUM(COUNT(Customer_ID)) over() AS total_customer
		,ROUND(100.0*COUNT(Customer_ID)/SUM(COUNT(Customer_ID)) OVER(),0) AS percent_
FROM dbo.telecom_customer_churn
GROUP BY Internet_Service
;

-- churn-rate analysis based on Internet Type 
WITH ctetable AS (
	SELECT
		Customer_ID,Internet_Service,Internet_Type
		,CASE 
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed_OLD_customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned_OLD_customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned_NEW_customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed_NEW_customer'
		ELSE NULL END AS final_customer_status
	FROM dbo.telecom_customer_churn
)
SELECT Internet_Type, COUNT(Customer_ID) num_customer
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'stayed_OLD_customer' THEN 1 ELSE NULL END)
		/SUM(COUNT(CASE WHEN final_customer_status = 'stayed_OLD_customer' THEN 1 ELSE NULL END)) OVER(),0 )AS stayed_OLD_percent
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'churned_OLD_customer' THEN 1 ELSE NULL END) 
		/SUM(COUNT(CASE WHEN final_customer_status = 'churned_OLD_customer' THEN 1 ELSE NULL END)) OVER(),0) AS churned_OLD_percent
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'churned_NEW_customer' THEN 1 ELSE NULL END) 
		/SUM(COUNT(CASE WHEN final_customer_status = 'churned_NEW_customer' THEN 1 ELSE NULL END)) OVER(),0) AS churned_NEW_percent
	,ROUND(100.0*COUNT(CASE WHEN final_customer_status = 'stayed_NEW_customer' THEN 1 ELSE NULL END) 
		/SUM(COUNT(CASE WHEN final_customer_status = 'stayed_NEW_customer' THEN 1 ELSE NULL END)) OVER(),0) AS stayed_NEW_percent
FROM ctetable
WHERE Internet_Service = 'Yes'
GROUP BY Internet_Type
;


-- analysis of Avg_Monthly_GB_Download based on final status
WITH ctetable AS (
SELECT
	Customer_ID,Avg_Monthly_GB_Download
	,CASE
		WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed_OLD_customer'
		WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned_OLD_customer'
		WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned_NEW_customer'
		WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed_NEW_customer'
	ELSE NULL END AS final_customer_status
FROM dbo.telecom_customer_churn
WHERE Internet_Service = 'Yes'
)
SELECT	
	final_customer_status,MAX(Avg_Monthly_GB_Download) max_,MIN(Avg_Monthly_GB_Download) min_
	,AVG(Avg_Monthly_GB_Download) avg_,ROUND(SQRT(VAR(Avg_Monthly_GB_Download)),2) AS std_
FROM ctetable
GROUP BY final_customer_status

UNION ALL
-- overall Avg_Monthly_GB_Download 
SELECT	
	'All (Overall)' AS final_customer_status,MAX(Avg_Monthly_GB_Download) max_,MIN(Avg_Monthly_GB_Download) min_
	,AVG(Avg_Monthly_GB_Download) avg_, ROUND(SQRT(VAR(Avg_Monthly_GB_Download)),2) AS std_	
FROM dbo.telecom_customer_churn
;


-- analysis of additional subscriptions
WITH ctetable AS (
	SELECT
		Customer_ID,Online_Security,Online_Backup,Device_Protection_Plan,Premium_Tech_Support
		,Streaming_Movies,Streaming_Music,Streaming_TV,Unlimited_Data
		,CASE
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed_OLD_customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned_OLD_customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned_NEW_customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed_NEW_customer'
		ELSE NULL END AS final_customer_status
	FROM dbo.telecom_customer_churn
	WHERE Internet_Service = 'Yes'
)
SELECT final_customer_status
	, ROUND(100.0*COUNT(CASE WHEN Online_Security = 'Yes' THEN 1 ELSE NULL END)/COUNT(*),0) security_yes
	, ROUND(100.0*COUNT(CASE WHEN Online_Security = 'No' THEN 1 ELSE NULL END)/COUNT(*),0) security_no
	, ROUND(100.0*COUNT(CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE NULL END)/COUNT(*),0) backup_yes
	, ROUND(100.0*COUNT(CASE WHEN Online_Backup = 'No' THEN 1 ELSE NULL END)/COUNT(*),0) backup_no
	, ROUND(100.0*COUNT(CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE NULL END)/COUNT(*),0) protection_yes
	, ROUND(100.0*COUNT(CASE WHEN Device_Protection_Plan = 'No' THEN 1 ELSE NULL END)/COUNT(*),0) protection_no
	, ROUND(100.0*COUNT(CASE WHEN Premium_Tech_Support = 'Yes' THEN 1 ELSE NULL END)/COUNT(*),0) support_yes
	, ROUND(100.0*COUNT(CASE WHEN Premium_Tech_Support = 'No' THEN 1 ELSE NULL END)/COUNT(*),0) support_no
FROM ctetable
GROUP BY final_customer_status
ORDER BY final_customer_status DESC
;


-- churn analysis based on streaming part-1

SELECT 
	COUNT(CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE NULL END) AS movies_yes
	,COUNT(CASE WHEN Streaming_Movies = 'No' THEN 1 ELSE NULL END) AS movies_no
	,COUNT(CASE WHEN Streaming_Music = 'Yes' THEN 1 ELSE NULL END) AS music_yes
	,COUNT(CASE WHEN Streaming_Music = 'No' THEN 1 ELSE NULL END) AS music_no
	,COUNT(CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE NULL END) AS tv_yes
	,COUNT(CASE WHEN Streaming_TV = 'No' THEN 1 ELSE NULL END) AS tv_no
	,COUNT(*)  AS total
FROM dbo.telecom_customer_churn
WHERE Internet_Service = 'Yes'
;

-- churn-rate analysis based on Streaming part-2
WITH ctetable AS (
	SELECT
		Customer_ID,Internet_Service,Streaming_Movies,Streaming_Music,Streaming_TV
		,CASE 
			WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed_OLD_customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned_OLD_customer'
			WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned_NEW_customer'
			WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed_NEW_customer'
		ELSE NULL END AS final_customer_status
	FROM dbo.telecom_customer_churn
)
SELECT
	final_customer_status
	,ROUND(100.0*COUNT(CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE NULL END)/COUNT(*)
		,0) AS movies_yes
	,ROUND(100.0*COUNT(CASE WHEN Streaming_Movies = 'No' THEN 1 ELSE NULL END)/COUNT(*)
		,0) AS movies_no
	,ROUND(100.0*COUNT(CASE WHEN Streaming_Music = 'Yes' THEN 1 ELSE NULL END)/COUNT(*)
		,0) AS music_yes
	,ROUND(100.0*COUNT(CASE WHEN Streaming_Music = 'No' THEN 1 ELSE NULL END)/COUNT(*)
		,0) AS music_no
	,ROUND(100.0*COUNT(CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE NULL END)/COUNT(*)
		,0) AS TV_yes
	,ROUND(100.0*COUNT(CASE WHEN Streaming_TV = 'No' THEN 1 ELSE NULL END)/COUNT(*)
		,0) AS TV_no
FROM ctetable
WHERE Internet_Service = 'Yes'
GROUP BY final_customer_status
;


-- analysis of total revenue, monthly charge and refund for each final category
WITH ctetable AS (
	SELECT
			CASE 
				WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed OLD customer'
				WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned OLD customer'
				WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned NEW customer'
				WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed NEW customer'
				ELSE NULL 
			END AS final_customer_status
			,Monthly_Charge,Total_Charges,Total_Revenue,Total_Extra_Data_Charges,Total_Long_Distance_Charges,Total_Refunds
	FROM dbo.telecom_customer_churn
)
SELECT final_customer_status, ROUND(AVG(Monthly_Charge),2) average_monthly_charge
	,ROUND(AVG(Total_Revenue),2) average_total_revenue
	,ROUND(AVG(Total_Refunds),2) agerage_total_refund
	,ROUND(SUM(Total_Revenue),2) AS total_revenue
FROM ctetable
GROUP BY final_customer_status
UNION
SELECT 'All(overall)' AS final_customer_status,ROUND(AVG(Monthly_Charge),2) average_monthly_charge
	,ROUND(AVG(Total_Revenue),2) average_total_revenue
	,ROUND(AVG(Total_Refunds),2) agerage_total_refund
	,ROUND(SUM(Total_Revenue),2) AS total_revenue
FROM dbo.telecom_customer_churn
ORDER BY final_customer_status DESC
;


-- analysis of churn based on contract type part-1
SELECT contract AS contract_type,COUNT(*) AS num_customer
	,SUM(COUNT(*)) OVER() AS total_customer
	,ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),0) AS contract_to_overall_percent
FROM dbo.telecom_customer_churn
GROUP BY  Contract
;


-- analysis of churn based on contract type part-2
WITH ctetable AS (
	SELECT
			CASE 
				WHEN Customer_Status = 'Stayed' AND Tenure_in_Months > 3 THEN 'stayed OLD customer'
				WHEN Customer_Status = 'Churned' AND Tenure_in_Months > 3 THEN 'churned OLD customer'
				WHEN Customer_Status = 'Churned' AND Tenure_in_Months <= 3 THEN 'churned NEW customer'
				WHEN Customer_Status = 'Joined' AND Tenure_in_Months <= 3 THEN 'stayed NEW customer'
				ELSE NULL 
			END AS final_customer_status
			,Customer_ID,Monthly_Charge,Total_Revenue,Contract,Paperless_Billing
	FROM dbo.telecom_customer_churn as tele
)
SELECT Contract AS contract_type, final_customer_status
	,ROUND(100.0*COUNT(Customer_ID) 
		/SUM(COUNT(Customer_ID)) OVER(PARTITION BY Contract) 
	,2) AS status_to_contract_type_percent
FROM ctetable
GROUP BY contract, final_customer_status
ORDER BY contract, final_customer_status
;


-- Analysis of churn based on the churn category
SELECT 
	Churn_Category
	,COUNT(Customer_ID) num_customer_churned
	,ROUND(100.0*COUNT(Customer_ID)
		/SUM(COUNT(Customer_ID)) OVER()
	,1) AS percent_of_total_churned_customer
FROM dbo.telecom_customer_churn
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category
ORDER BY COUNT(Customer_ID) DESC
;


-- Analysis of churn based on reasons in each churn category
SELECT 
	Churn_Category,Churn_Reason
	,COUNT(Customer_ID) num_customer_churned
	, SUM(COUNT(Customer_ID)) 
		OVER(PARTITION BY Churn_Category) 
		AS total_churn_customer_each_category
	,ROUND(100.0*COUNT(Customer_ID)
		/SUM(COUNT(Customer_ID)) 
			OVER(PARTITION BY Churn_Category)
	,1) AS percent_in_each_churn_category
FROM dbo.telecom_customer_churn
WHERE Customer_Status = 'Churned'
GROUP BY Churn_Category, Churn_Reason
ORDER BY 
	Churn_Category
	,COUNT(Customer_ID) DESC
;










-- top 10 counties by number of customers
SELECT 
	TOP 10 (zip.state_county),COUNT(cust.Customer_ID) AS num_customer
FROM 
	dbo.telecom_customer_churn AS cust
	LEFT JOIN dbo.telecom_zipcode_population AS zip
	ON cust.Zip_Code = zip.Zip_Code
GROUP BY zip.state_county
ORDER BY COUNT(cust.Customer_ID) DESC
;

-- to 10 counties by total revenue
SELECT 
	TOP 10 (zip.state_county),ROUND(SUM(cust.Total_Revenue),2) as total_revenue	
FROM 
	dbo.telecom_customer_churn AS cust
	LEFT JOIN dbo.telecom_zipcode_population AS zip
	ON cust.Zip_Code = zip.Zip_Code
GROUP BY zip.state_county
ORDER BY SUM(cust.Total_Revenue) DESC
;


-- to 10 counties by Churn rate
SELECT 
	TOP 10 zip.state_county
	 ,ROUND(
		100.0*COUNT(CASE WHEN cust.Customer_Status = 'Churned' THEN 1 ELSE NULL END)
		/COUNT(cust.Customer_ID)
	,1) AS churn_rate
FROM 
	 dbo.telecom_customer_churn AS cust
	LEFT JOIN dbo.telecom_zipcode_population AS zip
	ON cust.Zip_Code = zip.Zip_Code
GROUP BY zip.state_county
order by ROUND(
		100.0*COUNT(CASE WHEN cust.Customer_Status = 'Churned' THEN 1 ELSE NULL END)
		/COUNT(cust.Customer_ID)
	,1)  DESC
;

