## Wildfire Fuels and Hazard predction in the Haard forest

This repository contains code and data to reproduce the analysis described in the paper below. It was published in *Fire* on 20 February 2022 and is Open Access.

> Heisig, J.; Olson, E.; Pebesma, E. Predicting Wildfire Fuels and Hazard in a Central European Temperate Forest Using Active and Passive Remote Sensing. Fire 2022, 5, 29. [https://doi.org/10.3390/fire5010029](https://doi.org/10.3390/fire5010029)


The workflow of our fire hazard analysis includes the following steps:

1. Process satellite-based predictor data <img src="https://image.pngaaa.com/772/546772-middle.png" title="GEE" width="35"/>
2. Process LiDAR-based predictor data including canopy fuel variables <img src="https://www.clipartmax.com/png/middle/13-137348_logo-r-programming.png" alt="drawing" title="R" width="25"/>
3. Predict surface fuel types <img src="https://www.clipartmax.com/png/middle/13-137348_logo-r-programming.png" alt="drawing" title="R" width="25"/>
4. Predict Crown Bulk Density <img src="https://www.clipartmax.com/png/middle/13-137348_logo-r-programming.png" alt="drawing" title="R" width="25"/>
5. Run fire behavior and spread model to derive fire hazard :fire: :globe_with_meridians:
6. Plot figures from the publication <img src="https://www.clipartmax.com/png/middle/13-137348_logo-r-programming.png" alt="drawing" title="R" width="25"/>

All steps are individually reproducible and described in more detail below.

### 1. Process satellite-based predictor data

Sentinel-1 & -2 data for 2019 was collected and processed using Google Earth Engine. We produced temporal composites of the 10th, 50th, and 90th percentile, thereby catching intra-annual changes in vegetation reflectance and backscatter. Follow [**this link**](https://code.earthengine.google.com/5458224e8dc2182e7fecf6bb9398444e) to run the process (~10 seconds). (An active Earth Engine user account is required. Sign-up is free of charge.)
Alternatively, you may skip this entire step and download the complete predictor data for this study using the link in step 2.

### 2. Process LiDAR-based predictor data including canopy fuel variables

We use open LiDAR data to calculate forest structure and terrain variables. 
You can view to code [here on Github](02_LiDAR_processing.md) or run the process yourself. If you choose to run it we advise you to do so on a local machine by downloading this repository. Be prepared that this may take several hours depending on your hardware. Run¹ `install.R` before starting `02_LiDAR_processing.Rmd`. Alternatively, you may skip this entire step and download the [**complete predictor data**](https://uni-muenster.sciebo.de/s/XPEk2uBClq2v3ob) for this study.

### 3. Predict surface fuel types

Field sampling produced three custom fire behavior fuel models, each representing one dominant species (pine, red oak, and beech). To connect fuel models and their spatial distribution we classify these species using a Random Forest model and a range of LiDAR- and satellite-based predictor variables.
You can view code and outputs of `03_spatial_prediction_surface_fuel_models.Rmd` [here on Github](03_spatial_prediction_surface_fuel_models.md) or [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/joheisig/Haard_Wildfire_Fuels_Hazard/main?urlpath=rstudio) to run¹ the analysis interactively in your browser (~10 seconds).

### 4. Predict Crown Bulk Density (CBD)

CBD is relevant for crown fire spread calculation but other than the remaining canopy fuel variables it is difficult to measure in the field. We use allometric equations to estimate CBD from field measurements of other forest structure variables. This data serves as reference for a Ridge regression model. Again, modeling is supported by LiDAR- and satellite-based predictor variables. 
You can view code and outputs of `04_spatial_prediction_crown_bulk_density.Rmd` [here on Github](04_spatial_prediction_crown_bulk_density.md) or [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/joheisig/Haard_Wildfire_Fuels_Hazard/main?urlpath=rstudio) to run¹ the analysis interactively in your browser (~10 seconds). Make sure to click *Session > Clear Workspace* and *Session > Restart R* before you run¹ the analysis to prevent errors from artifacts of the last step.

### 5. Run fire behavior and spread model

The four previous steps had the purpose of preparing variables relevant to fire behavior and spread in the study area. They can be combined to form the 'fire landscape', represented by a 8-layer raster stack including:

- surface fuel map
- canopy fuel metrics (height, base height, cover, bulk density)
- terrain (elevation, slope, aspect)

Fire modeling is executed in [**FlamMap**](https://www.firelab.org/project/flammap) which is free to [download](https://www.firelab.org/media/709) from the Missoula Fire Sciences Laboratory website (Note: FlamMap only runs on 64-bit Microsoft Windows OS).

Reproducing fire behavior calculations in FlamMap's GUI requires more interaction than the scripts used in previous steps. 

Step-by-step-guide:

- 5.1. Install FlamMap following instructions provided by the links above.
- 5.2. If you have not already downloaded this repository, do so now. All relevant files are located in the directory ***FlamMap_files***.
- 5.3. Open FlamMap. 
- 5.4. Click ***Landscape > Open Landscape*** and select the file ***Haard_FlamMap_landscape.lcp***.
- 5.5. Click ***Analysis Area > Import Run*** and select ***Run Logs > run_log_S1.txt***.
- 5.6. Open the run in the navigation tree on the left and give it sensible name (e.g. S1).
- 5.7. Activate ***Use Custom Fuels*** and select ***Fuels > custom_fuels_haard.fmd***.
- 5.8. Choose ***Winds > Gridded Wind Files***. Select appropriate wind direction and wind speed files in the ***Wind*** directory depending on the scenario you selected in step 5.
- 5.9. All other options are defined by the log file. Switch to tab **Fire Behavior Options** and click ***Launch Basic FB***. Outputs will appear in navigation tree and in the map pane.
- 5.10. Switch to tab **Minimum Travel Time**, click ***Ignitions > Fire Size List File*** and select ***FireSizeList10000.csv***.
- 5.11. Click ***Barriers > Barriers File*** and select ***Barriers > roads.shp***.
- 5.12. Click ***Launch MTT*** to start simulations of fire spread. 
- 5.13. Repeat steps 5.5 through 5.12 for each scenario you want to reproduce.

## 6. Plot figures from the publication

All figures in our paper can be reproduced (even without running analysis steps 1-5). Plotting routines are divided into several scripts following this naming convention: `06_*.R`. They can be executed¹ interactively via [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/joheisig/Haard_Wildfire_Fuels_Hazard/main?urlpath=rstudio) or on your local machine (<1 minute´). Data displayed in plots includes

- `06_overview_map.R`: study area overview and field sampling locations (Fig. 1)
- `06_plot_surface_fuels.R`: surface fuels field data and spatial prediction (Fig. 5 & 6)
- `06_plot_CBD.R`: CBD field data and spatial prediction (Fig. 7 & 8)
- `06_plot_wind_speed_direction.R`: wind station data (Fig. 2)
- `06_plot_fire_behavior_hazard.R`: WindNinja outputs, fire behavior, conditional burn probability, and fire hazard (Fig. 3, 9, 10, 11)

Outputs in PNG format can be found in the [`figures`](figures) directory.

Feel free to contact `jheisig@uni-muenster.de` for questions or feedback!


---

1 *To execute R code in RStudio, open an `.R` or an `.Rmd` file. For `.R` files you may run code line by line using `Ctrl + Enter` or highlight the entire script and press `Run` to execute it. `.Rmd` files you can either `Knit` to receive a single document containing code and outputs or run single code chunks by pressing the green triangle at top right of each chunk.*
