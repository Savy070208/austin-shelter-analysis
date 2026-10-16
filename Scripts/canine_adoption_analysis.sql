-- PROJECT: Austin Animal Center Canine Adoption Analysis
-- AUTHOR: Savyansh Srivastava
-- DATE: October 2026


-- Table Verification & Row Counts
-- Purpose: Confirm successful import of tables and verify via row count
SELECT 'intakes' AS table_name, COUNT(*) AS total_rows 
FROM `capstone-shelter-analysis.austin_canine_shelter.canine_intake`
UNION ALL
SELECT 'outcomes' AS table_name, COUNT(*) AS total_rows 
FROM `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`;


-- Outcome Status Analysis
-- Purpose: Calculate total count and share of all canine outcome statuses (e.g., Adopted, Euthanized, Transferred, etc.)
SELECT 
  outcome_status,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
GROUP BY 
  outcome_status
ORDER BY 
  total_dogs DESC;


-- Outcome Status Categorization
-- Purpose: Categorize 26 outcome statuses into 5 standardized categories and calculate percentage share of each category
SELECT 
  CASE 
    WHEN outcome_status LIKE '%Adopted%' THEN 'Adopted'
    WHEN outcome_status LIKE '%Transfer%' THEN 'Transfer Out'
    WHEN outcome_status LIKE '%Reclaimed%' 
      OR outcome_status LIKE '%Returned%' 
      OR outcome_status LIKE '%Redemption%' THEN 'Return to Owner'
    WHEN outcome_status LIKE '%Euthan%' THEN 'Euthanasia'
    ELSE 'Other / Died in Care'
  END AS outcome_categories,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
GROUP BY 
  1
ORDER BY 
  total_dogs DESC;

-- Adoption Length of Stay (LOS) Metrics
-- Purpose: Calculate baseline metrics for length of stay (LOS) for adopted dogs, including total adoptions, average LOS, median LOS, minimum LOS, and maximum LOS.
SELECT 
  COUNT(*) AS total_adoptions,
  ROUND(AVG(days_in_shelter), 1) AS avg_los_days,
  APPROX_QUANTILES(days_in_shelter, 100)[OFFSET(50)] AS median_los_days,
  MIN(days_in_shelter) AS min_days,
  MAX(days_in_shelter) AS max_days
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
WHERE 
  outcome_status LIKE '%Adopted%';

-- Purpose: Categorize adopted dogs into length of stay (LOS) tiers and calculate total count and percentage share of each tier.
SELECT 
  CASE WHEN 
  days_in_shelter <= 7 THEN "0-7 days (Short-Term)"
  WHEN days_in_shelter <= 30 THEN "8-30 days (Average)"
  WHEN days_in_shelter <= 90 THEN "31-90 days (Extended Stay)"
  ELSE "90+ days (Long-Term)"
  END AS los_tiers,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percent_share
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
WHERE
  outcome_status LIKE "%Adopted%"
GROUP BY los_tiers
ORDER BY percent_share DESC

-- Canine Demographic Influence on LOS for Adopted Dogs
-- Purpose: Determine the significane of having a name on the LOS of adopted dogs (calculating total dogs, percentage share, average LOS and median LOS)
SELECT 
  has_name,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percent_share,
  ROUND(AVG(days_in_shelter), 1) AS los,
  APPROX_QUANTILES(days_in_shelter,100)[OFFSET(50)] AS median_los_days
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
WHERE
  outcome_status LIKE "%Adopted%"
GROUP BY
  has_name

-- Purpose: Determine the significance of sex on the LOS of adopted dogs (calculating total dogs, percentage share, average LOS and median LOS)
SELECT 
  sex,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percent_share,
  ROUND(AVG(days_in_shelter), 1) AS avg_los,
  APPROX_QUANTILES(days_in_shelter,100)[OFFSET(50)] AS median_los_days
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
WHERE
  outcome_status LIKE "%Adopted%"
GROUP BY
  sex

-- Purpose: Determine the significance of sterilization status on the LOS of adopted dogs
SELECT 
  INITCAP(spayed_neutered) AS spayed_neutered, -- Dataset had inconsistent capitalization for this column
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percent_share,
  ROUND(AVG(days_in_shelter), 1) AS avg_los,
  APPROX_QUANTILES(days_in_shelter, 100)[OFFSET(50)] AS median_los_days
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
WHERE
  outcome_status LIKE "%Adopted%"
GROUP BY 
  INITCAP(spayed_neutered);

-- Purpose: Determine the significance of `age_bracket` on the LOS of adopted dogs (calculating total dogs, percentage share, average LOS and median LOS)
SELECT 
  outcome_age_bracket,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percent_share,
  ROUND(AVG(days_in_shelter), 1) AS avg_los,
  APPROX_QUANTILES(days_in_shelter,100)[OFFSET(50)] AS median_los_days
FROM 
  `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
WHERE
  outcome_status LIKE "%Adopted%"
GROUP BY
  outcome_age_bracket
ORDER BY
  avg_los DESC

-- Analysis of Non-Adoption Outcomes
-- Purpose: Categorize non-adoption outcomes into 4 categories (Return to Owner, Transfer Out, Non-Live (Euthanasia/Death), Other)
WITH categorized_outcomes AS (
  SELECT 
    animal_id,
    days_in_shelter,
    outcome_age_bracket,
    CASE 
      WHEN outcome_status IN ('Reclaimed', 'Redemption (Offsite)', 'Returned To Owner')
        OR outcome_status LIKE '%Return to Owner%'
        THEN 'Return to Owner'

      WHEN outcome_status LIKE '%Transfer%'
        THEN 'Transfer Out'

      WHEN outcome_status LIKE '%Euthaniz%'
        OR outcome_status LIKE '%DOA%'
        OR outcome_status LIKE '%Death%'
        OR outcome_status LIKE '%Cremat%'
        OR outcome_status LIKE '%Interred%'
        THEN 'Non-Live (Euthanasia/Death)'

      ELSE 'Other'
    END AS clean_outcome
  FROM 
    `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
  WHERE 
    outcome_status NOT LIKE '%Adopted%'
)

SELECT 
  clean_outcome,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_unadopted,
  APPROX_QUANTILES(days_in_shelter, 100)[OFFSET(50)] AS median_los_days,
  ROUND(AVG(days_in_shelter), 1) AS avg_los_days
FROM 
  categorized_outcomes
GROUP BY 
  clean_outcome
ORDER BY 
  total_dogs DESC;

-- Purpose: Breakdown non-adoption outcomes by age bracket and outcome category
WITH categorized_outcomes AS (
  SELECT 
    animal_id,
    days_in_shelter,
    outcome_age_bracket,
    CASE 
      WHEN outcome_status IN ('Reclaimed', 'Redemption (Offsite)', 'Returned To Owner')
        OR outcome_status LIKE '%Return to Owner%'
        THEN 'Return to Owner'
      WHEN outcome_status LIKE '%Transfer%'
        THEN 'Transfer Out'
      WHEN outcome_status LIKE '%Euthaniz%'
        OR outcome_status LIKE '%DOA%'
        OR outcome_status LIKE '%Death%'
        OR outcome_status LIKE '%Cremat%'
        OR outcome_status LIKE '%Interred%'
        THEN 'Non-Live (Euthanasia/Death)'
      ELSE 'Other'
    END AS clean_outcome
  FROM 
    `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
  WHERE 
    outcome_status NOT LIKE '%Adopted%'
)

SELECT 
  outcome_age_bracket,
  clean_outcome,
  COUNT(*) AS total_dogs,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY outcome_age_bracket), 2) AS pct_within_age_group,
  APPROX_QUANTILES(days_in_shelter, 100)[OFFSET(50)] AS median_los_days,
  ROUND(AVG(days_in_shelter), 1) AS avg_los_days
FROM 
  categorized_outcomes
GROUP BY 
  outcome_age_bracket,
  clean_outcome
ORDER BY 
  outcome_age_bracket,
  total_dogs DESC;

-- Purpose: Identify the top 10 primary breeds with the highest number of non-adoption outcomes
WITH categorized_outcomes AS (
  SELECT 
    animal_id,
    days_in_shelter,
    outcome_age_bracket,
    primary_breed,
    CASE 
      WHEN outcome_status IN ('Reclaimed', 'Redemption (Offsite)', 'Returned To Owner')
        OR outcome_status LIKE '%Return to Owner%'
        THEN 'Return to Owner'
      WHEN outcome_status LIKE '%Transfer%'
        THEN 'Transfer Out'
      WHEN outcome_status LIKE '%Euthaniz%'
        OR outcome_status LIKE '%DOA%'
        OR outcome_status LIKE '%Death%'
        OR outcome_status LIKE '%Cremat%'
        OR outcome_status LIKE '%Interred%'
        THEN 'Non-Live (Euthanasia/Death)'
      ELSE 'Other'
    END AS clean_outcome
  FROM 
    `capstone-shelter-analysis.austin_canine_shelter.canine_outcome`
  WHERE 
    outcome_status NOT LIKE '%Adopted%'
)

SELECT 
  primary_breed,
  COUNT(*) AS total_unadopted_dogs,
  COUNTIF(clean_outcome = 'Return to Owner') AS rto_count,
  COUNTIF(clean_outcome = 'Transfer Out') AS transfer_count,
  COUNTIF(clean_outcome = 'Non-Live (Euthanasia/Death)') AS non_live_count,
  ROUND(COUNTIF(clean_outcome = 'Non-Live (Euthanasia/Death)') * 100.0 / COUNT(*), 2) AS non_live_pct,
  ROUND(AVG(days_in_shelter), 1) AS avg_los_days,
  APPROX_QUANTILES(days_in_shelter, 100)[OFFSET(50)] AS median_los_days
FROM 
  categorized_outcomes
GROUP BY 
  primary_breed
HAVING 
  COUNT(*) >= 30
ORDER BY 
  total_unadopted_dogs DESC
LIMIT 10;
