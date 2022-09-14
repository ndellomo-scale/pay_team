#New Global fraud spam checks

#Libraries
library(stringr)
library(lubridate)
library(readr)
library(tidyverse)
library(scales)
library(tictoc)
library(stringdist)
library(Redashr)
library(tictoc)

#Set up connection
  REDASH_API_KEY <- "F1SCtNJ9XaWOoj5rkqZWxh6sVQ5FM23a2DoOJfcA"
  conn <- redash_connect("https://redash.scale.com/", REDASH_API_KEY, "_Snowflake")
  setwd("~/Documents/GitHub/pay_team/FRAUD_SPAM")
  
#Function to run Redash API
  getQ <- function(fileName){
  query <- readChar(fileName, file.info(fileName)$size)
  query <- gsub("\r", " ", query)
  query <- gsub("\n", " ", query)
  query <- gsub("ï»¿", " ", query)
  Result <- dbGetQuery(conn, query)
  return(Result)
}

#Get data
  RefSummary <- getQ("ReferralSummary.sql")
  WorkersInfo <- getQ("SF 2 - worker info.sql")
  WorkerGrade <- getQ("SF 2 - workers grade.sql")
  Projects <- getQ("SF 2 - Projects.sql")
  Subs0 <- getQ("SF 2 - submissions.sql")

#Worker main df
  pos <- match(WorkersInfo$WORKER_EMAIL, WorkerGrade$WORKER_EMAIL)
  WorkersInfo[,14:21] <- WorkerGrade[pos,2:9]

#Similar email check
  workerP <- WorkersInfo %>% dplyr::filter(TOT_PAY > 1) %>% dplyr::filter(SOURCE == "Crowd")
  uniquemodels <- unique(as.character(workerP$WORKER_EMAIL))
  
  distancemodels <- stringdistmatrix(uniquemodels,uniquemodels, method = "jw")
  rownames(distancemodels) <- uniquemodels
  
  distancemodels[distancemodels==0] <- NA
  fuzzyAlgoThreshold <- 0.15
  pair <- vector(); grade <- vector()
  for(i in 1:ncol(distancemodels)){
    clmn <- distancemodels[,i]
    if(min(clmn, na.rm = T)<fuzzyAlgoThreshold){
      pair[i] <- uniquemodels[which.min(clmn)]
      grade[i] <- min(clmn, na.rm = T)
    }else{
      pair[i] <- NA
      grade[i] <- NA
    }
  }
  answer <- data.frame(uniquemodels, pair, grade)
  answer <- answer[!is.na(answer$pair),]
  answer2 <- answer[order(answer$grade),]
  answer2$grade <- 1/answer2$grade
  answer2$grade <- ifelse(answer2$grade>12.5,answer2$grade,0)
  answer2$grade <- normalize(answer2$grade)
  
  pos <-  match(WorkersInfo$WORKER_EMAIL, answer2$uniquemodels)
  WorkersInfo$SimEmails <- 0
  for(i in 1:length(pos)){
    if(is.na(pos[i])){WorkersInfo$SimEmails[i] <- 0}else{
      WorkersInfo$SimEmails[i] <- answer2$grade[pos[i]]
      
    }
  }
  WorkersInfo$emailSim <- answer2$grade[pos]
  WorkersInfo <- WorkersInfo %>% select(-FLAG)


#Referral Fraud
  source("Referral fraud check.R")
  RefFraudList <- RefFraud(RefSummary)
  RefFraudSubmissions <- RefFraudList[[1]]
  RefFraudEmails <- RefFraudList[[2]]


#Submissions check (outliers)
  checkPerformance <- function(projectTasker, project){
    #Checks for outliers
    acc <- (projectTasker[3]/project[3]) - 1
    speed <- (projectTasker[6]/project[9]) - 1 #taskPerHour
    normHourly <- (projectTasker[7]/project[10]) - 1
    grade <- -acc + abs(speed) + normHourly
    return(list(grade, acc, speed, normHourly))
  }
  
  
  Subs <- as.data.frame(Subs0)
  Subs$Grade <- Subs$accVS <- Subs$speedVS <- Subs$hourlyVS <- 0
  for (i in 1:nrow(Subs)){
    check <- Subs[i,]
    if(!is.na(check[2])){
      pos <- match(check[2], Projects$PROJECT_NAME)
      grade <- checkPerformance(check, Projects[pos,])
      Subs$Grade[i] <- as.numeric(grade[[1]])
      Subs$accVS[i] <- as.numeric(grade[[2]])
      Subs$speedVS[i] <- as.numeric(grade[[3]])
      Subs$hourlyVS[i] <- as.numeric(grade[[4]])
    }
    if(i%%1000==0){print(i/nrow(Subs))}
  }
  
  Subs2 <- Subs2[order(-Subs2$Grade),]
  Subs2 <- Subs2 %>% filter(TOT_PAY>20)

#Save CSVs
  write.csv(WorkersInfo, "Worker.csv")
  write.csv(Projects, "Projects.csv", row.names = FALSE)
  write.csv(Subs2[1:200,], "TaskerProjectTop200.csv", row.names = FALSE)
  write.csv(answer2[answer2$grade!=0,], "SusEmails.csv", row.names = FALSE)
  topPay <- WorkersInfo[order(-WorkersInfo$TOT_PAY),]
  topPay <- topPay %>% filter(SOURCE != "other")
  write.csv(topPay[1:30,], "topPay.csv", row.names = FALSE)


