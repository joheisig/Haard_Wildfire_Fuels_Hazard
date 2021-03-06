Forest structure predictor variables from LiDAR point clouds
================
Johannes Heisig

LiDAR data forms the basis for various forest structure regression
models as the vertical distribution of laser returns describes tree
characteristics well. Here we use open LiDAR data provided by and for
the German state of Northrhine-Westfalia in
([description](https://www.bezreg-koeln.nrw.de/brk_internet/geobasis/hoehenmodelle/3d-messdaten/index.html),
[download](https://www.opengeodata.nrw.de/produkte/geobasis/hm/3dm_l_las/))
to compute 74 metrics related to tree height, cover, and terrain at 10
meter resolution. Computation is facilitated by the `lidR` package. See
the publication for more details. Data comes in 1x1 km tiles and in .laz
format. Our study used 90 tiles covering the study area. This demo for
reproducibility reasons, however, only uses 1 tile to limit
computational costs. If desired one can process all 90 tiles, which are
listed in *data/relevant_laz_files_Haard.txt*, by following instructions
in the Download sections. We recommend to run it on a local machine.

## Download

``` r
dir = "data/lidar/"
if (! dir.exists(file.path(dir, "download"))){ 
  dir.create(file.path(dir, "download"), recursive = T)
}

URL <- "https://www.opengeodata.nrw.de/produkte/geobasis/hm/3dm_l_las/3dm_l_las/"
relevant <- readLines("data/relevant_laz_files_Haard.txt") # 90 tiles

# The line below reduces the number of tiles to 1
# which results in a ~195 mb download. 
# Remove it to download all 90 tiles covering the Haard.
relevant = relevant[30]

links = paste0(URL, relevant)
files <- paste0(dir,"download/", relevant)

for (i in 1:length(links)) {
  if (! file.exists(files[i])){
    message(paste0(i, "....."))
    download.file(links[i], files[i])
}}
```

## Setup

``` r
dirs = paste0(dir, 
              c('01_normalized', '02_height_metrics', 
                '03_chm', '04_cover_metrics', 
                '05_density_metrics', '06_rumple', '07_dem'))
for (i in dirs) if (! dir.exists(i)) dir.create(i)

library(lidR)
library(future)
library(dplyr)
library(terra)
source("02_lidar_metrics.R") # contains definitions of metrics to compute

RES = 10  # output raster resolution
ncores = 4  # number of cores for parallel processing
plan(multisession, workers = ncores, gc=T) # starts parallel session

# read raw LiDAR tiles as catalog
ctg_raw <- readLAScatalog(files)
plot(ctg_raw, map=T)
```

## 1. Normalize heights

``` r
# processing options
opt_chunk_size(ctg_raw) <- 500
opt_chunk_buffer(ctg_raw) <- 10
opt_select(ctg_raw) <- "xyz"
opt_laz_compression(ctg_raw) <- TRUE
plot(ctg_raw, chunk = TRUE)
opt_output_files(ctg_raw) <-"data/lidar/01_normalized/znorm_{ID}_{XCENTER}_{YCENTER}"

ctg_raw = normalize_height(ctg_raw, tin(), overwrite=T)
```

## 2. Height metrics

``` r
# read again to use normalized point cloud
ctg <- readLAScatalog(file.path(dir,"01_normalized/"))
opt_chunk_size(ctg) <- 500
opt_chunk_buffer(ctg) <- 10
opt_select(ctg) <- "xyzcr"
plot(ctg, chunk = TRUE)
opt_output_files(ctg) <-"data/lidar/02_height_metrics/height_metrics_{ID}_{XCENTER}_{YCENTER}"
ctg@output_options$drivers$Raster$param$overwrite = T
ctg@output_options$drivers$Raster$param$format = "raster"
ctg@output_options$drivers$Raster$extension = ".grd"
summary(ctg)

h = grid_metrics(ctg, .lidar_height_metrics, RES) 
```

## 3. Canopy Height Model

``` r
opt_output_files(ctg) <- "data/lidar/03_chm/chm_{ID}_{XCENTER}_{YCENTER}"

chm = grid_canopy(ctg, RES, pitfree(thresholds = c(0,10,20), subcircle = 0.2)) 
```

## 4. Cover metrics

``` r
opt_output_files(ctg) <- "data/lidar/04_cover_metrics/cover_metrics_{ID}_{XCENTER}_{YCENTER}"

cov = grid_metrics(ctg, .lidar_cover_metrics, RES)
```

## 5. Rumple index

``` r
opt_output_files(ctg) <-"data/lidar/06_rumple/rumple_{ID}_{XCENTER}_{YCENTER}"

rumple = grid_metrics(ctg, .rumple_index, RES)
```

## 6. Density metrics

``` r
opt_output_files(ctg) <- "data/lidar/05_density_metrics/density_metrics_{ID}_{XCENTER}_{YCENTER}"

d = grid_metrics(ctg, .lidar_density_metrics, RES)
```

## 7. DEM

``` r
# DEM calculations require raw (non-normalized) points
opt_output_files(ctg_raw) <- ""
dem = grid_terrain(ctg_raw, res=RES, algorithm = tin())
names(dem) = "dem"
writeRaster(dem, "data/lidar/07_dem/07_dem_10m.grd", overwrite=T)
```

## 8. Merge raster tiles

``` r
outdir = "data/lidar/08_merged_results"
if (! dir.exists(outdir)) dir.create(outdir)

for (d in dirs[c(2:6)]){
  tiles = lapply(list.files(d, pattern = ".grd$", full.names = T), terra::rast)
  big = do.call(terra::merge, tiles)
  names(big) = names(tiles[[1]])
  if (d == dirs[6]) names(big) = "rumple"
  outname = file.path(outdir, 
                      paste0(basename(d), "_", RES, "m.grd"))
  terra::writeRaster(big, outname, overwrite = T)
  print(outname)
}

writeRaster(dem, "data/lidar/08_merged_results/07_dem_10m.grd", overwrite=T)
```

## 9. Terrain metrics

``` r
out = file.path(outdir, paste0("terrain_", RES, "m.grd"))
terrain(dem, opt = c("slope", "aspect"), unit = "degrees",
          filename = out, format = "raster", overwrite=T)
```

## 10. Merge all results

``` r
result_out = "LiDAR_predictor_metrics_10m.grd"

if (file.exists(file.path(outdir, result_out))){
  unlink(list.files(outdir, substr(result_out, 1, nchar(result_out)-4),
                    full.names = T))
  print("Existing results were deleted.")
}
  
list.files(outdir, pattern = ".grd$", full.names = T) |> 
    terra::rast() |> 
    terra::writeRaster(file.path(outdir, result_out), overwrite=T)
```
