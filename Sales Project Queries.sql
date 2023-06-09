--Inspecting Data
--This query is used to inspect the sales_data_sample table and display all rows and columns
select * from [dbo].[sales_data_sample]

--Checking unique values
--This query is used to display unique values in specific columns
select distinct status from [dbo].[sales_data_sample] 
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] 
select distinct COUNTRY from [dbo].[sales_data_sample] 
select distinct DEALSIZE from [dbo].[sales_data_sample] 
select distinct TERRITORY from [dbo].[sales_data_sample] 


--This query will provide a list of all the unique months in which sales occurred in 2003
select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2003

--ANALYSIS
--Total revenue generated by each product line
select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

--Total sales revenue by year
select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

--Total revenue for each deal size category
select  DEALSIZE,  sum(sales) Revenue
from [dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc


--Best month for sales in the year and how much was earned in each month
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 -- can choose other years to see 
group by  MONTH_ID
order by 2 desc


--Checking on products sold in November, which is the highest earned month 
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc


--Finding the best customer using RFM
--Recency_Frequency_Monetary Analysis

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven�t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

-- The output of this query is a list of customers with their RFM scores and the segment they belong to. 
--The segments are:
--Lost Customers: customers who used to purchase frequently but haven't bought in a while
--Slipping Away: big spenders who haven't purchased lately, at risk of leaving
--New Customers: customers who just started purchasing from the company
--Potential Churners: customers who buy often but have a low monetary value, at risk of leaving
--Active: customers who buy often and recently, but at low price points
--Loyal: customers who are frequent buyers and have a high monetary value, the most valuable segment


--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc


--Some More Queries
--City with highest number of sales in a specific country
select city, sum (sales) Revenue
from [dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc

---Best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc

--Total Revenue for each Quarter
select QUARTER, sum(sales) Revenue
from (
select YEAR_ID, case
when MONTH_ID in (1,2,3) then 'Q1'
when MONTH_ID in (4,5,6) then 'Q2'
when MONTH_ID in (7,8,9) then 'Q3'
when MONTH_ID in (10,11,12) then 'Q4'
end as QUARTER, sales
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 --can change year to see others
) x
group by QUARTER;


--Top 5 products with highest revenue 
select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 --can change year to see others
group by PRODUCTLINE
order by 2 desc
OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY;

--Top 5 customers with highest revenue 
select CUSTOMERNAME, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by CUSTOMERNAME
order by 2 desc
OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY;

--Average Order Value
SELECT CUSTOMERNAME, AVG(SALES) AS AVERAGE_ORDER_VALUE
FROM [dbo].[sales_data_sample]
GROUP BY CUSTOMERNAME
ORDER BY AVERAGE_ORDER_VALUE DESC

--Customer Lifetime Value
SELECT CUSTOMERNAME, SUM(SALES) AS MONETARY_VALUE, COUNT(DISTINCT ORDERNUMBER) AS FREQUENCY, 
DATEDIFF(DAY, MIN(ORDERDATE), MAX(ORDERDATE)) AS RECENCY
FROM [dbo].[sales_data_sample]
GROUP BY CUSTOMERNAME
ORDER BY MONETARY_VALUE DESC

--Sales by Region
SELECT COUNTRY, STATE, CITY, SUM(SALES) AS REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY COUNTRY, STATE, CITY
ORDER BY REVENUE DESC

--Monthly Sales Trend
SELECT YEAR_ID, MONTH_ID, SUM(SALES) AS REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID, MONTH_ID
ORDER BY YEAR_ID, MONTH_ID

--Order Status Distribution
SELECT STATUS, COUNT(*) AS FREQUENCY
FROM [dbo].[sales_data_sample]
GROUP BY STATUS
ORDER BY FREQUENCY DESC

--Moving AVG of sales for each product line over the past 3 months
SELECT 
  PRODUCTLINE, 
  ORDERDATE, 
  SALES, 
  AVG(SALES) OVER (
    PARTITION BY PRODUCTLINE 
    ORDER BY ORDERDATE 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS MovingAvg
FROM 
  [dbo].[sales_data_sample];


-- Customers who have not made any purhcaes in the last 6 months
  SELECT CUSTOMERNAME
FROM [dbo].[sales_data_sample]
GROUP BY CUSTOMERNAME
HAVING MAX(ORDERDATE) < DATEADD(MONTH, -6, GETDATE())

--Percentage of sales for each product line each year 
SELECT YEAR_ID, PRODUCTLINE, SUM(sales) AS TotalSales, 
    100 * SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY YEAR_ID) AS SalesPercentage
FROM [dbo].[sales_data_sample]
WHERE year_id = 2004 --Can change
GROUP BY YEAR_ID, PRODUCTLINE
ORDER BY YEAR_ID, SalesPercentage DESC


