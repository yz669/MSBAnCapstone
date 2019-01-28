---
layout: page
title: Capstone Project (MS Business Analytics) 
tagline: Behavioral segmentation and forecasting based on natural gas consumption
description:
---
*Vineeta Agarwal, Pragati Awasthi, Alex Graber, Grace Li, Faiz Nassur, Khushbu Pandit, An Tran, Yi Zhu*

# Business Problem
A local utility company uses Rate Codes to help define the rates that accountholders pay for natural gas and electricity. Rate codes help the company correctly bill customers; rate codes are determined at the time of sign-up using best available data regarding expected use (commercial vs. residential, gas vs. electric heating, pool vs no pool).  It is possible that a customer may not know all of their appliances or energy use needs when creating an account, leading to potential rate code misclassification.  Additionally, customers within each rate code group may not have similar use patterns, leading to decreased accuracy when forecasting by rate code.
Data was provided by the local utility company.  All PII was removed/obfuscated.

The objective of the project is to build and validate a customer segmentation based on the influence of weather to enable the company to create more accurate forecasts for natural gas consumption. The project scope includes:
1.	Understand current Rate Code segmentation and forecast applications
2.	Create a new segmentation based on the influence weather attributes have on natural gas consumption
3.	Identify the best forecast models for each segment
4.	Identify potential rate code mislabeling 

# Analysis and Modeling
### Procedure
Broadly speaking, our procedure for analysis and modelling consisted of 4 main steps (see Figure 1 below):
1.	Identify differing use patterns and group meter IDs according to similarity of use.
2.	Create forecasting models and identify optimal model for each cluster.
3.	Compare forecast accuracy from forecasts based on clusters to accuracy from forecasts based on rate code
4.	Identify accounts where actual patterns of use do not align with anticipated patterns inferred from rate codes.

![Figure 1](/assets/Fig1.png)

### Segmentation
Segmentation seeks to identify groups with similar behavior.  As our task was to identify a weather-based model, we wanted to understand how each customer (meter ID) behaved with respect to weather.  With that in mind, we created groups by answering the following questions: “On average, how much gas use does the meter read,” and “How does the metered use respond to changes in temperature?” 
To understand how much gas each meter used, we calculated each meter’s average use from 2017 to 2018.  Looking at the distribution of consumption, we defined 4 thresholds, creating 5 clusters where the meters in each group all have similar average daily use (see Figures 2,3):


Objective: Build & validate segmentation that includes influence of weather to enable more accurate forecasting.  Evaluate by creating simple forecast models.

