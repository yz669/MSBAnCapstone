---
layout: page
title: Capstone Project (MS Business Analytics) 
tagline: Behavioral segmentation and forecasting based on natural gas consumption
description:
---
*Vineeta Agarwal, Pragati Awasthi, Alex Graber, Grace Li, Faiz Nassur, Khushbu Pandit, An Tran, Yi Zhu*

# Business Problem
A local utility company uses Rate Codes to help define the rates that accountholders pay for natural gas and electricity. Rate codes help the company correctly bill customers; rate codes are determined at the time of sign-up using best available data regarding expected use (commercial vs. residential, gas vs. electric heating, pool vs no pool).  It is possible that a customer may not know all of their appliances or energy use needs when creating an account, leading to potential rate code misclassification.  Additionally, customers within each rate code group may not have similar use patterns, leading to decreased accuracy when forecasting by rate code.  
Billing is done based on use where use is defined at the local meter; electricity is billed based on kilowatt-hour (kWh) used, and gas is billed based on 100 cubic feet (CCF) used.  
Data was provided by the local utility company.  All PII was removed/obfuscated.

The objective of the project is to build and validate a customer segmentation based on the influence of weather to enable the company to create more accurate forecasts for natural gas consumption. The project scope includes:
1.	Understand current Rate Code segmentation and forecast applications
2.	Create a new segmentation based on the influence weather attributes have on natural gas consumption
3.	Identify the best forecast models for each segment
4.	Identify potential rate code mislabeling 

<details><summary>Summary</summary>
   
# Summary  

1. Retroactively adding account attributes such as magnitude of average use and response to temperature may support improved forecasting and billing abilities.  
    * Response to temperature must be defined over a timeframe that experiences temperate and cold temperatures (Sept – Feb).
    * Segmenting by magnitude of average use reduces regression errors, but also requires a history of use over a timeframe that experiences both warm and cold temperatures.
    * The few accounts in the ‘huge’ magnitude category have highly varied use, making forecasting as a cluster challenging.
2. 83% of meters demonstrate temperature-driven gas consumption; these meters account for only 54% of total gas sold in 2018.
    * The majority of meters are temperature-driven based on our analysis.
      * Weather-based forecasting works well for these accounts, covering residential and small/medium commercial meters.
    * A few (11) large, commercial accounts are not weather-driven and account for nearly half of the gas consumption Jan-Sept, 2018.
      * Forecasting for these large accounts is challenging; use is not easily predicted by weather or history.
3. Forecast models using prior temperature and change in temperature are sufficient to predict gas use for temperature responders.
    * Among responder groups, the prior day’s lowest temperature and the change from day to day explains approximately 80% of the change in daily use.
    * Hourly forecasts based on the prior hour’s low and change in temperature over the past 6 hours do not perform as well as a daily model.
    * Weather-based forecasts require anticipated future temperatures to predict future use; we recommend using them in the near-term (potentially to improve spot-market purchase predictions).
    * Models based on historic use do not perform any better than weather models, even on clusters that do not respond to weather.
4. Weather models demonstrate significantly better performance on responder clusters, as opposed to non-responders or PECO Rate Codes.
5. When comparing clusters to Rate Codes, we identified a small proportion of customers who may be misclassified and need further investigation.
    * 17% of residential meters and 3% of commercial meters exhibit average use < 1.5 CCF / day and are not responsive to weather.  However, they are billed using the gas heat Rate Code.
    * Of the accounts that have both a gas and electric meter, 14% are minimal gas users and not responsive to weather.  However, they are billed using the electric non-heat Rate Code.
    * Adding response to weather to PECO’s current rate codes may help improve forecasting for responsive groups, and help identify potentially misclassified accounts.

</details>



# Analysis and Modeling
<details><summary>Procedure</summary>
   
### Procedure  

Broadly speaking, our procedure for analysis and modelling consisted of 4 main steps (see Figure 1 below):
1.	Identify differing use patterns and group meter IDs according to similarity of use.
2.	Create forecasting models and identify optimal model for each cluster.
3.	Compare forecast accuracy from forecasts based on clusters to accuracy from forecasts based on rate code
4.	Identify accounts where actual patterns of use do not align with anticipated patterns inferred from rate codes.

![Figure 1](/assets/Fig1.png)

</details> 

<details><summary>Segmentation</summary>
   
### Segmentation  

Segmentation seeks to identify groups with similar behavior.  As our task was to identify a weather-based model, we wanted to understand how each customer (meter ID) behaved with respect to weather.  With that in mind, we created groups by answering the following questions: “On average, how much gas use does the meter read,” and “How does the metered use respond to changes in temperature?” 
To understand how much gas each meter used, we calculated each meter’s average use from 2017 to 2018.  Looking at the distribution of consumption, we defined 4 thresholds, creating 5 clusters where the meters in each group all have similar average daily use (see Figures 2,3):

![Figure 2](/assets/App1.png)

We expect residential and small commercial accounts to have relatively small daily usage, and only large commercial and industrial accounts to have high use. As 88% of our population are residential customers, it makes sense that we have a large population of customers who fall into minimal and low usage clusters.  

![Figure 3](/assets/Fig3.png)

In order to understand how use responds to weather, we had a hypothesis that as temperatures decrease, gas use should increase when it is used as a source of heating.  Therefore, we looked at use from September 2017 to February 2018 as these months should exhibit temperature variation and also contain the coldest temperatures of the year.  We then examined temperature vs average gas use for each date and meter.  This allowed us to identify whether and how each meter’s use changes in response to the temperature.  
The goal of clustering is to identify groups of meters that have similar behavior which we interpreted as similar weather responses.  We used an algorithm called k-shape that identifies similarities between time-series data, allowing us to identify groups with similar behavior.  Using k-shape, we identified 2 clusters (see Figures 4, 5) based on whether their gas consumption is responsive to temperate and cold temperatures or not.  The weather-responsive cluster demonstrates gas consumption with a directly inverse relationship to temperature.  Clusters that do not directly respond to weather (‘non-responders’) may ignore large temperature swings, demonstrate high use that is not related to weather, or behave non-intuitively. 

![Figure 4](/assets/Fig4.png)

![Figure 5](/assets/Fig5.png)

The majority (84%) of the meters in our data are responders (see Figure 6).  As with the magnitude of use analysis, this makes sense as most of our meters belong to residential accounts, which primarily use natural gas for heating.  When gas is used for heating, we would expect to see use increase as temperatures decrease.

![Figure 6](/assets/Fig6.png)

Combining magnitude of use and response to temperature analyses, we identified 10 clusters (5 use, 2 response).  However, no accounts exist in the low use non-responder category, leaving us with 9 clusters, of which the largest cluster has low average use (1.5-3.5 CCF per day) and responds to weather. 

![Figure 7](/assets/Fig7.png)

</details> 

