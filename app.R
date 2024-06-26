##################################
# Created by EPI-interactive
# 18 Feb 2020
# https://www.epi-interactive.com
##################################

library(leaflet)
library(sp)
library(raster)
library(shiny)
library(sf)

ui <- fluidPage(
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/style.css")
    ),
    div(class="col-xs-3 sidebar",
        div(fluidRow(h1("Choropleth Grid")),
        hr(),
        sliderInput(
            "xSlider",
            "Horizontal Grid Count",
            min = 10,
            max = 70,
            value = 50
        ),
        sliderInput(
            "ySlider",
            "Vertical Grid Count",
            min = 10,
            max = 70,
            value = 50
        )),
        tags$img(src="images/Epi_Logo.png", width= "90%")
    ),
    div(class="col-xs-9 main",
        leafletOutput("gridMap", height = "65%", width = "75%")
    )
)

server <- function(input, output) {
    #Read in shape file
    shapeData_raw <- st_read("shapes/Wellington_City_Council_Boundary.shp")  
    shapeData <- sf::as_Spatial(shapeData_raw)
    
    #Read in data
    data <- read.csv("data/Wellington_City_Sculptures.csv", stringsAsFactors = F)
    
    # From the data, create coordinates and project them the same as the shape file
    xy <- data.frame(lon = data$X, lat = data$Y)
    data <- SpatialPointsDataFrame(
        coords = xy,
        data = data,
        proj4string = CRS(proj4string(shapeData))
    )
    
    
    output$gridMap <- renderLeaflet({
        # define boundaries of object
        shapeExtent <- extent(bbox(shapeData))                   
        # create the grid itself, within extent boundaries
        shapeRaster <- raster(shapeExtent, ncol=input$ySlider, nrow=input$xSlider)
        # give it the same projection as shapeData
        projection(shapeRaster) <- CRS(proj4string(shapeData))
        # convert into polygon
        shapePoly <- rasterToPolygons(shapeRaster)

        # Clip grid to match the general area of the shapeData
        clip <- crop(shapePoly, shapeData)
        
        # use the shapeData boundaries to create a better outline for the grid
        map <- raster::intersect(clip, shapeData)
        
        #match data count to grid
        sculptureCount <- aggregate(x = data["FID"],
                                    by = map,
                                    FUN = length)
        
        # define color bins
        qpal <- colorBin("YlOrRd",
                     sculptureCount$FID,
                     bins = 6,
                     na.color = "#f0f0f0",
                     right = T)
        
        labelContent <- paste0(
                ifelse(!is.na(sculptureCount$FID), sculptureCount$FID, "No"),
                ifelse(
                    sculptureCount$FID == 1 &
                        !is.na(sculptureCount$FID),
                    " Sculpture",
                    " Sculptures"
                )
            )
        
        # Render the map
        leaflet(sculptureCount,
                options = leafletOptions(minZoom = 11)) %>%
            addTiles() %>%
            addPolygons(
                fillColor = ~qpal(sculptureCount$FID),
                weight = 1,
                color = "white",
                fillOpacity = 0.8,
                label = labelContent,
                highlight = highlightOptions(
                    weight = 1,
                    color = "black",
                    bringToFront = TRUE,
                    fillOpacity = 1
                )
            ) %>%
            addLegend(
                values =  ~ sculptureCount$FID,
                pal = qpal,
                na.label = "0",
                labFormat = function(type, cuts) {
                    #remove overlapping labels
                    sapply(2:length(cuts), function(i){
                       paste(cuts[i-1]+1, "-", cuts[i])
                    })
                },
                title = "Sculpture Count"
            )
    })
}

# Run the application
shinyApp(ui = ui, server = server)
