library(shiny)
library(tidyverse)
library(lubridate)
library(glue)
library(leaflet)
library(plotly)
library(sf)


occurence_pl <-
  readr::read_csv("./biodiversity-data/occurence_pl.csv") %>%
  mutate(
    display_name = ifelse(is.na(vernacularName), scientificName,glue(
      "{scientificName} ({vernacularName})",
      scientificName = scientificName,
      vernacularName = vernacularName
    )),
    popup = glue(
      "
                                  <b>{display_name}</b><br>
                                  occurrence ID: {occurrence_id}<br>
                                  Date Seen: {date_seen}<br>
                                  Sex: {sex}<br>
                                  Life Stage: {life_stage}<br>
                                  Behavior: {behavior}",
      display_name = display_name,
      occurrence_id = occurrenceID,
      date_seen = as.Date(eventDate),
      sex = sex,
      life_stage = lifeStage,
      behavior = behavior
    )
  )
# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel(title = div(
    img(src = "appsilon_logo.png",
        width = "200px"),
    "Biodiversity Dashboard"
  )),
  
  selectizeInput(
    "searchSpecies",
    "Search By Species",
    choices = NULL
  ),
  sliderInput("filterTime",
              "Filter By Date",
              value = max(as.Date(occurence_pl$eventDate)),
              min= min(as.Date(occurence_pl$eventDate)),
              max= max(as.Date(occurence_pl$eventDate))),
  # Sidebar with a slider input for number of bins
  fixedRow(column(6,
                  leafletOutput("mapOutput")),
           column(6,
                  plotlyOutput("timelineOutput")))
)


# Define server logic required to draw a histogram
server <- function(input, output, session) {
  updateSelectizeInput(
    session,
    'searchSpecies',
    choices = unique(occurence_pl$display_name),
    selected="Alces alces (Elk)",
    server = TRUE
  )
  
  mapOutput <- eventReactive(input$searchSpecies, {
    occurence_pl %>%
      filter(display_name %in% input$searchSpecies) %>%
      leaflet(options = leafletOptions(attributionControl=FALSE)) %>%
      addTiles() %>%
      addCircleMarkers(
        lng =  ~ longitudeDecimal,
        lat =  ~ latitudeDecimal,
        popup = ~ popup
      )
  })
  
  output$mapOutput <- renderLeaflet(mapOutput())
  
  timelineData <- eventReactive(input$searchSpecies,
                                {
                                  occurence_pl %>%
                                    filter(display_name == input$searchSpecies) %>%
                                    mutate(
                                      month = eventDate %>%
                                        as.Date() %>%
                                        month(),
                                      year = eventDate %>% as.Date() %>% year(),
                                      month_year = glue("{month}-{year}",
                                                        month = month,
                                                        year = year) %>% my()
                                    ) %>%
                                    group_by(month_year) %>%
                                    summarize(n = n()) %>%
                                    plot_ly(
                                      x = ~ month_year,
                                      y = ~ n,
                                      fill = "blue",
                                      type = "scatter",
                                      mode = "lines"
                                    ) %>%
                                    layout(
                                      title = "Monthly Frequency Over Time",
                                      xaxis = list(title = ""),
                                      yaxis = list(title = "",
                                                   dtick = 1)
                                    )
                                  
                                })
  
  output$timelineOutput <- renderPlotly(timelineData())
  
}

# Run the application
shinyApp(ui = ui, server = server)
