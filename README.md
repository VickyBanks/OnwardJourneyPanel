# iPlayer Big-Screen Onward Journey Panel
The project was looking into the onward journey navigation bar on iPlayer big screen (TV). Here users can access more episode of the same brand as the content being viewed, or content from another brand which the user is being recommended. The navigation is only visible whilst content is being played and so the project wanted to look at whether the user's journey to the content affected both how quickly they used the menu and the content they selected from the menu. 

## Using the Scripts
1. `timeOfClick.sql` was used to find the between the content beginning and the onward navigation bar being clicked. The data was saved to the files `time_to_click_Jan2020.csv` and `next_ep_type_Jan2020.csv`.
2. `journeyToClick.sql` was used to find the location of the click that took users to the content they were viewing when they used the onward journey navigation bar. The script provides the date, unique visitor ID, visit ID, check type, and the placement, container, and attribute of the content click were saved into a .csv file.
3. `time_of_click_analysis.R` is used to produce bar charts showing how long it takes users to click the navigation bar after content begins playing.
4. `nextEpTypeAnalysis.R` produces the Sankey diagram showing what type of content users' click on the navigatio bar take the to.
5. `clickOrigin.R` investigates how the origin of the content affects whether the navigation was clicked. 
6. `contentClickToNavClickJourney.R` joins the origin of content to the destination of a click to see what similarities and differences there across the whole journey.
7. `TV Onward Journey Navigation.Rmd` contains the full analysis of the project using the graphs and charts created within the above scripts.

## Script Description and Purpose

### timeOfClick.sql
This script identifies any visit where the user clicked on the navigation bar as recorded in the **s3_audience.publisher** table in the **SCV** between **2020-01-15** and **2020-01-29** and takes every record for that visit. The first instance of the content ID associated with the episode being viewed when the navigation clicks occurred is identified as the start of viewing content. The time between this event and the navigation click is recorded as the time to click. This method ensures that the time only begins when the user is actually able to click the navigation bar for example after any gates are closed or trailers are completed. This happens for any and all navigation clicks within a single visit. This was saved as the file `time_to_click_Jan2020.csv`.

The script then went onto identify where the click took the user. Firstly, a simplified version of `prez.scv_vmb` was created only containing video content. Names of content series were then simplified and multiple version of series (e.g. 30-minute cut downs compared to the full content) renamed to identify them as distinct content. A running episode count was then added to enable the analysis to identify that the 'next episode' for the final episode in a series is the first of the following series.

The content users navigated to was then categorised as being the same brand, same series, next episode, or not for all cases. For example something of a different brand would be given 0, 0, 0, respectively, the next episode of the same brand and series would be 1, 1, 1 whereas the next episode falling in another series would be 1, 0, 1. This data was then saved out as the file `next_ep_type_Jan2020.csv`.

### journeyToClick.sql

The aim of this script was to identify the origin of the click that lead to content being view along with the destination of the navigation bar click. As with the previous SQL script, any visit where the user clicked on the navigation bar as recorded in the **s3_audience.publisher** table in the **SCV** between **2020-01-15** and **2020-01-29** and takes every record for that visit. 

Then any click that might lead to content playing was selected for those visits. 
These clicks included:

* Clicks direct to content from the homepage, a tleo page, a channel page, category page or search.
* Clicks from the autoplay system where automatic play happens, or a user clicks the content before the autoplay occurs.
* Deep links to content from off platform, either through live viewing triggers (e.g. red button) or other providers (e.g. amazon).

For each piece of content being viewed when the navigation bar was selected, the master brand was identified by joining the visit information to the **prez.id_profile** table using the content ID of the episode being viewed. For content coming from categories pages the content ID was no available, so the master brand was set as 'CBBC' or 'CBeebies' for content from those categories, but for other categories that contain content from any Masterbrand this was left blank. For content coming from a channel page the ID was also not available, so the master brand was set as the channel's Masterbrand. Master brand was needed to check that the click to content identified was indeed a click to the content being viewed when the navigation bar was used. 


The origin of content was identified as the click to content occurring directly before the navigation click. Where possible, the ID of the destination content of the content click was matched with the content being viewed when the navigation was selected. If not possible the master brand was matched, and if still not possible the click directly before was clicked. The level of check was noted down for future reference.


In order for comparison to be made, the percentage of clicks to content coming from each origin was also found for every piece of content viewed in every visit, regardless of the onward navigation being used. 

The date, unique visitor ID, visit ID, check type, and the placement, container, and attribute of the content click were saved into the files `allContentClickOrigins.csv` and `navContentClickOrigins`. 

### time_of_click_analysis.R

This script took in the file `time_to_click_Jan2020.csv` which was the output from the `timeOfClick.sql` script. The script then split the times into one-minute intervals and created graphs to visualised how long it took users to click. The graphs created showed the time to click for all clicks, for clicks to the recommended content and the related content separately, and for clicks taking users to different destinations.

### nextEpTypeAnalysis.R

This script is used to produce a Sankey diagram illustrating the flow of users to from the content they're viewing to the content their navigation click takes them to. For example, 23% of clicks take users to the next episode within the same series. 

### clickOrigin.R

This script looks at how users got to the content where they then clicked the onward journey navigation bar and what affect that has on their behaviour compared to all users including those who both did and did not click the navigation bar. 

It looks at these key parts:

* The number of navigation clicks per visit and the percentage of clicks that has each level of check on them. 
* The origin of content (i.e. from the homepage, a channel page, or a TLEO page) and what proportion each origin contributes.
* The method used by users to move from one episode to another (i.e. navigation click, autoplay etc.). The same was done for content views coming from the homepage. 
* The rate of user's clicking the navigation bar per content origin.
* The rate of user's clicking the navigation bar depending on which homepage module was their origin.


### contentClickToNavClickJourney.R
This script pulls together the information about the user's origin and destination from viewing content and clicking the navigation bar (i.e. the sequence *origin -> content view -> navigation click -> destination content*). 

The proportion of clicks going to each destination is compared for each origin to see if the origin affects destination. A Sankey diagram is then produced showing the flow of content viewing from the different origins to the different destinations. This is manipulatable as so nodes can be moved if desired whilst clicking or hovering will reveal raw numbers. A series of bar charts is then produced showing how the time to click the navigation depends on the origin of the content, whilst another graph shows the how the proportion of clicks each minute to each destination changes over time.




