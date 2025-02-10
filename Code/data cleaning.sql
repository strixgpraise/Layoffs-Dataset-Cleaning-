-- DATA CLEANING PROCESS

-- Step 1: Create a backup of the original table before cleaning

SELECT *
FROM layoffs;

CREATE TABLE layoff_cleaning
LIKE layoffs;

INSERT layoffs_cleaning
SELECT *
FROM layoffs;


-- 1. Removing duplicated values
WITH duplicate_cte AS 
(SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage,
country, fund_raised_millions) AS row_num -- Assigns row numbers to duplicates
FROM layoffs_cleaning)

SELECT *
FROM duplicate_cte
WHERE row_num > 1;  -- Shows all duplicate rows

-- Step 2: Create a cleaned version of the table

CREATE TABLE `layoffs_cleaning2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_cleaning2;

-- Step 3: Insert unique records with row numbers
INSERT INTO layoffs_cleaning2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_cleaning;

-- Step 4: Remove duplicate rows based on row_num
DELETE 
FROM layoffs_cleaning2
WHERE row_num > 1;

SELECT * 
FROM layoffs_cleaning2
WHERE row_num > 1;

-- 2. Standardizind data

-- Trim spaces from company names
SELECT company, TRIM(company)
FROM layoffs_cleaning2;

UPDATE layoffs_cleaning2
SET company = TRIM(company);

-- Standardize industry names (Example: "Crypto" variations)
SELECT *
FROM layoffs_cleaning2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_cleaning2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names (e.g., Remove trailing periods in "United States.")
SELECT DISTINCT industry
FROM layoffs_cleaning2
ORDER BY 1;

SELECT *
FROM layoffs_cleaning2
WHERE country LIKE 'united state%'
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_cleaning2
ORDER BY 1;

UPDATE layoffs_cleaning2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'united state';

-- Convert date column from TEXT to DATE format
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_cleaning2;


UPDATE layoffs_cleaning2
SET date = STR_TO_DATE(`date`, '%m/%d/%Y');


ALTER TABLE layoffs_cleaning2
MODIFY COLUMN `date` DATE;

-- 3. Working wuth null and blank

SELECT *
FROM layoffs_cleaning2
WHERE total_laid_off IS NULL
AND percentage_laid_off is NULL;

SELECT *
FROM layoffs_cleaning2
WHERE industry IS NULL 
OR industry = '';


SELECT *
FROM layoffs_cleaning2
WHERE company = 'Airbnb';


-- Replace empty industry values with NULL
UPDATE layoffs_cleaning2
SET industry = null
WHERE industry = '';

-- Fill missing industry data based on the company name
SELECT t1.industry, t2.industry
FROM layoffs_cleaning2 t1
JOIN layoffs_cleaning2 t2 
	on t1.company = t2.company
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;


UPDATE layoffs_cleaning2 t1
JOIN layoffs_cleaning2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

SELECT * 
FROM layoffs_cleaning2;

SELECT *
FROM layoffs_cleaning2
WHERE total_laid_off IS NULL 
AND percentage_laid_off is NULL;

-- Delete rows where both total_laid_off and percentage_laid_off are NULL
DELETE 
FROM layoffs_cleaning2
WHERE total_laid_off IS NULL 
AND percentage_laid_off is NULL;


-- 4. Remove unnecessary Columns

ALTER TABLE layoffs_cleaning2
DROP COLUMN row_num;