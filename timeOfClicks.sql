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
ORDER BY unique_visitor_cookie_id, visit_id, event_position
LIMIT 10;

SELECT *
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
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

DROP TABLE IF EXISTS vb_tv_nav_example;
CREATE TABLE vb_tv_nav_example AS
SELECT DISTINCT p.unique_visitor_cookie_id,
                p.visit_id,
                p.event_position,
                p.attribute,
                p.placement,
                CASE
                    WHEN left(right(p.placement, 13), 8) SIMILAR TO '%[0-9]%' THEN left(right(p.placement, 13), 8)
                    ELSE 'none' END                                                                  AS current_ep_id,
                p.result                                                                             AS next_ep_id,
                to_timestamp(p.event_start_datetime, 'YYYY-MM-DD HH24:MI:SS') at time zone
                'Etc/UTC'                                                                            AS event_start_datetime-- convert this to a datetime

FROM s3_audience.publisher p
         JOIN vb_tv_nav_select vb
              ON p.dt = vb.dt AND p.unique_visitor_cookie_id = vb.unique_visitor_cookie_id AND
                 vb.visit_id = p.visit_id AND vb.dt = p.dt;

CREATE TABLE vb_tv_nav_example1 AS
SELECT *,
       row_number()
       OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position) AS visit_row_num
FROM vb_tv_nav_example;



-- identify the start of viewing new content (this is needed for if someone watches content and then comes back later to the same content)
DROP TABLE IF EXISTS vb_tv_nav_example2;
CREATE TABLE vb_tv_nav_example2 AS
SELECT *,
       CASE
           WHEN current_ep_id != LAG(current_ep_id, 1) -- current ep id same as one above
                                 OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position)
               THEN 'new_viewing'
           WHEN visit_row_num = 1 THEN 'new_viewing'
           END AS viewing_session
FROM vb_tv_nav_example1
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT * FROM vb_tv_nav_example2 ORDER BY unique_visitor_cookie_id, visit_id, event_position;

-- Select only the new content watching or the click event
-- give the time of the previous event
DROP TABLE IF EXISTS vb_tv_nav_example3 ;
CREATE TABLE vb_tv_nav_example3 AS
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
         FROM vb_tv_nav_example2
         WHERE attribute = 'page-section-related~select'
            OR viewing_session IS NOT NULL
         ORDER BY unique_visitor_cookie_id, visit_id, event_position)
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT * FROM vb_tv_nav_example3 ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT unique_visitor_cookie_id,
       visit_id,
       event_position,
       current_ep_id,
       event_start_datetime - previous_event_start_datetime AS time_since_content_start
FROM vb_tv_nav_example3
WHERE attribute = 'page-section-related~select'
ORDER BY unique_visitor_cookie_id, visit_id, event_position;





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