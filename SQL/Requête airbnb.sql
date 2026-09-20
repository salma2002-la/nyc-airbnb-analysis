select * from `nyc_airbnb.parquet_cleaned_airbnb`;

SELECT *
FROM `nyc_airbnb.parquet_cleaned_airbnb`
WHERE id IS NULL
   OR name IS NULL
   OR host_id IS NULL
   OR host_name IS NULL
   OR neighbourhood_group IS NULL
   OR room_type IS NULL
   OR price IS NULL;

with RankedListings AS (
   select *, row_number() over(partition by id ORDER BY id )as row_num

   FROM `nyc_airbnb.parquet_cleaned_airbnb`)

  select *
  from RankedListings
  where row_num>1;

-- Standardization

SELECT DISTINCT neighbourhood_group FROM `nyc_airbnb.parquet_cleaned_airbnb`;
SELECT DISTINCT name FROM `nyc_airbnb.parquet_cleaned_airbnb`;
SELECT DISTINCT host_name FROM `nyc_airbnb.parquet_cleaned_airbnb`;
SELECT DISTINCT neighbourhood FROM `nyc_airbnb.parquet_cleaned_airbnb`;
SELECT DISTINCT room_type FROM `nyc_airbnb.parquet_cleaned_airbnb`;


SELECT DISTINCT neighbourhood_group
FROM `nyc_airbnb.parquet_cleaned_airbnb`
WHERE neighbourhood_group != TRIM(neighbourhood_group);

SELECT DISTINCT room_type
FROM `nyc_airbnb.parquet_cleaned_airbnb`
WHERE room_type != TRIM(room_type);


SELECT 
  room_type, 
  COUNT(*) AS count_type
FROM `nyc_airbnb.parquet_cleaned_airbnb`
GROUP BY room_type;



-- Outliers Check

SELECT 
  MIN(price) AS min_price,
  MAX(price) AS max_price,
  MIN(minimum_nights) AS min_nights,
  MAX(minimum_nights) AS max_nights
FROM `nyc_airbnb.parquet_cleaned_airbnb`;


select *
FROM `nyc_airbnb.parquet_cleaned_airbnb`
where price=0 ;

/* 
====================================================================
TRAITEMENT DES VALEURS ANOMALES (price = 0)
====================================================================
1. ÉVALUATION DE L'IMPACT : 
   - Seules 11 lignes touchées sur 47 000 (~0.02%), volume négligeable.

2. DIAGNOSTIC DU PROBLÈME :
   - Probable erreur de saisie/système (un prix de 0$ n'est pas viable).

3. STRATÉGIE RETENUE :
   - EXCLUSION PAR FILTRAGE (Filtre dynamique : WHERE price > 0).
   - Raison : Préserve les données brutes sans altérer les moyennes (AVG), 
     tout en évitant la suppression définitive (DELETE) ou l'imputation artificielle.
====================================================================
*/

-- we are going to be sure that 10000 is an outlier price 
 
SELECT id, name, room_type, price
FROM `nyc_airbnb.parquet_cleaned_airbnb`
ORDER BY price DESC
LIMIT 10;


SELECT id, name, room_type, price,minimum_nights
FROM `nyc_airbnb.parquet_cleaned_airbnb`
ORDER BY minimum_nights DESC
LIMIT 10;
/*
SELECT 
  PERCENTILE_CONT(price, 0.50) OVER() AS median_price, (autrement pour dire la médianne)
  PERCENTILE_CONT(price, 0.95) OVER() AS p95_price,
  PERCENTILE_CONT(price, 0.99) OVER() AS p99_price
FROM `nyc_airbnb.parquet_cleaned_airbnb`
LIMIT 1;
*/

-- 1.Pricing & Yield (أشحال الثمن وأشحال المداخيل المتوقعة)

select
distinct neighbourhood_group,
percentile_cont(price, 0.5 ) over(partition by neighbourhood_group) as med_price,
percentile_cont(price*reviews_per_month, 0.5 ) over(partition by neighbourhood_group) as med_revenue
from `nyc_airbnb.parquet_cleaned_airbnb`
WHERE price > 0
order by med_price desc;

/*"
Manhattan هي أغلى منطقة فـ نيويورك بـ وسيط سعر $150/ليلة، ولكنها ماشي هي الأفضل عائدًا! أحياء مثل Staten Island و Queens كيحققوا أعلى مداخيل شهرية وسيطة بفضل الإقبال والطلب، مما كيجعلهم أهداف ممتازة للـ High Yield Investment."*/

-- 2. (Demand and Activity: Which neighborhoods show the highest guest demand based on review activity and availability?)
-- we search for low availibility and reviews per month 
select
distinct neighbourhood,
percentile_cont(availability_365,0.5) over(partition by neighbourhood) as med_avail,
percentile_cont(reviews_per_month,0.5) over(partition by neighbourhood) as med_rev
from `nyc_airbnb.parquet_cleaned_airbnb`
WHERE price > 0
order by med_rev desc;
/*
"Contrary to broad borough trends, specific localized neighborhoods like Huguenot, Silver Lake, and East Elmhurst capture the highest guest demand in New York City, generating over 3.7 to 4.3 reviews per month. These areas represent consistent, high-activity micro-markets for real estate investors aiming for frequent bookings."
*/
-- 3. Quality & Hidden Gems
-- we search for first neighbouhood rich with app
-- second Moderate Price with High Demand


WITH NeighborhoodMetrics AS (
  SELECT DISTINCT
    neighbourhood,

    COUNT(id) OVER(PARTITION BY neighbourhood) AS total_listings,
    PERCENTILE_CONT(price, 0.5) OVER(PARTITION BY neighbourhood) AS med_price,
    PERCENTILE_CONT(reviews_per_month, 0.5) OVER(PARTITION BY neighbourhood) AS med_reviews,
    PERCENTILE_CONT(price, 0.5) OVER() AS overall_nyc_med_price,
    PERCENTILE_CONT(reviews_per_month, 0.5) OVER() AS overall_nyc_med_reviews
  FROM `nyc_airbnb.parquet_cleaned_airbnb`
  WHERE price > 0
)

select DISTINCT neighbourhood,total_listings,med_price,med_reviews
from NeighborhoodMetrics
where total_listings>10 and med_price< overall_nyc_med_price and med_reviews>overall_nyc_med_reviews
order by med_reviews desc;
/*
"By benchmarking against NYC-wide medians, we identified prime investment targets like East Elmhurst (Median Price: $60, Reviews/mo: 3.76) and Springfield Gardens ($80, Reviews/mo: 2.53). These neighborhoods offer moderate property acquisition costs paired with exceptional guest demand, providing the ideal setup for high ROI short-term rentals."
*/

-- 4. Property Types: Which room types generate the highest estimated revenue
select distinct room_type,concat(round(count(id) OVER(PARTITION BY room_type)*100/count(id) over() ,2),'%')AS percentage_by_app,
round(percentile_cont(price*reviews_per_month,0.5) over(partition by room_type ),2) as revenue_of_rooms
FROM `nyc_airbnb.parquet_cleaned_airbnb`
WHERE price > 0
order by revenue_of_rooms desc;

-- 5. "5. Competition and Host Profile: Is the market dominated by single hosts or multi-listing real estate investors?"
-- we are going to use host_id and calculated_host_listings_count



with nb_app as (
select distinct host_id,
calculated_host_listings_count as total_properties_by_host,
count(id) over() as total_app_NYC
FROM `nyc_airbnb.parquet_cleaned_airbnb`
where price>0
)

select distinct host_id, total_properties_by_host,concat(round((total_properties_by_host*100)/total_app_NYC,2),'%') as percentage_app_by_host
from nb_app
order by percentage_app_by_host desc;

-- 6. **6. Marketing Impact:** Do specific listing title keywords (e.g., "Luxury", "Cozy", "Modern") correlate with higher prices?
WITH CategorizedListings AS (
select price,
    reviews_per_month,
CASE WHEN LOWER(name) LIKE '%luxury%' THEN TRUE ELSE FALSE END AS is_luxury,
    CASE WHEN LOWER(name) LIKE '%cozy%' THEN TRUE ELSE FALSE END AS is_cozy,
    CASE WHEN LOWER(name) LIKE '%modern%' THEN TRUE ELSE FALSE END AS is_modern,
    CASE WHEN LOWER(name) LIKE '%spacious%' THEN TRUE ELSE FALSE END AS is_spacious
  FROM `nyc_airbnb.parquet_cleaned_airbnb`

WHERE price > 0)

SELECT DISTINCT
  -- Luxury Metrics
  PERCENTILE_CONT(CASE WHEN is_luxury THEN price END, 0.5) OVER() AS med_price_luxury,
  PERCENTILE_CONT(CASE WHEN is_luxury THEN reviews_per_month END, 0.5) OVER() AS med_reviews_luxury,
  
  -- Cozy Metrics
  PERCENTILE_CONT(CASE WHEN is_cozy THEN price END, 0.5) OVER() AS med_price_cozy,
  PERCENTILE_CONT(CASE WHEN is_cozy THEN reviews_per_month END, 0.5) OVER() AS med_reviews_cozy,

  -- Modern Metrics
  PERCENTILE_CONT(CASE WHEN is_modern THEN price END, 0.5) OVER() AS med_price_modern,
  PERCENTILE_CONT(CASE WHEN is_modern THEN reviews_per_month END, 0.5) OVER() AS med_reviews_modern,

  -- Spacious Metrics
  PERCENTILE_CONT(CASE WHEN is_spacious THEN price END, 0.5) OVER() AS med_price_spacious,
  PERCENTILE_CONT(CASE WHEN is_spacious THEN reviews_per_month END, 0.5) OVER() AS med_reviews_spacious

FROM CategorizedListings

;
