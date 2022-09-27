#Libraries

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

a <- "\U2022"
source("~/Documents/GitHub/pay_team/SSOT pay setup/functions.r")

# Define UI for application that draws a histogram
ui <- {dashboardPage(dashboardHeader(title = strong(em("Pay set up SSOT")), titleWidth = 250),
                     dashboardSidebar(width = 250, collapsed = TRUE,
                                      sidebarMenu(
                                          menuItem("Main analysis", tabName = "Main", icon = icon("chart-bar")),
                                          menuItem("Backtest/Solver", icon = icon("calculator"), tabName = "BS")
                                      )),
                     dashboardBody(
                         tabItems(
                             tabItem(tabName = "Main",
                                     
                                     fluidRow(column(6, 
                                                     
                                                     #Instructions
                                                     box(title = "Instructions", status = "primary", solidHeader = T, width = 12, height = 160, 
                                                         h5(paste(a, "Upload the csv for 'SSOT pay setup query' for the specific project.", sep = " ")),
                                                         h5(paste(a, "Analyze data through each 'data box'.", sep = " ")),
                                                         h5(paste(a, "Go to the 'Backtest/Solver' tab to backtest or optimize formulas.", sep = " "))
                                                     )
                                     ), column(6, 
                                               #CSV upload
                                               box(title = "CSV upload", status = "primary", solidHeader = T, width = 12, height = 160,
                                                   fileInput(inputId = "CSV", label = "Upload pay data", multiple = FALSE, accept = NULL)
                                               )
                                     ),
                                     
                                     
                                     fluidRow(column(12,
                                                     #CSV summary
                                                     box(title = "Filtering", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("GetInputs")
                                                         
                                                     )),
                                              
                                              column(6,
                                                     
                                                     box(title = "Hourly rate", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("HRsummary"),
                                                         numericInput(inputId = "xlimitHR", label = "Xlimit", value = 20, min = 1, max = 100),
                                                         tabsetPanel(type = "tabs",
                                                                     tabPanel("Taskers", plotlyOutput("HR1")),
                                                                     tabPanel("Accuracy", plotlyOutput("HR2")),
                                                                     tabPanel("Country", plotlyOutput("HR3"))
                                                                     
                                                                     )
                                                         
                                                     )),
                                              
                                              column(6,
                                                     
                                                     box(title = "Time", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("TIMEsummary"),
                                                         numericInput(inputId = "xlimitTime", label = "Xlimit", value = 100, min = 1, max = 20000),
                                                         tabsetPanel(type = "tabs",
                                                                     tabPanel("Taskers", plotlyOutput("Time1")),
                                                                     tabPanel("Accuracy", plotlyOutput("Time2")),
                                                                     tabPanel("Country", plotlyOutput("Time3"))
                                                                     
                                                         )
                                                         
                                                     )),
                                              
                                              column(6,
                                                     
                                                     box(title = "Pay per task", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("PPTsummary"),
                                                         tabsetPanel(type = "tabs",
                                                                     tabPanel("Taskers", plotlyOutput("PPT1")),
                                                                     tabPanel("Accuracy", plotlyOutput("PPT2")),
                                                                     tabPanel("Country", plotlyOutput("PPT3"))
                                                                     
                                                         )
                                                         
                                                     )),
                                              
                                              column(6,
                                                     
                                                     box(title = "Submissions", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("SUBSsummary"),
                                                         tabsetPanel(type = "tabs",
                                                                     tabPanel("Accuracy", plotlyOutput("SUBS1")),
                                                                     tabPanel("Country", plotlyOutput("SUBS2"))
                                                                     
                                                         )
                                                         
                                                     ))
                                              
                                              
                                              
                                                     
                                                     
                                     )
                                     
                                     ),
                                     br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br()
                                     
                                     
                                     #shinyDashboardThemes(theme = "purple_gradient"),     
                                     
                                     
                                     
                             ),
                             
                             tabItem(tabName = "BS",
                                     h3("Backtest/Solver"),
                                     
                                     fluidRow(column(6, 
                                                     
                                                     #Instructions
                                                     box(title = "Select action/formula", status = "primary", solidHeader = T, width = 12, 
                                                         
                                                          radioGroupButtons(
                                                             inputId = "BacktestS", label = "Action:", 
                                                             choices = c("Backtest", "Solver"), 
                                                             justified = TRUE, status = "primary"),
                                                         
                                                         radioGroupButtons(
                                                             inputId = "Formula", label = "Formula:", 
                                                             choices = c("V2", "AccContribution", "PSP", "AccBucket"), 
                                                             justified = TRUE, status = "primary")),
                                                     
                                                     ),
                                              
                                              column(6, 
                                                     
                                                     #Instructions
                                                     box(title = "Input vars", status = "primary", solidHeader = T, width = 12, 
                                                         
                                                         uiOutput("BSinput"),
                                                         br(), 
                                                         actionButton(inputId = "Compute", label = "Compute")
                                                     
                                              )
                                              
                                              ),
                                              
                                              #Backtest/solver hourly
                                              column(6,
                                                     
                                                     box(title = "Hourly rate", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("HR2summary"),
                                                         tabsetPanel(type = "tabs",
                                                                     tabPanel("Taskers", plotlyOutput("HR21")),
                                                                     tabPanel("Accuracy", plotlyOutput("HR22")),
                                                                     tabPanel("Country", plotlyOutput("HR23"))
                                                                     
                                                         )
                                                         
                                                     )
                                                     
                                                     
                                                     ),
                                              #Backtest/solver PPT
                                              column(6,
                                                     
                                                     box(title = "Hourly rate", status = "primary", solidHeader = T, width = 12, collapsible = F, 
                                                         
                                                         uiOutput("PPT2summary"),
                                                         tabsetPanel(type = "tabs",
                                                                     tabPanel("Taskers", plotlyOutput("PPT21")),
                                                                     tabPanel("Accuracy", plotlyOutput("PPT22")),
                                                                     tabPanel("Country", plotlyOutput("PPT23"))
                                                                     
                                                         )
                                                         
                                                     )
                                                     
                                                     
                                              ),
                                              
                                              )
                                     
                                     
                             )
                             
                             
                         )))
}

# Define server logic required to draw a histogram
server <- function(input, output) {

    #Reactive values
    r <- reactiveValues()
    
    #Get inputs and read csv
    output$GetInputs <- renderUI({
        
        #Get data
        if (is.null(input$CSV)){return()}
        CSV <- read.csv(input$CSV$datapath)
        #r$data <- read.csv("~/Desktop/Data0.csv")
        r$data <- CSV
        
        #UI
        fluidRow(column(3, 
                        selectInput(inputId = "WS", label = "Select worker_source", 
                                    choices = c("Complete dataset", unique(r$data$WORKER_SOURCE)))),
                 column(3, 
                        selectInput(inputId = "Country", label = "Select Country", 
                                    choices = c("Complete dataset", unique(r$data$COUNTRY)))),
                 column(3, 
                        selectInput(inputId = "WL", label = "Select worker_level", 
                                    choices = c("Complete dataset", unique(r$data$WORK_LEVEL)))),
                 column(3, 
                        selectInput(inputId = "Timer", label = "Select Timer", 
                                    choices = c("BG", "HB", "HB_active", "V2", "V2_active"))),
                 column(3, 
                        selectInput(inputId = "Normalized", label = "Select pay type", 
                                    choices = c("NORMALIZED PAYOUT", "PAYOUT"))),
                 column(3, 
                        selectInput(inputId = "Accuracy", label = "Select accuracy type", 
                                    choices = c("Numeric", "Tier"))       
                        
        )
        )
        
    })
    
    #Hourly
    output$HRsummary <- renderUI({
        
        #UI
        fluidRow(column(12, 
                        shinydashboard::valueBox(value = round(as.numeric(r$HR[[1]][1,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR[[1]][1,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$HR[[1]][2,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR[[1]][2,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$HR[[1]][3,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR[[1]][3,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$HR[[1]][4,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR[[1]][4,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3)
        )
        )
        
    })
    output$HR1 <- renderPlotly({r$HR[[2]]})
    output$HR2 <- renderPlotly({r$HR[[3]]})
    output$HR3 <- renderPlotly({r$HR[[4]]})
    
    #PPT
    output$PPTsummary <- renderUI({
        
        #UI
        fluidRow(column(12, 
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT[[1]][1,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT[[1]][1,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT[[1]][2,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT[[1]][2,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT[[1]][3,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT[[1]][3,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT[[1]][4,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT[[1]][4,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3)
        )
        )
        
    })
    output$PPT1 <- renderPlotly({r$PPT[[2]]})
    output$PPT2 <- renderPlotly({r$PPT[[3]]})
    output$PPT3 <- renderPlotly({r$PPT[[4]]})
    
    #SUBS
    output$SUBSsummary <- renderUI({
        
        #Main data
        r$filteredData <- preFilter(r$data, input$WS, input$Country, input$WL, input$Timer, input$Normalized, input$Accuracy)
        
        r$HR <- getHourly(r$filteredData, input$xlimitHR)
        r$PPT <- getPPT(r$filteredData)
        r$SUBS <- getSubs(r$filteredData)
        r$Time <- getTime(r$filteredData, input$xlimitTime)
        r$Acc <- getAcc(r$filteredData)
        
        #UI
        fluidRow(column(12, 
                        shinydashboard::valueBox(value = round(as.numeric(r$SUBS[[1]][1,2]), 3), subtitle = paste("Submissions in lvl ", as.numeric(r$SUBS[[1]][1,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$SUBS[[1]][2,2]), 3), subtitle = paste("Submissions in lvl ", as.numeric(r$SUBS[[1]][2,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$SUBS[[1]][3,2]), 3), subtitle = paste("Submissions in lvl ", as.numeric(r$SUBS[[1]][3,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$SUBS[[1]][4,2]), 3), subtitle = paste("Submissions in lvl ", as.numeric(r$SUBS[[1]][4,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3)
        )
        )
        
    })
    output$SUBS1 <- renderPlotly({r$SUBS[[2]]})
    output$SUBS2 <- renderPlotly({r$SUBS[[3]]})
    
    #TIME
    output$TIMEsummary <- renderUI({
        
        #UI
        fluidRow(column(12, 
                        shinydashboard::valueBox(value = round(as.numeric(r$Time[[1]][1,2]), 3), subtitle = paste("Time per task lvl ", as.numeric(r$Time[[1]][1,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$Time[[1]][2,2]), 3), subtitle = paste("Time per task lvl ", as.numeric(r$Time[[1]][2,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$Time[[1]][3,2]), 3), subtitle = paste("Time per task lvl ", as.numeric(r$Time[[1]][3,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$Time[[1]][4,2]), 3), subtitle = paste("Time per task lvl ", as.numeric(r$Time[[1]][4,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3)
        )
        )
        
    })
    output$Time1 <- renderPlotly({r$Time[[2]]})
    output$Time2 <- renderPlotly({r$Time[[3]]})
    output$Time3 <- renderPlotly({r$Time[[4]]})
    
    #Backtest Solver
    output$BSinput <- renderUI({
        
        if(input$BacktestS == "Solver"){
            #Solver
            vars <- data.frame("Levels" = c(-1,0,1,10), "Desired Hourly rate" = c(1.125, 1.375, 1.625, 1.75))
            
        }else{
            #Backtest
            if(input$Formula == 'V2'){
                vars <- data.frame("Levels" = c(-1,0,1,10), "AccExp" = c(1.125, 1.375, 1.625, 1.75),
                        "TW" = c(1.125, 1.375, 1.625, 1.75), "AW" = c(1.125, 1.375, 1.625, 1.75),
                        "GR" = c(2, 2.25, 2.5, 2.75))
                
            }
            if(input$Formula == 'AccContribution'){
                vars <- data.frame("Levels" = c(-1,0,1,10), "AccExp" = c(1.125, 1.375, 1.625, 1.75),
                                   "CPTW" = c(1.125, 1.375, 1.625, 1.75), "GR" = c(2., 2.25, 2.5, 2.75))
                
            }
            if(input$Formula == 'PSP'){
                vars <- data.frame("Levels" = c(-1,0,1,10), "CPTW" = c(2, 4, 5, 6),
                                   "Uth" = c(0.75, 0.75, 0.75, 0.75), "Bth" = c(0.85, 0.85, 0.85, 0.85), 
                                   "Sth" = c(0.9, 0.9, 0.9, 0.9), "Gth" = c(0.95, 0.95, 0.95, 0.95), 
                                   "UM" = c(0.5, 0.5, 0.5, 0.5), "BM" = c(0.68, 0.68, 0.68, 0.68), 
                                   "SM" = c(1, 1, 1, 1), "GM" = c(1.1, 1.1, 1.1, 1.1))
                
            }
            if(input$Formula == 'AccBucket'){
                vars <- data.frame("Levels" = c(-1,0,1,10), "HR" = c(1.25, 1.5, 1.75, 2),
                                   "Uth" = c(0.75, 0.75, 0.75, 0.75), "Bth" = c(0.85, 0.85, 0.85, 0.85), 
                                   "Sth" = c(0.9, 0.9, 0.9, 0.9), "Gth" = c(0.95, 0.95, 0.95, 0.95), 
                                   "UM" = c(0.5, 0.5, 0.5, 0.5), "BM" = c(0.68, 0.68, 0.68, 0.68), 
                                   "SM" = c(1, 1, 1, 1), "GM" = c(1.1, 1.1, 1.1, 1.1))
                
            }
            
            
        }
        
        fluidRow(column(12,
                        rhandsontable(vars, editable = T, digits = 4, options = list(pageLength = 10), rowHeaders = F)%>%
                            hot_col("Levels", readOnly = TRUE)))
        
    })
    
    #Action
    observeEvent(input$Compute, {
        r$vars1 <- as.data.frame(hot_to_r(input$BSinput))
        if(input$BacktestS == "Solver"){
            
            if(input$Formula == "V2"){
                V2optim <- V2formulaSolve(r$data, r$vars1[,2], input$Timer, 0.05)
                newData <- V2optim[[1]]
                hourly <- newData %>% group_by(WORK_LEVEL) %>% 
                    summarise(hourly = sum(FinalPay, na.rm = T)/sum(Time, na.rm = T))
                print(hourly)
                print(c)
                print(t)
                c <- V2optim[[2]]
                t <- V2optim[[3]]
            }
            
            
            
            
            
            
        }
        
        
        #New data
        r$filteredData2 <- preFilter(newData, input$WS, input$Country, input$WL, input$Timer, input$Normalized, input$Accuracy)
        
        r$HR2 <- getHourly(r$filteredData2, xlimit = 20)
        r$PPT2 <- getPPT(r$filteredData2)
        
    })
    
    
    #Hourly
    output$HR2summary <- renderUI({
        
        #UI
        fluidRow(column(12, 
                        shinydashboard::valueBox(value = round(as.numeric(r$HR2[[1]][1,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR2[[1]][1,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$HR2[[1]][2,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR2[[1]][2,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$HR2[[1]][3,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR2[[1]][3,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$HR2[[1]][4,2]), 3), subtitle = paste("Hourly rate lvl ", as.numeric(r$HR2[[1]][4,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3)
        )
        )
        
    })
    output$HR21 <- renderPlotly({r$HR2[[2]]})
    output$HR22 <- renderPlotly({r$HR2[[3]]})
    output$HR23 <- renderPlotly({r$HR2[[4]]})
    
    #PPT
    output$PPT2summary <- renderUI({
        
        #UI
        fluidRow(column(12, 
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT2[[1]][1,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT2[[1]][1,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT2[[1]][2,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT2[[1]][2,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT2[[1]][3,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT2[[1]][3,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3),
                        shinydashboard::valueBox(value = round(as.numeric(r$PPT2[[1]][4,2]), 3), subtitle = paste("Pay per task lvl ", as.numeric(r$PPT2[[1]][4,1]), sep = ""), icon = icon("user"), color = "aqua", width = 3)
        )
        )
        
    })
    output$PPT21 <- renderPlotly({r$PPT2[[2]]})
    output$PPT22 <- renderPlotly({r$PPT2[[3]]})
    output$PPT23 <- renderPlotly({r$PPT2[[4]]})
    
    
    
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)
