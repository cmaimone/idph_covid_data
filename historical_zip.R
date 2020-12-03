# Add in historical zip code data from https://github.com/FarhadGSRX/IL-Covid-Data-Repeater

library(tidyverse)
library(lubridate)

hzip <- read_csv("basedata/IDPH Stats Zip - long.csv") %>% 
  mutate(update_date = mdy(update_date),
         Tested = ifelse(update_date == "2020-10-11", NA, Tested))  # known missing data

current_zip <- read_csv("current_data/zip.csv")

hzip %>%
  select(zip=Zip, 
         date = update_date,
         confirmed_cases = Positive_Cases,
         total_tested = Tested) %>%
  bind_rows(current_zip) %>%
  group_by(zip, date) %>%
  summarize(confirmed_cases = max(confirmed_cases),
            total_tested = max(total_tested, na.rm=TRUE),
            total_tested = ifelse(total_tested == -Inf, NA, total_tested)) %>%
  arrange(desc(date), zip) %>%
  write_csv("current_data/zip.csv")






