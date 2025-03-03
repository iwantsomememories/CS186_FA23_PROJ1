-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, halloffame.playerID, yearid
  FROM halloffame INNER JOIN people ON halloffame.playerID = people.playerID
  WHERE inducted = "Y"
  ORDER BY yearid DESC, halloffame.playerID ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, q2i.playerid, playerOfCA.schoolID, yearid
  FROM q2i INNER JOIN (SELECT collegeplaying.playerid, collegeplaying.schoolID FROM collegeplaying INNER JOIN schools ON collegeplaying.schoolID = schools.schoolID WHERE schools.schoolState = "CA") as playerOfCA ON q2i.playerid = playerOfCA.playerid
  ORDER BY q2i.yearid DESC, playerOfCA.schoolID ASC, q2i.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerID, p.namefirst, p.namelast, c.schoolID
  FROM halloffame as h LEFT JOIN collegeplaying as c ON h.playerID = c.playerid
  INNER JOIN people AS p on h.playerID = p.playerID
  WHERE h.inducted = "Y"
  ORDER BY p.playerID DESC, c.schoolID ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerID, p.namefirst, p.namelast, b.yearID, ((b.H + b.H2B + 2 * b.H3B + 3 * b.HR) * 1.0 / b.AB) AS slg
  FROM batting as b INNER JOIN people as p ON b.playerID = p.playerID
  WHERE b.AB > 50
  ORDER BY slg DESC, b.yearID ASC, p.playerID ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT b.playerID, p.namefirst, p.namelast, ((SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB)) AS lslg
  FROM batting as b INNER JOIN people as p ON b.playerID = p.playerID
  GROUP BY b.playerID
  HAVING SUM(b.AB) > 50
  ORDER BY lslg DESC, b.playerID ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast, ((SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB)) AS lslg
  FROM batting as b INNER JOIN people as p ON b.playerID = p.playerID
  GROUP BY b.playerID
  HAVING SUM(b.AB) > 50 AND lslg > (SELECT ((SUM(b.H) + SUM(b.H2B) + 2 * SUM(b.H3B) + 3 * SUM(b.HR)) * 1.0 / SUM(b.AB)) FROM batting as b WHERE b.playerID = "mayswi01")
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearID, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearID
  ORDER BY yearID ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH s2016 AS (
    SELECT * FROM salaries
    WHERE yearID = 2016
  ),
  sstats AS (
    SELECT MIN(salary) as mins, MAX(salary) as maxs, (MAX(salary) - MIN(salary)) / 10.0 AS width
    FROM s2016
  ),
  sbinids AS (
    SELECT s2016.salary, MIN(CAST((s2016.salary - sstats.mins) / sstats.width AS INT), 9) AS binid
    FROM s2016, sstats
  )
  SELECT b.binid, (SELECT mins FROM sstats) + b.binid * (SELECT width FROM sstats), (SELECT mins FROM sstats) + (b.binid + 1) * (SELECT width FROM sstats), COUNT(*)
  FROM binids AS b LEFT JOIN sbinids AS s ON b.binid = s.binid 
  GROUP BY b.binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH sstats(yearID, mins, maxs, avgs) AS (
    SELECT yearID, MIN(salary), MAX(salary), AVG(salary)
    FROM salaries
    GROUP BY yearID
  )
  SELECT a.yearID, a.mins - b.mins, a.maxs - b.maxs, a.avgs - b.avgs
  FROM sstats AS a INNER JOIN sstats AS b ON a.yearID = b.yearID + 1
  ORDER BY a.yearID ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH salaries_of_twoyears AS (
    SELECT * 
    FROM salaries
    WHERE yearID = 2000 OR yearID = 2001
  ),
  max_salary(yearID, peak) AS (
    SELECT yearID, MAX(salary)
    FROM salaries_of_twoyears
    GROUP BY yearID
  )
  SELECT s.playerID, p.namefirst, p.namelast, s.salary, s.yearID
  FROM salaries_of_twoyears AS s 
  INNER JOIN people AS p ON s.playerID = p.playerID
  INNER JOIN max_salary AS m ON s.yearID = m.yearID
  WHERE s.salary = m.peak
  ORDER BY s.yearID ASC
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  WITH team_2016 AS (
    SELECT * 
    FROM teams
    WHERE yearID = 2016
  ),
  salary_2016 AS (
    SELECT *
    FROM salaries
    WHERE yearID = 2016
  ),
  allstar_2016 AS (
    SELECT *
    FROM allstarfull
    WHERE yearID = 2016
  )
  SELECT t.teamID, (MAX(s.salary) - MIN(s.salary))
  FROM team_2016 AS t 
  INNER JOIN allstar_2016 AS a ON t.teamID = a.teamID
  INNER JOIN salary_2016 AS s ON a.playerID = s.playerID
  GROUP BY t.teamID
;

