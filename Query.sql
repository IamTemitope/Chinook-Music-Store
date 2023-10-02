-- Countries by Most Invoice 
SELECT
  c.country,
  COUNT(i.invoiceid)
FROM customer c
JOIN invoice i
  ON c.customerid = i.customerid
GROUP BY 1
ORDER BY 2 DESC;


-- City with best customer
SELECT c.city,
       sum(il.quantity * il.unitprice) "revenue"
FROM customer c
JOIN invoice i ON c.customerid = i.customerid
JOIN invoiceline il ON i.invoiceid = il.invoiceid
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


-- Best Customer
SELECT c.customerid,
       sum(il.quantity * il.unitprice) "revenue"
FROM customer c
JOIN invoice i ON c.customerid = i.customerid
JOIN invoiceline il ON i.invoiceid = il.invoiceid
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;



-- Email, First Name, Last Name and Genre of all rock music listeners
 SELECT c.email "Email",
       c.firstname "First Name",
       c.lastname "Last Name",
       g.name "Genre"
FROM customer c
JOIN invoice i ON c.customerid = i.customerid
JOIN invoiceline il ON i.invoiceid = il.invoiceid
JOIN track t ON il.trackid = t.trackid
JOIN genre g ON t.genreid = g.genreid
WHERE g.name = 'Rock';


-- Writer of Top Music in Rock Genre
SELECT b.artistid "Artist ID",
       a.name "Name",
       count(*) "Songs"
FROM track t
JOIN genre g ON t.genreid = g.genreid
JOIN album b ON t.albumid = b.albumid
JOIN artist a ON b.artistid = a.artistid
WHERE g.name = 'Rock'
GROUP BY 1,
         2
ORDER BY 3 DESC
LIMIT 10;



-- Which Artist has earned the most according to invoice line
SELECT b.artistid "Artist ID",
       a.name "Name",
       sum(il.quantity * il.unitprice) "Revenue"
FROM invoiceline il
JOIN track t ON il.trackid = t.trackid
JOIN album b ON t.albumid = b.albumid
JOIN artist a ON b.artistid = a.artistid
GROUP BY 1,
         2
ORDER BY 3 DESC
LIMIT 10;



-- Top customers of the artist who earned the most according to invoice line
WITH top_artist AS (
  SELECT a.ArtistId, a.Name, SUM(il.UnitPrice * il.Quantity) AS earnings
  FROM InvoiceLine il
  JOIN Track t ON il.TrackId = t.TrackId
  JOIN Album al ON t.AlbumId = al.AlbumId
  JOIN Artist a ON al.ArtistId = a.ArtistId
  GROUP BY a.ArtistId, a.Name
  ORDER BY earnings DESC
  LIMIT 1
)

SELECT c.CustomerId, c.FirstName || ' ' || c.LastName AS CustomerName, SUM(il.UnitPrice * il.Quantity) AS total_spending
FROM Invoice i
JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist a ON al.ArtistId = a.ArtistId
JOIN Customer c ON i.CustomerId = c.CustomerId
WHERE a.ArtistId = (SELECT ArtistId FROM top_artist)
GROUP BY c.CustomerId, CustomerName
ORDER BY total_spending DESC
LIMIT 1;



-- Most Popular Genre For Each Country
WITH genre_purchases AS
  (SELECT g.GenreId,
          g.Name,
          i.BillingCountry,
          SUM(il.Quantity) AS total_purchases,
          RANK() OVER (PARTITION BY i.BillingCountry
                       ORDER BY SUM(il.Quantity) DESC) AS genre_rank
   FROM genre g
   JOIN track t ON g.GenreId = t.GenreId
   JOIN invoiceline il ON t.TrackId = il.TrackId
   JOIN invoice i ON il.InvoiceId = i.InvoiceId
   GROUP BY g.GenreId,
            g.Name,
            i.BillingCountry)
SELECT BillingCountry,
       Name AS TopGenre,
       total_purchases
FROM genre_purchases
WHERE genre_rank = 1
ORDER BY BillingCountry;




-- Tracks that have a song length longer than average song length
select name,
       milliseconds
from track
where milliseconds >
    (select avg(milliseconds)
     from track)




-- Categorizing song length
With Category As
  (SELECT name,
          milliseconds,
          CASE
              WHEN milliseconds >
                     (SELECT AVG(milliseconds)
                      FROM track) THEN '+ Average'
              WHEN milliseconds <
                     (SELECT AVG(milliseconds)
                      FROM track) THEN '- Average'
              ELSE 'Average'
          END AS track_duration_category
   FROM track
   Order by 3)
Select track_duration_category,
       count(*)
from category
group by 1;




-- Customer that has spent the most on music for each country
WITH RANKING AS
  (SELECT i.billingcountry "Country",
          c.customerid "Id",
          Concat(c.firstname, ' ', c.lastname) "Name",
          sum(i.total) "Total Spent",
          rank () over (partition by i.billingcountry
                        order by sum(i.total) desc)
   FROM customer c
   JOIN invoice i ON c.customerid = i.customerid
   GROUP BY 1,
            2,
            3)
Select "Country",
       "Id",
       "Name",
       "Total Spent"
from ranking
where rank = 1
Order by 1




-- Group Countries into earnings Categories
With Average AS
  (SELECT billingcountry "Country",
          sum(total) "Revenue"
   FROM invoice
   GROUP BY 1
   Order by 2)
SELECT billingcountry "Country",
       sum(total) "Revenue",
       CASE
           WHEN sum(total) >
                  (Select avg ("Revenue")
                   from average) THEN 'Positive'
           ELSE 'Negative'
       END AS "Revenue Rate"
FROM invoice
GROUP BY 1
Order by 2
