##################################
# Created by EPI-interactive
# 18 Feb 2020
# https://www.epi-interactive.com
##################################

library(leaflet)
library(rgdal)
library(sp)
library(raster)
library(rgeos)

ui <- fluidPage(titlePanel("Choropleth Grid"),
                sidebarLayout(
                    sidebarPanel(
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
                        )
                    ),
                    mainPanel(leafletOutput("gridMap"))
                ))

server <- function(input, output) {
    #Read in shape file
    shapeData <- readOGR("shapes/Wellington_City_Council_Boundary.shp")
    
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
        shapePoly <- as(shapeRaster, 'SpatialPolygonsDataFrame') 
        
        
        # Clip grid to match the general area of the shapeData
        clip <- shapePoly[shapeData, ]
        
        # use the shapeData boundaries to create a better outline for the grid
        map <- gIntersection(clip,
                          shapeData,
                          byid = TRUE,
                          drop_lower_td = TRUE)
        
        #match data count to grid
        sculptureCount <- aggregate(x = data["FID"],
                                    by = map,
                                    FUN = length)
        
        
        # define color bins
        qpal <- colorBin("YlOrRd",
                     sculptureCount$FID,
                     bins = 5,
                     na.color = "transparent")
        
        labelContent <- paste0(
                sculptureCount$FID,
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
            addProviderTiles("Hydda.Base",
                             options = providerTileOptions(noWrap = TRUE)) %>%
            addPolygons(
                fillColor = ~ qpal(sculptureCount$FID),
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
                title = "Sculpture Count"
            )
    })
}

# Run the application
shinyApp(ui = ui, server = server)
