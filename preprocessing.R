# Preprocessing
library(data.table)
library(fst)
library(sparklyr)

# download_filepath <- "C:/Users/ben29/Downloads/biodiversity-data.tar.gz"
# 
# untar(download_filepath)

# Now load data into SQLite by importing the csv files. 

setwd("./appsilon_app/biodiversity_dashboard")
sc <- spark_connect(master = "local")

sparklyr::spark_read_csv(sc=sc,
                         name="multimedia",
                         path="./biodiversity-data/multimedia.csv",
                         memory=FALSE)

sparklyr::spark_read_csv(sc=sc,
                         name="occurence",
                         path="./biodiversity-data/occurence.csv",
                         memory=FALSE)



occurencePL <- dbGetQuery(sc,"SELECT * FROM occurence WHERE countryCode=='PL'")
