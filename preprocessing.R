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
