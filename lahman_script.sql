--Q1 What range of years for baseball games played does the provided database cover?

SELECT *
FROM appearances;

SELECT MIN(yearid), MAX(yearid)
FROM appearances;

--Q1 Answer: 1871-2016

--Q2 Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT *
FROM people;

SELECT CONCAT(namefirst,' ',namelast), height
FROM people
WHERE height IN
    (SELECT MIN(height)
    FROM people);
--Finding # of Games
SELECT *
FROM appearances;



SELECT playerid, CONCAT(p.namefirst,' ',p.namelast), p.height, a.g_all AS games_played
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid)
WHERE height IN
    (SELECT MIN(height)
    FROM people);

--Finding name of team
SELECT *
FROM teams;

SELECT DISTINCT CONCAT(p.namefirst,' ',p.namelast), p.height, a.g_all AS games_played, t.name AS team_name
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams as t
USING (teamid)
WHERE height IN
    (SELECT MIN(height)
    FROM people);
--Q2 Answer: Eddie Gaedel; 43in; 1 game; St. Louis Browns

--Q3 Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?


--Finding players for Vandy

SELECT *
FROM people;

SELECT *
FROM schools;

SELECT *
FROM collegeplaying;

SELECT playerid, count(playerid) AS dupecheck, salary
FROM salaries
WHERE playerid = 'konerpa01'
GROUP BY playerid, salary
ORDER BY dupecheck DESC;

SELECT DISTINCT p.namefirst AS first_name, p.namelast AS last_name, s.schoolname, playerid, COALESCE(SUM(sa.salary)::NUMERIC::MONEY,'0') AS total_salary
FROM people AS p
LEFT JOIN collegeplaying AS c
USING(playerid)
LEFT JOIN schools AS s
ON c.schoolid = s.schoolid
LEFT JOIN salaries as sa
USING (playerid)
WHERE s.schoolname LIKE 'Vand%'
GROUP BY first_name, last_name, playerid,s.schoolname
ORDER BY total_salary DESC

--Q3 Answer: Most Earned = David Price @$245,553,888