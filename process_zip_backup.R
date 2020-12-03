# Add in a historical zip code file into the data series

library(tidyverse)


make_date <- function(x) {
  mdy(paste(x$month, x$day, x$year))
}

zips <- jsonlite::fromJSON("backups/zips_2020-11-01 23:00:00.json")

zfiledate <- make_date(zips %>% extract2(1))

read_csv("current_data/zip_long.csv",
         col_types="cDii") %>%
  bind_rows(mutate(zips$zip_values, date=zfiledate)) %>%
  group_by(zip, date) %>%
  summarize(confirmed_cases=max(confirmed_cases),
            total_tested=max(total_tested)) %>%
  write_csv("current_data/zip_long.csv")

