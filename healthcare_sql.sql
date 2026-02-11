create database Analysis;
use Analysis;

-- Create the main table 
CREATE TABLE patient_admissions (
    patient_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    blood_type VARCHAR(5),
    medical_condition VARCHAR(50),
    date_of_admission DATE,
    doctor VARCHAR(100),
    hospital VARCHAR(200),
    insurance_provider VARCHAR(50),
    billing_amount DECIMAL(10,2),
    room_number INT,
    admission_type VARCHAR(20),
    discharge_date DATE,
    medication VARCHAR(50),
    test_results VARCHAR(20)
);

--  Data quality check - Find records with issues
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN billing_amount < 0 THEN 1 END) as negative_billing,
    COUNT(CASE WHEN age < 0 OR age > 120 THEN 1 END) as invalid_age,
    COUNT(CASE WHEN discharge_date < date_of_admission THEN 1 END) as date_errors
FROM patient_admissions;

-- Clean patient names 
UPDATE patient_admissions
SET name = INITCAP(name);  


-- Create calculated field - Length of Stay
ALTER TABLE patient_admissions 
ADD COLUMN length_of_stay INT;

UPDATE patient_admissions
SET length_of_stay = DATEDIFF(discharge_date, date_of_admission);
-

-- Create age groups for analysis
ALTER TABLE patient_admissions 
ADD COLUMN age_group VARCHAR(20);

UPDATE patient_admissions
SET age_group = CASE 
    WHEN age < 18 THEN 'Minor (0-17)'
    WHEN age BETWEEN 18 AND 35 THEN 'Young Adult (18-35)'
    WHEN age BETWEEN 36 AND 55 THEN 'Middle Age (36-55)'
    WHEN age BETWEEN 56 AND 70 THEN 'Senior (56-70)'
    ELSE 'Elderly (70+)'
END;




-- Overall summary statistics
SELECT 
    COUNT(*) as total_admissions,
    COUNT(DISTINCT name) as unique_patients,
    MIN(date_of_admission) as earliest_admission,
    MAX(date_of_admission) as latest_admission,
    ROUND(AVG(age), 1) as avg_age,
    ROUND(AVG(billing_amount), 2) as avg_billing,
    ROUND(AVG(length_of_stay), 1) as avg_length_of_stay
FROM patient_admissions;

--  Distribution by gender
SELECT 
    gender,
    COUNT(*) as patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_admissions), 2) as percentage,
    ROUND(AVG(age), 1) as avg_age,
    ROUND(AVG(billing_amount), 2) as avg_billing
FROM patient_admissions
GROUP BY gender
ORDER BY patient_count DESC;

-- Medical condition analysis
SELECT 
    medical_condition,
    COUNT(*) as case_count,
    ROUND(AVG(age), 1) as avg_age,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    ROUND(AVG(length_of_stay), 1) as avg_los,
    MIN(billing_amount) as min_cost,
    MAX(billing_amount) as max_cost
FROM patient_admissions
GROUP BY medical_condition
ORDER BY avg_cost DESC;

-- Admission type breakdown
SELECT 
    admission_type,
    COUNT(*) as admission_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_admissions), 2) as percentage,
    ROUND(AVG(billing_amount), 2) as avg_billing,
    ROUND(AVG(length_of_stay), 1) as avg_los
FROM patient_admissions
GROUP BY admission_type
ORDER BY admission_count DESC;




--  Monthly admission trends
SELECT 
    DATE_FORMAT(date_of_admission, '%Y-%m') as admission_month,  
     
     COUNT(*) as admissions,
    ROUND(AVG(billing_amount), 2) as avg_billing
FROM patient_admissions
GROUP BY DATE_FORMAT(date_of_admission, '%Y-%m')
ORDER BY admission_month;

--  Seasonal patterns 
SELECT 
    YEAR(date_of_admission) as year,
    QUARTER(date_of_admission) as quarter,
    COUNT(*) as admissions,
    ROUND(AVG(billing_amount), 2) as avg_billing
FROM patient_admissions
GROUP BY YEAR(date_of_admission), QUARTER(date_of_admission)
ORDER BY year, quarter;

-- Day of week analysis
SELECT 
    DAYNAME(date_of_admission) as day_of_week, 
    
    COUNT(*) as admissions,
    ROUND(AVG(billing_amount), 2) as avg_billing
FROM patient_admissions
GROUP BY DAYNAME(date_of_admission)
ORDER BY admissions DESC;

-- Year-over-year comparison
SELECT 
    YEAR(date_of_admission) as year,
    COUNT(*) as total_admissions,
    ROUND(SUM(billing_amount), 2) as total_revenue,
    ROUND(AVG(billing_amount), 2) as avg_billing_per_admission
FROM patient_admissions
GROUP BY YEAR(date_of_admission)
ORDER BY year;




-- Revenue by insurance provider
SELECT 
    insurance_provider,
    COUNT(*) as claim_count,
    ROUND(SUM(billing_amount), 2) as total_revenue,
    ROUND(AVG(billing_amount), 2) as avg_claim_amount,
    ROUND(MIN(billing_amount), 2) as min_claim,
    ROUND(MAX(billing_amount), 2) as max_claim
FROM patient_admissions
GROUP BY insurance_provider
ORDER BY total_revenue DESC;

-- Query 4.2: High-cost cases (top 10%)
SELECT 
    name,
    age,
    medical_condition,
    admission_type,
    billing_amount,
    length_of_stay
FROM patient_admissions
WHERE billing_amount >= (SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY billing_amount)
                         FROM patient_admissions)
ORDER BY billing_amount DESC;

-- Cost analysis by age group
SELECT 
    age_group,
    COUNT(*) as patient_count,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    ROUND(SUM(billing_amount), 2) as total_cost
FROM patient_admissions
GROUP BY age_group
ORDER BY 
    CASE age_group
        WHEN 'Minor (0-17)' THEN 1
        WHEN 'Young Adult (18-35)' THEN 2
        WHEN 'Middle Age (36-55)' THEN 3
        WHEN 'Senior (56-70)' THEN 4
        WHEN 'Elderly (70+)' THEN 5
    END;

-- Medical condition vs admission type 
SELECT 
    medical_condition,
    admission_type,
    COUNT(*) as cases,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    ROUND(SUM(billing_amount), 2) as total_cost
FROM patient_admissions
GROUP BY medical_condition, admission_type
ORDER BY medical_condition, avg_cost DESC;




-- Test results distribution
SELECT 
    test_results,
    COUNT(*) as result_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_admissions), 2) as percentage
FROM patient_admissions
GROUP BY test_results
ORDER BY result_count DESC;

-- Test results by medical condition
SELECT 
    medical_condition,
    test_results,
    COUNT(*) as case_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY medical_condition), 2) as pct_within_condition
FROM patient_admissions
GROUP BY medical_condition, test_results
ORDER BY medical_condition, case_count DESC;

-- Medication usage analysis
SELECT 
    medication,
    COUNT(*) as prescription_count,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    COUNT(DISTINCT medical_condition) as conditions_treated
FROM patient_admissions
GROUP BY medication
ORDER BY prescription_count DESC;

-- Length of stay by medical condition and admission type
SELECT 
    medical_condition,
    admission_type,
    COUNT(*) as cases,
    ROUND(AVG(length_of_stay), 1) as avg_los,
    MIN(length_of_stay) as min_los,
    MAX(length_of_stay) as max_los
FROM patient_admissions
GROUP BY medical_condition, admission_type
ORDER BY avg_los DESC;




-- Emergency vs Elective admissions comparison
SELECT 
    'Emergency' as category,
    COUNT(*) as total_cases,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    ROUND(AVG(length_of_stay), 1) as avg_los
FROM patient_admissions
WHERE admission_type = 'Emergency'

UNION ALL

SELECT 
    'Elective' as category,
    COUNT(*) as total_cases,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    ROUND(AVG(length_of_stay), 1) as avg_los
FROM patient_admissions
WHERE admission_type = 'Elective';

-- Gender comparison by medical condition
SELECT 
    medical_condition,
    SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) as male_count,
    SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) as female_count,
    ROUND(AVG(CASE WHEN gender = 'Male' THEN billing_amount END), 2) as male_avg_cost,
    ROUND(AVG(CASE WHEN gender = 'Female' THEN billing_amount END), 2) as female_avg_cost
FROM patient_admissions
GROUP BY medical_condition;

-- Top 10 most expensive cases
SELECT 
    name,
    age,
    gender,
    medical_condition,
    admission_type,
    billing_amount,
    length_of_stay,
    insurance_provider
FROM patient_admissions
ORDER BY billing_amount DESC
LIMIT 10;



-- Running total of admissions by month
SELECT 
    DATE_FORMAT(date_of_admission, '%Y-%m') as month,
    COUNT(*) as monthly_admissions,
    SUM(COUNT(*)) OVER (ORDER BY DATE_FORMAT(date_of_admission, '%Y-%m')) as cumulative_admissions
FROM patient_admissions
GROUP BY DATE_FORMAT(date_of_admission, '%Y-%m')
ORDER BY month;

-- Ranking hospitals by average billing
SELECT 
    hospital,
    COUNT(*) as patient_count,
    ROUND(AVG(billing_amount), 2) as avg_billing,
    RANK() OVER (ORDER BY AVG(billing_amount) DESC) as cost_rank
FROM patient_admissions
GROUP BY hospital
HAVING COUNT(*) >= 5  
ORDER BY avg_billing DESC
LIMIT 20;

-- Percentage of abnormal test results by condition
SELECT 
    medical_condition,
    COUNT(*) as total_cases,
    SUM(CASE WHEN test_results = 'Abnormal' THEN 1 ELSE 0 END) as abnormal_count,
    ROUND(SUM(CASE WHEN test_results = 'Abnormal' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as abnormal_percentage
FROM patient_admissions
GROUP BY medical_condition
ORDER BY abnormal_percentage DESC;

-- Cohort analysis - patients by admission year and condition
SELECT 
    YEAR(date_of_admission) as admission_year,
    medical_condition,
    COUNT(*) as patient_count,
    ROUND(AVG(billing_amount), 2) as avg_cost
FROM patient_admissions
GROUP BY YEAR(date_of_admission), medical_condition
ORDER BY admission_year, patient_count DESC;


-- Create view for monthly KPIs
CREATE OR REPLACE VIEW monthly_kpis AS
SELECT 
    DATE_FORMAT(date_of_admission, '%Y-%m') as month,
    COUNT(*) as total_admissions,
    COUNT(CASE WHEN admission_type = 'Emergency' THEN 1 END) as emergency_count,
    ROUND(AVG(billing_amount), 2) as avg_revenue,
    ROUND(SUM(billing_amount), 2) as total_revenue,
    ROUND(AVG(length_of_stay), 1) as avg_los
FROM patient_admissions
GROUP BY DATE_FORMAT(date_of_admission, '%Y-%m');

-- Create view for condition summary
CREATE OR REPLACE VIEW condition_summary AS
SELECT 
    medical_condition,
    COUNT(*) as total_cases,
    ROUND(AVG(age), 1) as avg_patient_age,
    ROUND(AVG(billing_amount), 2) as avg_cost,
    ROUND(AVG(length_of_stay), 1) as avg_los,
    COUNT(CASE WHEN test_results = 'Abnormal' THEN 1 END) as abnormal_results,
    COUNT(CASE WHEN admission_type = 'Emergency' THEN 1 END) as emergency_admissions
FROM patient_admissions
GROUP BY medical_condition;

-- Export data for Excel/BI tools
SELECT 
    pa.*,
    age_group,
    length_of_stay,
    DATE_FORMAT(date_of_admission, '%Y') as admission_year,
    DATE_FORMAT(date_of_admission, '%m') as admission_month,
    QUARTER(date_of_admission) as admission_quarter,
    DAYNAME(date_of_admission) as admission_day
FROM patient_admissions pa
ORDER BY date_of_admission;




