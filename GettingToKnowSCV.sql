--1. How many distinct unique visitors were there to iPlayer, Sounds and both in the last week and last month.
SELECT * FROM audience.audience_activity_daily_summary_enriched LIMIT 5;

SELECT destination, COUNT(DISTINCT audience_id)
FROM audience.audience_activity_daily_summary_enriched
WHERE date_of_event > '2020-01-01'
    AND destination = 'PS_IPLAYER'
   OR destination = 'PS_SOUNDS'
GROUP BY destination;
-- destination,count
-- PS_IPLAYER,16,013,032
-- PS_SOUNDS,13,092,306

SELECT COUNT(DISTINCT audience_id)
FROM audience.audience_activity_daily_summary_enriched
WHERE date_of_event > '2020-01-01'
    AND destination = 'PS_IPLAYER'
   OR destination = 'PS_SOUNDS';

-- 22,187,251


--2. How many 16-34s are there in our database - how many male/female

SELECT gender, COUNT(DISTINCT bbc_hid3) FROM prez.id_profile
WHERE age >= 16 AND age <= 34
GROUP BY gender;

/*gender,count
null , 4,381,151
prefer not to say,  810,568
other, 177,510
male,  7,502,747
female, 7,523,864  */


--3. How many unique 16-34s were there on iPlayer yesterday?
--4. How many events fire on the home page when it loads?
--5. How many clicks and impressions are there in the average visit?
--6. How many types of tv were used to watch iPlayer yesterday?
--7. What 5 places along the featured row had the most clicks?
--8. When auto play happens how do you identify the current ID of the content and the ID of the next episode?