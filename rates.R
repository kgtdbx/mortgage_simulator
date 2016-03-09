
# Setup
library(dplyr)
library(stats)
library(zoo)

rates <- 'data/30-yr_historics.csv' %>%
    read.csv(stringsAsFactors = FALSE) %>%
    transmute(rate, date = as.Date(date))

# Identify Fourier Transform periods
y_spectrum <- spectrum(rates$rate)
potential_frequencies <- with(y_spectrum, freq[freq < 0.1 & spec > 25])
potential_periods = (1 / potential_frequencies) * mean(diff(rates$date))

# Model periods
for (period_length in potential_periods) {
    rates[, paste0('period_', round(period_length))] <- ceiling(
        as.numeric(rates$date) / period_length
    )
}

rm(y_spectrum, potential_frequencies, period_length)

m <- glm(rate ~ ., data = rates)

# Predict future rates
future_dates <- data.frame(
    date = seq(from = max(rates$date), length.out = 35 * 365.25, by = 'day')
)

for (period_length in potential_periods) {
    future_dates[, paste0('period_', round(period_length))] <- ceiling(
        as.numeric(future_dates$date) / period_length
    )
}
rm(period_length, potential_periods)

# Bootstrap errors by adding random residuals from the fit to historical data
future_rates <- 1000 %>%
    replicate(sample(residuals(m), nrow(future_dates), replace = TRUE)) +
    predict(m, newdata = future_dates)

future_rates <- as.data.frame(future_rates)

future_rates$date <- future_dates$date
rm(future_dates)

future_rates <- future_rates %>%
    group_by(date = as.Date(as.character(cut(date, 'month')))) %>%
    summarise_each(funs(mean(.[. >= min(rates$rate)], na.rm = TRUE)))

future_rates <- data.frame(
    date = future_rates$date,
    rate = apply(select(future_rates, -date), 1, mean, na.rm = TRUE),
    rate_sd = apply(select(future_rates, -date), 1, sd, na.rm = TRUE)
)

future_rates$rate <- na.locf(future_rates$rate, na.rm = FALSE)
future_rates$rate_sd <- sd(rates$rate) # na.locf(future_rates$rate_sd, na.rm = FALSE)

plot(
    c(rates$date, future_rates$date),
    c(rates$rate, future_rates$rate),
    col = c(rep('black', nrow(rates)), rep('red', nrow(future_rates)))
)

save(future_rates, file = 'data/future_rates.RData')
