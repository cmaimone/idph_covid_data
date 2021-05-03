library(readr)
library(dplyr)
library(httr)
library(glue)
library(lubridate)
library(stringr)
library(magrittr)
library(zip)
library(jsonlite)

zfiledate <- "2021-05-02"

zip_demo <- read_csv("current_data/zip_demo.zip",
                     col_types="ccccii") 

for (zipcode in unique(zip_demo$zip)) {
  print(zipcode)
  demo <- fromJSON(glue("backups/zip_demo/zip_{n}_{d1}.json", n=zipcode, d1=zfiledate))
  
  try(silent=TRUE, {
    age <- demo$age %>%
      select(group=age_group, cases=count, tested) %>%
      mutate(measure="age", zip=as.character(zipcode), date=zfiledate, group = str_trim(group)) 
    zip_demo <- bind_rows(zip_demo, age)
  })
  try(silent=TRUE, {
    race <- demo$race %>%
      select(group=description, cases=count, tested) %>%
      mutate(measure="race", zip=as.character(zipcode), date=zfiledate, group = str_trim(group))
    zip_demo <- bind_rows(zip_demo, race)
  })
  try(silent=TRUE, {
    gender <- demo$gender %>%
      select(group=description, cases=count, tested) %>%
      mutate(measure="gender", zip=as.character(zipcode), date=zfiledate, group = str_trim(group))
    zip_demo <- bind_rows(zip_demo, gender)
  })
}

# make sure only have one entry per group per day
zip_demo %>%
  group_by(zip, date, measure, group) %>%
  summarize(cases=max(cases),
            tested=max(tested)) %>%
  arrange(desc(date), zip) %>% 
  write_csv("current_data/zip_demo.csv")

# zip up this file to save space
zip("current_data/zip_demo.zip", "current_data/zip_demo.csv")

# condense backup files (keep individual files locally, push zip to git)
zip(glue("backups/zip_demo/{d1}.zip", d1=zfiledate), 
    list.files("backups/zip_demo", pattern=as.character(zfiledate), full.names=TRUE))
