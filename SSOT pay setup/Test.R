# Analysis, Backtest and solver

library(dplyr)
library(plotly)

source("~/Documents/GitHub/pay_team/SSOT pay setup/functions.r")

  ##Analysis
  
  Data0 <- Data <- read.csv("~/Desktop/Data0.csv")
  Data <- Data %>% mutate("AccN" = runif(n = nrow(Data),min = 0, max = 1))
  Timer <- c("BG", "HB", "HB_active", "V2", "V2_active")
  Timer <- "BG"
  
      ####Hourly Rate 
          #HR <- preFilter(Data, Source, Country, Level, Timer, Norm, Acc)
          HR <- preFilter(Data, "Complete dataset", "Complete dataset", "Complete dataset", "BG", F, "Tier")
          HR <- getHourly(HR, xlimit = 20)
          HRavgByLevels <- HR[[1]]
          HRDistHist <- HR[[2]]
          HRDistHistAcc <- HR[[3]]
          HRDistHistCountry <- HR[[4]]
          
      ####Pay per task 
          #PPT <- preFilter(Data, Source, Country, Level, Timer, Norm, Acc)
          PPT <- preFilter(Data, "ALL", "ALL", -1, "BG", F, "Tier")
          PPT <- getPPT(PPT)
          PPTavgByLevels <- PPT[[1]]
          PPTDistHist <- PPT[[2]]
          PPTDistHistAcc <- PPT[[3]]
          PPTDistHistCountry <- PPT[[4]]
      
      
      ####Submission count
          #Subs <- preFilter(Data, Source, Country, Level, Timer, Norm, Acc)
          Subs <- preFilter(Data, "ALL", "ALL", "ALL", "BG", F, "NTier")
          Subs <- getSubs(Subs)
          SubsTotByLevels <- Subs[[1]]
          SubsDistHistAcc <- Subs[[2]]
          SubsDistHistCountry <- Subs[[3]]
  
      
      ####Time dist
          #Time <- preFilter(Data, Source, Country, Level, Timer, Norm, Acc)
          Time <- preFilter(Data, "ALL", "ALL", "ALL", "BG", F, "NTier")
          Time <- getTime(Time, xlimit = 150)
          TimeAvgByLevels <- Time[[1]]
          TimeDistHist <- Time[[2]]
          TimeDistHistAcc <- Time[[3]]
          TimeDistHistCountry <- Time[[4]]
          
          
      ####Accuracy
          #Acc <- preFilter(Data, Source, Country, Level, Timer, Norm, Acc)
          Acc <- preFilter(Data, "ALL", "ALL", "ALL", "BG", F, "Tier")
          Acc <- getAcc(Acc)
          ACCavgByLevels <- Acc[[1]]
          ACCDistHist <- Acc[[2]]
          ACCDistHistCountry <- Acc[[3]]
      
          
      ####Extras
          #TotPayByCountry <- TPBC(Data)
          #TagImpact <- TagImpact(Data)
          
          
          
          
          
  ##Backtest + Solver
          
      ##Inputs
          #V2
          
          
          
          
          #AccCont
          
          #PayPerSub + QT
          
          #AccBucket + QT
          
          
      