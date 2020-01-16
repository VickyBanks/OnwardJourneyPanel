SELECT * FROM s3_audience.publisher
WHERE metadata LIKE '%iplayer::bigscreen-html%'
ORDER BY unique_visitor_cookie_id, visit_id, event_position
LIMIT 50
;

SELECT * FROM  s3_audience.publisher
WHERE container LIKE '%page-section-related%' AND metadata LIKE '%iplayer::bigscreen-html%'
ORDER BY unique_visitor_cookie_id, visit_id, event_position
LIMIT 50;


SELECT visit_id, event_position,attribute, placement, left(right(placement, 13),8) AS current_ep_id, result AS next_ep_id, publisher_clicks, publisher_impressions
FROM s3_audience.publisher
WHERE container LIKE '%page-section-related%' AND metadata LIKE '%iplayer::bigscreen-html%'
ORDER BY visit_id, event_position
LIMIT 10;

