-- ============================================================
-- Belgium Labour Market Analysis
-- Author: Oussama Achraf
-- Data sources: 
--   - Statbel Labour Force Survey (HVD open data)
--   - Eurostat LFS: Employment by country of birth (lfsa_ergacob)
--   - Eurostat LFS: Employment by origin, education and region (lfst_r_lfe2emprc)
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


-- ------------------------------------------------------------
-- QUERY 6: Does education close the origin gap? (Belgium, 2024)
-- Question: Is the employment gap between native and non-EU born workers
-- larger or smaller for highly educated workers?
-- ------------------------------------------------------------
SELECT 
    year,
    isced11,
    ROUND(CAST(MAX(CASE WHEN c_birth = 'NAT' THEN employment_rate END) AS REAL), 1) AS native,
    ROUND(CAST(MAX(CASE WHEN c_birth = 'NEU27_2020_FOR' THEN employment_rate END) AS REAL), 1) AS non_eu,
    ROUND(CAST(MAX(CASE WHEN c_birth = 'NAT' THEN employment_rate END) AS REAL) - 
          CAST(MAX(CASE WHEN c_birth = 'NEU27_2020_FOR' THEN employment_rate END) AS REAL), 1) AS gap_pp
FROM eurostat_employment_origin_education
WHERE geo = 'BE'
    AND sex = 'T'
    AND isced11 IN ('ED0-2', 'ED3_4', 'ED5-8')
    AND year = '2024'
GROUP BY year, isced11
ORDER BY isced11;

-- Finding: The gap widens with education level rather than closing.
-- Low education: 3.8pp gap. Medium: 10.9pp. High (tertiary): 13.1pp.
-- This is counterintuitive — education benefits native-born workers
-- disproportionately. A highly educated non-EU born worker still faces
-- a 13pp employment disadvantage relative to a native-born peer.
-- This suggests the barriers are structural (networks, discrimination,
-- credential recognition) rather than purely about qualifications.


-- ------------------------------------------------------------
-- QUERY 7: Education-origin gap by Belgian region (2024)
-- Question: Does the education-origin gap pattern hold across all
-- three Belgian regions, or is it specific to certain areas?
-- ------------------------------------------------------------
SELECT 
    geo,
    isced11,
    ROUND(CAST(MAX(CASE WHEN c_birth = 'NAT' THEN employment_rate END) AS REAL), 1) AS native,
    ROUND(CAST(MAX(CASE WHEN c_birth = 'NEU27_2020_FOR' THEN employment_rate END) AS REAL), 1) AS non_eu,
    ROUND(CAST(MAX(CASE WHEN c_birth = 'NAT' THEN employment_rate END) AS REAL) - 
          CAST(MAX(CASE WHEN c_birth = 'NEU27_2020_FOR' THEN employment_rate END) AS REAL), 1) AS gap_pp
FROM eurostat_employment_origin_education
WHERE sex = 'T'
    AND isced11 IN ('ED0-2', 'ED3_4', 'ED5-8')
    AND year = '2024'
    AND geo IN ('BE', 'BE10', 'BE2', 'BE3')
GROUP BY geo, isced11
ORDER BY geo, isced11;

-- Finding: The widening gap pattern holds across Flanders and Wallonia.
-- Flanders: 3.0pp (low) to 7.8pp (medium) to 12.1pp (high).
-- Wallonia: 3.0pp (low) to 13.3pp (medium) to 13.6pp (high).
-- Brussels is the exception: at medium education, non-EU workers
-- actually outperform native-born workers by 5.1pp, likely reflecting
-- Brussels' concentration of EU institutions and international
-- organisations where foreign-born workers find more opportunities.
