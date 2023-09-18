--1. How many olympics games have been held?

select count(distinct Games) as Total_Games from eventsdb;

--2. List down all Olympics games held so far.

select distinct Games, Season, City from eventsdb
group by Games, Season, City
order by Games;

--3. Mention the total no of nations who participated in each olympics game?

select Games, count(distinct NOC) as Total_Nation from eventsdb
group by games order by Games;

--4. Which year saw the highest and lowest no of countries participating in olympics.

with t1 as(
	select Games, count(distinct NOC) as Total_Nation, rank() over (order by count(distinct NOC)) as rnk  from eventsdb
	group by games)
select Games, Total_Nation from t1 where rnk in (1,51);

--5. Which nation has participated in all of the olympic games.
select * from eventsdb;

with t1 as(
	select count(distinct games) as total_games from eventsdb),
	t2 as(
	select ev.Games, re.region as Country from eventsdb ev
	inner join  regions re on re.NOC = ev.NOC group by Games, re.region),
	t3 as (
	select country, count(*) as total_participated_games from t2 group by country)
select t3.* from t3 join t1 on t3.total_participated_games = t1.total_games;

--6 Identify the sport which was played in all summer olympics.

with t1 as (
	select count(distinct games) as total_games from eventsdb where season = 'Summer'),
	t2 as (
	select games, sport from eventsdb where season = 'Summer' group by Games, sport),
	t3 as (
	select sport, count(*) as total_sport from t2 group by sport)
select t3.* from t3 join t1 on t3.total_sport = t1.total_games;

--7.Which Sports were just played only once in the olympics.

select * from eventsdb;
with t1 as(
	select distinct games, sport from eventsdb group by Games, sport),
	t2 as (
	select sport, count(*) as Games_Played from t1 group by sport)
select t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.Games_Played = 1
order by t1.sport;

--8. Fetch the total no of sports played in each olympic games.

select Games, count(distinct Sport) from eventsdb group by Games order by 2 desc;

--9. Fetch oldest athletes to win a gold medal.

with t1 as (
	select *, rank() over (order by Age desc) as rnk from eventsdb where medal = 'Gold')
select * from t1 where rnk = 1;

--10. Fetch the top 5 athletes who have won the most gold medals. 

with t1 as (
	select ev.name, rg.Region as Country, count(*) as gold_medal from eventsdb ev
	join regions rg on ev.NOC = rg.NOC where medal = 'Gold' group by ev.Name, rg.Region),
	t2 as (
	select *, DENSE_RANK() over (order by gold_medal desc) as rnk from t1)
select Name, Country, gold_medal from t2 where rnk <=5;

--11. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

with t1 as (
	select ev.name, rg.Region as Country, count(*) as medals_won from eventsdb ev
	join regions rg on ev.NOC = rg.NOC where medal in ('Gold', 'Silver', 'Bronze') group by ev.Name, rg.Region),
	t2 as (
	select *, DENSE_RANK() over (order by medals_won desc) as rnk from t1)
select Name, Country, medals_won from t2 where rnk <=5;

--12. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with t1 as (
	select rg.Region as Country, count(*) as medals_won from regions rg
	join eventsdb ev on ev.NOC = rg.NOC where medal in ('Gold', 'Silver', 'Bronze') group by rg.Region),
	t2 as (
	select *, DENSE_RANK() over (order by medals_won desc) as rnk from t1)
select Country, medals_won from t2 where rnk <=5;

-- 13. List down total gold, silver and bronze medals won by each country.

with t1 as (
	select re.Region as Country, ev.medal from eventsdb ev
	inner join regions re on re.NOC = ev.NOC)
select Country, 
sum (case when medal = 'Gold' then 1 else 0 end )as Gold_Medal,
sum (case when medal = 'Silver' then 1 else 0 end )as Silver_Medal,
sum (case when medal = 'Bronze' then 1 else 0 end )as Bronze_Medal
from t1 group by Country
order by Gold_Medal desc, Silver_Medal desc, Bronze_Medal desc;

--14. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

with t1 as (
	select ev. Games, re.Region as Country, ev.medal from eventsdb ev
	inner join regions re on re.NOC = ev.NOC)
select Games, Country, 
sum (case when medal = 'Gold' then 1 else 0 end )as Gold_Medal,
sum (case when medal = 'Silver' then 1 else 0 end )as Silver_Medal,
sum (case when medal = 'Bronze' then 1 else 0 end )as Bronze_Medal
from t1 group by Country, Games
order by Games;

--15. Which countries have never won gold medal but have won silver/bronze medals?

select re.Region as Country,
sum(case when Medal = 'Gold' then 1 else 0 end) as Gold_Medal,
sum(case when Medal = 'Silver' then 1 else 0 end) as Silver_Medal,
sum(case when Medal = 'Bronze' then 1 else 0 end) as Bronze_Medal
from eventsdb ev
inner join regions re on re.NOC = ev.NOC
group by re.region 
having sum(case when Medal = 'Gold' then 1 else 0 end) = 0
order by Silver_Medal desc;

--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with t as
(select games, region,
COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM eventsdb AS a
JOIN regions AS n ON a.NOC = n.NOC
group by games,region)
select distinct games
, concat(first_value(region) over(partition by games order by gold desc)
, ' - '
, first_value(Gold) over(partition by games order by gold desc)) as Max_Gold
, concat(first_value(region) over(partition by games order by silver desc)
, ' - '
, first_value(Silver) over(partition by games order by silver desc)) as Max_Silver
, concat(first_value(region) over(partition by games order by bronze desc)
, ' - '
, first_value(Bronze) over(partition by games order by bronze desc)) as Max_Bronze
from t
order by games;

--17. Find the Ratio of male and female athletes participated in all olympic games.
with cte as (
select (
select count(distinct ID ) as CM from eventsdb where Sex='M') as M,
(select count(distinct ID ) as CM from eventsdb where Sex='F') as F)
select concat('1',':',round(M/F,2)) as Sex_ratio from cte

--18. In which Sport/event, India has won highest medals.

select top 1 sport,count(medal) as Total_medal FROM eventsdb AS a
JOIN regions AS n ON a.NOC = n.NOC
where region = 'India'
group by sport
order by Total_medal desc

--19. How many medals won by India in Olympic.

select Games,
count(case when medal = 'Gold' then Medal end) as Gold_Medal,
count(case when medal = 'Silver' then Medal end) as Silver_Medal,
count(case when medal = 'Bronze' then Medal end) as Bronze_Medal
from eventsdb
where NOC ='IND'
group by Games
order by Games asc;

--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

SELECT team, sport, games, COUNT(medal) AS Total_medal
FROM eventsdb
WHERE team = 'India' AND sport = 'Hockey' and medal <> 'NA'
GROUP BY team, sport, games
ORDER BY Total_medal desc


