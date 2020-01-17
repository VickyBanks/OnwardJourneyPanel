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
                    ELSE 'none' END AS current_ep_id,
                p.result          AS next_ep_id,
                p.event_start_datetime
FROM s3_audience.publisher p
         JOIN vb_tv_nav_select vb
              ON p.dt = vb.dt AND p.unique_visitor_cookie_id = vb.unique_visitor_cookie_id AND
                 vb.visit_id = p.visit_id AND vb.dt = p.dt;


--- Need to have session IDs for if someone plays content, then goes back to it, can't just use the first occurance.


DROP TABLE IF EXISTS vb_tv_nav_example2;
CREATE TABLE vb_tv_nav_example2 AS
SELECT *,
       row_number()
       OVER (PARTITION BY unique_visitor_cookie_id,visit_id ORDER BY event_start_datetime) AS visit_row_id
FROM vb_tv_nav_example
ORDER BY unique_visitor_cookie_id, visit_id, event_position;

SELECT * FROM vb_tv_nav_example2 ORDER BY unique_visitor_cookie_id, visit_id, event_position;

CREATE TABLE vb_session_num AS
SELECT DISTINCT unique_visitor_cookie_id,
                visit_id,
                current_ep_id,
                row_number()
                OVER (PARTITION BY unique_visitor_cookie_id,visit_id ORDER BY event_start_datetime) AS visit_row_id
FROM vb_tv_nav_example;
-------------
SELECT * FROM vb_tv_nav_example a
LEFT JOIN vb_session_num b ON a.unique_visitor_cookie_id = b.unique_visitor_cookie_id AND a.visit_id = b.visit_id AND a.current_ep_id = b.current_ep_id
ORDER BY a.unique_visitor_cookie_id, a.visit_id, a.event_position;

-----------

SELECT *,
       CASE
           WHEN current_ep_id = LAG(current_ep_id, 1) -- current ep id same as one above
                                OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position)
               THEN LAG(visit_row_id, 1) -- then keep session count same as row count above
                    OVER (PARTITION BY unique_visitor_cookie_id, visit_id ORDER BY unique_visitor_cookie_id, visit_id, event_position)
           ELSE visit_row_id
           END AS new_session_count
FROM vb_tv_nav_example2
ORDER BY unique_visitor_cookie_id, visit_id, event_position;






SELECT DISTINCT brand_id,
                brand_title,
                series_id,
                series_title,
                episode_id,
                episode_title,
                clip_id,
                clip_title
FROM prez.scv_vmb
WHERE brand_id = 'm000csdm'
   OR series_id = 'm000csdm'
   or episode_id = 'm000csdm'
   OR clip_id = 'm000csdm';


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