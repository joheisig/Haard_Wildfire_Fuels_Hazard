## Wildfire Fuels and Hazard predction in the Haard forest

This repository contains code and data to reproduce the analysis described in

> Heisig, J., Olson, E., Pebesma, E. (2022): Predicting Wildfire Fuels and Hazard in a Central European Temperate Forest Using Active and Passive Remote Sensing. Fire. xxx. doi/xxx. link.

The workflow includes the following steps:

1. Process satellite-based predictor data (Google Earth Engine)
2. Process LiDAR-based predictor data including canopy fuel variables (R)
3. Predict surface fuel types (R)
4. Predict Crown Bulk Density (R)
5. Run fire behavior and spread model to derive fire hazard (FlamMap)

All individual steps are reproducible and described in more detail below.

### 1. Process satellite-based predictor data

Sentinel-1 & -2 data for 2019 was collected and processed using Google Earth Engine. We produced temporal composites of the 10th, 50th, and 90th percentile, thereby catching intra-annual changes in vegetation reflectance and backscatter. Follow [this link](https://code.earthengine.google.com/5458224e8dc2182e7fecf6bb9398444e) to run the process. (An active Earth Engine user account is required. Sign-up is free of charge.)
Alternatively, you may skip this entire step and download the complete predictor data for this study [here](). **Zenodo-link**

### 2. Process LiDAR-based predictor data including canopy fuel variables


Alternatively, you may skip this entire step and download the complete predictor data for this study [here](). **Zenodo-link**

### 3. Predict surface fuel types

Field sampling produced three custom fire behavior fuel models, each representing one dominant species (pine, red oak, and beech). To connect fuel models and their spatial distribution we classify these species using a Random Forest model and a range of LiDAR- and satellite-based predictor variables.
You can view code and outputs [here on Github](R/01_spatial_prediction_surface_fuel_models.md) or run the analysis on Binder.

### 4. Predict Crown Bulk Density

You can follow code and outputs [here](R/02_spatial_prediction_crown_bulk_density.md)

### 5. Run fire behavior and spread model to derive fire hazard 

The four previous steps had the purpose of preparing variables relevant to fire behavior and spread in the study area. They can be combined to form the 'fire landscape', represented by a 8-layer raster stack including:

- surface fuel map
- canopy fuel metrics (height, base height, cover, bulk density)
- terrain (elevation, slope, aspect)

Fire modeling is executed in [FlamMap](https://www.firelab.org/project/flammap) which is free to [download](https://www.firelab.org/media/709) from the Missoula Fire Sciences Laboratory website (Note: FlamMap only runs on 64-bit Microsoft Windows OS).

Reproducing fire behavior calculations in FlamMap's GUI requires more interaction than the scripts used in previous steps. 

Step-by-step-guide:






