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
