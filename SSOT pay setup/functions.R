##### Functions
## Needs the data from the SSOT query

library(shiny)
library(dplyr)
library(tidyverse)
library(formattable)
library(scales)
library(shinydashboard)
library(DT)
library(shinyWidgets)
library(plotly)
library(rhandsontable)
library(tictoc)


getMode <- function(vector){
  tab <- table(vector)
  mode <- names(tab)[which.max(tab)]
  return(mode)
}

#########Analysis
preFilter <- function(Data, Source, Country, Level, Timer, Norm, Acc){
  
  Timer0 <- c("BG", "HB", "HB_active", "V2", "V2_active")
  colnames(Data)[match(Timer, Timer0)+10] <- "Time"
  
  if(Source == "Complete dataset"){}else{Data <- Data %>% dplyr::filter(WORKER_SOURCE %in% Source)}
  
  if(Country == "Complete dataset"){}else{Data <- Data %>% dplyr::filter(COUNTRY %in% Country)}
  
  if(Level == "Complete dataset"){}else{Data <- Data %>% dplyr::filter(WORK_LEVEL %in% Level)}
  
  if(Norm == "NORMALIZED PAYOUT"){colnames(Data)[10] <- "PAY"}else{colnames(Data)[9] <- "PAY"}
  
  if(Acc == "Tier"){colnames(Data)[29] <- "ACC"}else{colnames(Data)[30] <- "ACC"}
  
  return(Data)
  
}

getHourly <- function(FilteredData, xlimit = 10){
  
  FilteredData <- FilteredData %>% mutate("hourly" = ifelse(Time == 0, 0, PAY/(Time/3600)))
  
  #Hourly rate by levels
  HRavgByLevels <- FilteredData %>%  group_by(WORK_LEVEL) %>% 
    summarise(hourly = sum(PAY, na.rm = T)/(sum(Time, na.rm = T)/3600))
  
  #Histogram data by submission
  HRDistHist <- FilteredData$hourly[FilteredData$hourly<xlimit]
  HRDistHist <- plot_ly(x = HRDistHist, nbinsx = 20, type = "histogram") %>% 
    layout(
      title = "Hourly rate distribution by tasker",
      xaxis = list(title = "Hourly Rate"), yaxis = list(title = "Submission Count")
    )
  
  #Histogram data by Acc
  if(class(FilteredData$ACC) == "character"){
    HRDistHistAcc <- FilteredData[FilteredData$ACC!="",] %>%  group_by(ACC) %>% 
      summarise(hourly = sum(PAY, na.rm = T)/(sum(Time, na.rm = T)/3600))
    HRDistHistAcc <- plot_ly(x = HRDistHistAcc$ACC, y = HRDistHistAcc$hourly,
                             type = "bar") %>% 
      layout(
        title = "Hourly rate distribution by Accuracy",
        xaxis = list(title = "Tier", categoryorder = "array",
                     categoryarray = c("unranked", "bronze", "silver", "gold")),
        yaxis = list(title = 'Hourly rate')
      )
  }else{
    FilteredData$ACC[FilteredData$ACC<0] <- 0
    FilteredData <- FilteredData %>% mutate("acc_bucket" =
                                              cut(x = FilteredData$ACC, 
                                                  breaks = seq(from = 0, to = 1, by = 0.1)))
    HRDistHistAcc <- FilteredData %>%  group_by(acc_bucket) %>% 
      summarise(hourly = sum(PAY, na.rm = T)/(sum(Time, na.rm = T)/3600))
    HRDistHistAcc <- plot_ly(x = HRDistHistAcc$acc_bucket, y = HRDistHistAcc$hourly,
                             type = "bar") %>% 
      layout(
        title = "Hourly rate distribution by Accuracy",
        xaxis = list(title = "Accuracy"),
        yaxis = list(title = 'Hourly rate')
      )
  }
  
  #Histogram data by Country
  HRDistHistCountry <- FilteredData %>%  group_by(COUNTRY) %>% 
    summarise(hourly = sum(PAY, na.rm = T)/(sum(Time, na.rm = T)/3600))
  HRDistHistCountry <- plot_ly(x = HRDistHistCountry$COUNTRY, y = HRDistHistCountry$hourly,
                           type = "bar") %>% 
    layout(
      title = "Hourly rate distribution by Country",
      xaxis = list(title = "Country"),
      yaxis = list(title = 'Hourly rate')
    )
  
  
  return(list(HRavgByLevels, HRDistHist, HRDistHistAcc, HRDistHistCountry))
}

getPPT <- function(FilteredData){
  
  #PPT by levels
  PPTavgByLevels <- FilteredData %>%  group_by(WORK_LEVEL) %>% 
    summarise(PPT = mean(PAY, na.rm = T))
  
  #Histogram data by submission
  PPTDistHist <- FilteredData$PAY
  PPTDistHist <- plot_ly(x = PPTDistHist, type = "histogram", nbinsx = 20) %>% 
    layout(
      title = "Pay per task distribution by tasker",
      xaxis = list(title = "Pay per task"), yaxis = list(title = "Submission Count")
    )
  
  #Histogram data by Acc
  if(class(FilteredData$ACC) == "character"){
    PPTDistHistAcc <- FilteredData[FilteredData$ACC!="",] %>%  group_by(ACC) %>% 
      summarise(PPT = mean(PAY, na.rm = T))
    PPTDistHistAcc <- plot_ly(x = PPTDistHistAcc$ACC, y = PPTDistHistAcc$PPT,
                             type = "bar") %>% 
      layout(
        title = "Pay per task distribution by Accuracy",
        xaxis = list(title = "Tier", categoryorder = "array",
                     categoryarray = c("unranked", "bronze", "silver", "gold")),
        yaxis = list(title = 'Pay per task')
      )
  }else{
    FilteredData$ACC[FilteredData$ACC<0] <- 0
    FilteredData <- FilteredData %>% mutate("acc_bucket" =
                                              cut(x = FilteredData$ACC, 
                                                  breaks = seq(from = 0, to = 1, by = 0.1)))
    PPTDistHistAcc <- FilteredData %>%  group_by(acc_bucket) %>% 
      summarise(PPT = mean(PAY, na.rm = T))
    PPTDistHistAcc <- plot_ly(x = PPTDistHistAcc$acc_bucket, y = PPTDistHistAcc$PPT,
                             type = "bar") %>% 
      layout(
        title = "Pay per task distribution by Accuracy",
        xaxis = list(title = "Accuracy"),
        yaxis = list(title = 'Pay per task')
      )
  }
  
  #Histogram data by Country
  PPTDistHistCountry <- FilteredData %>%  group_by(COUNTRY) %>% 
    summarise(PPT = mean(PAY, na.rm = T))
  PPTDistHistCountry <- plot_ly(x = PPTDistHistCountry$COUNTRY, y = PPTDistHistCountry$PPT,
                               type = "bar") %>% 
    layout(
      title = "Pay per task distribution by Country",
      xaxis = list(title = "Country"),
      yaxis = list(title = 'Pay per task')
    )
  
  
  return(list(PPTavgByLevels, PPTDistHist, PPTDistHistAcc, PPTDistHistCountry))
}

getSubs <- function(FilteredData){
  
  #PPT by levels
  SUBSByLevels <- FilteredData %>%  group_by(WORK_LEVEL) %>% 
    summarise(Total_subs = n())

  #Histogram data by Acc
  if(class(FilteredData$ACC) == "character"){
    SUBSDistHistAcc <- FilteredData[FilteredData$ACC!="",] %>%  group_by(ACC) %>% 
      summarise(Total_subs = n())
    SUBSDistHistAcc <- plot_ly(x = SUBSDistHistAcc$ACC, y = SUBSDistHistAcc$Total_subs,
                              type = "bar") %>% 
      layout(
        title = "Submission distribution by Accuracy",
        xaxis = list(title = "Tier", categoryorder = "array",
                     categoryarray = c("unranked", "bronze", "silver", "gold")),
        yaxis = list(title = 'Submission count')
      )
  }else{
    FilteredData$ACC[FilteredData$ACC<0] <- 0
    FilteredData <- FilteredData %>% mutate("acc_bucket" =
                                              cut(x = FilteredData$ACC, 
                                                  breaks = seq(from = 0, to = 1, by = 0.1)))
    SUBSDistHistAcc <- FilteredData %>%  group_by(acc_bucket) %>% 
      summarise(Total_subs = n())
    SUBSDistHistAcc <- plot_ly(x = SUBSDistHistAcc$acc_bucket, y = SUBSDistHistAcc$Total_subs,
                              type = "bar") %>% 
      layout(
        title = "Submission distribution by Accuracy",
        xaxis = list(title = "Accuracy"),
        yaxis = list(title = 'Submission Count')
      )
  }
  
  #Histogram data by Country
  SUBSDistHistCountry <- FilteredData %>%  group_by(COUNTRY) %>% 
    summarise(Total_subs = n())
  SUBSDistHistCountry <- plot_ly(x = SUBSDistHistCountry$COUNTRY, y = SUBSDistHistCountry$Total_subs,
                                type = "bar") %>% 
    layout(
      title = "Submission distribution by Country",
      xaxis = list(title = "Country"),
      yaxis = list(title = 'Submission count')
    )
  
  
  return(list(SUBSByLevels, SUBSDistHistAcc, SUBSDistHistCountry))
}

getTime <- function(FilteredData, xlimit){
  
  #PPT by levels
  TIMEavgByLevels <- FilteredData %>%  group_by(WORK_LEVEL) %>% 
    summarise(TPT = mean(Time, na.rm = T))
  
  #Histogram data by submission
  if(!is.null(xlimit)){TIMEDistHist <- FilteredData$Time[FilteredData$Time<xlimit]}else{
    TIMEDistHist <- FilteredData$Time
  }
  TIMEDistHist <- plot_ly(x = TIMEDistHist, type = "histogram", nbinsx = 20) %>% 
    layout(
      title = "Time per task distribution by tasker (secs)",
      xaxis = list(title = "Time per task"), yaxis = list(title = "Hours")
    )
  
  #Histogram data by Acc
  if(class(FilteredData$ACC) == "character"){
    TIMEDistHistAcc <- FilteredData[FilteredData$ACC!="",] %>%  group_by(ACC) %>% 
      summarise(TPT = mean(Time, na.rm = T))
    TIMEDistHistAcc <- plot_ly(x = TIMEDistHistAcc$ACC, y = TIMEDistHistAcc$TPT,
                              type = "bar") %>% 
      layout(
        title = "Time per task distribution by Accuracy (secs)",
        xaxis = list(title = "Tier", categoryorder = "array",
                     categoryarray = c("unranked", "bronze", "silver", "gold")),
        yaxis = list(title = 'Time per task')
      )
  }else{
    FilteredData$ACC[FilteredData$ACC<0] <- 0
    FilteredData <- FilteredData %>% mutate("acc_bucket" =
                                              cut(x = FilteredData$ACC, 
                                                  breaks = seq(from = 0, to = 1, by = 0.1)))
    TIMEDistHistAcc <- FilteredData %>%  group_by(acc_bucket) %>% 
      summarise(TPT = mean(PAY, na.rm = T))
    TIMEDistHistAcc <- plot_ly(x = TIMEDistHistAcc$acc_bucket, y = TIMEDistHistAcc$TPT,
                              type = "bar") %>% 
      layout(
        title = "Time per task distribution by Accuracy (secs)",
        xaxis = list(title = "Accuracy"),
        yaxis = list(title = 'Time per task')
      )
  }
  
  #Histogram data by Country
  TIMEDistHistCountry <- FilteredData %>%  group_by(COUNTRY) %>% 
    summarise(TPT = mean(Time, na.rm = T))
  TIMEDistHistCountry <- plot_ly(x = TIMEDistHistCountry$COUNTRY, y = TIMEDistHistCountry$TPT,
                                type = "bar") %>% 
    layout(
      title = "Time per task distribution by Country (secs)",
      xaxis = list(title = "Country"),
      yaxis = list(title = 'Time per task')
    )
  
  
  return(list(TIMEavgByLevels, TIMEDistHist, TIMEDistHistAcc, TIMEDistHistCountry))
}


#TPBC
#TagImpact



#########Backtest + solver
V2formulaBT <- function(data, x, c, t, GR, Timer){
  
  #Specify time
  Timer0 <- c("BG", "HB", "HB_active", "V2", "V2_active")
  colnames(data)[match(Timer, Timer0)+10] <- "Time"
  
  #Backtest
    pos <- match(data$WORK_LEVEL, c(-1,0,1,10))
    x1vec <- x[pos]
    c1vec <- c[pos]
    t1vec <- t[pos]
    GRvec <- GR[pos]
    #Formula
    data <- data %>%
      mutate("Formula" = 
               ifelse(BASE_ACCURACY<0, 0, 
                      (BASE_ACCURACY^x1vec)*((V2_RELATIVE_CORRECT_WORK*c1vec)+(V2_TOTAL_WORK*t1vec)))/10000) %>% 
      #Multipliers  
      mutate("PayWithMults" =
               Formula * COUNTRYMULT * TAGMULT * REVIEWSTATUSMULT
               ) %>% 
      #Guardrails
      mutate("HOURLY" = PayWithMults / (Time/3600),
             "ADJhourly" = 
               ifelse(HOURLY>GRvec, 
                      GRvec*(1+log10(HOURLY/GRvec)), HOURLY),
             "FinalPay" = 
               ADJhourly*(Time/3600)
             )
}
V2formulaSolve <- function(data, hourlyVec, Time, th){
  
  threshold = 10
  x <- c(2,2,2,2)
  c <- c(1,1,1,1)
  t <- c(1,1,1,1)
  GR <- c(3.5,3.5,3.5,3.5)
  lvls <- c(-1,0,1,10)
  
  for(i in 1:4){
    if(!(lvls[i] %in% unique(data$WORK_LEVEL))){threshold <- th -1}else{

      #Get hourly
      data0 <- data %>% dplyr::filter(WORK_LEVEL == lvls[i])
      newdata <- V2formulaBT(data0, x, c, t, GR, Time)
      HR <- sum(newdata$FinalPay, na.rm = T) / sum(newdata$Time, na.rm = T) 
      threshold <- abs(hourlyVec[i]-HR)
      n <- 1
      
      #Solver Quasi Newton Rapson
      while(threshold > th){
        
        #Sizing constant and delta calc
        sizingConstant <- 0.99^n
        if(sizingConstant<0.5){sizingConstant <- 0.5}
        delta <- threshold*sizingConstant
        
        #Increase or decrease var
        if(HR>hourlyVec[i]){
          t[i] <- x[i]-delta ###Me sentí genio con está idea. Hasta cierto punto parecido al Newton Rapson
          c[i] <- c[i]-delta
        }else{
          t[i] <- x[i]+delta 
          c[i] <- c[i]+delta
        }
        
        
        #Get new hourly
        newdata <- V2formulaBT(data0, x, c, t, GR, Time)
        HR <- sum(newdata$FinalPay, na.rm = T) / sum(newdata$Time, na.rm = T) 
        threshold <- abs(hourlyVec[i]-HR)
        n <- n + 1
        
      }
    }
  }
  
  newdata <- V2formulaBT(data, x, c, t, GR, Time)
  
  return(list(newdata, t, c))
    
}
    
    
#ACformula <- function(date, hourly)
#ABformula <- function(data, QT, hourly)
#PSPformula <- function(data, QT, hourly)



F3Dformula <- function(PbS, exp, cents){
  PbS <- PbS%>%mutate("Formula" = 
                        ifelse(ACC<0, 0, 
                               (((V2_CORRECT_WORK/V2_TOTAL_WORK)^exp)-(((V2_CORRECT_WORK-V2_RELATIVE_CORRECT_WORK)/V2_TOTAL_WORK)^exp))*cents*PAYOUT_TOTAL_WORK/100))
  return(PbS)
}










SetHourlyV2 <- function(data, hourly, threshold0){
  
  
  
}

#set hourly function
SetHourly <- function(PbS, formula, hourly, threshold0){
  lvl <- unique(PbS$WORK_LEVEL)
  level <- c(-1, 0, 1, 10, 11, 12)
  mm <- match(lvl, level)
  lvl <- level[mm]
  vars2D <- data.frame("Levels" = c(-1,0,1,10,11,12), "X" = c(2, 2, 2, 0, 0, 0), "C" = c(12, 6, 6, 0, 0, 0), "T" = c(12, 6, 6, 0, 0, 0))
  vars3D <- data.frame("Levels" = c(-1,0,1,10,11,12), "accExp" = c(1.5, 2, 2, 2, 0, 0), "centsPerTW" = c(1, 1.2, .8, .4, 0, 0))
  if(formula == "2D"){vars <- vars2D}else if(formula == "3D"){vars <- vars3D}
  
  withProgress(message = 'Working on it', value = 0.1, {
    for(i in 1:length(lvl)){
      threshold <- 1
      setProgress(value = 0.1+(i/10), message = paste("Working on level ", lvl[i], sep = ""))
      n <- 1
      while(threshold>threshold0){
        n <- n+1
        if(formula == "2D"){
          
          #Variables in a vector for levels
          x1 <- vars[,2]
          c1 <- vars[,3]
          t1 <- vars[,4]
          
          #Variable for each case
          llevel <- c(-1, 0, 1, 10, 11, 12)
          lvlMatch <- match(PbS$WORK_LEVEL, llevel)
          x1vec <- x1[lvlMatch]
          c1vec <- c1[lvlMatch]
          t1vec <- t1[lvlMatch]
          
          #Formula
          PbS <- F2Dformula(PbS, x1vec, c1vec, t1vec)
          
          ND <- NewData(PbS, NA, unique(PbS$WORK_LEVEL))
          HR <- ND[[3]]
          threshold <- abs(hourly[i]-HR[i])
          #In case it starts taking to many iterations the delta starts decreasing to be more precise
          sizingConstant <- 0.99^n
          if(sizingConstant<0.5){sizingConstant <- 0.5}
          delta <- threshold*sizingConstant
          if(HR[i]>hourly[i]){
            vars[i, 3] <- vars[i, 3]-delta ###Me sentí genio con está idea. Hasta cierto punto parecido al Newton Rapson
            vars[i, 4] <- vars[i, 4]-delta
          }else{
            vars[i, 3] <- vars[i, 3]+delta
            vars[i, 4] <- vars[i, 4]+delta
          }
          
        } #Add Formula
        if(formula == "3D"){
          
          #Variables in a vector for levels
          accExp <- vars[,2]
          centsPerTW <- vars[,3]
          
          #Variable for each case
          llevel <- c(-1, 0, 1, 10, 11, 12)
          lvlMatch <- match(PbS$WORK_LEVEL, llevel)
          accExpVec <- accExp[lvlMatch]
          centsPerTWVec <- centsPerTW[lvlMatch]
          
          #Formula
          PbS <- F3Dformula(PbS, accExpVec, centsPerTWVec)
          
          ND <- NewData(PbS, NA, unique(PbS$WORK_LEVEL))
          HR <- ND[[3]]
          threshold <- abs(hourly[i]-HR[i])
          #In case it starts taking to many iterations the delta starts decreasing to be more precise
          sizingConstant <- 0.95^n
          if(sizingConstant<0.5){sizingConstant <- 0.5}
          delta <- threshold*sizingConstant
          if(HR[i]>hourly[i]){
            if((vars[i ,3]-threshold)<0){delta <- 0.1}
            vars[i ,3] <- vars[i ,3]-delta
          }else{
            vars[i ,3] <- vars[i ,3]+delta
          }
        }
      }
    }})
  varsAndHourly <- list(vars, HR, lvl)
  return(varsAndHourly)
  
}


