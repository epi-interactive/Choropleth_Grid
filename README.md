# Choropleth Grid

Choropleth grids can be a useful customisation from standard choropleth maps which display counts for each area. The grid allows us to  group cases with similar values (such as case counts) together.

The visualisation requires two sets of data:
- The shape file which describes the area boundaries
- The data, with coordinates, which you like to display

Combining these two dataset, we can create a map like the one below:
![Choropleth Grid](https://github.com/epi-interactive/choropleth_grid/blob/master/choropleth_image.PNG)

Demo can be found [here](https://shiny.epi-interactive.com/apps/choropleth_grid/)

# How it works
- Load in the shape file using readOGR from the rgdal package, this creates a SpatialPolygonsDataFrame 
- Load in the data, using whichever read method is appropriate - here I've used read.csv
- The coordinates from the data are also turned into a SpatialPointsDataFrame and projected to be the same as the shape file
    ``` r
    xy <- data.frame(lon = data$X, lat = data$Y)
    data <- SpatialPointsDataFrame(
        coords = xy,
        data = data,
        proj4string = CRS(proj4string(shapeData))
    )
    ```
- Create the grid itself, using the raster package 
	- extent allows us to create a bounding box around our shapes
	    ``` r 
        shapeExtent <- extent(bbox(shapeData)) 
         ```
	- raster creates a grid from the bounding box. This is also where we specify the number of cells, in this example we are using the slider values
	    ``` r 
        shapeRaster <- raster(shapeExtent, ncol=input$ySlider, nrow=input$xSlider) 
        ```
	- the grid should then be projected to fit the shape and converted into a polygon
	    ``` r 
        projection(shapeRaster) <- CRS(proj4string(shapeData))
        shapePoly <- as(shapeRaster, 'SpatialPolygonsDataFrame') 
        ```
- Clip the grid to match the general area of the shapeData
    ``` r 
    clip <- shapePoly[shapeData, ]
    ```
- Finer borders on the grid are created by finding the intersection of the shape and the grid
    ``` r 
    map <- gIntersection(clip, shapeData, byid = TRUE, drop_lower_td = TRUE) 
    ```
- The grid is then coloured using the aggregate function, using one of the data's column aggregated by the trimmed grid. 
    ``` r 
     sculptureCount <- aggregate(x = data["FID"], by = map, FUN = length)
    ```
- Finally we can render the map and style it as desired
 
# Sources
- [Sculpture Dataset](https://data-wcc.opendata.arcgis.com/datasets/wellington-city-sculptures)
- [Wellington Shape File](https://data-wcc.opendata.arcgis.com/datasets/wellington-city-council-boundary)
- [Code Credit](https://hautahi.com/rmaps)
