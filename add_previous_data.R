# add in previous collection

library(fst)
library(tidyverse)

old <- read_fst("basedata/il-covid-counts-by-zipcode-11_12_2020.fst")
old2 <- old %>% 
  pivot_longer(cols=c(-date, -zipcode)) %>%
  mutate(var = ifelse(startsWith(name, "total_tested"), "tested", "cases"),
         name = str_remove(name, "confirmed_cases|total_tested"),
         name = str_remove(name, "^_"),
         name = str_replace_all(name, "_", " ")) %>%
  mutate(measure = case_when(
    name %in% c("male", "female", "unknownleftblank") ~ "gender",
    str_starts(name, "^\\d|^less|^unknown") ~ "age",
    TRUE ~ "race")) %>%
  mutate(name = str_replace(name, " to ", "-"),
         name = str_replace(name, "less than ", "<"),
         name = str_replace(name, " or more", "+"),
         name = na_if(name, ""),
         name = ifelse(name=="leftblank", "Left Blank", name),
         name = ifelse(name =="unknownleftblank", "Unknown/Left Blank", name),
         name = str_to_title(name),
         name = ifelse(name=="Aian", "AI/AN**", name),
         name = ifelse(name =="Nhpi", "NH/PI*", name)) %>%
  filter(!is.na(value),  # cases not reported in original files
         !is.na(name)) %>%  # overall counts for the county, which we have in a separate file here
  pivot_wider(id_cols=c(zipcode, date, measure, name), names_from=var, values_from=value)

  
zip_demo <- read_csv("current_data/zip_demo.csv",
                     col_types="cDccii") 

old2 %>%
  select(date, zip=zipcode, measure=measure, group=name, cases, tested) %>%
  mutate(date = ymd(date)) %>%
  bind_rows(zip_demo) %>%
  group_by(zip, date, measure, group) %>%
  summarize(cases=max(cases),
            tested=max(tested)) %>% 
  arrange(desc(date), zip) %>% 
  write_csv("current_data/zip_demo.csv")
