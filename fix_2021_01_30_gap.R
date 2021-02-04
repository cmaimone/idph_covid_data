# Fix gap in data sets for 1/29/21-2/3/21 transition

county <- read_csv("current_data/county.csv")
county_demo <- read_csv("current_data/county_demo.csv")

county_agg <- county_demo %>%
  group_by(county, date, measure) %>%
  summarize(cases=sum(cases, na.rm=TRUE),
            tested=sum(tested, na.rm=TRUE)) %>% 
  ungroup() %>%
  group_by(county, date) %>%
  summarize(cases=max(cases, na.rm=TRUE),
            tested=max(tested, na.rm=TRUE))

# Missing 1/30/21-2/2/21

county_agg <- county_agg %>%
  filter(date >= "2021-01-30", date <= "2021-02-02") %>%
  rename(County=county, total_tested=tested, confirmed_cases=cases)

county %>%
  bind_rows(county_agg) %>%
  arrange(desc(date), County) %>% 
  write_csv("current_data/county.csv")



