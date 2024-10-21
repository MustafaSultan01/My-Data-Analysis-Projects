-- Bellabeat Case Study Analysis

-- Total Distinct ID's for each table used:
SELECT 'daily_activity' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.daily_activity
UNION
SELECT 'heartrate_seconds_merged' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.heartrate_seconds_merged
UNION
SELECT 'hourly_calories' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.hourly_calories
UNION
SELECT 'hourly_intensity' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.hourly_intensity
UNION
SELECT 'hourly_steps' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.hourly_steps
UNION
SELECT 'sleep_day' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.sleep_day
UNION
SELECT 'weight_log' AS TableName, count(DISTINCT(Id)) AS DistinctCount FROM project_tables.weight_log ;

# We can't use "heartrate_seconds_merged" & "weight_log" table for our analysis as the number of users isn't desirable. 


-- 1. Number of times users use Fitbit Tracker in 2 months + 2 days (i.e 62 days):
WITH Count_Users AS (
SELECT Id, COUNT(Id) AS Total_Id
FROM project_tables.daily_activity
GROUP BY Id ) ,

Tracking AS (
SELECT Total_Id AS Number_of_times_logged_Data, COUNT(Total_Id) AS Number_of_Users,
	CASE
		WHEN Total_Id >= 45 THEN "Active Tracking Users"
        WHEN Total_Id BETWEEN 25 AND 44 THEN "Moderate Tracking Users"
        WHEN Total_Id < 25 THEN "Low Tracking Users"
	END AS Tracking_Users
FROM Count_Users
WHERE Total_Id <= 62
GROUP BY Total_Id
ORDER BY Number_of_times_logged_Data DESC )

SELECT Tracking_Users, SUM(Number_of_Users) AS Total_Users
FROM Tracking
GROUP BY Tracking_Users ;


-- 2. Proportion of Calories Per Distance by Day
SELECT ActivityDay AS WeekDays, 
	COALESCE(SUM(CAST(Calories AS DOUBLE)), 0) AS CaloriesPerDay,   -- casting calorie as double to ensure consistency & avoid type mismatch
	ROUND(COALESCE(SUM(CAST(TotalDistance AS DOUBLE)), 0), 2) AS DistancePerDay,
	ROUND((COALESCE(SUM(CAST(Calories AS DOUBLE)), 0) / COALESCE(SUM(CAST(TotalDistance AS DOUBLE)), 0)), 2) AS CaloriesPerDistance
FROM project_tables.daily_activity 
GROUP BY WeekDays
ORDER BY
  CASE WeekDays
      WHEN 'Sunday' THEN 1
      WHEN 'Monday' THEN 2
      WHEN 'Tuesday' THEN 3
      WHEN 'Wednesday' THEN 4
      WHEN 'Thursday' THEN 5
      WHEN 'Friday' THEN 6 
      WHEN 'Saturday' THEN 7
  END ;
  
  
-- 3. Average Steps per hour:
# LPAD() ensures single digit hours are displayed as 2-digit hours with leading zero. 
SELECT LPAD(HOUR(ActivityHour), 2, '0') AS active_hour, 
	ROUND(AVG(Total_Steps), 0) AS avg_steps_per_hour
FROM project_tables.hourly_steps
GROUP BY active_hour
ORDER BY active_hour asc ;


-- 4. Total Steps and Distance by Id:
SELECT Id, SUM(TotalSteps) AS Total_Steps, ROUND(SUM(TotalDistance), 2) AS Total_Distance,
	ROUND((SUM(TotalSteps) / SUM(TotalDistance)), 2) AS Steps_per_Distance
FROM project_tables.daily_activity
GROUP BY Id ;


-- 5. Average Sleep duration (in hours) by Days:
SELECT da.ActivityDay AS WeekDays, AVG(sd.Total_Minutes_Asleep) AS Avg_ASleep,
	ROUND((AVG(sd.Total_Minutes_Asleep)/60), 1) AS Hours_Asleep
FROM project_tables.daily_activity da INNER JOIN project_tables.sleep_day sd
	ON da.`Date` = sd.Sleep_Date
GROUP BY WeekDays
ORDER BY 
	CASE WeekDays
    WHEN 'Sunday' THEN 1
    WHEN 'Monday' THEN 2
    WHEN 'Tuesday' THEN 3
    WHEN 'Wednesday' THEN 4
    WHEN 'Thursday' THEN 5
    WHEN 'Friday' THEN 6
    WHEN 'Saturday' THEN 7
END ;


-- 6. Correlation of Steps & Active Minutes (Walking or doing other tasks?):
SELECT TotalSteps,
	SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes + SedentaryMinutes) AS TotalMinutes_Tracking,
	SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS ActiveMinutes,
    SUM(SedentaryMinutes) AS InactiveMinutes
FROM project_tables.daily_activity 
WHERE TotalSteps IS NULL OR TotalSteps > 0
GROUP BY TotalSteps
ORDER BY TotalSteps asc ;


-- 7. Correlation of Sleep with ActiveMinutes by Days:
SELECT da.ActivityDay AS WeekDays, 
	ROUND(AVG(sd.Total_Minutes_Asleep),0) AS Avg_Sleep_Minutes,
    ROUND(AVG(da.VeryActiveMinutes + da.FairlyActiveMinutes + da.LightlyActiveMinutes), 0) AS Avg_Active_Minutes,
    ROUND(AVG(da.SedentaryMinutes), 0) AS Avg_Inactive_Minutes
FROM project_tables.daily_activity da INNER JOIN project_tables.sleep_day sd
	ON da.`Date` = sd.Sleep_Date
GROUP BY WeekDays
ORDER BY
	CASE WeekDays
		WHEN 'Sunday' THEN 1
        WHEN 'Monday' THEN 2
        WHEN 'Tuesday' THEN 3
        WHEN 'Wedday' THEN 4
        WHEN 'Thursday' THEN 5
        WHEN 'Friday' THEN 6
        WHEN 'Saturday' THEN 7
	END ;


-- 8. Count of Type of Users based on Number of Steps:
WITH total_users AS (
SELECT Id, ROUND(AVG(TotalSteps), 0) AS Avg_Total_Steps,
	CASE
		WHEN ROUND(AVG(TotalSteps), 0) < 5000 THEN "Inactive User"
        WHEN ROUND(AVG(TotalSteps), 0) BETWEEN 5000 AND 7499 THEN "Low Active User"
        WHEN ROUND(AVG(TotalSteps), 0) BETWEEN 7500 AND 9999 THEN "Average Active User"
        WHEN ROUND(AVG(TotalSteps), 0) BETWEEN 10000 AND 12499 THEN "Active User"
        WHEN ROUND(AVG(TotalSteps), 0) > 12500 THEN "Very Active User"
	END AS User_Type
FROM project_tables.daily_activity 
GROUP BY Id )

SELECT User_Type, COUNT(Id) AS User_Count
FROM total_users
GROUP BY User_Type 
ORDER BY User_Count ASC ;


-- 9. Total Steps by Hour:
SELECT TIME(ActivityHour), SUM(Total_Steps) AS TotalSteps
FROM project_tables.hourly_steps
GROUP BY TIME(ActivityHour)
ORDER BY TotalSteps DESC ;

-- 10. Most Active Steps Day:
SELECT ActivityDay AS Weekdays, ROUND(AVG(TotalSteps), 2) AS Avg_Daily_Steps
FROM project_tables.daily_activity
GROUP BY Weekdays
ORDER BY Avg_Daily_Steps DESC ;
