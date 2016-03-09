
library(shiny)
library(ZillowR)
library(XML)

set_zillow_web_service_id(readLines('zws_id.txt', warn = FALSE))

load('data/future_rates.RData')

cumsum_payments <- function(
    P = input$price - as.numeric(xmlToList(response$response[['downPayment']])),
    I = rates$thirtyYearFixed
) {
    source('mortgage.R')

    x <- data.frame(
        months_remaining = rev(seq(length(I))),
        principal = P,
        payment = NA
    )

    for (i in seq(nrow(x))) {
        y <- mortgage(x$principal[i], I[i], x$months_remaining[i]/12)
        x$payment[i] <- y$Monthly_Payment
        if (i < nrow(x)) x$principal[i + 1] <- x$principal[i] - y$Monthly_Principal
    }

    return(cumsum(x$payment))
}

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    output$mortgagePlot <- renderPlot({
        if (grepl('^\\d+$', input$zip)) {
            response <- ZillowR::GetMonthlyPayments(
                price = as.integer(input$price),
                down = as.integer(input$down),
                dollarsdown = as.integer(input$dollarsdown),
                zip = input$zip
            )
        } else {
            response <- ZillowR::GetMonthlyPayments(
                price = as.integer(input$price),
                down = as.integer(input$down),
                dollarsdown = as.integer(input$dollarsdown)
            )
        }

        rates <- data.frame(
            as.numeric(xmlToList(response[['response']][[1]])$rate),
            as.numeric(xmlToList(response[['response']][[2]])$rate),
            as.numeric(xmlToList(response[['response']][[3]])$rate)
        )

        names(rates) <- c(
            xmlToList(response[['response']][[1]])$.attrs[['loanType']],
            xmlToList(response[['response']][[2]])$.attrs[['loanType']],
            xmlToList(response[['response']][[3]])$.attrs[['loanType']]
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

        rm(gt_5yr, predicted_index)

        y <- data.frame(
            fixed_30 = cumsum_payments(I = rates$thirtyYearFixed),
            arm = cumsum_payments(I = rates$fiveOneARM),
            arm_lb = cumsum_payments(I = rates$lb),
            arm_ub = cumsum_payments(I = rates$ub)
        )

        plot(c(0, nrow(y)), c(min(y), max(y)), type = 'n', ann = FALSE, las = 1)
        title(xlab = 'Month', ylab = 'Total payments')
        lines(seq(nrow(y)), y$fixed_30, lwd = 2)
        lines(seq(nrow(y)), y$arm_lb, lty = 2, col = 'red')
        lines(seq(nrow(y)), y$arm_ub, lty = 2, col = 'red')
        # lines(seq(nrow(y)), y$arm, lwd = 2, col = 'red')
    })

})
