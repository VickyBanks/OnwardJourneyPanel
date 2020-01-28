------ SECTION 1 --- Find the time taken to click the tv onwards journey menu after the content has begun -------------

-- Select visits and UV on TV where the onward nav was clicked
DROP TABLE IF EXISTS vb_tv_nav_select;
CREATE TABLE vb_tv_nav_select AS
SELECT DISTINCT dt,
                unique_visitor_cookie_id,
                visit_id,
                event_position,
                event_start_datetime,
                attribute,
                left(right(placement, 13), 8) AS current_ep_id,
                result                        AS next_ep_id
FROM s3_audience.publisher
WHERE container LIKE '%page-section-related%'
  AND attribute LIKE '%page-section-related~select%'
  AND metadata LIKE '%iplayer::bigscreen-html%'
  AND dt >= 20191101
  AND dt <= 20191114
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT *
FROM vb_tv_nav_select
LIMIT 5;

-- How many visits did not click this panel?

SELECT nav_click, count(*)
FROM (SELECT DISTINCT a.dt,
                      a.unique_visitor_cookie_id,
                      a.visit_id,
                      ISNULL(b.nav_click, 'no_click') AS nav_click
      FROM s3_audience.publisher a
               LEFT JOIN (SELECT DISTINCT dt,
                                          unique_visitor_cookie_id,
                                          visit_id,
                                          CAST('with_click' AS varchar) AS nav_click
                          FROM vb_tv_nav_select) b ON a.dt = b.dt AND
                                                      a.unique_visitor_cookie_id = b.unique_visitor_cookie_id AND
                                                      a.visit_id = b.visit_id
      WHERE metadata LIKE '%iplayer::bigscreen-html%'
        AND a.dt >= 20191101
        AND a.dt <= 20191114)
GROUP BY nav_click;

-- with click =  4,505,569 = 10%
-- no click   = 41,987,593 = 90%

-- Get all events for those users who click the onward journey panel.
DROP TABLE IF EXISTS vb_tv_nav;
CREATE TABLE vb_tv_nav AS
SELECT DISTINCT p.dt,
                p.unique_visitor_cookie_id,
                p.visit_id,
                p.event_position,
                p.attribute,
                p.placement,
                CASE
                    WHEN left(right(p.placement, 13), 8) SIMILAR TO '%[0-9]%'
                        THEN left(right(p.placement, 13), 8) -- if this contains a number then its an ep id, if not make blank
                    ELSE 'none' END AS current_ep_id,
                p.result            AS next_ep_id,
                to_timestamp(p.event_start_datetime, 'YYYY-MM-DD HH24:MI:SS') at time zone
                'Etc/UTC'           AS event_start_datetime-- convert this to a datetime with time UTC
FROM s3_audience.publisher p
         JOIN vb_tv_nav_select vb
              ON p.dt = vb.dt AND p.unique_visitor_cookie_id = vb.unique_visitor_cookie_id AND
                 vb.visit_id = p.visit_id AND vb.dt = p.dt;


SELECT *
FROM vb_tv_nav_select
LIMIT 5;

-- Add in row number to enable the first instance from a visit to be classified as the start of viewing
DROP TABLE IF EXISTS vb_tv_nav_num;
CREATE TABLE vb_tv_nav_num AS
SELECT *,
       row_number()
       OVER (PARTITION BY dt,unique_visitor_cookie_id, visit_id ORDER BY dt,unique_visitor_cookie_id, visit_id, event_position) AS visit_row_num
FROM vb_tv_nav;


-- identify the start of viewing new content (this is needed for if someone watches content and then comes back later to the same content)
DROP TABLE IF EXISTS vb_tv_nav_new_content_flag;
CREATE TABLE vb_tv_nav_new_content_flag AS
SELECT *,
       CASE
           WHEN current_ep_id != LAG(current_ep_id, 1) -- current ep id same as one above
                                 OVER (PARTITION BY dt, unique_visitor_cookie_id, visit_id ORDER BY dt,unique_visitor_cookie_id, visit_id, event_position)
               THEN 'new_viewing'
           WHEN visit_row_num = 1 THEN 'new_viewing'
           END AS viewing_session
FROM vb_tv_nav_num
ORDER BY unique_visitor_cookie_id, visit_id, event_position;


/*SELECT *
FROM vb_tv_nav_new_content_flag
ORDER BY unique_visitor_cookie_id, visit_id, event_position;*/

-- Select the rows where new content is flagged and the rows where the click event is given
-- Add in the time of the previous event as a new column to be used for calculations
DROP TABLE IF EXISTS vb_tv_nav_key_events;
CREATE TABLE vb_tv_nav_key_events AS
SELECT DISTINCT dt,
                unique_visitor_cookie_id,
                visit_id,
                event_position,
                attribute,
                placement,
                current_ep_id,
                event_start_datetime,
                viewing_session,
                LAG(event_start_datetime, 1)
                OVER (PARTITION BY dt, unique_visitor_cookie_id, visit_id ORDER BY dt, unique_visitor_cookie_id, visit_id, event_position) AS previous_event_start_datetime
FROM (
         SELECT *
         FROM vb_tv_nav_new_content_flag
         WHERE attribute = 'page-section-related~select'
            OR viewing_session IS NOT NULL
         ORDER BY unique_visitor_cookie_id, visit_id, event_position)
ORDER BY dt, unique_visitor_cookie_id, visit_id, event_position;

SELECT *
FROM vb_tv_nav_key_events
ORDER BY unique_visitor_cookie_id, visit_id, event_position
LIMIT 5;

--DATEDIFF(date , event_start_datetime, previous_event_start_datetime) AS test,
--to_timestamp(event_start_datetime - previous_event_start_datetime, 'YYYY-MM-DD HH24:MI:SS') at time zone 'Etc/UTC' AS time_since_content_start
--event_start_datetime - previous_event_start_datetime  AS time_since_content_start,

DROP TABLE vb_tv_nav_time_to_click;
CREATE TABLE vb_tv_nav_time_to_click AS
SELECT dt,
       unique_visitor_cookie_id,
       visit_id,
       current_ep_id,
       event_start_datetime,
       previous_event_start_datetime,
       DATEDIFF(s, CAST(previous_event_start_datetime AS TIMESTAMP),
                CAST(event_start_datetime AS TIMESTAMP)) AS time_since_content_start_sec
FROM vb_tv_nav_key_events
WHERE attribute = 'page-section-related~select'
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT visit_id, time_since_content_start_sec
FROM vb_tv_nav_time_to_click;

SELECT *
FROM vb_tv_nav_time_to_click
WHERE visit_id = 784641
ORDER BY dt, event_start_datetime;

-- look at groupings in minutes
SELECT CASE
           WHEN time_since_content_start_sec >= 0 AND time_since_content_start_sec < 60 THEN '0-1'
           WHEN time_since_content_start_sec >= 60 AND time_since_content_start_sec < 300 THEN '1-5'
           WHEN time_since_content_start_sec >= 300 AND time_since_content_start_sec < 600 THEN '5-10'
           WHEN time_since_content_start_sec >= 600 AND time_since_content_start_sec < 900 THEN '10-15'
           WHEN time_since_content_start_sec >= 900 AND time_since_content_start_sec < 1200 THEN '15-20'
           WHEN time_since_content_start_sec < 0 THEN 'Smaller than 0'
           WHEN time_since_content_start_sec IS NULL THEN 'null'
           ELSE '20+'
           END AS time_ranges,
       count(visit_id)
FROM vb_tv_nav_time_to_click
GROUP BY 1;



ALTER TABLE vb_tv_nav_time_to_click
    ADD COLUMN time_since_content_start timestamptz;
SELECT *
FROM vb_tv_nav_time_to_click;
UPDATE vb_tv_nav_time_to_click
SET time_since_content_start=
            to_timestamp(event_start_datetime - previous_event_start_datetime, 'YYYY-MM-DD HH24:MI:SS') at time zone
            'Etc/UTC';

SELECT * FROM vb_tv_nav_time_to_click WHERE dt = 20191111 AND visit_id =17686132;




-------- SECTION 2 ---  Find where those click taking the user - -- i.e another episode of the same series/brand or not? ---------------------

-- Create a simple subset of the VMB for just TV episodes ignoring radio or tv clips/trailers
DROP TABLE IF EXISTS vb_vmb_subset_temp;
CREATE TABLE vb_vmb_subset_temp AS
SELECT DISTINCT a.brand_id,
                a.brand_title,
                a.series_id,
                a.series_title,
                a.episode_id,
                a.episode_title,
                b.episode_number
FROM prez.scv_vmb a
         LEFT JOIN (SELECT DISTINCT episode_id, episode_number FROM central_insights_sandbox.episode_numbers) b
                   on a.episode_id = b.episode_id
WHERE clip_id = 'null'       --This is to prevent clips pulling in null episode values (i.e series trailers)
  AND a.media_type = 'video' -- remove any radio content
  AND master_brand_name NOT ILIKE '%radio%'
  AND master_brand_name NOT ILIKE '%asian network%'
  AND master_brand_name NOT ILIKE '%WM 95.6%'
ORDER BY a.brand_id,
         a.series_id,
         a.episode_id,
         b.episode_number;

-- Number episodes sequentially across all series.
CREATE TABLE vb_vmb_subset AS
SELECT *,
       row_number()
       over (PARTITION BY brand_title ORDER BY brand_title, series_title, episode_number) AS running_ep_count
FROM vb_vmb_subset_temp
WHERE episode_number IS NOT NULL -- eliminates anything that has not been given an episode number
ORDER BY brand_title,
         series_title,
         episode_number;

--SELECT * FROM vb_vmb_subset WHERE episode_id = 'b007cldz';

DROP TABLE IF EXISTS vb_vmb_subset_temp;

-- For each click on the nav bar get the brand & series IDs of the content, the episode number, the running episode count(i.e over many series) for the current and next content.
-- This will be used to see if people click onto the same or different brands/series
CREATE TABLE vb_tv_nav_next_ep_full_info AS
SELECT a.dt,
       a.unique_visitor_cookie_id,
       a.time_since_content_start_sec,
       a.visit_id,
       c.brand_id       AS current_brand_id,
       c.brand_title    AS current_brand_title,
       c.series_id      AS current_series_id,
       c.series_title   AS current_series_title,
       a.current_ep_id,
       c.episode_title  AS current_ep_title,
       c.episode_number AS current_ep_num,
       c.running_ep_count AS current_running_ep_count,
       d.brand_id       AS next_brand_id,
       d.brand_title    AS next_brand_title,
       d.series_id      AS next_series_id,
       d.series_title   AS next_series_title,
       b.next_ep_id,
       d.episode_title  AS next_ep_title,
       d.episode_number AS next_ep_num,
       d.running_ep_count AS next_running_ep_count
FROM vb_tv_nav_time_to_click a
         JOIN vb_tv_nav_select b ON a.dt = b.dt AND
                                    a.unique_visitor_cookie_id = b.unique_visitor_cookie_id AND
                                    a.visit_id = b.visit_id AND
                                    a.current_ep_id = b.current_ep_id
         JOIN vb_vmb_subset c ON a.current_ep_id = c.episode_id
         JOIN vb_vmb_subset d ON b.next_ep_id = d.episode_id
;

SELECT * FROM vb_tv_nav_next_ep_full_info limit 5;


-- Identify if people have clicked onto content of the same brand, same brand & same series, next episode of content or unrelated content.
CREATE TABLE vb_tv_nav_next_ep_summary AS
SELECT dt,unique_visitor_cookie_id, visit_id, time_since_content_start_sec,
       CASE
           WHEN current_brand_id = next_brand_id THEN 1
           ELSE 0 END AS same_brand,
       CASE
           WHEN current_brand_id = next_brand_id AND current_series_id = next_series_id THEN 1
           ELSE 0 END AS same_brand_series,
       CASE
           WHEN current_brand_id = next_brand_id AND current_series_id = next_series_id AND
                current_running_ep_count + 1 = next_running_ep_count THEN 1
           ELSE 0 END AS next_ep
FROM vb_tv_nav_next_ep_full_info
ORDER BY dt, visit_id;

-- How many journey's are in the same brand?
SELECT next_ep, count(visit_id) FROM
vb_tv_nav_next_ep_summary
GROUP BY next_ep;



-------------------
SELECT *
FROM central_insights_sandbox.episode_numbers
WHERE episode_id = 'p040trv9'
LIMIT 5;

SELECT DISTINCT brand_id,
                brand_title,
                series_id,
                series_title,
                episode_id,
                episode_title,
                clip_id,
                clip_title
FROM prez.scv_vmb
WHERE --brand_id = 'p07ptd54'
   --OR series_id = 'p07ptd54'
   --or
      episode_id = 'b007cldz'
   --OR clip_id = 'p07ptd54'
   ;


-- WHEN left(right(placement, 13), 8) LIKE 'yer.load' THEN NULL
-- WHEN left(right(placement, 13), 8) LIKE 'witching' THEN NULL
-- WHEN left(right(placement, 13), 8) LIKE 'layer.tv' THEN NULL
-- WHEN left(right(placement, 13), 8) LIKE 'ctivated' THEN NULL
-- WHEN left(right(placement, 13), 8) LIKE '%one_%' THEN NULL
---  WHEN left(right(placement, 13), 8) LIKE '%two_%' THEN NULL
-- ELSE left(right(placement, 13), 8)
--   WHEN left(right(placement, 13), 8) LIKE '%[0-9]%' THEN 5
---   ELSE 6
--