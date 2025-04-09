-- Creating Database  "Marketing_Camp_analysis"--

Create Database Marketing_Camp_analysis;
use Marketing_Camp_analysis

-- CREATING TABLES --

CREATE TABLE PRODUCTS
(
    Productid Int,
    Prd_name Varchar(200),
    Category char(6),
    Price decimal(10,2)
)

CREATE TABLE COUNTRIES
(
    countryID int,
    Country varchar(100),
    City varchar(100)
)

CREATE TABLE CUSTOMER_JOURNEY
(
    Journeyid int,
    custid int,
	productid int,
	Visitdate Date,
	Stage varchar(100),
	Action varchar(100),
    Duration varchar(100)
)

CREATE TABLE ENGAGEMENT_DATA
(
    EngagementID int,
	ContentID int,
    ContentType varchar(100),
	Likes int,
    Eng_date date,
    CampaignID int,
	ProductID int,
	Views_clicks_comb varchar(100)
)

CREATE TABLE CUSTOMERS
(
    countryID int,
	Country varchar(100),
	City varchar(100)

)

CREATE TABLE CUST_REVIEWS
(
    Reviewid int,
	Custid int,
	Productid int,
	ReviewDate Date,
	Rating int,
	Review_text varchar(200)
)

Select table_name from INFORMATION_SCHEMA.TABLES

--COPYING PATH OF DATA FROM LOCAL DATA--

--PATH: /Users/sparshsoni/Downloads/Cust_review.csv --CUST_REVIEWS
    --  /Users/sparshsoni/Downloads/Countries.csv -- COUNTRIES 
    --  /Users/sparshsoni/Downloads/customer_journey.csv -- CUSTOMER_JOURNEY
    --  /Users/sparshsoni/Downloads/Products.csv -- PRODUCTS
    --  /Users/sparshsoni/Downloads/Engagement_data.csv -- ENGAGEMENT_DATA
    --  /Users/sparshsoni/Downloads/Customers.csv -- CUSTOMERS

-- BULK INSERTION QUERY TO INSERT CSV DATA INTO SQL ENVIRONMENT--

--PRODUCTS--
--METHOD 1
/*
Bulk insert products
from /*path*/ '/Users/sparshsoni/Downloads/Products.csv'
-- DEFINING PARAMETER
with(fieldterminator='\t',Rowterminator='\n',firstrow=2)--c.s.v=comma seperated values
*/

--METHOD 2
-- USING SQL SERVER IMPORT EXTENSION BEFORE CREATING TABLE-->IMPORT WIZARD

-- Analysing all records --
select * from products
select * from cust_review
select * from engagement_data
select * from countries
select * from customers
select * from customer_journey

-- Changing datatype of duration column to int
select COLUMN_NAME, data_type from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'customer_journey'
select * from customer_journey

update customer_journey set Duration = NULL
where duration = 'null'

alter table customer_journey
alter column duration int

-- CREATING RELATIONSHIP BETWEEN TABLES--

Alter table products
add PRIMARY key (productid)

alter table customers
add primary key (custid)

alter table cust_review
add primary key (Reviewid)

Alter table cust_review
add FOREIGN key (productid) REFERENCES products

Alter table cust_review
add FOREIGN key (productid) REFERENCES customers

alter table engagement_data
add primary key (EngagementID)

Alter table engagement_data
add FOREIGN key (productid) REFERENCES customers

alter table countries
add primary key (countryID)

alter table customer_journey 
add FOREIGN key (productid) REFERENCES products 

alter table customer_journey 
add FOREIGN key (custid) REFERENCES customers

alter table customers 
add FOREIGN key(locid) REFERENCES countries

alter table customer_journey
add PRIMARY key (Journeyid)
-- giving duplicates error

--finding duplicates 
with cte as (
select ROW_NUMBER() OVER(partition by Journeyid order by Journeyid) as row_num
from CUSTOMER_JOURNEY)
select * from cte

with cte as (
select ROW_NUMBER() OVER(partition by Journeyid order by Journeyid) as row_num
from CUSTOMER_JOURNEY)
delete from cte
where row_num>1

alter table customer_journey
add PRIMARY key (Journeyid)

-- CREATING INDIVIDUAL COLUMNS FOR VIEWS AND CLICKS FROM ENGAGEMENT_DATA TABLE

select * from engagement_data
alter table engagement_data
add Views INT, Clicks INT

select LEFT(view_clicks_comb,CHARINDEX('-',view_clicks_comb,0)-1)
from ENGAGEMENT_DATA

update ENGAGEMENT_DATA 
set views = LEFT(view_clicks_comb,CHARINDEX('-',view_clicks_comb,0)-1)

select RIGHT(view_clicks_comb,LEN(view_clicks_comb)-CHARINDEX('-',view_clicks_comb,0))
from ENGAGEMENT_DATA

update ENGAGEMENT_DATA 
set CLICKS = RIGHT(view_clicks_comb,LEN(view_clicks_comb)-CHARINDEX('-',view_clicks_comb,0))
from ENGAGEMENT_DATA
-- showing error because of text data --

-- finding the data which are not getting converted to int
select * from ENGAGEMENT_DATA
where view_clicks_comb like '%[a-z]%'

-- assuming 26-feb as 26-02 and 01 for jan
update ENGAGEMENT_DATA set view_clicks_comb = 
case when view_clicks_comb like '%jan' then '01'
when view_clicks_comb like '%feb' then '02'
else view_clicks_comb end

--updating click column again
update ENGAGEMENT_DATA 
set CLICKS = RIGHT(view_clicks_comb,LEN(view_clicks_comb)-CHARINDEX('-',view_clicks_comb,0))
from ENGAGEMENT_DATA

alter table ENGAGEMENT_DATA 
drop column view_clicks_comb

-- DATA DISTRIBUTION --

-- CUSTOMERS AND ITS JOURNEY TOWARDS CAMPAIGNS

-- Basic customer details and behavior
select gender, count(*) as Gender_counts from CUSTOMERS
group by Gender

select rating, count(*) as Rating_counts_by_customers from CUST_review
group by rating
order by rating desc

select stage, count(*) as Stages_counts from CUSTOMER_JOURNEY
GROUP by stage

-- total purchase count calculation
select count([action]) as "Total purchase count" from CUSTOMER_JOURNEY
where [action] = 'purchase'

--max products purchased by which customer
with customer_purchase_counts as 
(
select custid, count([action]) as 'Purchase_count' from CUSTOMER_JOURNEY
where [Action] = 'purchase'
group by Custid
)
, maxpurchase_id as (
select custid, purchase_count as 'max_purchase_count' from customer_purchase_counts
where purchase_count = (select MAX(purchase_count) from customer_purchase_counts
)
)
select CustName as 'Customers with most purchasing' from CUSTOMERS 
where custid in (select Custid from maxpurchase_id)

-- Checking most active age groups among customers
go
with age_groups as 
(select *, (case when age<18 then 'kids'
                when age>=18 and age<35 then 'young adults'
                when age>35 and age<60 then 'mid adults'
                else 'old adults' end ) 
as 'groups' from customers)

select groups, count(*) as counts from age_groups
group by groups
order by counts desc

-- Top 5 products purchased by customers and rated more than or equals 3 --

with rated_most as
(
select r.productid, j.action, r.rating   from CUST_REVIEW r
inner join CUSTOMER_JOURNEY j
on r.custid = j.custid
where rating>=3 and action = 'purchase'
AND r.productid = j.productid
)
, top_prod as (
select top 5 productid, count(*) as product_count from rated_most
group by PRODUCTid
order by product_count desc
)

select tp.productid, p.prd_name from top_prod tp
inner join PRODUCTS p
on tp.productid = p.Productid


-- Most engaging cqmpaign in terms of ctr

select top 5 campaignid, sum(views) as 'tot_views',
    sum(clicks) as 'tot_clicks',
    (sum(clicks)*100.0)/sum(views) as 'CTR' from ENGAGEMENT_DATA
group by  campaignid
order by CTR desc

-- Most engaging campaign in terms of conversion rate
with eng_summarize as(select productid, campaignid, sum(clicks) as 'tot_clicks', sum(views) as 'total_vws'
from engagement_data
group by productid, campaignid)

, summ_ofpurc as ( select productid, count(*) as 't_purc'
					from customer_journey 
					where action='purchase'
					group by productid)

, camp_eff as (Select e.campaignid, sum(tot_clicks) as 't_cl', sum(total_vws) as 't_vw', sum(tot_clicks)*100.0/sum(total_vws) as CTR,
				round(sum(t_purc)*100.0,2) /sum(total_vws) as 'Con_rate'
				from eng_summarize e
				join summ_ofpurc s
				on e.ProductID=s.productid
				group by e.CampaignID)
Select top 5 Campaignid, T_cl,t_vw,ctr ,Con_rate
from camp_eff
order by con_rate desc

-- Demographic analysis refer to the city or country or state

with customers_details_purchased_ones as
(
Select cs.Custid,ct.Country, cj.productid, cj.[Action] from CUSTOMERS cs
inner join COUNTRIES ct
on cs.Locid = ct.countryID
inner join CUSTOMER_JOURNEY cj
on cs.Custid = cj.custid
where cj.action = 'purchase'
)
, products_avg_ratings as 
(
select cr.custid, cr.productid, p.prd_name, sum(cr.rating)/(1.0*count(*)) as 'Av_rating' from CUST_REVIEW cr
inner join PRODUCTS p 
on cr.productid = p.Productid
GROUP by cr.custid, cr.productid, p.prd_name
)

select a.country, count(a.[Action]) as 'purchase_count', avg(b.av_rating)
as 'average_rating'
from customers_details_purchased_ones a 
left join products_avg_ratings b 
on a.Custid = b.custid and a.productid = b.productid
group by a.Country
 order by purchase_count desc