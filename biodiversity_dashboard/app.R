library(shiny)
library(tidyverse)
library(lubridate)
library(glue)
library(leaflet)
library(plotly)
occurence_pl<-readr::read_csv("./biodiversity-data/occurence_pl.csv") %>% 
              mutate(display_name = glue::glue("{scientificName} ({vernacularName})",
                                   scientificName=scientificName,
                                   vernacularName=vernacularName))
# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel("Appsilon Biodiversity Dashboard"),
  
  # Sidebar with a slider input for number of bins
  sidebarLayout(
    # Show a plot of the generated distribution
    mainPanel(
      leafletOutput("mapOutput"),
      plotlyOutput("timelineOutput")
      
      ),
    sidebarPanel(
      selectizeInput("searchSpecies",
                     "Search Species",
                     choices = NULL)
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  updateSelectizeInput(
    session,
    'searchSpecies',
    choices = unique(occurence_pl$display_name),
    server = TRUE
  )
  
  map <- leaflet() %>%  
         addTiles() %>%  
         fitBounds(14.0745211117, 
                   49.0273953314, 
                   24.0299857927, 
                   54.8515359564)
  
  output$mapOutput <- renderLeaflet(map)
  
  timelineData<- eventReactive(input$searchSpecies,
                              {
                                occurence_pl %>% 
                                filter(display_name==input$searchSpecies) %>% 
                                mutate(month=eventDate %>% 
                                                 as.Date() %>% 
                                                 month(),
                                        year = eventDate %>% as.Date() %>% year(),
                                       month_year = glue("{month}-{year}",
                                                         month=month,
                                                         year=year) %>% my()) %>% 
                                  group_by(month_year) %>% 
                                  summarize(n=n()) %>% 
                                  plot_ly(x = ~month_year, 
                                          y = ~n, 
                                          color ="blue", 
                                          type = "scatter", 
                                          mode = "lines") %>%
                                 layout(title = "Frequency Over Time")
                }
              )
  
  output$timelineOutput<-renderPlotly(timelineData())
  
}

# Run the application 
shinyApp(ui = ui, server = server)
