WITH fs_with_geom AS (
    SELECT 
        *,
        ST_Point(longitude, latitude) AS geometry
    FROM fs
    WHERE longitude IS NOT NULL 
    AND latitude IS NOT NULL
),

nearby_pairs AS (
    SELECT 
        fs.*,
        o.*,
        ST_Distance(fs.geometry, o.geometry) AS distance_meters,
        jaro_winkler_similarity(
            lower(trim(fs.name)), 
            lower(trim(o.names->>'primary'))
        ) AS name_similarity
    FROM fs_with_geom fs, omf o
    WHERE ST_DWithin(fs.geometry, o.geometry, 100)
),

scored_matches AS (
    SELECT 
        *,
        CASE 
            WHEN distance_meters <= 50 THEN 3
            WHEN distance_meters <= 100 THEN 1
            ELSE 0
        END AS distance_score,
        
        CASE 
            WHEN name_similarity >= 0.9 THEN 5
            WHEN name_similarity >= 0.8 THEN 3
            WHEN name_similarity >= 0.7 THEN 1
            ELSE 0
        END AS name_score,
        
        CASE 
            WHEN tel IS NOT NULL 
                AND phones IS NOT NULL 
                AND array_contains(phones, regexp_replace(tel, '[^0-9]', '')) 
            THEN 3
            ELSE 0
        END AS phone_score,
        
        CASE 
            WHEN website IS NOT NULL 
                AND websites IS NOT NULL 
                AND array_contains(websites, lower(trim(website)))
            THEN 3
            ELSE 0
        END AS website_score,
        
        CASE 
            WHEN postcode IS NOT NULL 
                AND addresses[1].postcode = postcode
            THEN 2
            ELSE 0
        END AS postcode_score
    FROM nearby_pairs
)

SELECT 
    n.fsq_place_id,
    n.name AS fs_name,
    n.id AS omf_id,
    n.names->>'primary' AS omf_name,
    n.distance_meters,
    n.name_similarity,
    n.distance_score + n.name_score + n.phone_score + n.website_score + n.postcode_score AS total_score,
    n.distance_score,
    n.name_score,
    n.phone_score,
    n.website_score,
    n.postcode_score
FROM scored_matches n
WHERE 
    (n.distance_score + n.name_score + n.phone_score + n.website_score + n.postcode_score) >= 4
ORDER BY 
    n.fsq_place_id,
    total_score DESC;