library(dplyr)
library(rJava)
library(openxlsx)
library(ggplot2)
library(zoo)
library(readxl)
library(corrplot)
library(reshape)
library(lubridate)
library('forecast')
library('tseries')
library(lmtest)
library(data.table)
library(dplyr)

#Read the weather data - temperature
weather_tmp <- read_xlsx('Weather Data for Drexel 9_28_2018.xlsx', sheet = 1)
weather_tmp <- weather_tmp[-c(36:37)]

#Filter to include users from 2017 - 2018
weather_tmp <- weather_tmp %>% filter(Dt > as.POSIXct("2016-12-31") & Dt <=  as.POSIXct("2018-09-30"))
weather_tmp$Dt <- (format(weather_tmp$Dt, format = "%m/%d/%Y"))
weather_tmp$monthYear  <- format(as.Date(weather_tmp$Dt, "%m/%d/%Y"), "%m/%Y")
weather_tmp$Dt <- mdy(weather_tmp$Dt)

#filter for gas usage
filter_CCF <- function(df){
  df$monthYear  <- format(as.Date(df$METERREADDATE, "%m/%d/%Y"), "%m/%Y")
  df$AVG_GAS_USAGE <- rowMeans(df[,c(5:29)])
  df$DAILY_GAS_USAGE <- rowSums(df[,c(5:29)])
  df <- df[df$UOM == "CCF",]
  df <- df %>% select(-starts_with("INTERVAL"))
}


##Read 2016 winter data
hourly_2016.10 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2016.10.xlsx',  sheet = 1)) 
hourly_2016.11 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2016.11.xlsx',  sheet = 1))
hourly_2016.11 <- hourly_2016.11 %>% select(-c(Min_Usage, Avg_Usage, Max_Usage))
hourly_2016.12 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2016.12.xlsx',  sheet = 1))
hourly_2016.12 <- hourly_2016.12 %>% select(-c(Min_Usage, Avg_Usage, Max_Usage))

#2017 data - use as training set for forecasting 2018
hourly_2017.01 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.01.xlsx',  sheet = 1))
hourly_2017.02 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.02.xlsx',  sheet = 1))
hourly_2017.02 <- hourly_2017.02 %>% select(-DAILY_INTERVAL_USAGE)
hourly_2017.03 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.03.xlsx',  sheet = 1))
hourly_2017.03 <- hourly_2017.03 %>% select(-c(Min_Usage, Avg_Usage, Max_Usage))
hourly_2017.04 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.04.xlsx',  sheet = 1))
hourly_2017.04 <- hourly_2017.04 %>% select(-c(Min_Usage, Avg_Usage, Max_Usage))
hourly_2017.05 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.05.xlsx',  sheet = 1))
hourly_2017.06 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.06.xlsx',  sheet = 1))
hourly_2017.07 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.07.xlsx',  sheet = 1))
hourly_2017.08 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.08.xlsx',  sheet = 1))
hourly_2017.09 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.09.xlsx',  sheet = 1))
hourly_2017.10 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.10.xlsx',  sheet = 1))
hourly_2017.11 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.11.xlsx',  sheet = 1))
hourly_2017.12 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2017.12.xlsx',  sheet = 1))
####
data_2017 <- rbind(hourly_2017.01, hourly_2017.02, hourly_2017.03,hourly_2017.04,
                    hourly_2017.05, hourly_2017.06, hourly_2017.07, hourly_2017.08,
                    hourly_2017.09, hourly_2017.10, hourly_2017.11, hourly_2017.12)

#2018 data
hourly_2018.01 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.01.xlsx',  sheet = 1))
hourly_2018.02 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.02.xlsx',  sheet = 1))
hourly_2018.03 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.03.xlsx',  sheet = 1))
hourly_2018.04 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.04.xlsx',  sheet = 1))
hourly_2018.05 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.05.xlsx',  sheet = 1))
hourly_2018.06 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.06.xlsx',  sheet = 1))
hourly_2018.07 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.07.xlsx',  sheet = 1))
hourly_2018.08 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.08.xlsx',  sheet = 1))
hourly_2018.09 <- filter_CCF(read.xlsx('PECO Zip HourlyUsage_2018.09.xlsx',  sheet = 1))

data_2018 <- rbind(hourly_2018.01,hourly_2018.02,hourly_2018.03,hourly_2018.04,hourly_2018.05,
                   hourly_2018.06, hourly_2018.07, hourly_2018.08, hourly_2018.09)

#Combinee 2018 and 2018 data
final_data <- rbind(data_2017,data_2018)

training_data <- rbind(hourly_2017.11, hourly_2017.12, hourly_2018.01, hourly_2018.02)
testing_data <- rbind(hourly_2016.11, hourly_2016.12, hourly_2017.01, hourly_2017.02)
final_data <- rbind(testing_data, training_data)

all_clusters <- read.xlsx('all.xlsx')
final_codebook <- read.csv('final_codebook_combined_v2.csv')
weather_data <- weather_tmp %>% filter(monthYear %in% c("11/2016","12/2016","01/2017","02/2017","11/2017",
                                                       "12/2017","01/2018","02/2018"))
weather_data$Dt <- mdy(weather_data$Dt)

weather_data_no2016 <- weather_tmp %>% filter(monthYear %in% c("01/2017","02/2017","11/2017",
                                                               "12/2017","01/2018","02/2018"))
weather_data_no2016$Dt <- mdy(weather_data_no2016$Dt)

#Forecast for months where 2016 is not included
get_cluster_forecast_no2016 <- function(cluster){
      level_cluster <- final_codebook %>% filter(Cluster == cluster)
      users_cluster <- final_data[(final_data$DMETERNO %in% level_cluster$DMETERNO),]
      users_cluster <- users_cluster %>% group_by(METERREADDATE) %>% summarise(DAILY_USAGE = mean(AVG_GAS_USAGE))
      users_cluster$METERREADDATE <- mdy(users_cluster$METERREADDATE)
      users_cluster <- users_cluster %>% arrange(METERREADDATE)
      
      combined_cluster <- cbind(users_cluster, weather_data_no2016)
      combined_cluster <- combined_cluster %>% select(-Dt)
      combined_cluster <- combined_cluster %>% select(-starts_with('HR'))
      combined_cluster$cnt_ma = ma(combined_cluster$DAILY_USAGE, order=1) 
      count_ma = ts(na.omit(combined_cluster$cnt_ma), frequency=7)
      
      decomp = stl(count_ma, s.window="periodic")
      deseasonal_cnt <- seasadj(decomp)
      plot(decomp)
      
      fit_no_holdout = auto.arima(ts(deseasonal_cnt[-c(121:179)]), 
                                  xreg = combined_cluster$Avg[-c(121:179)],seasonal = FALSE)
      
      xreg_store <- cbind(model.matrix(~as.numeric(combined_cluster$Avg[-c(121:179)])))
      xreg_store <- xreg_store[,-1]
      
      fcast_no_holdout <- forecast(fit_no_holdout,h=59, level = c(0,0), xreg = xreg_store)
      plot(fcast_no_holdout, main = "Gas usage Forecast", xaxt = "n",
           xlab ="Time Period", ylab="Average gas usage" )
      lines(ts(deseasonal_cnt))
      axis(1, at=1:179, labels=format(as.Date(combined_cluster$METERREADDATE),"%b-%Y"))
      return(fcast_no_holdout)
}

#Forecast for data where 2016 is included
get_cluster_forecast <- function(cluster){
  level_cluster <- final_codebook %>% filter(Cluster == cluster)
  users_cluster <- final_data[(final_data$DMETERNO %in% level_cluster$DMETERNO),]
  users_cluster <- users_cluster %>% group_by(METERREADDATE) %>% summarise(DAILY_USAGE = mean(AVG_GAS_USAGE))
  users_cluster$METERREADDATE <- mdy(users_cluster$METERREADDATE)
  users_cluster <- users_cluster %>% arrange(METERREADDATE)
  
  combined_cluster <- cbind(users_cluster, weather_data)
  combined_cluster <- combined_cluster %>% select(-Dt)
  combined_cluster <- combined_cluster %>% select(-starts_with('HR'))
  combined_cluster$cnt_ma = ma(combined_cluster$DAILY_USAGE, order=1) 
  count_ma = ts(na.omit(combined_cluster$cnt_ma), frequency=7)

  decomp = stl(count_ma, s.window="periodic")
  deseasonal_cnt_high_c1 <- seasadj(decomp)
  plot(decomp)
  
  fit_no_holdout_high = auto.arima(ts(deseasonal_cnt[-c(182:240)]), 
                                      xreg = combined_cluster$Avg[-c(182:240)],seasonal = FALSE)
  
  xreg_store <- cbind(model.matrix(~as.numeric(combined_cluster$Avg[-c(182:240)])))
  xreg_store <- xreg_store[,-1]
  
  fcast_no_holdout <- forecast(fit_no_holdout,h=61, level = c(0,0), xreg = xreg_store)
  plot(fcast_no_holdout, main = "Gas usage for Residential customers cluster 2", xaxt = "n",
       xlab ="Time Period", ylab="Average gas usage" )
  lines(ts(deseasonal_cnt))
  return(fcast_no_holdout)
}

get_cluster_forecast_3 <- function(cluster){
  level_cluster <- final_codebook %>% filter(Cluster == cluster)
  users_cluster <- final_data[(final_data$DMETERNO %in% level_cluster$DMETERNO),]
  users_cluster <- users_cluster %>% group_by(METERREADDATE) %>% summarise(DAILY_USAGE = mean(AVG_GAS_USAGE))
  users_cluster$METERREADDATE <- mdy(users_cluster$METERREADDATE)
  users_cluster <- users_cluster %>% arrange(METERREADDATE)
  
  weather_data_no2016 <- weather_data_no2016 %>% filter(Dt != '2017-12-20')
  combined_cluster <- cbind(users_cluster, weather_data_no2016)
  combined_cluster <- combined_cluster %>% select(-Dt)
  combined_cluster <- combined_cluster %>% select(-starts_with('HR'))
  combined_cluster$cnt_ma = ma(combined_cluster$DAILY_USAGE, order=1) 
  count_ma = ts(na.omit(combined_cluster$cnt_ma), frequency=7)
  
  decomp = stl(count_ma, s.window="periodic")
  deseasonal_cnt <- seasadj(decomp)
  plot(decomp)
  
  fit_no_holdout = auto.arima(ts(deseasonal_cnt[-c(121:179)]), 
                              xreg = combined_cluster$Avg[-c(121:179)],seasonal = FALSE)
  
  xreg_store <- cbind(model.matrix(~as.numeric(combined_cluster$Avg[-c(121:179)])))
  xreg_store <- xreg_store[,-1]
  
  fcast_no_holdout <- forecast(fit_no_holdout,h=59, level = c(0,0), xreg = xreg_store)
  plot(fcast_no_holdout, main = "Gas usage for Residential customers cluster 2",
       xlab ="Time Period", ylab="Average gas usage" )
  lines(ts(deseasonal_cnt))
  return(fcast_no_holdout)
}


get_cluster_forecast_final <- function(cluster){
  level_cluster <- final_codebook %>% filter(Cluster == cluster)
  users_cluster <- final_data[(final_data$DMETERNO %in% level_cluster$DMETERNO),]
  users_cluster <- users_cluster %>% group_by(METERREADDATE) %>% summarise(DAILY_USAGE = mean(AVG_GAS_USAGE))
  users_cluster$METERREADDATE <- mdy(users_cluster$METERREADDATE)
  users_cluster <- users_cluster %>% arrange(METERREADDATE)
  
  combined_cluster <- cbind(users_cluster, weather_tmp)
  combined_cluster <- combined_cluster %>% select(-Dt)
  combined_cluster <- combined_cluster %>% select(-starts_with('HR'))
  combined_cluster$cnt_ma = ma(combined_cluster$DAILY_USAGE, order=1) 
  count_ma = ts(na.omit(combined_cluster$cnt_ma), frequency=7)
  
  decomp = stl(count_ma, s.window="periodic")
  deseasonal_cnt <- seasadj(decomp)
  plot(decomp)
  
  fit_no_holdout = auto.arima(ts(deseasonal_cnt[-c(121:179)]), 
                              xreg = combined_cluster$Avg[-c(121:179)],seasonal = FALSE)
  
  xreg_store <- cbind(model.matrix(~as.numeric(combined_cluster$Avg[-c(121:179)])))
  xreg_store <- xreg_store[,-1]
  
  fcast_no_holdout <- forecast(fit_no_holdout,h=59, level = c(0,0), xreg = xreg_store)
  plot(fcast_no_holdout, main = "Gas usage for Residential customers cluster 2",
       xlab ="Time Period", ylab="Average gas usage" )
  lines(ts(deseasonal_cnt))
  return(fcast_no_holdout)
}

#Huge Cluster 1
fcast_huge_c1 <- get_cluster_forecast_final('Huge_NoResp')
level_cluster <- final_codebook %>% filter(Cluster == 'Huge_NoResp')
users_cluster <- final_data[(final_data$DMETERNO %in% level_cluster$DMETERNO),]
users_cluster <- users_cluster %>% group_by(METERREADDATE) %>% summarise(DAILY_USAGE = mean(AVG_GAS_USAGE))
users_cluster$METERREADDATE <- mdy(users_cluster$METERREADDATE)
users_cluster <- users_cluster %>% arrange(METERREADDATE)

weather <- weather_data_no2016[c(121:179),] %>% select(Dt)
huge_c1 <- cbind(weather,fcast$`Point Forecast`)
acc_huge_c1 <- accuracy(fcast_huge_c1)
acc_huge_c1

acc_huge_c2 <- accuracy(get_cluster_forecast('Huge_Resp'))
acc_huge_c2

#High Cluster 1 - No Response
acc_high_c1 <- accuracy(get_cluster_forecast_no2016('High_NoResp'))
acc_high_c1

#High Cluster 2 - Response to cold weather
acc_high_c2 <- accuracy(get_cluster_forecast_no2016('High_Resp'))
acc_high_c2

acc_high_c3 <- accuracy(get_cluster_forecast_3('High_ColdResp'))
acc_high_c3

acc_moderate_c1 <- accuracy(get_cluster_forecast_no2016('Mod_NoResp'))
acc_moderate_c1

acc_moderate_c2 <- accuracy(get_cluster_forecast_no2016('Mod_Resp'))
acc_moderate_c2

acc_moderate_c3 <- accuracy(get_cluster_forecast_3('Mod_ColdResp'))
acc_moderate_c3

acc_light <- accuracy(get_cluster_forecast_no2016('Light'))
acc_light

acc_min_c1 <- accuracy(get_cluster_forecast_no2016('Min_NoResp'))
acc_min_c1

acc_min_C2 <- accuracy(get_cluster_forecast_no2016('Min_Resp'))
acc_min_C2

acc_min_c3 <- accuracy(get_cluster_forecast_no2016('Min_ColdResp'))
acc_min_c3


#Huge Cluster 1
fcast_huge_c1 <- get_cluster_forecast_no2016('Huge_NoResp')
fcast <- as.data.frame(fcast_huge_c1$fitted)
weather <- weather_data_no2016[c(121:179),] %>% select(Dt)
huge_c1 <- cbind(weather,fcast$`Point Forecast`)
acc_huge_c1 <- accuracy(fcast_huge_c1)
acc_huge_c1

acc_huge_c2 <- accuracy(get_cluster_forecast('Huge_Resp'))
acc_huge_c2

#High Cluster 1 - No Response
acc_high_c1 <- accuracy(get_cluster_forecast_no2016('High_NoResp'))
acc_high_c1

#High Cluster 2 - Response to cold weather
acc_high_c2 <- accuracy(get_cluster_forecast_no2016('High_Resp'))
acc_high_c2

acc_high_c3 <- accuracy(get_cluster_forecast_3('High_ColdResp'))
acc_high_c3

acc_moderate_c1 <- accuracy(get_cluster_forecast_no2016('Mod_NoResp'))
acc_moderate_c1

acc_moderate_c2 <- accuracy(get_cluster_forecast_no2016('Mod_Resp'))
acc_moderate_c2

acc_moderate_c3 <- accuracy(get_cluster_forecast_3('Mod_ColdResp'))
acc_moderate_c3

acc_light <- accuracy(get_cluster_forecast_no2016('Light'))
acc_light

acc_min_c1 <- accuracy(get_cluster_forecast_no2016('Min_NoResp'))
acc_min_c1

acc_min_C2 <- accuracy(get_cluster_forecast_no2016('Min_Resp'))
acc_min_C2

acc_min_c3 <- accuracy(get_cluster_forecast_no2016('Min_ColdResp'))
acc_min_c3

