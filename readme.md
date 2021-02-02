# IDPH COVID-19 Statistics

## Data

Data displayed on the [IDPH website](http://www.dph.illinois.gov/covid19/covid19-statistics) is collected and aggregated here.  Data since 2020-11-02 is collected from underlying JSON files and includes demographic data.  Older data was collected by scraping the displayed website using [this code](https://github.com/FarhadGSRX/IL-Covid-Data-Repeater/).

Find an issue or problem?  Please add an issue on this repo or [let me know](mailto:christina.maimone@northwestern.edu).

If you've been using data from the [previous repository](https://github.com/FarhadGSRX/IL-Covid-Data-Repeater/), the main files you'll likely be interested in are:

No Demographics: 
* [County Data](https://github.com/cmaimone/idph_covid_data/blob/master/current_data/county.csv?raw=true)
* [Zip Code Data](https://github.com/cmaimone/idph_covid_data/blob/master/current_data/zip.csv?raw=true)
* State Level Data: "Illinois" is an entry in the county data file.

Demographics:
* [County Data](https://github.com/cmaimone/idph_covid_data/blob/master/current_data/county_demo.csv?raw=true)
* [Zip Code Data](https://github.com/cmaimone/idph_covid_data/blob/master/current_data/zip_demo.zip?raw=true) - note: compressed file; missing 12/3/20 and 12/4/20
* State Level Data: "Illinois" is an entry in the county data file.

COVID Data Availability:

* By County
  * Cumulative cases, tests, and deaths by date daily back to 3/17/20: [`current_data/county.csv`](current_data/county.csv)
  * Age (groups), race, and gender demographics (all separately, not intersecting) - cumulative tests and cases (not deaths) - by date daily back to 11/2/20: [`current_data/county_demo.csv`](current_data/county_demo.csv)
  * Youth tests and cases, weekly, by county, back to 6/7/20 [`current_data/county_youth_historical.csv`](current_data/county_youth_historical.csv)
  * **Note:** The county data files include "Illinois" as a county with state totals - be careful if aggregating this data.
* By State
  * Same as for county, included as "Illinois" in the county files above
  * For entire state, by age and race (intersecting, by age groups), tests, cases, and deaths, daily, back to 11/1/20: [`current_data/state_demo.csv`](current_data/state_demo.csv) - NAs indicate totals for the demographic grouping
  * For entire state, by age (cases) and race/ethnicity (cases, tests) (separately), daily back to early 2020 (but not updated daily) - [`current_data/race_eth_historical.csv`](current_data/race_eth_historical.csv)  (note: hispanic/not hispanic categories overlap with the other categories; days with 0s for a category aren't included) and [`current_data/age_historical.csv`](current_data/age_historical.csv)
* By Zip Code
  * Cumulative cases and tests (not deaths) by date daily back to 3/17/20: [`current_data/zip.csv`](current_data/zip.csv)
  * Age (groups), race, and gender demographics (all separately, not intersecting) - cumulative tests and cases (not deaths) - by date daily back to 4/18/20: [`current_data/zip_demo.zip`](current_data/zip_demo.zip) **NOTE**: compressed file
* Hospitalization Data
  * State statistics, back to 11/2/2020 - [`current_data/hospitalization_state.csv`](current_data/hospitalization_state.csv)
  * Regional statistics, back to 11/2/2020 - [`current_data/hospitalization_regional.csv`](current_data/hospitalization_regional.csv)
  * Historical state utilization statistics, back to 4/12/2020 - [`current_data/hospitalization_utilization.csv`](current_data/hospitalization_utilization.csv)
  * Symptoms, daily, back to beginning of 2020 (not updated daily) - [`current_data/symptoms_historical.csv`](current_data/symptoms_historical.csv)
  

Helper Files:

* [`current_data/helper/NOFO_Regions.csv`](current_data/helper/NOFO_Regions.csv): aggregates counties into NOFO regions
* [`current_data/helper/Illinois_Census_200414_1816.csv`](current_data/helper/Illinois_Census_200414_1816.csv): Census demographics for counties with mapping to NOFO region, metro area, and FIPS county code
* [`current_data/helper/population.csv`](current_data/helper/population.csv): Illinois population for race and age groups, from http://www.dph.illinois.gov/sitefiles/COVIDRaceEthnicity.json

# Notes about Data/Collection

The IDPH reports historical time series for the following files.  The data files here have the currently reported value for each day, which may differ than the originally reported value for a given day.  To see the data as reported on a given date, check the backups folder for the last JSON file downloaded with a listed date, or the archives in the [previous repository/spreadsheets](https://github.com/FarhadGSRX/IL-Covid-Data-Repeater/).

* [`current_data/county.csv`](current_data/county.csv) - 3/17/20 onward
* [`current_data/race_eth_historical.csv`](current_data/race_eth_historical.csv) - early 2020 onward
* [`current_data/age_historical.csv`](current_data/age_historical.csv) - early 2020 onward
* [`current_data/hospitalization_utilization.csv`](current_data/hospitalization_utilization.csv) - 4/12/20 onward
* [`current_data/county_youth_historical.csv`](current_data/county_youth_historical.csv) - 2020-06-07 onward
* [`current_data/symptoms_historical.csv`](current_data/symptoms_historical.csv) - early 2020 onward

The IDPH does NOT report historical time series for the following files.  The data files here are aggregated by collecting this data daily from the IDPH and keeping a record of the maximum value reported each day.  Due to data corrections, the cumulative values for a day could be slightly lower than those for a previous day.

* [`current_data/county_demo.csv`](current_data/county_demo.csv) - 11/2/20 onward
* [`current_data/zip_demo.zip`](current_data/zip_demo.zip) - 4/18/20 onward, note: compressed file; missing 12/3, 12/4
* [`current_data/state_demo.csv`](current_data/state_demo.csv) - 11/1/20 onward
* [`current_data/zip.csv`](current_data/zip.csv) - 3/17/20 onward
* [`current_data/hospitalization_state.csv`](current_data/hospitalization_state.csv) - 11/2/20
* [`current_data/hospitalization_regional.csv`](current_data/hospitalization_regional.csv) - 11/2/20


### Data Notes

* 2021/02/02: The historical data file hasn't been updated by IDPH since 1/29, which means several of the data files haven't been updated.  All of the updated data that is available is being collected.
* 2020/12/5: missing December 3-4 from the zip_demo.zip file
* 2020/12/2: switched files out of lfs and zipped zip_demo file
* 2020/11/24: county demographics files changed format for age data -- extra race and deaths items included for age groups, but without data in them; this necessitated a change in the script; monitoring for future changes
* "Cases" has been labeled "Positive Cases" and "Confirmed Cases" in various iterations of the data.  The data series appear to be consistent, and these are reported in the same columns in data files here.


# Acknowledgement

[Farhad Ghamsari](https://github.com/FarhadGSRX) created the [first version](https://github.com/FarhadGSRX/IL-Covid-Data-Repeater/) of this software in March 2020.

