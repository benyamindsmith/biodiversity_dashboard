# appsilon_app

A submission of the Biodiversity Dashboard Assignment for the Appsilon Shiny Developer Job Posting

## Introduction


## Preprocessing

Due to the files being very large, the data needed to be initially loaded with spark via the `sparklyr` package. After that the `occurences.csv` file was filtered to only Poland data. 

While the raw extracted biodiversity data is not included in the submission, the pre-processing code to reduce the data set to a size that can be used is: 

```r
library(sparklyr)
library(DBI)

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
dbGetQuery(sc,"SELECT * FROM occurrence WHERE countryCode=='PL'") |> 
readr::write_csv("./data/occurrence_pl.csv")

```

This can also be seen [preprocessing.R]().

## Modularized Code

(Summarize data)

## ShinyApps.io Deployment

## Unit Tests


