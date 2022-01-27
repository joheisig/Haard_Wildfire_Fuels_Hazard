library(tidyverse)
library(stars)
library(sf)
library(mapview)
library(tmap)

# weather station
st_point(c(7.1998, 51.7335)) |> 
  st_sfc(crs = 4326) |>  
  st_as_sf()  |> 
  mutate(plot_id = 999, dom_spp = "", geometry = x) |> 
  select(plot_id, dom_spp, geometry) -> station
st_geometry(station) = "geometry"
station = select(station, -x)

# all field plots
all.plots = st_read("data/haard_field_plot_locations.csv", crs=4326,
                options=c("X_POSSIBLE_NAMES=lon","Y_POSSIBLE_NAMES=lat")) |>
  mutate(plot_id = as.numeric(plot_id)) |> 
  select(plot_id, dom_spp) |> 
  rbind(station)
all.plots$type = factor(all.plots$type, levels = c("S. Fuels", "S. & C. Fuels", "Weather Station"))

# CBD field plots
cbd.plots = read.csv("data/haard_canopy_FuelCalc_output.csv")[-1,] |> 
  mutate(plot_id = sub(x=PlotID, "-Inventory", "") |> as.numeric()) |> 
  select(plot_id) |> 
  drop_na()

cbd.plots = inner_join(cbd.plots, all.plots, by ="plot_id") |> st_as_sf()


all.plots$type = "S. Fuels"
all.plots$type[all.plots$plot_id %in% cbd.plots$plot_id] = "S. & C. Fuels"
all.plots$type[nrow(all.plots)] = "Weather Station"
all.plots = all.plots[order(all.plots$type, decreasing = T),]
mapview(all.plots, zcol="type") 

# landscape
lcc = readRDS("results/landscape.rds") |> 
  select(LCC) |> 
  mutate(LCC = case_when(LCC == "Agri" ~ "Agriculture",
                         TRUE ~ as.character(LCC)) |> as.factor() )

lc.pal = c("#F2D588", "#BFB19F", "#A6EC83", "#6A8666", "#98A14F", "#D573C5", "#5BA8F3")
(map = 
  tm_shape(lcc) + 
  tm_raster(title = "Land Cover", palette = lc.pal, legend.is.portrait = T) +
  tm_shape(all.plots) +
  tm_symbols(col = "type", border.col = "white", title.col = "Field Plot Type",
             palette = c("red","black",  "blue"), size = 0.2, alpha=0.9, 
             shape = "type", shapes = 23, legend.shape.show = F) +
  tm_layout(legend.outside=F, legend.text.size = 0.7,
            legend.title.size=0.7, asp = 1.1,
            legend.frame=TRUE, legend.position=c(0.99, 0.01),
            legend.just = c("right", "bottom"), legend.width=-0.2,
            legend.height=-0.6, outer.margins = c(0,0,0,0),
            inner.margins = c(0,0,0,0), #legend.stack = "ver",
            fontfamily = "Palatino") +
  tm_compass(position = c("RIGHT","top"), text.size = 0.7) +
  tm_graticules(labels.inside.frame =T, n.x=5, n.y=3) +
  tm_scale_bar(position = c("LEFT","BOTTOM"), text.size = 0.7, breaks = c(0,1,2))
)

# saveRDS(map, "figures/overview_map.rds")
# pdf("figures/overview_map.pdf", height = 4, width = 4 *1.1); map; dev.off()


# true color base map ---------------------------
ger = giscoR::gisco_countries |> filter(CNTR_NAME == "Deutschland") 
bdl = giscoR::gisco_get_nuts(country = "Deutschland", nuts_level = "1")
inset = 
  tm_shape(bdl) +
  tm_polygons(border.col = "grey40", col = "white", lwd=0.4) +
  tm_shape(ger) +
  tm_borders(col = "black") +
  tm_shape(station) +
  tm_dots(col="red",size=0.16) +
  tm_layout(bg.color = "transparent", frame = F)


region = st_bbox(lcc) |> st_as_sfc() |>  st_buffer(-400) |> st_bbox()
tc = maptiles::get_tiles(region, "Esri.WorldImagery", zoom = 13, crop=F) |> 
  terra::project("epsg:4326")
#tc = terra::crop(tc, terra::ext(372010, 381990, 5724010, 5732990))
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
              inner.margins = c(0,0,0,0),
              # fontfamily = "Palatino"
    ) +
    tm_compass(position = c("LEFT","top"), text.size = 0.7, size = 2) +
    #  tm_graticules(labels.inside.frame = F, labels.rot = c(0,90),
    #                x=c(7.15,7.20,7.25), y = c(51.675, 51.7, 51.725)) +
    tm_scale_bar(position = c("left","BOTTOM"), text.size = 0.7, 
                 breaks = c(0,1,2))
  
) 


w <- 0.3
h <- 0.8 * w
vp <- grid::viewport(x=0.999, y=0.035, width = w, height=h, just=c("right", "bottom"))

tmap_save(map, "figures/tmap_inset.png", 
          insets_tm=inset, insets_vp=vp,
          height=91, width=91, units="mm")
  
  
####################################################
# test map stratified by spp

tm_shape(tc) +
  tm_rgb() + 
  tm_shape(all.plots[all.plots$type =="S. & C. Fuels",]) +
  tm_symbols(col = "dom_spp", size = 0.2, alpha=0.7, shape = 0,
             legend.shape.show = F, legend.col.show = F) +
  tm_shape(all.plots[all.plots$type ==  "S. Fuels",]) +
  tm_symbols(col="dom_spp", size = 0.12, alpha = 0.8, shape = 1,palette="-RdYlBu") +
  tm_shape(all.plots[all.plots$type == "Weather Station",]) +
  tm_symbols(col="blue", size = 0.4, shape = 17)

####################################################
library(ggplot2)
library(RStoolbox)
tcs = raster::stack(tc)

ggRGB(tcs, limits = matrix(c(10,225,0,251,60,249),ncol=2,by=T)) +
  coord_equal() +
  theme_void() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) 


data(rlogo)
ggRGB(rlogo, r=1, g=2, b=3)
## Define minMax ranges
ggRGB(rlogo, r=1,g=2, b=3, limits = matrix(c(0,250,10,250,10,255),  ncol = 2, by = TRUE))
## Perform stong linear contrast stretch
ggRGB(rlogo, r = 1, g = 2, b = 3,stretch = "lin", quantiles = c(0.2, 0.8))

###########################

t = maptiles::get_tiles(st_bbox(mapview::breweries), "Esri.WorldImagery", zoom = 10, crop=T)


m = tm_shape(t) +
  tm_rgb() +
  tm_shape(mapview::breweries) +
  tm_symbols(col = "founded",  size = "number.of.types",
             palette = c("red","black", "blue"), alpha=0.9, 
             legend.size.show = F
  ) +
  tm_layout(legend.frame = T, legend.height = -0.3, legend.width = 0.2,
            legend.text.size = 0.3)


tmap_save("figures/tmap.png")



