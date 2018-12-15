# Natural Gas Arima Forecasting


# Install and Load libraries
## Install the necessary packages - tidyr, dplyr, ggplot2, readxl, caret, forecast, tseries, TSA, reshape, reshape2, lubridate

library(tidyr)
library(dplyr)
library(ggplot2)
library(readxl)
library(caret)
library(forecast)
library(tseries)
library(TSA)
library(reshape)
library(lubridate)
library(reshape2)

# Data Input and Wrangling
##Read in customer information  and weather data

zip_customer <- read_xlsx("PECO Zip Customer 2018.10.01 v2.xlsx", 1)
zip_customer_details <- read_xlsx("PECO Zip Customer 2018.10.01 v2.xlsx", 2)
weather_data_tmp <- read_xlsx("Weather Data for Drexel 9_28_2018.xlsx", 1)
weather_data_hum <- read_xlsx("Weather_humidity.xlsx", 1)
weather_data_wsp <- read_xlsx("Weather Data for Drexel 9_28_2018.xlsx", 3)
weather_data_cc <- read_xlsx("Weather_cc.xlsx", 1)
## Fitler customer ata based on Unit of measurement = CCF
## 2018 Data
hour_sept_2018 <- read_xlsx("PECO Zip HourlyUsage_2018.09.xlsx",1)%>%filter(UOM=="CCF") 
hour_aug_2018 <- read_xlsx("PECO Zip HourlyUsage_2018.08.xlsx",1)%>%filter(UOM=="CCF")
hour_july_2018 <- read_xlsx("PECO Zip HourlyUsage_2018.07.xlsx", 1)%>%filter(UOM=="CCF")
hour_june_2018 <- read_xlsx("PECO Zip HourlyUsage_2018.06.xlsx",1)%>%filter(UOM=="CCF")
hour_may_2018<- read_xlsx("PECO Zip HourlyUsage_2018.05.xlsx",1)%>%filter(UOM=="CCF")
hour_april_2018<- read_xlsx("PECO Zip HourlyUsage_2018.04.xlsx",1)%>%filter(UOM=="CCF")
hour_march_2018<- read_xlsx("PECO Zip HourlyUsage_2018.03.xlsx",1)%>%filter(UOM=="CCF")
hour_feb_2018<- read_xlsx("PECO Zip HourlyUsage_2018.02.xlsx",1)%>%filter(UOM=="CCF")
hour_jan_2018 <- read_xlsx("PECO Zip HourlyUsage_2018.01.xlsx", 1)%>%filter(UOM=="CCF")

## 2017 Data
hour_jan_2017<- read_xlsx("PECO Zip HourlyUsage_2017.01.xlsx",1)%>%filter(UOM=="CCF")
hour_feb_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.02.xlsx",1)%>%filter(UOM=="CCF")
hour_march_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.03.xlsx",1)%>%filter(UOM=="CCF")
hour_april_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.04.xlsx",1)%>%filter(UOM=="CCF")
hour_may_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.05.xlsx",1)%>%filter(UOM=="CCF")
hour_june_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.06.xlsx",1)%>%filter(UOM=="CCF")
hour_july_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.07.xlsx",1)%>%filter(UOM=="CCF")
hour_aug_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.08.xlsx",1)%>%filter(UOM=="CCF")
hour_sept_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.09.xlsx",1)%>%filter(UOM=="CCF")
hour_oct_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.10.xlsx",1)%>%filter(UOM=="CCF")
hour_nov_2017 <- read_xlsx("PECO Zip HourlyUsage_2017.11.xlsx",1)%>%filter(UOM=="CCF")
hour_dec_2017<- read_xlsx("PECO Zip HourlyUsage_2017.12.xlsx",1)%>%filter(UOM=="CCF")

## 2016 Data
hour_oct_2016 <- read_xlsx("PECO Zip HourlyUsage_2016.10.xlsx",1)%>%filter(UOM=="CCF")
hour_nov_2016 <- read_xlsx("PECO Zip HourlyUsage_2016.11.xlsx",1)%>%filter(UOM=="CCF")
hour_dec_2016 <- read_xlsx("PECO Zip HourlyUsage_2016.12.xlsx",1)%>%filter(UOM=="CCF")


# Building Functions

## Function to generate hourly data using arguments based on weather data, customer data, month, year, customer segment, cluster size
get_hour_df<- function(w_df, DF,month,year,customer_segment,cs_type="residential",cluster,size="S"){
  if(cs_type=="residential") {
    customer_segment <- customer_segment%>%filter(Cluster==cluster)
  } 
  if(cs_type=="commercial"){
    customer_segment <- customer_segment%>%filter(Cluster==cluster)%>%filter(Size==size)
  }
# browser()
w_df <- w_df %>% filter(format(as.Date(Dt),"%m/%Y") %in% paste0(month,"/",year))
w_df <- w_df[,c(1:25)]
w_df <- melt(w_df, id.vars = 'Dt') %>% arrange(Dt)
colnames(w_df)[3] <- "Temperature"
w_df <- w_df %>% select(-c(variable))

DF <- DF%>%filter(DMETERNO%in%customer_segment$DMETERNO)%>% select(METERREADDATE, starts_with('INTERVAL')) %>% 
  select(-c('INTERVAL_25')) %>%   arrange(METERREADDATE) 
DF <- DF %>%  group_by(METERREADDATE) %>%   summarise_all(funs(mean))
if(month=="12"&year=="2017" & cluster==2 & cs_type=="residential"|month=="12"&year=="2017"&size=="M" & cluster==1 & cs_type=="commercial"|month=="08"&year=="2018"&size=="M" & cluster==1 & cs_type=="commercial"|month=="08"&year=="2018"&size=="M" & cluster==2 & cs_type=="commercial"|month=="09"&year=="2018" & cluster==1 & cs_type=="commercial"|(month=="08"&year=="2018" & cluster==0 & cs_type=="commercial" )){
  add_on <- DF[19,]
  add_on$METERREADDATE <- "12/20/2017"
  DF <- rbind(DF,add_on)
}
DF <- melt(DF, id.vars = 'METERREADDATE') %>% arrange(METERREADDATE)

colnames(DF)[3] <- "Average Gas Usage"
DF <- DF %>% select(-c(variable))
DF <- cbind(DF, w_df)
DF2 <- DF %>% select(-c(METERREADDATE))
hours <- c(1:24)
hourly_data <- c(rep(hours,(nrow(DF)/24)))
DF3 <- as.data.frame(cbind(DF2, hourly_data))
DF3$Date <- mdy(DF$METERREADDATE) + hours(DF3$hourly_data)
DF3 <- DF3 %>% select(-c(hourly_data,Dt))
DF3 <- DF3 %>% select(Date, everything())
return(DF3)
}


# Read Clusters
## Based on K-shape and DTW we obtain our residential and commercial clusters
residential_customers <- read_xlsx("suffi_R.xlsx",1) #4718 rows
commercial_customers <- read_xlsx("suffi_C.xlsx",1) #752 rows
table(commercial_customers[,c("Cluster","Size")])

unique(residential_customers$Cluster) # 3clusters 0,1,2
unique(commercial_customers[,c("Cluster","Size")]) # 2 Large, 3 Medium, 3 Small #need to reduce these
table(commercial_customers[,c("Cluster","Size")]) # number in each #we can pick out the individual values from large


note_df <- read.csv("final_codebook_combined_v2.csv")

head(get_hour_df(weather_data_tmp,hour_jan_2017,"01","2017",cs_type = "residential",size="S",cluster = 1,customer_segment = residential_customers))

## Running the functions for each month/year and combining them into a single dataframe

jan_2017 <- get_hour_df(weather_data_tmp,hour_jan_2017,"01","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
feb_2017 <- get_hour_df(weather_data_tmp,hour_feb_2017,"02","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
march_2017 <- get_hour_df(weather_data_tmp,hour_march_2017,"03","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
april_2017 <- get_hour_df(weather_data_tmp,hour_april_2017,"04","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
may_2017 <- get_hour_df(weather_data_tmp,hour_may_2017,"05","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
june_2017 <- get_hour_df(weather_data_tmp,hour_june_2017,"06","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
july_2017 <- get_hour_df(weather_data_tmp,hour_july_2017,"07","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
aug_2017 <- get_hour_df(weather_data_tmp,hour_aug_2017,"08","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
sept_2017 <- get_hour_df(weather_data_tmp,hour_sept_2017,"09","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
oct_2017 <- get_hour_df(weather_data_tmp,hour_oct_2017,"10","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
nov_2017 <- get_hour_df(weather_data_tmp,hour_nov_2017,"11","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
dec_2017 <- get_hour_df(weather_data_tmp,hour_dec_2017,"12","2017",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)

data_2017 <- rbind(jan_2017,feb_2017,march_2017,april_2017,may_2017,june_2017,july_2017,aug_2017,sept_2017,oct_2017,nov_2017,dec_2017)

jan_2018 <- get_hour_df(weather_data_tmp,hour_jan_2018,"01","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
feb_2018 <- get_hour_df(weather_data_tmp,hour_feb_2018,"02","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
march_2018 <- get_hour_df(weather_data_tmp,hour_march_2018,"03","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
april_2018 <- get_hour_df(weather_data_tmp,hour_april_2018,"04","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
may_2018 <- get_hour_df(weather_data_tmp,hour_may_2018,"05","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
june_2018 <- get_hour_df(weather_data_tmp,hour_june_2018,"06","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
july_2018 <- get_hour_df(weather_data_tmp,hour_july_2018,"07","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
aug_2018 <- get_hour_df(weather_data_tmp,hour_aug_2018,"08","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)
sept_2018 <- get_hour_df(weather_data_tmp,hour_sept_2018,"09","2018",cs_type = "commercial",size="M",cluster = 2,customer_segment = commercial_customers)


data_2018 <- rbind(jan_2018,feb_2018,march_2018,april_2018,may_2018,june_2018,july_2018,aug_2018,sept_2018)


complete_data <- rbind(data_2017,data_2018)

## Converting Date format
complete_data$Date <-as.POSIXct(complete_data$Date, tz = "", format,
                                tryFormats = c("%Y-%m-%d %H:%M:%OS"))

## Converting to Time Series Format
count_ts = ts(complete_data[, c('Average Gas Usage')])
## Smoothening outliers
complete_data$clean_use = tsclean(count_ts)
colnames(complete_data) <- c("Date","avg_gas_usage","temp","clean_use")

#ggplot(complete_data, aes(Date, avg_gas_usage)) + geom_line() + scale_x_date('month')  + ylab("Average daily use") +xlab("")

## Sorting data by Date, and observing moving averages
temp_df <- complete_data%>%arrange(Date)
temp_df$cnt_ma = ma(temp_df$avg_gas_usage, order=1) # using the clean count with no outliers
temp_df$cnt_ma30 = ma(temp_df$avg_gas_usage, order=24)
 
 
 ggplot() +
   geom_line(data = temp_df, aes(x = METERREADDATE, y = mean_daily_usage, colour = "Counts")) +
   geom_line(data = temp_df, aes(x = METERREADDATE, y = cnt_ma,   colour = "Daily Moving Average"))  +
   geom_line(data = temp_df, aes(x = METERREADDATE, y = cnt_ma30, colour = "Monthly Moving Average"))  +
   ylab('Average gas use')


count_ma = ts(na.omit(temp_df$cnt_ma),frequency=8) #total_days/frequency

decomp = stl(count_ma, s.window="periodic")
deseasonal_cnt <- seasadj(decomp)
plot(decomp)


count_d1 = diff(deseasonal_cnt, differences = 1)
plot(count_d1)
adf.test(count_d1, alternative = "stationary")



## Using the Auto.arima model with Seasonality. The data has been partitioned to be trained on 2017 and tested on 2018.
fit_no_holdout = auto.arima(ts(deseasonal_cnt[-c(8759:15312)]), xreg = temp_df$temp[-c(8759:15312)],seasonal = TRUE)
xreg_store <- cbind(model.matrix(~as.numeric(temp_df$temp[-c(8759:15312)])))
xreg_store <- xreg_store[,-1]
fcast_no_holdout <- forecast(fit_no_holdout,h=5312, xreg = xreg_store, level=c(0,0))
plot(fcast_no_holdout, main="Time Series Forecast for Hourly Average Gas Use", xaxt = "n", ylab = "Average Gas Use", xlab = "Month-Year",ylim = c(0,50))
lines(ts(deseasonal_cnt))
axis(1, at=1:15312, labels=format(as.Date(temp_df$Date),"%b-%Y"))

## Evaluate model Accuracy
accuracy(f=fcast_no_holdout,start = c(8759,1),end =c(15312,1),frequency=1)
