#====================================================================
# This script produces Figures 5 and 6 from the publication
# 
# Heisig, J.; Olson, E.; Pebesma, E. Predicting Wildfire Fuels 
# and Hazard in a Central European Temperate Forest Using Active 
# and Passive Remote Sensing. Fire 2022, 5, 29. 
# https://doi.org/10.3390/fire5010029
#====================================================================

library(patchwork)
library(ggplot2)
library(cowplot)
library(dplyr)
library(tidyr)
library(stars)

## 1. Field sampling data Boxplot -------------------------

s = readxl::read_xlsx(file.path(getwd(),"data","field_sampling_data.xlsx")) |> 
  select(spp, `1hr_lit_sum_bm`, `10hr_bm`, `100hr_bm`, 
         her_l_bm, shr_l_bm, fuelbed_dep) |> 
  rename(Species = spp, 
         `1hr` = `1hr_lit_sum_bm`, 
         `10hr` = `10hr_bm`, 
         `100hr` = `100hr_bm`, 
         "Live Herb" = her_l_bm, 
         "Live Shrub" = shr_l_bm, 
         "Fuelbed Depth" = fuelbed_dep) |> 
  mutate(Species = recode_factor(Species,"Be"="Beech","RO"="Red Oak","Pi"="Pine"),
         Species = factor(Species, levels = c("Beech", "Pine", "Red Oak"))) |> 
  group_by(Species)

# quick table
s  |> 
  summarise(across(everything(), function(x) round(median(x),2))) |> 
  knitr::kable()

# plot
s = s |> 
  pivot_longer(-Species) |> 
  mutate(name = factor(name, c("1hr","10hr","100hr","Live Herb",
                               "Live Shrub","Fuelbed Depth"))) 

facs <- levels(s$name)
boxcol = "chocolate2"
ggplot(s, aes(x=name,y=value,fill=Species, groups=Species)) +
  geom_rect(aes(ymin=0, ymax=3), alpha=0.4,
            xmin=which(facs=="Fuelbed Depth")-0.5, 
            xmax=which(facs=="Fuelbed Depth")+0.5, 
            color=boxcol, fill=NA) +
  geom_boxplot(outlier.alpha = 0.4, notch = T) +
  scale_fill_manual(values=c("gold2", "springgreen4",
                             "palevioletred1"), name="") +
  theme_minimal_hgrid() +
  theme(legend.position = c(0.3,0.8),
        legend.direction = "horizontal", 
        legend.margin = margin(2,2,2,2),
        legend.background = element_rect(color = "black"), 
        axis.text.y.right = element_text(color = boxcol), 
        axis.title.y.right = element_text(color = boxcol), 
        plot.background = element_rect(fill="white") ) +
  labs(x="",y="Fuel Loading [kg/m²]") +
  scale_y_continuous(sec.axis = sec_axis(~ .,name = "Fuelbed Depth [m]")) 

ggsave(file.path(getwd(),"figures","surface_fuel_samples.png"), scale = 1.7, 
       width = 12, height=7, units="cm")  


## 2. Fuel model prediction and AOA ------------------------------

fm = read_stars(file.path(getwd(),"results","haard_surface_fuel_map.tif")) |> 
  setNames("FuelType") |> 
  transmute(FuelType = factor(FuelType, levels = c(1:4), 
                         labels = c("Beech", "Pine", "Red Oak", "NB")))

aoa.fm = read_stars(file.path(getwd(),"results","AOA_haard_surface_fuel_map.tif")) |> 
  setNames("AOA") |> 
  c(fm["FuelType"]) |>  
  mutate(AOA = ifelse(FuelType == "NB", NaN, AOA),
         AOA = factor(AOA, levels = c(0,1,NaN), labels = c("outside", "inside", "NB")))

l.pos = "right"

lay = ggplot() +
  coord_equal() + theme_void() +
  scale_x_discrete(expand=c(0,0)) + 
  scale_y_discrete(expand=c(0,0)) +
  theme(legend.position = l.pos,
        plot.margin = margin(5,5,5,5), 
        plot.tag.position = "left",
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,0,0),
        legend.justification = "left")

p1 = lay + geom_stars(data=fm) +
  scale_fill_manual(values=c("gold2",
                             "springgreen4",
                             "palevioletred1", 
                             "grey80"), 
                    name="Fuel Models") +
  guides(fill=guide_legend(ncol=1))

p2 = lay + geom_stars(data=aoa.fm) +
  scale_fill_manual(values=c("firebrick","lightgreen", "grey80"), name="AOA") +
  guides(fill=guide_legend(ncol=1))

PL = wrap_plots(p1, p2, nrow = 2) + 
  plot_annotation(tag_levels = "A")
PL

ggsave(file.path(getwd(),"figures","surface_fuel_model_prediction.png"), 
       height =20, width = 14.5, units = "cm")
