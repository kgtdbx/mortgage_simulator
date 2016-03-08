
library(shiny)
library(ZillowR)

set_zillow_web_service_id(readLines('zws_id.txt', warn = FALSE))

load('data/future_rates.RData')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    output$mortgagePlot <- renderPlot({
        plot(rnorm(input$price))
    })

})
