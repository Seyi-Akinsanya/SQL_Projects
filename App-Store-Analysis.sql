USE PortfolioProjects

-- Step 1: Data Cleaning

-- Remove duplicate entries
WITH DuplicateCTE AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS row_num
    FROM app_data
)
DELETE FROM app_data WHERE id IN (SELECT id FROM DuplicateCTE WHERE row_num > 1);

WITH DuplicateCTE AS (
    SELECT app_table_id, ROW_NUMBER() OVER (PARTITION BY app_table_id ORDER BY app_table_id) AS row_num
    FROM app_privacy_labels
)
DELETE FROM app_privacy_labels WHERE app_table_id IN (SELECT app_table_id FROM DuplicateCTE WHERE row_num > 1);

WITH DuplicateCTE AS (
    SELECT app_table_id, ROW_NUMBER() OVER (PARTITION BY app_table_id ORDER BY app_table_id) AS row_num
    FROM app_genre
)
DELETE FROM app_genre WHERE app_table_id IN (SELECT app_table_id FROM DuplicateCTE WHERE row_num > 1);

WITH DuplicateCTE AS (
    SELECT app_table_id, ROW_NUMBER() OVER (PARTITION BY app_table_id ORDER BY app_table_id) AS row_num
    FROM app_policy
)
DELETE FROM app_policy WHERE app_table_id IN (SELECT app_table_id FROM DuplicateCTE WHERE row_num > 1);

-- Handle NULL values
SELECT COALESCE(app_id, -1) AS app_id FROM app_data;
SELECT COALESCE(app_table_id, -1) AS app_table_id FROM app_privacy_labels;
SELECT COALESCE(app_table_id, -1) AS app_table_id FROM app_genre;
SELECT COALESCE(app_table_id, -1) AS app_table_id FROM app_policy;

-- Normalize price column
UPDATE app_data SET price = 0 WHERE price IS NULL;

-- Standardize country codes to uppercase
UPDATE app_data SET country_code = UPPER(country_code);


-- Step 2: Apply Indexing for Optimization
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_app_id' AND object_id = OBJECT_ID('app_data'))
    CREATE INDEX idx_app_id ON app_data (id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_privacy_app_id' AND object_id = OBJECT_ID('app_privacy_labels'))
    CREATE INDEX idx_privacy_app_id ON app_privacy_labels (app_table_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_genre_code' AND object_id = OBJECT_ID('app_genre'))
    CREATE INDEX idx_genre_code ON app_genre (genre_code);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_policy_status' AND object_id = OBJECT_ID('app_policy'))
    CREATE INDEX idx_policy_status ON app_policy (app_table_id);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_price' AND object_id = OBJECT_ID('app_data'))
    CREATE INDEX idx_price ON app_data (price);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_rating_purchases' AND object_id = OBJECT_ID('app_data'))
    CREATE INDEX idx_rating_purchases ON app_data (has_in_app_purchases, user_rating_value);


-- Step 3: Query Insights

-- 1. Do Apps with In-App Purchases Receive Higher Ratings?
WITH InAppData AS (
    SELECT a.has_in_app_purchases, 
           AVG(user_rating_value) AS avg_rating
    FROM app_data a
    JOIN app_privacy_labels s ON a.id = s.app_table_id
    GROUP BY a.has_in_app_purchases
)
SELECT has_in_app_purchases, avg_rating FROM InAppData;

-- 2. Do Privacy-Friendly Apps Receive Higher Ratings? (Using Subquery)
WITH PrivacyRatings AS (
    SELECT a.id, a.user_rating_value,
           CASE WHEN s.privacy_type_track = 0 AND s.privacy_type_linked = 0 
                THEN 'Privacy-Friendly' ELSE 'Non-Privacy-Friendly' END AS privacy_status
    FROM app_data a
    LEFT JOIN app_privacy_labels s ON a.id = s.app_table_id
)
SELECT privacy_status, AVG(user_rating_value) AS avg_rating
FROM PrivacyRatings
GROUP BY privacy_status;

-- 3. Which Genres Have the Most Apps and Highest Ratings?
WITH GenreStats AS (
    SELECT g.genre_code, COUNT(a.id) AS app_count, AVG(a.user_rating_value) AS avg_rating
    FROM app_data a
    JOIN app_genre g ON a.id = g.app_table_id
    GROUP BY g.genre_code
)
SELECT TOP 20 * FROM GenreStats
ORDER BY avg_rating DESC;

-- 4. Which App Genres Are Most Likely to Have Privacy Policies?
WITH PrivacyPolicyStats AS (
    SELECT g.genre_code, 
           COUNT(a.id) AS total_apps,
           SUM(CASE WHEN p.privacy_policy_url IS NOT NULL THEN 1 ELSE 0 END) AS apps_with_policies
    FROM app_data a
    JOIN app_genre g ON a.id = g.app_table_id
    LEFT JOIN app_policy p ON a.id = p.app_table_id
    GROUP BY g.genre_code
)
SELECT genre_code, total_apps, apps_with_policies,
       (CAST(apps_with_policies AS FLOAT) / total_apps) * 100 AS percentage_with_policies
FROM PrivacyPolicyStats
ORDER BY percentage_with_policies DESC;

-- 5. Which Genres Collect the Most User Data?
WITH AppDataCollection AS (
    SELECT g.genre_code, 
           SUM(s.privacy_type_track + s.privacy_type_linked) AS data_collected,
		   AVG(a.user_rating_value) AS avg_rating
    FROM app_data a
    JOIN app_genre g ON a.id = g.app_table_id
    JOIN app_privacy_labels s ON a.id = s.app_table_id
    GROUP BY g.genre_code
)
SELECT TOP 20 * FROM AppDataCollection
ORDER BY data_collected DESC;
