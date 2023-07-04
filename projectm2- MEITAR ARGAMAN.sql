-- Name:MEITAR ARGAMAN
-- Date:21/5/2023
-- Description: - PROJECT 2 MEITAR ARGAMAN

use AdventureWorks2019

--1. 

select p.ProductID , 
       p.Name, 
	   p.Color, 
	   p.ListPrice , 
	   p.Size
from [Production].[Product]p
except 
select s.ProductID, Name , Color, ListPrice, Size
from [Sales].[SalesOrderDetail] s
join [Production].[Product]p
on p.ProductID = s.ProductID


-- 
update sales.customer set personid=customerid    
where customerid <=290 
update sales.customer set personid=customerid+1700     
where customerid >= 300 and customerid<=350  
update sales.customer set personid=customerid+1700     
where customerid >= 352 and customerid<=701


--2
select c.CustomerID as [CustomerID],
       isnull (p.LastName ,'UnKnown') as [Last Name],
	   isnull (p.FirstName  ,'UnKnown')as [First Name]
from [Sales].[Customer] as c
left join [Person].[Person] as p
on p.BusinessEntityID= c.personid
full join [Sales].[SalesOrderHeader] as soh
on soh.CustomerID= c.CustomerID
where soh.SalesOrderID is null
order by c.CustomerID



--3.
select CustomerID,FirstName,LastName ,CountOfOrders
from (
select top 10 c.CustomerID as [CustomerID],
              p.FirstName as [FirstName],
			  p.LastName as [LastName],
			  count (soh.CustomerID)as [CountOfOrders], 
			  DENSE_RANK()over(order by count (soh.CustomerID)desc ) as [Ran]
from [Sales].[Customer] as c
join [Person].[Person] as p
on p.BusinessEntityID= c.PersonID
join [Sales].[SalesOrderHeader] as soh 
on soh.CustomerID= c.CustomerID
group by c.CustomerID, p.FirstName, p.LastName) as s
where Ran<= 5


--4. 
select * from
        (select p.FirstName, 
        p.LastName , 
		JobTitle ,
		e.HireDate,
		count (jobtitle)over (partition by JobTitle order by jobtitle )as [CountOfTitle]
from [Sales].[Customer]as c
join [Person].[Person] as p
on p.BusinessEntityID= c.CustomerID
join [HumanResources].[Employee] as e
on e.BusinessEntityID = c.CustomerID
group by FirstName ,p.LastName ,JobTitle ,e.HireDate ) as a
order by JobTitle


--5. 
with CTEm2
as 
(
select s.SalesOrderID as [SalesOrderID] ,
       c.CustomerID as [CustomerID], 
	   p.lastname as [lastname], 
	   p.FirstName as [FirstName],
       s.OrderDate,
	   dense_rank() over(partition by c.CustomerID 
	   order by s.orderDate desc) as Ord,
       lead(s.OrderDate,1) over(partition by c.CustomerID 
	   order by s.orderDate desc) as [PreviounsOrder] 
from [Person].[Person]p
 right join [Sales].[Customer]c
 on p.BusinessEntityID = c.PersonID
 join 
[Sales].[SalesOrderHeader]s
 on s.CustomerID = c.CustomerID
)
select [SalesOrderID] ,
       [CustomerID], 
	   [lastname],
	   [FirstName],
	   [OrderDate],
	   [previounsOrder] 
from CTEm2
where Ord =1
order by CustomerID

--6.
with CTE_Order
as (
SELECT  year (OrderDate) as [Year],
       soh.SalesOrderID as [Sales Order ID], 
	   LastName as [Last Name],
	   FirstName as [First Name],
	   soh.SubTotal  as[Total],
	   DENSE_RANK() over(partition by year( SOH.OrderDate)
	   order by  soh.SubTotal desc) as [Rn]
from [Sales].[Customer] as c
left join [Person].[Person] as p
on p.BusinessEntityID = c.PersonID
full join [Sales].[SalesOrderHeader] as soh
on soh.CustomerID= c.CustomerID 
where SOH.SalesOrderID is not null )
select CTE_Order.[Year],
       CTE_Order.[Sales Order ID], 
       CTE_Order.[First Name],
       CTE_Order.[Last Name],
       FORMAT(Cast(CTE_Order.[Total] as money),'C', 'en-us') As [Total]
from CTE_Order
where CTE_Order.[Rn] =1


--7.
select *
from (select year(OrderDate) as [Year],
             Month(OrderDate) as [Month], 
			 s.SalesOrderID
from [Sales].[SalesOrderHeader]s ) o
pivot (COUNT(SalesOrderID) for [Year] in ([2011] , [2012] , [2013], [2014])) as Pvt
order by [Month]


--8
with cte_1
as
(select cast(Year(OrderDate) AS varchar(20)) [Year] ,
       Month(OrderDate)AS [Month],
	   FORMAT (sum (LineTotal), 'c', 'EN-US' )as [Sum_Price],
       FORMAT (sum (sum (LineTotal))over
	   (partition by Year(OrderDate)
	   order by Year(OrderDate) ,Month(OrderDate )), 'c', 'EN-US' )as [Money]
from [Sales].[Customer] as c
join [Person].[Person] as p
on p.BusinessEntityID = c.PersonID
join [Sales].[SalesOrderHeader] as soh
on soh.CustomerID= c.CustomerID 
JOIN [Sales].[SalesOrderDetail] as sd
ON sd.SalesOrderID = soh.SalesOrderID
group by year(OrderDate), Month(OrderDate))
,
cte_2 as 
(SELECT cast (year (OrderDate) as varchar(20) )+' Total:' [Year],
       null [Month],
	   null [Sum_Price],
	   format(sum (linetotal ), 'c', 'EN-US') as [Money]
from [Sales].[Customer] as c
join [Person].[Person] as p
on p.BusinessEntityID = c.PersonID
join [Sales].[SalesOrderHeader] as soh
on soh.CustomerID= c.CustomerID 
JOIN [Sales].[SalesOrderDetail] as sd
on sd.SalesOrderID = soh.SalesOrderID
group by year(OrderDate)
union 
select 'grand_total'[Year],
       null[Month],
	   null[Sum_Price],
	   format(SUM (linetotal ), 'c', 'EN-US') as [Money]
from [Sales].[Customer] as c
join [Person].[Person] as p
on p.BusinessEntityID = c.PersonID
join [Sales].[SalesOrderHeader] as soh
on soh.CustomerID= c.CustomerID 
JOIN [Sales].[SalesOrderDetail] as sd
on sd.SalesOrderID = soh.SalesOrderID)

select * from cte_1 
union 
select * from cte_2


--9
select Name as [Department Name],
       E.BusinessEntityID as [Employee's Id],
       CONCAT(FirstName,' ',LastName)as [Employee's Full Name],
       E.HireDate as [HireDate],
	   DATEDIFF(MM,HireDate ,GETDATE()) as [Seniority],
       lag(CONCAT(FirstName,' ',LastName),1) over(partition by d.Name 
	   order by E.HireDate) as [Previuse Emp Name],
	   lag(E.HireDate,1)over(partition by d.Name order by E.HireDate )as [Previuse Emp HDate],
	   DATEDIFF(dd,lag(E.HireDate,1)over(partition by d.Name 
	   order by E.HireDate ),E.HireDate ) as [DiffDays]
from [HumanResources].[Employee] as E 
join [Person].[Person] as P
on P.BusinessEntityID=E.BusinessEntityID
join [HumanResources].[EmployeeDepartmentHistory]  as EDH
on E.BusinessEntityID = EDH.BusinessEntityID
join [HumanResources].[Department] as D
on D.DepartmentID=EDH.DepartmentID
where d.Name is not null and edh.EndDate is null
order by [Department Name] , HireDate desc


--10
with cte_hire1
as
(
select e.HireDate as  [Hire Date],
        EDH.DepartmentID as [Department ID],
        concat(e.BusinessEntityID,' ',LastName,' ',FirstName , ' ') as [a]
FROM [HumanResources].[Employee] as E 
JOIN [Person].[Person] as P
ON P.BusinessEntityID=E.BusinessEntityID
join [HumanResources].[EmployeeDepartmentHistory] as EDH
ON E.BusinessEntityID = EDH.BusinessEntityID
where edh.EndDate is null 
)
select cte_hire1.[Hire Date], 
       cte_hire1.[Department ID], 
       STRING_AGG(cte_hire1.a , ' , ') as [a]
from cte_hire1 
group by cte_hire1.[Hire Date], cte_hire1.[Department ID]
order by 1
