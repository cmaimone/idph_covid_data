library(readr)
library(dplyr)
library(httr)
library(glue)
library(lubridate)
library(stringr)
library(magrittr)
library(zip)

print("--------------------------------")
print(now())

make_date <- function(x) {
  mdy(paste(x$month, x$day, x$year))
}

most_recent_download <- function(type) {  # type is historical or zips
  mostrecent <- list.files(path="backups",
             pattern = glue("{t}_20*", t=type),
             full.names = TRUE) %>% 
    str_remove(glue("backups/{t}_", t=type)) %>%
    str_remove(".json") %>%
    str_remove(" UTC")
  glue("backups/{t}_{d}.json", t=type, d=mostrecent[which.max(parse_datetime(mostrecent))])
}

# Historical County Data ----

historical <- GET("http://www.dph.illinois.gov/sitefiles/COVIDHistoricalTestResults.json") 

historical %>% 
  content(as="text") %>%
  write("backups/historical_holding.json")

# if this is a new file, process...
if (tools::md5sum(most_recent_download("historical")) != tools::md5sum("backups/historical_holding.json")) {
  filedate <- make_date(historical %>% content() %>% extract2(1))
  file.rename("backups/historical_holding.json", glue("backups/historical_{d1}.json", d1=now()))

  county_hist <- historical %>% 
    content() %>% 
    extract2("historical_county") %>% 
    extract2(1) 
  
  result <- do.call(rbind.data.frame, county_hist[[1]]$values)
  result$date <- county_hist[[1]]$testDate
  for (d in 2:length(county_hist)) {
    df <- do.call(what=rbind.data.frame, county_hist[[d]]$values)
    df$date <- county_hist[[d]]$testDate
    result <- bind_rows(result, df)
  }
  
  result %>%
    select(-negative, -lat, -lon) %>%
    write_csv("current_data/county.csv")
  
  county_names <- unique(result$County)
  
  # County Demographics ----
  # assume these change when main file changes
  # will overwrite daily file if there already is one
  county_demo <- read_csv("current_data/county_demo.csv",
                          col_types = "cDccii")
  for (cn in county_names) {
    print(cn)
    resp <- GET(glue("https://idph.illinois.gov/DPHPublicInformation/api/COVID/GetCountyDemographics?countyName={n}", 
                     n=str_replace_all(cn, " ", "%20")))
    tmp <- resp %>% content()
    updated <- make_date(tmp$lastUpdatedDate)
    resp %>% content(as="text") %>% 
      write(file=glue("backups/county_demo/county_{n}_{d1}.json", n=str_replace_all(cn, " ", "_"), d1=updated))
    demo <- tmp %>%
      extract2(2) %>% 
      extract2(1) %>%
      extract("demographics") %>%
      extract2(1) 
    
    try({
      age <- demo$age %>% unlist() %>% 
        matrix(ncol=4, byrow=TRUE) %>% 
        data.frame() %>%
        select(group=X1, cases=X2, tested=X3) %>%
        mutate(cases = as.integer(cases),
               tested = as.integer(tested)) %>%
        mutate(measure="age", county=cn, date=updated, group = str_trim(group)) 
      county_demo <- bind_rows(county_demo, age)
    })
    try({
      race <- demo %$%
        do.call(what=rbind.data.frame, race) %>%
        select(group=description, cases=count, tested) %>%
        mutate(measure="race", county=cn, date=updated, group = str_trim(group))
      county_demo <- bind_rows(county_demo,race)
    })
    try({
      gender <- demo %$%
        do.call(what=rbind.data.frame, gender) %>%
        select(group=description, cases=count, tested) %>%
        mutate(measure="gender", county=cn, date=updated, group = str_trim(group))
      county_demo <- bind_rows(county_demo, gender)
    })
  }
  
  # make sure only have one entry per group per day
  county_demo %>%
    group_by(county, date, measure, group) %>%
    summarize(cases=max(cases),
              tested=max(tested)) %>%
    arrange(county, desc(date)) %>% 
    write_csv("current_data/county_demo.csv")
  
  
  # State Level Demographics ----
  state_demo <- historical %>% 
    content() %>% 
    extract2(4) 
  
  state_demo_data <- read_csv("current_data/state_demo.csv",
                              col_types="Dccciii")
  
  # age
  for (agegroup in state_demo$age) {
    state_demo_data <- bind_rows(state_demo_data, 
                                 do.call(rbind.data.frame, agegroup$demographics$race) %>%
                                  bind_rows(tibble(count=agegroup$count, 
                                                   tested=agegroup$tested,
                                                   deaths=agegroup$deaths)) %>%
                                  mutate(agegroup = agegroup$age_group,
                                         date=filedate) %>%
                                  select(date, agegroup, race=description, cases=count, tested, deaths))
  }
  # race
  state_demo_data <- bind_rows(state_demo_data, 
                               do.call(rbind.data.frame, state_demo$race) %>%
                                 mutate(agegroup = NA,
                                        date=filedate) %>%
                                 select(date, agegroup, race=description, cases=count, tested, deaths))
  # gender
  state_demo_data <- bind_rows(state_demo_data, 
                               do.call(rbind.data.frame, state_demo$gender) %>%
                                 mutate(agegroup = NA,
                                        race=NA,
                                        date=filedate) %>%
                                 select(date, agegroup, race, gender=description, cases=count, tested, deaths))
  
  state_demo_data %>%
    group_by(date, agegroup, race, gender) %>%
    summarize(cases=max(cases),
              tested=max(tested),
              deaths=max(deaths)) %>%
    arrange(desc(date)) %>%
    write_csv("current_data/state_demo.csv")
  
  
  # condense backup files (keep individual files locally, push zip to git)
  zip(glue("backups/county_demo/{d1}.zip", d1=filedate), 
      list.files("backups/county_demo", pattern=as.character(filedate), full.names=TRUE))
} # end of processing new historical file


# County Historical  Youth ----

print(">>Historical Youth")

resp <- GET("http://www.dph.illinois.gov/sitefiles/COVIDCountyRiskMetrics.json")

resp %>% 
  content(as="text") %>%
  write("backups/county_risk_holding.json")

# if this is a new file, process...
if (tools::md5sum(most_recent_download("county_risk")) != tools::md5sum("backups/county_risk_holding.json")) {
  
  file.rename("backups/county_risk_holding.json", glue("backups/county_risk_{d1}.json", d1=now()))
  
  x <- resp %>% 
    content() 
  
  do.call(rbind.data.frame, x[["historical_demographics"]]) %>%
    select(date=reported_date, County, youthCaseCount, youthCaseTested) %>%
    mutate(date = date(date)) %>%
    arrange(desc(date), County) %>%
    write_csv("current_data/county_youth_historical.csv")
  
} # symptoms



# Zip Codes ----

print(">>Zip Codes")

zips <- GET("https://idph.illinois.gov/DPHPublicInformation/api/COVID/GetZip")

zips %>% 
  content(as="text") %>%
  write("backups/zips_holding.json")

if (tools::md5sum(most_recent_download("zips")) != tools::md5sum("backups/zips_holding.json")) {
  file.rename("backups/zips_holding.json", glue("backups/zips_{d1}.json", d1=now()))
    
  zfiledate <- make_date(zips %>% content() %>% extract2(1))
  
  zip_hist_data <- do.call(rbind.data.frame, zips %>% content() %>% extract2(2)) %>%
    mutate(date = zfiledate)
  
  read_csv("current_data/zip.csv",
           col_types="ccii") %>%
    mutate(date = ymd(date)) %>%
    bind_rows(zip_hist_data) %>%
    group_by(zip, date) %>%
    summarize(confirmed_cases=max(confirmed_cases),
              total_tested=max(total_tested)) %>%
    arrange(desc(date), zip) %>%
    write_csv("current_data/zip.csv")
  
  
  # Zip Code Demographics ----
  
  # will read .zip file automatically
  zip_demo <- read_csv("current_data/zip_demo.zip",
                       col_types="cDccii") 
  
  for (zipcode in unique(zip_hist_data$zip)) {
    print(zipcode)
    resp <- GET(glue("https://idph.illinois.gov/DPHPublicInformation/api/COVID/GetZipDemographics?zipCode={z}", z=zipcode))
    
    demo <- resp %>% content()
    # file doesn't have last updated date -- use today (assume updated if other data is)
    
    resp %>% content(as="text") %>% 
      write(file=glue("backups/zip_demo/zip_{n}_{d1}.json", n=zipcode, d1=zfiledate))
    
    try(silent=TRUE, {
      age <- demo %$%
        do.call(what=rbind.data.frame, age) %>%
        select(group=age_group, cases=count, tested) %>%
        mutate(measure="age", zip=zipcode, date=zfiledate, group = str_trim(group)) 
      zip_demo <- bind_rows(zip_demo, age)
    })
    try(silent=TRUE, {
      race <- demo %$%
        do.call(what=rbind.data.frame, race) %>%
        select(group=description, cases=count, tested) %>%
        mutate(measure="race", zip=zipcode, date=zfiledate, group = str_trim(group))
      zip_demo <- bind_rows(zip_demo, race)
    })
    try(silent=TRUE, {
      gender <- demo %$%
        do.call(what=rbind.data.frame, gender) %>%
        select(group=description, cases=count, tested) %>%
        mutate(measure="gender", zip=zipcode, date=zfiledate, group = str_trim(group))
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
  

} # end process new zip data
  


# Race and Ethnicity ----
print(">>Race and Eth")

resp <- GET("http://www.dph.illinois.gov/sitefiles/COVIDRaceEthnicity.json")

resp %>% 
  content(as="text") %>%
  write("backups/raceeth_holding.json")

# if this is a new file, process...
if (tools::md5sum(most_recent_download("raceeth")) != tools::md5sum("backups/raceeth_holding.json")) {
  filedate <- make_date(resp %>% content() %>% extract2(1))
  file.rename("backups/raceeth_holding.json", glue("backups/raceeth_{d1}.json", d1=filedate))
  
  raceeth <- resp %>% 
    content() 
  
  # race
  do.call(rbind.data.frame, raceeth %>% extract2(2) ) %>%
    select(date=report_date, group=race, positive_cases, total_tested) %>%
    bind_rows(do.call(rbind.data.frame, raceeth %>% extract2(3)) %>%
                select(date=report_date, group=Ethnicity, positive_cases, total_tested)) %>%
    arrange(desc(date), group) %>%
    write_csv("current_data/race_eth_historical.csv")
  
  # age
  do.call(rbind.data.frame, raceeth %>% extract2(4) ) %>%
    select(date=report_date, group=AgeGrp, positive_cases) %>%
    arrange(desc(date), group) %>%
    write_csv("current_data/age_historical.csv")

} # end new race_eth data


# Hospitalization ----
print(">>Hospitalization")

resp <- GET("http://idph.illinois.gov/DPHPublicInformation/api/COVID/GetHospitalizationResults")

resp %>% 
  content(as="text") %>%
  write("backups/hospitalization_holding.json")

# if this is a new file, process...
if (tools::md5sum(most_recent_download("hospitalization")) != tools::md5sum("backups/hospitalization_holding.json")) {
  filedate <- make_date(resp %>% content() %>% extract2(1))
  file.rename("backups/hospitalization_holding.json", glue("backups/hospitalization_{d1}.json", d1=filedate))
  
  x <- resp %>% 
    content() 
  
  # regional
  do.call(rbind.data.frame, x %>% extract2(2) ) %>%
    mutate(date=filedate) %>%
    select(date, region, id, ICUAvail, ICUCapacity, VentsAvailable, VentsCapacity) %>%
    bind_rows(read_csv("current_data/hospitalization_regional.csv")) %>%
    group_by(date, region, id) %>%
    summarize(across(everything(), max, na.rm=TRUE)) %>%
    write_csv("current_data/hospitalization_regional.csv")
  
  # state
  x$statewideValues %>% unlist() %>% t() %>% data.frame() %>%
    mutate(date=filedate) %>%
    select(date, everything()) %>%
    bind_rows(read_csv("current_data/hospitalization_state.csv",
              col_types=cols(.default=col_character())) %>% mutate(date=ymd(date))) %>%
    group_by(date) %>%
    summarize(across(everything(), max, na.rm=TRUE)) %>%
    write_csv("current_data/hospitalization_state.csv")
  
  # utilization
  do.call(rbind.data.frame, x$HospitalUtilizationResults ) %>%
    mutate(date=date(ReportDate)) %>%
    select(date, everything(), -ReportDate) %>%
    bind_rows(read_csv("current_data/hospitalization_utilization.csv") %>% mutate(date=ymd(date))) %>%
    group_by(date) %>%
    summarize(across(everything(), max, na.rm=TRUE)) %>%
    arrange(desc(date)) %>%
    write_csv("current_data/hospitalization_utilization.csv")
  
} # end hospitalization


# Symptom Tracker ----
print(">>Symptoms")

resp <- GET("http://dph.illinois.gov/sitefiles/COVIDSyndromic.json")

resp %>% 
  content(as="text") %>%
  write("backups/symptoms_holding.json")

# if this is a new file, process...
if (tools::md5sum(most_recent_download("symptoms")) != tools::md5sum("backups/symptoms_holding.json")) {

  file.rename("backups/symptoms_holding.json", glue("backups/symptoms_{d1}.json", d1=now()))
  
  x <- resp %>% 
    content() 

  do.call(rbind.data.frame, x[[1]]) %>%
    select(date=timeResolution, category=combinedCategory, perc=count, count=numerator, baseline=denominator) %>%
    arrange(desc(date)) %>%
    write_csv("current_data/symptoms_historical.csv")
  
} # symptoms

print(">>Git")

# push everything to the repo
system("git add *")
system(glue('git commit -m "auto {m}"', m=today()))
system("git push origin master")

print(now())
