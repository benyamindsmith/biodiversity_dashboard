![](https://raw.githubusercontent.com/benyamindsmith/appsilon_app/main/www/appsilon_logo.png?token=GHSAT0AAAAAABXQSBT3BZGPBX7HTD3NGGMGY7W4ARQ)

# Biodiversity Dashboard Assignment

A submission of the Biodiversity Dashboard Assignment for the Appsilon Shiny Developer Job Posting

## Introduction

This dashboard focuses primarily on the ["Main Task"](https://docs.google.com/document/d/1E5DgNGL7cl6N1c1wMPmNggmGbRV-p1ySpL_Y-D4akOs/edit#heading=h.uvhg9zb5yl9e) as described in the assignment. 

The finished product looks like this: 

![image](https://user-images.githubusercontent.com/46410142/220816538-b836c938-99ed-4845-bb0f-eede3a59d106.png)

**For the scope of this project, only the occurrence data set has been used. Should additional features be requested the multimedia data set can also be used.**

## What does this address

The finished product addresses the following:

1. The General Overview
  
  - The dashboard allows for users to visualize a selected species of observations on both a map and view visually how often it is observed over time.
  
  - The focus of the dashboard is only for Poland. 

2. The Technical Requirements

  - There are no scaffolding tools like golem, packer, etc.
  
  - There is a README to help potential future developers of this app
(right here!)
  
  - [IN PROGRESS]

## Dependencies

The following packages are used for this dashboard: 

1. For pre-processing
    - `sparklyr`
  
    - `DBI`

2. For the dashboard:
    
    - `shiny`
    
    - `dplyr`
    
    - `glue`
    
    - `leaflet`
    
    - `plotly`

## Preprocessing

Due to the files being very large, the data needed to be initially loaded with spark via the `sparklyr` package. After that the `occurences.csv` file was filtered to only Poland data. 

While the raw extracted biodiversity data is not included in the submission, the pre-processing code to reduce the data set to a size that can be used is: 

```r
library(sparklyr)
library(DBI)
library(dplyr)
library(lubridate)
library(glue)
# The file path for where the tar.gz file is downloaded

download_filepath <- "./Downloads/biodiversity-data.tar.gz"

untar(download_filepath)

# Load the data with spark 

setwd("./appsilon_app")

sc <- spark_connect(master = "local")

spark_read_csv(sc=sc,
               name="occurrence",
               path="./data/occurrence.csv",
               memory=FALSE)

# Query the occurrence data for only Poland data
dbGetQuery(sc,"SELECT * FROM occurrence WHERE countryCode=='PL'") %>% 
readr::write_csv("./data/occurrence_pl.csv")

# Read and wrangle data in R because its easier
readr::read_csv("./data/occurrence_pl.csv") %>%
  mutate(
    month = eventDate %>%
      as.Date() %>%
      month(),
    year = eventDate %>% as.Date() %>% year(),
    coordinate_uncertainty = glue("{coordinateUncertaintyInMeters}m",
                                  coordinateUncertaintyInMeters=coordinateUncertaintyInMeters),
    month_year = glue("{month}-{year}",
                      month = month,
                      year = year) %>% my(),
    display_name = ifelse(
      is.na(vernacularName),
      scientificName,
      glue(
        "{scientificName} ({vernacularName})",
        scientificName = scientificName,
        vernacularName = vernacularName
      )
    ),
    popup = glue(
      "
       <b>{display_name}</b><br>
       occurrence ID: {occurrence_id}<br>
       Date Seen: {date_seen}<br>
       Sex: {sex}<br>
       Life Stage: {life_stage}<br>
       Behavior: {behavior}<br>
       <b>Coordinate Uncertainty: {coordinate_uncertainty} </b>
      ",
      display_name = display_name,
      occurrence_id = occurrenceID,
      date_seen = as.Date(eventDate),
      sex = sex,
      life_stage = lifeStage,
      behavior = behavior,
      coordinate_uncertainty=coordinate_uncertainty
    )
  ) %>% 
  readr::write_csv("./data/occurrence_pl_preprocessed.csv")

```

This can also be seen [preprocessing.R](https://github.com/benyamindsmith/appsilon_app/blob/main/preprocessing.R).


## Modularized Code

(Summarize data)

## ShinyApps.io Deployment

## Unit Tests

Due to the scope of this project and the way that the dashboard has been built, the author of this dashboard has not seen a need for unit tests on this dashboard. Should there be corner cases discovered, unit tests will be written. 



