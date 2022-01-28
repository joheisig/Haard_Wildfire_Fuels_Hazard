library(dplyr)
library(stars)
library(sf)
library(tmap)
library(giscoR)

# weather station
st_point(c(7.1998, 51.7335)) |> 
  st_sfc(crs = 4326) |>  
  st_as_sf()  |> 
  mutate(plot_id = 999, dom_spp = "", geometry = x) |> 
  select(plot_id, dom_spp, geometry) -> station
st_geometry(station) = "geometry"
station = select(station, -x)

# all field plots
all.plots = st_read(file.path(getwd(),"data","haard_field_plot_locations.csv"),
                    crs=4326,
                    options=c("X_POSSIBLE_NAMES=lon","Y_POSSIBLE_NAMES=lat")) |>
  mutate(plot_id = as.numeric(plot_id)) |> 
  select(plot_id, dom_spp) |> 
  rbind(station)

# CBD field plots
cbd.plots = read.csv(file.path(getwd(),"data","haard_cbd_fuelcalc.csv"))[-1,] |> 
  mutate(plot_id = sub(x=PlotID, "-Inventory", "") |> as.numeric()) |> 
  select(plot_id) |> 
  tidyr::drop_na()

cbd.plots = inner_join(cbd.plots, all.plots, by ="plot_id") |> st_as_sf()

all.plots$type = "S. Fuels"
all.plots$type[all.plots$plot_id %in% cbd.plots$plot_id] = "S. & C. Fuels"
all.plots$type[nrow(all.plots)] = "Weather Station"
all.plots = all.plots[order(all.plots$type, decreasing = T),]
plot(all.plots["type"]) 

# landscape 
lcc = read_stars(file.path(getwd(),"results","haard_surface_fuel_map.tif"))

# administrative boundaries
ger = giscoR::gisco_countries |> filter(CNTR_NAME == "Deutschland") 
bdl = giscoR::gisco_get_nuts(country = "Deutschland", nuts_level = "1")

# inset map
inset = 
  tm_shape(bdl) +
  tm_polygons(border.col = "grey40", col = "white", lwd=0.4) +
  tm_shape(ger) +
  tm_borders(col = "black") +
  tm_shape(station) +
  tm_dots(col="red",size=0.16) +
  tm_layout(bg.color = "transparent", frame = F)

# true color base map
region = st_bbox(lcc) |> st_as_sfc() |>  st_buffer(-400) |> st_bbox()
tc = maptiles::get_tiles(region, "Esri.WorldImagery", zoom = 13, crop=F) |> 
  terra::project("epsg:4326")

# plot
tmap_mode("plot")
(map = 
   tm_shape(tc) +
    tm_rgb() + 
  tm_shape(all.plots[all.plots$type =="S. & C. Fuels",]) +
   tm_symbols(col = "red", size = 0.2, alpha=0.7, shape = 0,
              legend.shape.show = F, legend.col.show = F) +
    tm_shape(all.plots[all.plots$type ==  "S. Fuels",]) +
    tm_symbols(col="goldenrod2", size = 0.12, alpha = 0.8, shape = 1) +
    tm_shape(all.plots[all.plots$type == "Weather Station",]) +
    tm_symbols(col="blue", size = 0.4, shape = 17) +
    tm_add_legend(type = "symbol", labels = c("Surface only", "Surface & canopy", "Weather station"),
                  col = c("goldenrod2","red","blue"), shape = c(1,0,17), title = "Field plot type",
                  is.portrait = T) +
    tm_layout(legend.outside = F, 
              legend.text.size = 1,
              legend.frame = TRUE,
              #legend.just = "right",
              legend.position = c(0.60, 0.77), #c("right","top"),
              legend.width = 0.37,
              legend.height = 0.2,
              outer.margins = c(.02,.02,.02,.02),
              inner.margins = c(0,0,0,0)) +
    tm_compass(position = c("LEFT","top"), text.size = 0.7, size = 2) +
    tm_scale_bar(position = c("left","BOTTOM"), text.size = 0.7, 
                 breaks = c(0,1,2))
) 

# assemble
w <- 0.3
h <- 0.8 * w
vp <- grid::viewport(x=0.999, y=0.035, width = w, height=h, just=c("right", "bottom"))

tmap_save(map, file.path(getwd(),"figures","overview_map.png"), 
          insets_tm=inset, insets_vp=vp,
          height=91, width=91, units="mm")
  
