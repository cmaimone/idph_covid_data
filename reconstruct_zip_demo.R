# Reconstruct zip demographics file from backups

library(tidyverse)
library(zip)
library(lubridate)
library(jsonlite)

# restart empty file
write("zip,date,measure,group,cases,tested\n",
      "current_data/zip_demo.csv")

zip_demo <- read_csv("current_data/zip_demo.csv",
                     col_types="cDccii")

for (f in list.files(path="backups/zip_demo", pattern="2020*", full.names = TRUE)) {
  unzip(f)
}

for (f in list.files(path="backups/zip_demo", pattern="zip_", full.names = TRUE)) {
  zipcode <- str_match(f, "zip_(\\d{5})_")[1,2]
  d1 <- str_match(f, "zip_\\d{5}_(.+).json")[1,2] %>% ymd()
  print(paste(zipcode, d1))
  x <- fromJSON(f)
  try(silent=TRUE,
    zip_demo <- x$age %>%
      mutate(zip=zipcode, date=d1, measure="age", age_group=trimws(age_group)) %>%
      rename(group=age_group, cases=count) %>%
      bind_rows(zip_demo)
  )
  try(silent=TRUE,
    zip_demo <- x$race %>%
      mutate(zip=zipcode, date=d1, measure="race") %>%
      rename(group=description, cases=count) %>%
      select(-color) %>%
      bind_rows(zip_demo)
  )
  try(silent=TRUE,
    zip_demo <- x$gender %>%
      mutate(zip=zipcode, date=d1, measure="gender") %>%
      rename(group=description, cases=count) %>%
      select(-color) %>%
      bind_rows(zip_demo)
  )
}

zip_demo %>%
  select(zip,date,measure,group,cases,tested) %>%
  write_csv("current_data/zip_demo.csv")


