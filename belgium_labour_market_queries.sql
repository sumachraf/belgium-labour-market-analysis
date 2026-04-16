-- ============================================================
-- Belgium Labour Market Analysis
-- Author: Oussama Achraf
-- Data sources: 
--   - Statbel Labour Force Survey (HVD open data)
--   - Eurostat LFS: Employment by country of birth (lfsa_ergacob)
--   - Eurostat LFS: Employment by migration status (lfsa_erganedm)
-- ============================================================


-- ------------------------------------------------------------
-- QUERY 1: Belgium employment gap — native vs non-EU born (2015–2024)
-- Question: How has the employment rate differed between native-born
-- and non-EU-born workers in Belgium over the past decade?
-- ------------------------------------------------------------
SELECT 
    year,
    c_birth,
    ROUND(CAST(employment_rate AS REAL), 1) AS emp_rate
FROM eurostat_employment_by_birth
WHERE geo = 'BE'
    AND sex = 'T'
    AND c_birth IN ('NAT', 'NEU27_2020_FOR')
ORDER BY year, c_birth;

-- Finding: Non-EU-born workers in Belgium consistently face employment
-- rates 15-21 percentage points lower than native-born workers.
-- The gap has persisted across all years with no sustained narrowing.


-- ------------------------------------------------------------
-- QUERY 2: Explicit gap calculation by year
-- Question: How large is the employment gap in each year, and
-- has it been improving or worsening over time?
-- ------------------------------------------------------------
SELECT 
    nat.year,
    nat.emp_rate AS native_born,
    neu.emp_rate AS non_eu_born,
    ROUND(nat.emp_rate - neu.emp_rate, 1) AS gap_pp
FROM (
    SELECT year, ROUND(CAST(employment_rate AS REAL), 1) AS emp_rate
    FROM eurostat_employment_by_birth
    WHERE geo = 'BE' AND sex = 'T' AND c_birth = 'NAT'
) nat
JOIN (
    SELECT year, ROUND(CAST(employment_rate AS REAL), 1) AS emp_rate
    FROM eurostat_employment_by_birth
    WHERE geo = 'BE' AND sex = 'T' AND c_birth = 'NEU27_2020_FOR'
) neu ON nat.year = neu.year
ORDER BY nat.year;

-- Finding: The gap narrowed from 20.8pp in 2015-2016 to 17.8pp in 2018,
-- then widened again to 20.3pp during COVID in 2020. By 2024 it stood
-- at 15.4pp — an improvement, but still among the largest in the EU.


-- ------------------------------------------------------------
-- QUERY 3: European ranking — which countries have the largest gap?
-- Question: How does Belgium compare to other EU countries in terms
-- of the employment gap between native and non-EU-born workers?
-- ------------------------------------------------------------
SELECT 
    nat.geo,
    ROUND(nat.emp_rate - neu.emp_rate, 1) AS gap_pp
FROM (
    SELECT geo, ROUND(CAST(employment_rate AS REAL), 1) AS emp_rate
    FROM eurostat_employment_by_birth
    WHERE year = '2024' AND sex = 'T' AND c_birth = 'NAT'
) nat
JOIN (
    SELECT geo, ROUND(CAST(employment_rate AS REAL), 1) AS emp_rate
    FROM eurostat_employment_by_birth
    WHERE year = '2024' AND sex = 'T' AND c_birth = 'NEU27_2020_FOR'
) neu ON nat.geo = neu.geo
WHERE nat.emp_rate IS NOT NULL AND neu.emp_rate IS NOT NULL
ORDER BY gap_pp DESC;

-- Finding: Belgium ranks 2nd in Europe for the largest employment gap
-- between native-born and non-EU-born workers in 2024 (15.4pp),
-- behind only the Netherlands (16.5pp).


-- ------------------------------------------------------------
-- QUERY 4: Education effect by Belgian province (2024)
-- Question: Does education level improve employment prospects equally
-- across all Belgian provinces?
-- ------------------------------------------------------------
SELECT 
    CD_YEAR,
    TX_NUTS_LVL2_DESCR_EN AS region,
    ROUND(CAST(MAX(CASE WHEN CD_ISCED_2011 = '5-8' THEN MS_VALUE END) AS REAL) * 100, 1) AS high_edu,
    ROUND(CAST(MAX(CASE WHEN CD_ISCED_2011 = '0' THEN MS_VALUE END) AS REAL) * 100, 1) AS low_edu,
    ROUND((CAST(MAX(CASE WHEN CD_ISCED_2011 = '5-8' THEN MS_VALUE END) AS REAL) - 
           CAST(MAX(CASE WHEN CD_ISCED_2011 = '0' THEN MS_VALUE END) AS REAL)) * 100, 1) AS edu_gap
FROM TF_HVD_LFS_EMPLOYMENT
WHERE CD_SEX = 'TOTAL'
    AND CD_QUARTER = 'TOTAL'
    AND TX_NUTS_LVL2_DESCR_EN != 'Total'
    AND CD_EMPMT_AGE = 'TOTAL'
    AND CD_YEAR = '2024'
GROUP BY CD_YEAR, region
ORDER BY edu_gap DESC;

-- Finding: The education premium is large across all provinces (55-67pp
-- gap between low and high education). However, high-education rates are
-- relatively uniform (82-88%), while low-education rates vary significantly
-- (19-30%). The gap is driven primarily by how poorly low-educated workers
-- fare, not by how well high-educated workers do.


-- ------------------------------------------------------------
-- QUERY 5: Belgium vs neighbouring countries (2024)
-- Question: How does Belgium compare to France, Germany, Netherlands
-- and Luxembourg for both native and non-EU born workers?
-- ------------------------------------------------------------
SELECT 
    geo,
    ROUND(CAST(employment_rate AS REAL), 1) AS emp_rate,
    c_birth
FROM eurostat_employment_by_birth
WHERE year = '2024'
    AND sex = 'T'
    AND geo IN ('BE', 'NL', 'DE', 'FR', 'LU')
    AND c_birth IN ('NAT', 'NEU27_2020_FOR')
ORDER BY c_birth, emp_rate DESC;

-- Finding: Belgium's native-born employment rate (74.8%) is the lowest
-- among its direct neighbours, sitting below France (76.8%), Germany
-- (84.1%) and Netherlands (85.9%). This suggests Belgium faces broader
-- structural labour market challenges beyond the origin gap alone,
-- relevant to the government's 80% employment target by 2029.
