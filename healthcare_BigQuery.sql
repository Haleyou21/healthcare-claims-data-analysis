/* Analyzing patient demographics by gender and race */
SELECT
  gender_concept_id,
  race_concept_id,
  COUNT(person_id) AS patient_count
FROM
  `bigquery-public-data.cms_synthetic_patient_data_omop.person`
GROUP BY
  gender_concept_id, race_concept_id
ORDER BY
  patient_count DESC;

/* Identifying the most common conditions for patients with specific drug exposure */
WITH drug_patients AS (
  SELECT
    person_id
  FROM
    `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
  WHERE
    drug_concept_id = 1125315
)
SELECT
  co.condition_concept_id,
  c.concept_name AS condition_name,
  COUNT(co.person_id) AS patient_count
FROM
  drug_patients dp
JOIN
  `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
ON
  dp.person_id = co.person_id
JOIN
  `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
ON
  co.condition_concept_id = c.concept_id
GROUP BY
  co.condition_concept_id, condition_name
ORDER BY
  patient_count DESC
LIMIT 1000;


/* Calculating average procedure costs over time */
SELECT
  EXTRACT(YEAR FROM procedure_date) AS procedure_year,
  AVG(cost) AS average_cost
FROM
  `bigquery-public-data.cms_synthetic_patient_data_omop.procedure_cost` pc
JOIN
  `bigquery-public-data.cms_synthetic_patient_data_omop.procedure_occurrence` po
ON
  pc.procedure_occurrence_id = po.procedure_occurrence_id
GROUP BY
  procedure_year
ORDER BY
  procedure_year;

/* Creating a cohort of patients with a specific condition treated with a specific drug */
WITH condition_patients AS (
  SELECT
    person_id
  FROM
    `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE
    condition_concept_id = 319835 
),
drug_patients AS (
  SELECT
    person_id
  FROM
    `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
  WHERE
    drug_concept_id = 1125315
)
SELECT
  p.person_id,
  p.year_of_birth,
  p.gender_concept_id,
  p.race_concept_id
FROM
  `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
JOIN
  condition_patients cp
ON
  p.person_id = cp.person_id
JOIN
  drug_patients dp
ON
  p.person_id = dp.person_id;

/* Analyzing mortality rates for patients with specific conditions */
WITH condition_patients AS (
  SELECT
    person_id,
    condition_start_date
  FROM
    `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE
    condition_concept_id = 319835
),
death_dates AS (
  SELECT
    person_id,
    death_date
  FROM
    `bigquery-public-data.cms_synthetic_patient_data_omop.death`
)
SELECT
  cp.condition_concept_id,
  c.concept_name AS condition_name,
  COUNT(dd.person_id) AS death_count,
  COUNT(cp.person_id) AS patient_count,
  (COUNT(dd.person_id) / COUNT(cp.person_id)) * 100 AS mortality_rate
FROM
  condition_patients cp
LEFT JOIN
  death_dates dd
ON
  cp.person_id = dd.person_id
JOIN
  `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
ON
  cp.condition_concept_id = c.concept_id
GROUP BY
  cp.condition_concept_id, condition_name
ORDER BY
  mortality_rate DESC
LIMIT 1000;
