
library(shiny)
library(ZillowR)

set_zillow_web_service_id(readLines('zws_id.txt', warn = FALSE))

load('data/future_rates.RData')

source('mortgage.R')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    output$mortgagePlot <- renderPlot({
        if (grepl('^\\d+$', input$zip)) {
            response <- ZillowR::GetMonthlyPayments(
                price = input$price,
                down = input$down,
                dollarsdown = input$dollarsdown,
                zip = input$zip
            )
        } else {
            response <- ZillowR::GetMonthlyPayments(
                price = input$price,
                down = input$down,
                dollarsdown = input$dollarsdown
            )
        }

        rates <- data.frame(
            as.numeric(XML::xmlToList(response[['response']][[1]])$rate),
            as.numeric(XML::xmlToList(response[['response']][[2]])$rate),
            as.numeric(XML::xmlToList(response[['response']][[3]])$rate)
        )

        names(rates) <- c(
            XML::xmlToList(response[['response']][[1]])$.attrs[['loanType']],
            XML::xmlToList(response[['response']][[2]])$.attrs[['loanType']],
            XML::xmlToList(response[['response']][[3]])$.attrs[['loanType']]
        )

        rates <- data.frame(
            date = future_rates$date[with(future_rates,
                date > Sys.Date() &
                date <= (Sys.Date() + 30 * 365.25)
            )],
            rates[, c('thirtyYearFixed', 'fiveOneARM')]
        )

        gt_5yr <- rates$date >= Sys.Date() + 5 * 365.25
        predicted_index <- match(rates$date, future_rates$date)

        rates$fiveOneARM[gt_5yr] <- future_rates$rate[predicted_index][gt_5yr]

        rates$lb <- rates$fiveOneARM
        rates$lb[gt_5yr] <- rates$fiveOneARM[gt_5yr] -
            qnorm(0.975) * future_rates$rate_sd[predicted_index][gt_5yr] / 1000

        rates$ub <- rates$fiveOneARM
        rates$ub[gt_5yr] <- rates$fiveOneARM[gt_5yr] +
            qnorm(0.975) * future_rates$rate_sd[predicted_index][gt_5yr] / 1000

    })

})
