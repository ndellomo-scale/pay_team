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
Subs <- getQ("SF 2 - submissions.sql")

#Similar email check
unique()

#Referral Fraud
source("Referral fraud check.R")
RefFraudList <- RefFraud(RefSummary)
RefFraudSubmissions <- RefFraudList[[1]]
RefFraudEmails <- RefFraudList[[2]]






