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

SELECT DISTINCT CONCAT(p.namefirst,' ',p.namelast) AS full_name, p.height, SUM(a.g_all) AS games_played, t.name AS team_name
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams as t
USING (teamid)
WHERE height IN
    (SELECT MIN(height)
    FROM people) --Final Code for Answer
GROUP BY full_name, p.height, team_name;    
--Q2 Answer: Eddie Gaedel; 43in; 52 games; St. Louis Browns

--Q3 Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

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
ORDER BY dupecheck DESC; --Used to verify if SUM was needed/there were duplicates in salary file. Spoiler, there were!

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
ORDER BY total_salary DESC; -- Final Code for Answer

--Q3 Answer: Most Earned = David Price @$245,553,888

--Q4 Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT *
FROM fielding;


SELECT 
    CASE 
        WHEN pos LIKE 'OF' THEN 'Outfield'
        WHEN pos LIKE 'SS' OR pos LIKE '1B' OR pos LIKE '2B' OR pos LIKE '3B' THEN 'Infield'
        WHEN pos LIKE 'P' OR pos LIKE 'C' THEN 'Battery'
        ELSE 'OTHER'
        END AS pos_long_name, 
        COUNT(PO) AS put_outs
FROM fielding
WHERE yearid = 2016
GROUP BY pos_long_name;

--Q4 Answer: Battery - 938; Infield - 661; Outfield - 354

--Q5 Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT *
FROM appearances;

SELECT *
FROM batting;

SELECT SUM(g_all)
FROM appearances;

SELECT *
FROM appearances
WHERE playerid = 'altroni01'; -- duplicate checK

SELECT *
FROM teams;

SELECT concat(decade,'-', decade +9) AS year, ROUND((subquery.total_SOs/subquery.total_games)/2.00,2) AS avg_strikeouts_per_game, ROUND((subquery.total_HRs/subquery.total_games)/2.00,2) AS avg_homeruns_per_game
FROM
    (SELECT SUM(so)/1.00 as total_SOs, SUM(g)/1.00 AS total_games, SUM(hr)/1.00 AS total_HRs, FLOOR(yearid/ 10)* 10 as decade
    FROM teams
    WHERE yearid >1919
    GROUP BY decade
    ORDER BY decade) AS subquery
GROUP BY decade, avg_strikeouts_per_game, avg_homeruns_per_game
ORDER BY decade; --final answer after WAY too much time spent on this haha

--Q5 Answer: Homeruns go up even as SOs do as well. 

--Q6 Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

SELECT *
FROM batting;

SELECT yearid, playerid, total_sb_attempted, SUM(sb) AS stolen_bases, SUM(cs) AS caught_stealing, TO_CHAR(sum(sb)/sum(total_sb_attempted)*100, 'fm00D0%') AS percent_sb_successful
FROM 
    (SELECT playerid, sb, cs, yearid, (COALESCE(SUM(sb),0)+COALESCE(SUM(cs),0)) AS total_sb_attempted
    FROM batting
    GROUP BY playerid, sb, cs, yearid) AS subquery
WHERE total_sb_attempted > 19 AND yearid = '2016'
GROUP BY yearid, playerid, total_sb_attempted
ORDER BY percent_sb_successful DESC; -- code to make sure I'm doing this right with extra columns

SELECT playerid, CONCAT(p.namefirst,' ',p.namelast) AS full_name, TO_CHAR(sum(sb)/sum(total_sb_attempted)*100, 'fm00D0%') AS percent_sb_successful
FROM 
    (SELECT playerid, sb, cs, yearid, (COALESCE(SUM(sb),0)+COALESCE(SUM(cs),0)) AS total_sb_attempted
    FROM batting
    GROUP BY playerid, sb, cs, yearid) AS subquery
LEFT JOIN people AS p
USING (playerid)
WHERE total_sb_attempted > 19 AND yearid = '2016'
GROUP BY playerid, full_name
ORDER BY percent_sb_successful DESC; -- Simplified code for answer with player name

--Q6 Answer: Chris Owings @ 91.3% success

/* Q7
- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
- What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
- Then redo your query, excluding the problem year. 
- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?*/

SELECT *
FROM teams;

SELECT yearid, teamid, w, COALESCE(wswin,'N') as won_world_series
From teams
WHERE wswin = 'N'
    AND yearid BETWEEN 1970 AND 2016
ORDER BY w DESC, yearid; -- largest # of dubs for not winning the big dance




--Q7 Answer: 116 wins; 