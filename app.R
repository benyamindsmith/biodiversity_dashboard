library(shiny)
library(dplyr)
library(lubridate)
library(glue)
library(leaflet)
library(plotly)

# The data 
occurrence_pl <-readr::read_csv("./data/occurrence_pl_preprocessed.csv") 

####################
# Modularized Code #
####################

# Month year range slider. Hides away the mess from the UI making it easier to read.  
month_year_slider <- function(id, display_name,dataset, month_year_column){
  
  if(!is.Date(dataset[[month_year_column]])){
    stop(glue("Invalid column selected. {month_year_column} does not have the 'Date' class"))
  }
  
  sliderInput(id,
              display_name,
              value = c(min(dataset[[month_year_column]]),
                        max(dataset[[month_year_column]])),
              min= min(dataset[[month_year_column]]),
              max= max(dataset[[month_year_column]]),
              timeFormat="%b %Y")
}

# Plotting functions (for server side)
map_plot <- function(data, 
                     lng, 
                     lat, 
                     popup) {
  data %>%
    leaflet(options = leafletOptions(attributionControl=FALSE)) %>%
    addTiles() %>%
    addMarkers(
      clusterOptions = markerClusterOptions(),
      lng = as.formula(paste0("~", {{lng}})),
      lat = as.formula(paste0("~", {{lat}})),
      popup =as.formula(paste0("~", {{popup}}))
    )
}

timeline_plot <- function(data, 
                          time_var, 
                          value_var, 
                          fill="blue",
                          title="Occurences Over Time",
                          xaxis_title="",
                          yaxis_title=""){
  
  data %>% 
  plot_ly(
    x = as.formula(paste0("~", {{time_var}})),
    y = as.formula(paste0("~", {{value_var}})),
    fill = fill,
    type = "scatter",
    mode = "lines"
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title),
      yaxis = list(title = yaxis_title)
    )
}
######
# UI #
######
ui <- fluidPage(
  # Application title
  titlePanel(title = div(
    img(src = "appsilon_logo.png",
        width = "200px"),
    "Biodiversity Dashboard"
  )),
  
  # Top Row- Species and Date Filters
  fixedRow(
  # Search by Species: Since the number of choices to search is large. 
  # A server side selective is done.
  column(3,selectizeInput("searchSpecies","Search By Species",choices = NULL)),
  
  column(3, month_year_slider("filterTime","Filter By Date (Month-Year)",occurrence_pl,"month_year"))
  ),
  
  # Bottom Row. Map and Timeline Outputs
  fixedRow(
    
    column(6,leafletOutput("mapOutput")),
    
    column(6,plotlyOutput("timelineOutput"))
    )
)

##########
# Server #
##########

server <- function(input, output, session) {
  
  # Server side selectize to allow for users to search by species (scientific and vernacular)
  updateSelectizeInput(
    session,
    'searchSpecies',
    choices = unique(occurrence_pl[["display_name"]]),
    selected="Alces alces (Elk)",
    server = TRUE
  )
  
  # A listener to check for changes in multiple inputs
  filterListener <- reactive({
    list(input$searchSpecies,input$filterTime)
  })
  
  #Output Plots
  mapOutput <- eventReactive(filterListener(), {
    
    # Filtered data for map
    filtered_data <- occurrence_pl %>%
                     filter(display_name == input$searchSpecies,
                            between(month_year,input$filterTime[1],input$filterTime[2])) 
    
      # Map plot returned
      map_plot(data=filtered_data,
               lng= "longitudeDecimal",
               lat="latitudeDecimal",
               popup="popup")
  })
  
  timelineOutput <- eventReactive(filterListener(),{
                                  # Filtered and aggregated data for timeline
                                  agg_data <- occurrence_pl %>%
                                    filter(
                                      display_name == input$searchSpecies,
                                      between(month_year, input$filterTime[1], input$filterTime[2])
                                    ) %>%
                                    group_by(month_year) %>%
                                    summarize(n = n()) 
                                    
                                    # Timeline plot returned
                                    timeline_plot(data=agg_data,
                                                  time_var="month_year",
                                                  value_var="n")
                                  
                                })
  
  # Rendered plots
  output$mapOutput <- renderLeaflet(mapOutput())
  output$timelineOutput <- renderPlotly(timelineOutput())
  
}

# Run the application
shinyApp(ui = ui, server = server)
