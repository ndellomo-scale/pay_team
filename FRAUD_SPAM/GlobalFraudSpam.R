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

#Get the data

conn <- redash_connect("https://redash.scale.com/", "F1SCtNJ9XaWOoj5rkqZWxh6sVQ5FM23a2DoOJfcA", "_Snowflake")
setwd("~/Documents/GitHub/pay_team/FRAUD_SPAM")

getQ <- function(fileName){
  query <- readChar(fileName, file.info(fileName)$size)
  query <- gsub("\r", " ", query)
  query <- gsub("\n", " ", query)
  query <- gsub("ï»¿", " ", query)
  Result <- dbGetQuery(conn, query)
  return(Result)
}

Workers <- getQ("SP2 Workers.sql")

