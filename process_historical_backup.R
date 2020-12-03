# Process an existing historical file
library(tidyverse)
library(lubridate)

make_date <- function(x) {
  mdy(paste(x$month, x$day, x$year))
}



historical <- jsonlite::fromJSON("backups/historical_2020-11-01 23:00:00.json")
filedate <- make_date(historical %>% extract2(1))


# County Time Series
county_hist <- historical %>% 
  extract2(7) %>% 
  extract2(1) 

result <- do.call(rbind.data.frame, county_hist[1, "values"])
result$date <- county_hist[1, "testDate"]
for (d in 2:nrow(county_hist)) {
  df <- do.call(what=rbind.data.frame, county_hist[d,"values"])
  df$date <- county_hist[d,"testDate"]
  result <- bind_rows(result, df)
}

# optionally, if want to overwrite...
result %>%
  select(-negative, -lat, -lon) %>%
  write_csv("current_data/county_long.csv")


# State Demographics

state_demo <- historical %>% 
  extract2(4) 

state_demo_data <- read_csv("current_data/state_demo_long.csv",
                            col_types="Dccciii")

# age
ag <- select(state_demo$age, agegroup=age_group, cases=count,
             tested, deaths) %>%
  mutate(date=filedate)
ag_race <- do.call(rbind.data.frame, state_demo$age$demographics[[1]]) %>%
  select(race=description, cases=count, tested, deaths)
ag_race <- ag_race %>% 
  mutate(agegroup = rep(ag$agegroup, each=n_distinct(ag_race$race)),
         date=filedate)

state_demo_data <- bind_rows(state_demo_data,
                             ag,
                             ag_race)
# race
state_demo_data <- bind_rows(state_demo_data, 
                             select(state_demo$race, race=description, cases=count, tested, deaths) %>%
                               mutate(date=filedate))
# gender
state_demo_data <- bind_rows(state_demo_data, 
                             select(state_demo$gender, gender=description, cases=count, tested, deaths) %>%
                               mutate(date=filedate))

state_demo_data %>%
  group_by(date, agegroup, race, gender) %>%
  summarize(cases=max(cases),
            tested=max(tested),
            deaths=max(deaths)) %>%
  write_csv("current_data/state_demo_long.csv")
