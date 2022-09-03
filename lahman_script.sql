--Q1 What range of years for baseball games played does the provided database cover?

SELECT *
FROM appearances;

SELECT MIN(yearid), MAX(yearid)
FROM appearances;

--Q1 Answer: 1871-2016 --- Walkthrough Answer: Correct

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

SELECT DISTINCT CONCAT(p.namefirst,' ',p.namelast) AS full_name, p.height, g_all AS games_played, t.name AS team_name
FROM people AS p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams as t
USING (teamid)
WHERE height IN
    (SELECT MIN(height)
    FROM people) 
GROUP BY full_name, p.height, team_name, games_played; --Final Code for Answer -- Walkthrough Answer: I had the code before this correct, but somehow did a SUM on the final code for games played.    
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
ORDER BY total_salary DESC; -- Final Code for Answer -- Walkthrough Answer: You're getting duplicates because when you join collegplaying, it's pulling in a row for every year they played in college. Using a subquery in the FROM or WHERE would have eliminated the duplicates. Salary should be $81M

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
GROUP BY pos_long_name; -- Walkthrough Answer: you should have used a sum not a count, your numbers are too low. 

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

SELECT concat(decade,'-', decade +9) AS year, 
    ROUND(subquery.total_SOs/(subquery.total_games/2.00),2) AS avg_strikeouts_per_game,                       ROUND(subquery.total_HRs/(subquery.total_games/2.00),2) AS avg_homeruns_per_game
FROM
    (SELECT SUM(so)/1.00 as total_SOs, SUM(g)/1.00 AS total_games, SUM(hr)/1.00 AS total_HRs, FLOOR(yearid/ 10)* 10 as decade
    FROM teams
    WHERE yearid >1919
    GROUP BY decade
    ORDER BY decade) AS subquery
GROUP BY decade, avg_strikeouts_per_game, avg_homeruns_per_game
ORDER BY decade; --WRONG answer after WAY too much time spent on this - I divided by 2 too soon and had my parenthesis in the wrong place. 

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

SELECT playerid, 
CONCAT(p.namefirst,' ',p.namelast) AS full_name, 
TO_CHAR(sum(sb)/sum(total_sb_attempted)*100, 'fm00D0%') AS percent_sb_successful
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
a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
b. What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
c. Then redo your query, excluding the problem year. 
d. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
e. What percentage of the time?*/

SELECT *
FROM teams;

SELECT yearid, teamid, SUM(w) as total_wins
From teams
WHERE wswin = 'N'
    AND yearid BETWEEN 1970 AND 2016
group by yearid, teamid
ORDER BY total_wins DESC; -- largest # of dubs for not winning the big dance that year

SELECT yearid, teamid, SUM(w) as total_wins
From teams
WHERE wswin = 'Y'
    AND yearid BETWEEN 1970 AND 2016
group by yearid, teamid
ORDER BY total_wins; -- smallest # of dubs for actually winning the big dance including strike year

SELECT *
From teams
WHERE yearid = 1981

SELECT yearid, teamid, SUM(w) as total_wins
From teams
WHERE wswin = 'Y'
    AND yearid BETWEEN 1970 AND 2016
    AND yearid != 1981
group by yearid, teamid
ORDER BY total_wins ASC; -- Query redone excluding 1981



WITH max_wins_by_year AS
    (SELECT yearid, MAX(w) as max_wins
    FROM teams
    GROUP BY yearid)

SELECT COUNT(teamid) AS max_and_wswin
FROM(
    SELECT t.yearid, t.teamid, t.w, mw.max_wins
    FROM teams AS t
    LEFT JOIN max_wins_by_year AS mw
    USING (yearid)
    WHERE t.w = mw.max_wins AND yearid >= 1970 AND yearid <=2016
    AND wswin = 'Y'
    GROUP BY t.yearid, t.teamid, t.w, mw.max_wins) AS checker -- # of times a team had max points AND won the world series for that year

SELECT *
from teams

    WITH max_wins_by_year AS
        (SELECT yearid, MAX(sum_wins) as max_wins
        FROM 
         (SELECT yearid, teamid, sum(w) AS sum_wins
         FROM teams
         GROUP BY yearid, teamid
         ORDER BY teamid) as sq
        GROUP BY yearid),

     ws_win AS
     (SELECT yearid, teamid, wswin
     FROM teams
     WHERE wswin = 'Y'),

     season_wins AS
     (SELECT yearid, teamid, SUM(w) as sum_wins
     FROM teams
     GROUP BY yearid, teamid)
 
SELECT DISTINCT mw.yearid, ws.teamid, mw.max_wins, sw.sum_wins, ws.wswin
FROM teams as t
INNER JOIN max_wins_by_year as mw
ON mw.yearid = t.yearid
INNER JOIN ws_win AS ws
ON ws.yearid = mw.yearid
INNER JOIN season_wins as sw
ON sw.teamid = ws.teamid
WHERE sw.sum_wins = mw.max_wins AND mw.yearid = sw.yearid AND t.wswin = 'Y' AND t.yearid >= 1970 AND t.yearid <=2016
ORDER BY yearid --#of times a team had max points AND won the world series for that year with team names


    WITH max_wins_by_year AS
        (SELECT yearid, MAX(sum_wins) as max_wins
        FROM 
         (SELECT yearid, teamid, sum(w) AS sum_wins
         FROM teams
         GROUP BY yearid, teamid
         ORDER BY teamid) as sq
        GROUP BY yearid),

     ws_win AS
     (SELECT yearid, teamid, wswin
     FROM teams
     WHERE wswin = 'Y' AND t.yearid >= 1970 AND t.yearid <=2016),

     season_wins AS
     (SELECT yearid, teamid, SUM(w) as sum_wins
     FROM teams
     GROUP BY yearid, teamid),
 
    num_of_years AS
    (Select COUNT(DISTINCT yearid) AS num_years
    FROM teams),

    num_ws_and_max AS
         (SELECT DISTINCT mw.yearid, ws.teamid, mw.max_wins, sw.sum_wins, ws.wswin
        FROM teams as t
        INNER JOIN max_wins_by_year as mw
        ON mw.yearid = t.yearid
        INNER JOIN ws_win AS ws
        ON ws.yearid = mw.yearid
        INNER JOIN season_wins as sw
        ON sw.teamid = ws.teamid
        WHERE sw.sum_wins = mw.max_wins AND mw.yearid = sw.yearid AND t.wswin = 'Y' AND t.yearid >= 1970 AND t.yearid <=2016)

SELECT TO_CHAR(CAST(count(DISTINCT t.yearid) AS NUMERIC)/CAST(COUNT(nwm.teamid) AS NUMERIC)*100, 'fm00D00%') AS perc_of_time
FROM teams as t
INNER JOIN max_wins_by_year as mw
ON mw.yearid = t.yearid
INNER JOIN ws_win AS ws
ON ws.yearid = mw.yearid
INNER JOIN season_wins as sw
ON sw.teamid = ws.teamid
INNER JOIN num_ws_and_max AS nwm
ON nwm.teamid = t.teamid
WHERE sw.sum_wins = mw.max_wins AND mw.yearid = sw.yearid AND t.wswin = 'Y' AND t.yearid >= 1970 AND t.yearid <=2016 - -- % of time has both highest wins and won world series

/* Q7 Answer: 
A. 2001/SEA/116 wins
B. 1981/LAN/63 -- MLB strike in 1981, 713 games cancelled
C. Excluding 1981, 2006/SLN/83 wins
D. 50 times - Walkthrough Answer: should be 12 times, I left out the 1970 - 2016 filter
E. 11.16% -- Walthrough answer: should be 26% bc of leaving out year filter above. Haven't fixed code yet. */

--Q8 Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT *
FROM homegames;

SELECT *
FROM teams;

SELECT *
FROM parks;

SELECT park, SUM(games)
FROM homegames
GROUP BY park; 

SELECT team, park, SUM(attendance)/SUM(games) AS avg_attendance
FROM homegames
WHERE year = 2016
GROUP BY team, park
ORDER BY avg_attendance DESC
LIMIT 5 --attendance per game per team


SELECT h.team, t.name, h.park, p.park_name, SUM(h.attendance)/SUM(h.games) AS avg_attendance
FROM homegames as h
LEFT JOIN teams AS t
   ON h.team = t.teamid
LEFT JOIN parks AS p
    ON h.park = p.park
WHERE year = 2016
GROUP BY h.team, t.name, h.park, p.park_name
ORDER BY avg_attendance DESC
LIMIT 5 --attendance per game per team


SELECT h.team, t.name, h.park, p.park_name, SUM(h.attendance)/SUM(h.games) AS avg_attendance
FROM homegames as h
LEFT JOIN teams AS t
   ON h.team = t.teamid
LEFT JOIN parks AS p
    ON h.park = p.park
WHERE year = 2016
--     AND t.name != 'St. Louis Browns'
--     AND t.name != 'St. Louis Perfectos'
GROUP BY h.team, t.name, h.park, p.park_name
ORDER BY avg_attendance DESC
LIMIT 5 --attendance per game per team with STL names deduped


WITH total_games_per_park AS
(SELECT park, year, SUM(games) AS park_games
FROM homegames
GROUP BY park, year
HAVING SUM(games) > 9 AND year = 2016)

SELECT h.team, t.name, h.park, p.park_name, SUM(h.attendance)/SUM(h.games) AS avg_attendance, MIN(park_games)
FROM homegames as h
LEFT JOIN teams AS t
   ON h.team = t.teamid and h.year = t.yearid
LEFT JOIN parks AS p
    ON h.park = p.park
INNER JOIN total_games_per_park
    on total_games_per_park.park = h.park
WHERE h.year = 2016
--     AND t.name != 'St. Louis Browns'
--     AND t.name != 'St. Louis Perfectos'
GROUP BY h.team, t.name, h.park, p.park_name, park_games
ORDER BY avg_attendance DESC
LIMIT 5 --qUERY FOR TOP 5 AVG



WITH total_games_per_park AS
(SELECT park, year, SUM(games) AS park_games
FROM homegames
GROUP BY park, year
HAVING SUM(games) > 9 AND year = 2016)

SELECT h.team, 
    (CASE WHEN t.name LIKE 'Cleveland%' THEN 'Cleveland Indians' 
    WHEN t.name LIKE 'Tampa%' THEN 'Tampa Bay Rays'
    WHEN t.name LIKE 'St. Louis%' THEN 'St. Louis Cardinals'
    ELSE t.name
    END) AS name_corrected,
    h.park, p.park_name, SUM(h.attendance)/SUM(h.games) AS avg_attendance, MIN(park_games)
FROM homegames as h
LEFT JOIN teams AS t
   ON h.team = t.teamid
LEFT JOIN parks AS p
    ON h.park = p.park
INNER JOIN total_games_per_park
    on total_games_per_park.park = h.park
WHERE h.year = 2016
    AND t.name != 'St. Louis Browns'
    AND t.name != 'St. Louis Perfectos'
    AND t.name != 'Tampa Bay Rays'
    AND t.name != 'Cleveland Naps'
GROUP BY h.team, name_corrected, h.park, p.park_name, park_games
ORDER BY avg_attendance ASC
LIMIT 5 --Query for bottom 5 avg

--Q8 Answer: In last two codes

--Q9 Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH al_team_name AS
(SELECT DISTINCT t.teamid, m.playerid, am.lgid, am.yearid, am.awardid, t.name
FROM teams AS t
LEFT JOIN managers AS m
USING (teamid)
INNER JOIN awardsmanagers as am
ON m.playerid = am.playerid AND m.yearid = am.yearid
WHERE am.lgid = 'AL' AND am.awardid = 'TSN Manager of the Year'),

nl_team_name AS
(SELECT DISTINCT t.teamid, m.playerid, am.lgid, am.yearid, am.awardid, t.name
FROM teams AS t
LEFT JOIN managers AS m
ON t.teamid = m.teamid AND t.yearid = m.yearid
INNER JOIN awardsmanagers as am
ON m.playerid = am.playerid AND m.yearid = am.yearid
WHERE am.lgid = 'NL' AND am.awardid = 'TSN Manager of the Year')

SELECT DISTINCT a2.playerid, CONCAT(p.namefirst,' ',p.namelast) AS full_name, a2.awardid, a2.yearid AS NL_year, nltn.name AS NL_team_name, a2.lgid, a3.yearid AS AL_year, altn.name AS al_team_name, a3.lgid
FROM awardsmanagers AS a1
JOIN awardsmanagers AS a2
ON a1.playerid = a2.playerid AND a2.lgid = 'NL'
JOIN awardsmanagers AS a3
ON a2.playerid = a3.playerid AND a3.lgid = 'AL'
LEFT JOIN people as p
ON a1.playerid = p.playerid 
LEFT JOIN al_team_name as altn
ON altn.playerid = a3.playerid
LEFT JOIN nl_team_name as nltn
ON nltn.playerid = a2.playerid
WHERE a2.awardid = 'TSN Manager of the Year' AND a3.awardid = 'TSN Manager of the Year' --- FINAL CODE FOR ANSWER AFTER WHAT SEEMED LIKE 17 HOURS Walkthrough Anser: Still got it wrong. Had to add an additional key for yearid to remove the duplicates I didn't notice were there. 

-- Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


WITH ten_yr_played AS
(SELECT playerid, p.debut, p.finalgame, DATE_PART('year',TO_DATE(p.finalgame, 'YYYY MM DD')::date) - DATE_PART('year',TO_DATE(p.debut, 'YYYY MM DD')::date) AS years_played
FROM batting
LEFT JOIN people as p
USING(playerid)
GROUP BY playerid, p.debut, p.finalgame
HAVING DATE_PART('year',TO_DATE(p.finalgame, 'YYYY MM DD')::date) - DATE_PART('year',TO_DATE(p.debut, 'YYYY MM DD')::date) > 9),

career_high_hr AS
(SELECT playerid, MAX(hr) AS career_high
FROM
    (SELECT yearid, playerid, sum(hr) AS hr
    FROM batting
    GROUP BY yearid, playerid) AS sq
 GROUP BY playerid),

season_hr_table AS
(SELECT DISTINCT yearid, playerid, SUM(hr) AS season_hr
 FROM batting
 WHERE yearid = 2016
GROUP BY yearid, playerid)


SELECT b.yearid, b.playerid, CONCAT(p.namefirst,' ',p.namelast) AS full_name, sht.season_hr, chh.career_high  
FROM batting as b
INNER JOIN ten_yr_played AS typ
USING (playerid)
LEFT JOIN career_high_hr AS chh
USING (playerid)
LEFT JOIN season_hr_table AS sht
USING (playerid)
INNER JOIN people as p
USING (playerid)
WHERE b.yearid = 2016 AND sht.season_hr = chh.career_high AND sht.season_hr != 0
GROUP BY b.yearid, playerid, full_name, sht.season_hr, chh.career_high -- final code for answer

-- Q11 Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.


