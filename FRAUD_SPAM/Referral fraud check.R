##Referral fraud

RefFraud <- function(RefSumTableOrig){
  
  #Distinct data
  RefSumTable <- RefSumTableOrig[,-3]
  RefSumTable$REFERRED_PAY <- round(RefSumTable$REFERRED_PAY,6)
  RefSumTable <- distinct(RefSumTable)
  
  #Referral Fraud table
  #Filter for taskers with more than 3 referrals or a ratio between local and internationals referrals > 0.5
  totRef <- totBanned <- difCountry <- OriginCountry <- ID <- pay <- vector()
  ID_referring <- unique(RefSumTable$REFERRING)
  
  for(i in 1:length(ID_referring)){
    subset <- dplyr::filter(RefSumTable, REFERRING == ID_referring[i])
    pay[i] <- sum(subset$PAY)
    OriginCountry[i] <- subset$REFERRING_COUNTRY[1]
    ID[i] <- subset$REFERRING[1]
    totRef[i] <- nrow(subset)
    totBanned <- nrow(dplyr::filter(subset, REFERRING_STATUS == "banned"))
    subset2 <- dplyr::filter(subset, REFERRING_COUNTRY != REFERRED_COUNTRY)
    difCountry[i] <- nrow(subset2)
  }
  
  RefFraud <- data.frame("ID" = ID, "OriginCountry" = OriginCountry, "Total Referrals" = totRef, "Total banned ref" = totBanned, "Ref dif countries" = difCountry, "Pay" = pay)
  RefFraud <- RefFraud[order(-RefFraud[,3]),]
  
  #Suspicious because of total referrals
  SuspiciousID <- RefFraud[RefFraud$Total.Referrals>3,]
  
  #Suspicious because of international referrals
  RefFraud <- RefFraud[order(-RefFraud$Ref.dif.countries),]
  SuspiciousID2 <- RefFraud[((RefFraud$Ref.dif.countries/RefFraud$Total.Referrals) > 0.5),]
  SuspiciousID <- distinct(rbind(SuspiciousID, SuspiciousID2))
  
  #Add attempts to suspicious IDs####################
  attempts <- vector()
  if(nrow(SuspiciousID)>0){
  #  for(i in 1:nrow(SuspiciousID)){
  #    subset <- dplyr::filter(Workers, WORKER == SuspiciousID$ID[i])
  #    attempts[i] <- sum(subset$ATTEMPTS)
  #  }
    SuspiciousID <- mutate(SuspiciousID, "Attempts" = 0)
    #Csv for freezing
    FinalSuspicious <- SuspiciousID[SuspiciousID$Attempts==0,]
    FinalSuspiciousID <- FinalSuspicious[,1]
    
    #Get emails to save on "Fraud 2022" doc
    email <- vector()
    for(i in 1:length(FinalSuspiciousID)){
      nam <- RefSumTable%>%filter(REFERRING == as.character(FinalSuspiciousID[i]))
      email[i] <- nam$WORKER_EMAIL[1]
    }
    
    RefSumTable <- RefSumTableOrig
    
    #Get the reward IDs
    SubmissionIDs <- c(" ")
    for(i in 1:length(FinalSuspiciousID)){
      df <- filter(RefSumTable, REFERRING == as.character(FinalSuspiciousID[i]))
      SubmissionIDs <- c(SubmissionIDs, df$REWARD_ID)
    }
    SubmissionIDs <- as.data.frame(SubmissionIDs[-1])
    colnames(SubmissionIDs) <- "_ID"
    #write.csv(SubmissionIDs, "FreezeReferrals.csv", row.names = FALSE)
    #write.csv(email, "emailReferral.csv", row.names = FALSE)
  }
  
  returnList <- list(SubmissionIDs, email)
  return(returnList)
  
}
  
  
  
  
  
  
  








