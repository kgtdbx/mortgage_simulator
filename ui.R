
library(shiny)

# Define UI for application
shinyUI(fluidPage(

    # Application title
    titlePanel('Mortgage simulator'),

    # Sidebar with inputs for Zillow API
    sidebarLayout(
        sidebarPanel(
            numericInput(
                inputId = 'price',
                label = 'Price',
                value = 100000,
                min = 0,
                max = 2e8,
                step = 1e3
            ),
            numericInput(
                inputId = 'down',
                label = 'Down (%)*',
                value = 20,
                min = 0,
                max = 100,
                step = 1
            ),
            numericInput(
                inputId = 'dollarsdown',
                label = 'Down ($)*',
                value = 2e4,
                min = 0,
                max = 2e8,
                step = 1e3
            ),
            textInput(
                inputId = 'zip',
                label = 'Zipcode (optional)',
                value = ''
            ),
            helpText('* Check your math! Downpayment values (%/$) do not automatically balance.'),
            submitButton('Go!')
        ),

        # Plot mortgage options
        mainPanel(
            plotOutput('mortgagePlot'),
            img(
                src = 'http://www.zillow.com/widgets/GetVersionedResource.htm?path=/static/logos/Zillowlogo_150x40_rounded.gif',
                height = 40,
                width = 150,
                alt = 'Zillow Real Estate Search'
            )
        )
    )
))
