--- Create Database

CREATE DATABASE healthcare_project;
USE healthcare_project;

-- Create Table
CREATE TABLE healthcare_data (
    Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(10),
    Blood_Type VARCHAR(5),
    Medical_Condition VARCHAR(50),
    Date_of_Admission DATE,
    Doctor VARCHAR(100),
    Hospital VARCHAR(100),
    Insurance_Provider VARCHAR(50),
    Billing_Amount DECIMAL(15, 2),
    Room_Number INT,
    Admission_Type VARCHAR(20),
    Discharge_Date DATE,
    Medication VARCHAR(50),
    Test_Results VARCHAR(20)
);

-- Load data into the data (manually or import through Data import wizard)
SELECT * FROM healthcare;

SELECT COUNT(*) FROM healthcare;

-- Modify column name
ALTER TABLE healthcare
RENAME COLUMN `Blood Type` TO Blood_Type,
RENAME COLUMN `Medical Condition` TO Medical_Condition,
RENAME COLUMN `Date of Admission` TO Date_of_Admission,
RENAME COLUMN `Insurance Provider` TO Insurance_Provider,
RENAME COLUMN `Billing Amount` TO Billing_Amount,
RENAME COLUMN `Room Number` TO Room_Number,
RENAME COLUMN `Admission Type` TO Admission_Type,
RENAME COLUMN `Discharge Date` TO Discharge_Date,
RENAME COLUMN `Test Results` TO Test_Results;


---- Data Cleaning

--- a. Checking for Duplicates
SELECT Name, Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission, Doctor, Hospital, 
       Insurance_Provider, Billing_Amount, Room_Number, Admission_Type, Discharge_Date, 
       Medication, Test_Results, COUNT(*) as duplicate_count
FROM healthcare
GROUP BY Name, Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission, Doctor, Hospital, 
         Insurance_Provider, Billing_Amount, Room_Number, Admission_Type, Discharge_Date, 
         Medication, Test_Results
HAVING duplicate_count > 1;

--- Standardize Categorical Data

SET SQL_SAFE_UPDATES = 0;


-- Gender: Should be "Male" or "Female"
UPDATE healthcare
SET Gender = CONCAT(UPPER(LEFT(Gender, 1)), LOWER(SUBSTRING(Gender, 2)))
WHERE Gender IN ('male', 'female', 'Male', 'Female', 'MALE', 'FEMALE');

-- Medical Condition: Standardize capitalization.
UPDATE healthcare
SET Medical_Condition = CONCAT(UPPER(LEFT(Medical_Condition, 1)), 
                               LOWER(SUBSTRING(Medical_Condition, 2)));
                               
-- Doctor Names: Similar standardization.
UPDATE healthcare
SET Doctor = CONCAT(UPPER(LEFT(Doctor, 1)), LOWER(SUBSTRING(Doctor, 2)));
                               
--- Handle Missing Values
-- a. Check for NULLs
SELECT *
FROM healthcare
WHERE Name IS NULL OR Age IS NULL OR Gender IS NULL OR Medical_Condition IS NULL;

-- b. Decide how to handle them (e.g., remove rows, impute values). For now, let’s flag them
ALTER TABLE healthcare ADD COLUMN Data_Issue VARCHAR(50);
UPDATE healthcare
SET Data_Issue = 'Missing Value'
WHERE Name IS NULL OR Age IS NULL OR Gender IS NULL;

-- UPDATE healthcare
UPDATE healthcare
SET Billing_Amount = ABS(Billing_Amount)
WHERE Billing_Amount < 0;

SELECT COUNT(*) FROM healthcare WHERE Billing_Amount < 0;

SELECT DISTINCT Billing_Amount FROM healthcare;

SET SQL_SAFE_UPDATES = 1;

---- EXPLORATORY DATA ANALYSIS

--- A. Patient Demographics & Medical Trends
-- Objective: Analyze patient demographics (gender, age, blood type) and medical conditions.
-- i. Count of Patients by Gender and Age Group
SELECT 
    Gender,
    CASE 
        WHEN Age < 20 THEN 'Under 20'
        WHEN Age BETWEEN 20 AND 39 THEN '20-39'
        WHEN Age BETWEEN 40 AND 59 THEN '40-59'
        WHEN Age >= 60 THEN '60+'
    END AS Age_Group,
    COUNT(*) AS Patient_Count
FROM healthcare
GROUP BY Gender, Age_Group
ORDER BY Gender, Age_Group;

-- ii. Most Common Medical Conditions
SELECT 
    Medical_Condition,
    COUNT(*) AS Condition_Count
FROM healthcare
GROUP BY Medical_Condition
ORDER BY Condition_Count DESC
LIMIT 5;

-- iii. Distribution of Blood Types Among Patients
SELECT 
    Blood_Type,
    COUNT(*) AS Blood_Type_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare), 2) AS Percentage
FROM healthcare
GROUP BY Blood_Type
ORDER BY Blood_Type_Count DESC;

--- B. Hospital & Admission Insights
-- Objective: Analyze hospital performance and admission trends.

-- i. Total Number of Admissions per Hospital
SELECT 
    Hospital,
    COUNT(*) AS Admission_Count
FROM healthcare
GROUP BY Hospital
ORDER BY Admission_Count DESC;

-- ii. Trend of Patient Admissions Over Time
SELECT 
    YEAR(Date_of_Admission) AS Admission_Year,
    MONTH(Date_of_Admission) AS Admission_Month,
    COUNT(*) AS Monthly_Admissions
FROM healthcare
GROUP BY YEAR(Date_of_Admission), MONTH(Date_of_Admission)
ORDER BY Admission_Year, Admission_Month;

-- iii. Average Length of Hospital Stay by Admission Type
SELECT 
    Admission_Type,
    AVG(DATEDIFF(Discharge_Date, Date_of_Admission)) AS Avg_Stay_Days
FROM healthcare
GROUP BY Admission_Type
ORDER BY Avg_Stay_Days DESC;

--- C. Financial Analysis
-- Objective: Evaluate billing and revenue patterns.

-- i. Average Billing per Admission Type
SELECT 
    Admission_Type,
    ROUND(AVG(Billing_Amount), 2) AS Avg_Billing
FROM healthcare
GROUP BY Admission_Type
ORDER BY Avg_Billing DESC;

-- ii. Total Revenue by Hospital and Insurance Provider
SELECT 
    Hospital,
    Insurance_Provider,
    ROUND(SUM(Billing_Amount), 2) AS Total_Revenue
FROM healthcare
GROUP BY Hospital, Insurance_Provider
ORDER BY Total_Revenue DESC;

-- iii. Comparison of Emergency vs Urgent vs Elective Admission Costs
SELECT 
    Admission_Type,
    ROUND(AVG(Billing_Amount), 2) AS Avg_Billing
FROM healthcare
WHERE Admission_Type IN ('Emergency', 'Urgent', 'Elective')
GROUP BY Admission_Type;

--- D. Doctor Performance & Treatment Analysis
-- Objective: Assess doctor performance and medication patterns.

-- i. Number of Patients Treated per Doctor
SELECT 
    Doctor,
    COUNT(*) AS Patient_Count
FROM healthcare
GROUP BY Doctor
ORDER BY Patient_Count DESC
LIMIT 10;

-- ii. Average Hospital Stay per Doctor
SELECT 
    Doctor,
    ROUND(AVG(DATEDIFF(Discharge_Date, Date_of_Admission)), 2) AS Avg_Stay_Days
FROM healthcare
GROUP BY Doctor
ORDER BY Avg_Stay_Days DESC;

-- iii. Most Commonly Prescribed Medications
SELECT 
    Medication,
    COUNT(*) AS Prescription_Count
FROM healthcare
GROUP BY Medication
ORDER BY Prescription_Count DESC
LIMIT 5;

--- E. Test Results & Medication Analysis
-- Objective: Explore test outcomes and their relation to medications.

-- i. Distribution of Test Results
SELECT 
    Test_Results,
    COUNT(*) AS Result_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare), 2) AS Percentage
FROM healthcare
GROUP BY Test_Results
ORDER BY Result_Count DESC;

-- ii. Correlation Between Test Results and Medication Prescribed
SELECT 
    Test_Results,
    Medication,
    COUNT(*) AS Count
FROM healthcare
GROUP BY Test_Results, Medication
ORDER BY Test_Results, Count DESC;
