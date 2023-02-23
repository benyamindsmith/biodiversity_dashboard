library(shiny)
library(dplyr)
library(lubridate)
library(glue)
library(leaflet)
library(plotly)

# TODO: MODULARIZE THE CODE!!
# TODO: NAMING SUCKS. FIX IT!!
occurrence_pl <-
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
  )
# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel(title = div(
    img(src = "appsilon_logo.png",
        width = "200px"),
    "Biodiversity Dashboard"
  )),
  
  fixedRow(
  column(3,
  selectizeInput(
    "searchSpecies",
    "Search By Species",
    choices = NULL
  )),
  column(3,
  sliderInput("filterTime",
              "Filter By Date (Month-Year)",
              value = c(min(as.Date(occurrence_pl$month_year)),
                        max(as.Date(occurrence_pl$month_year))),
              min= min(as.Date(occurrence_pl$month_year)),
              max= max(as.Date(occurrence_pl$month_year)),
              timeFormat="%b %Y"))),
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
    choices = unique(occurrence_pl$display_name),
    selected="Alces alces (Elk)",
    server = TRUE
  )
  
  toListen <- reactive({
    list(input$searchSpecies,input$filterTime)
  })
  
  mapOutput <- eventReactive(toListen(), {
    occurrence_pl %>%
      filter(display_name == input$searchSpecies,
             between(month_year,input$filterTime[1],input$filterTime[2])) %>%
      leaflet(options = leafletOptions(attributionControl=FALSE)) %>%
      addTiles() %>% 
      addMarkers(
        clusterOptions = markerClusterOptions(),
        lng =  ~ longitudeDecimal,
        lat =  ~ latitudeDecimal,
        popup = ~ popup
      )
  })
  
  output$mapOutput <- renderLeaflet(mapOutput())
  
  timelineData <- eventReactive(toListen(),
                                {
                                  occurrence_pl %>%
                                    filter(display_name == input$searchSpecies,
                                           between(month_year,input$filterTime[1],input$filterTime[2])) %>%
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
                                      title = "Occurrences Over Time",
                                      xaxis = list(title = ""),
                                      yaxis = list(title = "")
                                    )
                                  
                                })
  
  output$timelineOutput <- renderPlotly(timelineData())
  
}

# Run the application
shinyApp(ui = ui, server = server)
