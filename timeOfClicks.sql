-- select visits and UV on TV
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
  AND dt = 20191226
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

/*SELECT *
FROM vb_tv_nav_select;

SELECT vb.*, p.attribute, p.event_position, p.event_start_datetime, p.result
FROM vb_tv_nav_select vb
         JOIN s3_audience.publisher p
              ON vb.unique_visitor_cookie_id = p.unique_visitor_cookie_id AND vb.visit_id = p.visit_id AND vb.dt = p.dt
WHERE p.destination = 'PS_IPLAYER'
  AND vb.current_ep_id = p.result
  AND p.attribute = 'iplxp-ep-started'
  AND vb.event_position > p.event_position;


SELECT *,
       row_number()
       OVER (PARTITION BY unique_visitor_cookie_id,visit_id, current_ep_id ORDER BY event_start_datetime) AS current_ep_id_instance
FROM (SELECT DISTINCT p.unique_visitor_cookie_id,
                      p.visit_id,
                      p.event_position,
                      p.attribute,
                      p.placement,
                      CASE
                          WHEN left(right(p.placement, 13), 8) SIMILAR TO '%[0-9]%' THEN left(right(p.placement, 13), 8)
                          ELSE NULL END AS current_ep_id,
                      p.result          AS next_ep_id,
                      p.event_start_datetime
      FROM s3_audience.publisher p
               JOIN vb_tv_nav_select vb
                    ON p.dt = vb.dt AND p.unique_visitor_cookie_id = vb.unique_visitor_cookie_id AND
                       vb.visit_id = p.visit_id AND vb.dt = p.dt)
ORDER BY unique_visitor_cookie_id, visit_id, event_position;*/

DROP TABLE IF EXISTS vb_tv_nav;
CREATE TABLE vb_tv_nav AS
SELECT DISTINCT p.unique_visitor_cookie_id,
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

-- Add in row number to enable the first instance from a visit to be classified as the start of viewing
DROP TABLE IF EXISTS vb_tv_nav_num;
CREATE TABLE vb_tv_nav_num AS
SELECT *,
       row_number()
       OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position) AS visit_row_num
FROM vb_tv_nav;


-- identify the start of viewing new content (this is needed for if someone watches content and then comes back later to the same content)
DROP TABLE IF EXISTS vb_tv_nav_new_content_flag;
CREATE TABLE vb_tv_nav_new_content_flag AS
SELECT *,
       CASE
           WHEN current_ep_id != LAG(current_ep_id, 1) -- current ep id same as one above
                                 OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position)
               THEN 'new_viewing'
           WHEN visit_row_num = 1 THEN 'new_viewing'
           END AS viewing_session
FROM vb_tv_nav_num
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT *
FROM vb_tv_nav_new_content_flag
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

-- Select the rows where new content is flagged and the rows where the click event is given
-- Add in the time of the previous event as a new column to be used for calculations
DROP TABLE IF EXISTS vb_tv_nav_key_events;
CREATE TABLE vb_tv_nav_key_events AS
SELECT DISTINCT unique_visitor_cookie_id,
                visit_id,
                event_position,
                attribute,
                placement,
                current_ep_id,
                event_start_datetime,
                viewing_session,
                LAG(event_start_datetime, 1)
                OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position) AS previous_event_start_datetime
FROM (
         SELECT *
         FROM vb_tv_nav_new_content_flag
         WHERE attribute = 'page-section-related~select'
            OR viewing_session IS NOT NULL
         ORDER BY unique_visitor_cookie_id, visit_id, event_position)
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT *
FROM vb_tv_nav_key_events
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

--DATEDIFF(date , event_start_datetime, previous_event_start_datetime) AS test,
--to_timestamp(event_start_datetime - previous_event_start_datetime, 'YYYY-MM-DD HH24:MI:SS') at time zone 'Etc/UTC' AS time_since_content_start
--event_start_datetime - previous_event_start_datetime  AS time_since_content_start,

DROP TABLE vb_tv_nav_time_to_click;
CREATE TABLE vb_tv_nav_time_to_click AS
SELECT unique_visitor_cookie_id,
       visit_id,
       current_ep_id,
       event_start_datetime,
       previous_event_start_datetime,
       DATEDIFF(s, CAST(previous_event_start_datetime AS TIMESTAMP),
                CAST(event_start_datetime AS TIMESTAMP)) AS time_since_content_start_sec
FROM vb_tv_nav_key_events
WHERE attribute = 'page-section-related~select'
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT *
FROM vb_tv_nav_time_to_click;


SELECT CASE
           WHEN time_since_content_start_sec >= 0 AND time_since_content_start_sec < 60 THEN '0-1'
           WHEN time_since_content_start_sec >= 60 AND time_since_content_start_sec < 300 THEN '1-5'
           WHEN time_since_content_start_sec > 300 AND time_since_content_start_sec < 600 THEN '5-10'
           ELSE '10+'
           END AS time_ranges,
       count(visit_id)
FROM vb_tv_nav_time_to_click
GROUP BY 1;

CREATE TABLE new_example AS
SELECT date2 - date1 AS date_interval
FROM ABC;

ALTER TABLE vb_tv_nav_time_to_click
    ADD COLUMN time_since_content_start timestamptz;
SELECT *
FROM vb_tv_nav_time_to_click;
UPDATE vb_tv_nav_time_to_click
SET time_since_content_start=
            to_timestamp(event_start_datetime - previous_event_start_datetime, 'YYYY-MM-DD HH24:MI:SS') at time zone
            'Etc/UTC';


-------------------


SELECT DISTINCT brand_id,
                brand_title,
                series_id,
                series_title,
                episode_id,
                episode_title,
                clip_id,
                clip_title
FROM prez.scv_vmb
WHERE brand_id = 'b00x98tn'
   OR series_id = 'b00x98tn'
   or episode_id = 'b00x98tn'
   OR clip_id = 'b00x98tn';


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