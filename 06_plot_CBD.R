#==============================================================
# This script produces Figures 7 and 8 from the publication
# 
# Heisig, J.; Olson, E.; Pebesma, E. Predicting Wildfire Fuels 
# and Hazard in a Central European Temperate Forest Using Active 
# and Passive Remote Sensing. Fire 2022, 5, 29. 
# https://doi.org/10.3390/fire5010029
#==============================================================

library(cowplot)
library(patchwork)
library(ggplot2)
library(dplyr)
library(tidyr)
library(stars)

## 1. CBD field data Boxplot ---------------------------------

# join field observations and FuelCalc CBD estimates
y = read.csv(file.path(getwd(),"data","haard_canopy_fuels_field_obs.csv")) |> 
  select(plot_id, DBH, tree_height, base_height) |> 
  group_by(plot_id) |> 
  summarize(across(1:3, median))

x = read.csv(file.path(getwd(),"data","plot_level_CBD.csv")) |> 
  inner_join(y)
x = x |> select(-plot_id, -FC_CC, -FC_CBH, -FC_SH) |> 
  rename("Species" = "dom_spp", "CBD"="FC_CBD",
         "CBH"="base_height","CH"="tree_height") |> 
  pivot_longer(-Species) |> 
  mutate(Species = recode_factor(Species,"Be"="Beech","RO"="Red Oak","Pi"="Pine"),
         Species = factor(Species, levels = c("Beech", "Pine", "Red Oak"))) 

# single plot layout
P = function(d){ 
  ggplot(d, mapping = aes(name, value, fill=Species, groups=Species)) +
  geom_boxplot(outlier.alpha = 0.4) +
  scale_fill_manual(values=c("gold2", "springgreen4", 
                             "palevioletred1"), name="") +
  theme_minimal_hgrid() +
  theme(axis.text.x = element_blank(), 
        strip.text = element_text(face="bold"),
        legend.position = c(0.2, -0.1),
        legend.direction = "vertical",
        legend.margin = margin(2,2,2,2),
        axis.ticks.x = element_blank()) +
  labs(x="",y="") 
}

p0 = x |> filter(name %in% c("CBH")) |> P() +
  scale_y_continuous(limits = c(0,38)) +
  facet_grid(~name, scales = "free", 
             labeller = as_labeller(c(CBH = "CBH [m]")))
p1 = x |> filter(name %in% c("CH")) |> P() +
  scale_y_continuous(limits = c(0,38)) +
   facet_grid(~name, scales = "free", 
              labeller = as_labeller(c( CH = "CH [m]"))) 
p2 = x |> filter(name %in% c("DBH")) |> P() + 
  facet_grid(~name, scales = "free", 
             labeller = as_labeller(c(DBH = "DBH [cm]")))
p3 = x |> filter(name %in% c("CBD")) |> P() + 
  facet_grid(~name, scales = "free", 
             labeller = as_labeller(c(CBD = "CBD [kg/m³]")))

pp = (p0+p1)/(p2+p3)+ #guide_area() + 
  plot_layout(guides = "collect", nrow = 2) +
  plot_annotation(tag_levels = "A")
pp

ggsave(file.path(getwd(),"figures","canopy_fuel_samples.png"),scale = 1.7, 
       width = 9, height=7, units="cm")  


## 2. CBD model prediction ---------------------------------------

cbd = read_stars(file.path(getwd(),"results","haard_CBD.tif"))
AOA = read_stars(file.path(getwd(),"results","AOA_haard_CBD.tif"))
data = c(cbd, AOA) |> setNames(c("cbd","aoa")) |> 
mutate(aoa = ifelse(is.na(cbd), 99, aoa) |> 
         factor(levels = c(1,0,99),
                labels = c("inside","outside","NB")))

l.pos = "right"
lay = ggplot() +
  coord_equal() + theme_void() +
  scale_x_discrete(expand=c(0,0)) + 
  scale_y_discrete(expand=c(0,0)) +
  theme(legend.position = l.pos,
        plot.margin = margin(5,5,5,5), 
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,0,0),
        legend.justification = "left",
        plot.tag.position = "left")

pcbd = lay + geom_stars(data = cbd, downsample = 1) +
  scale_fill_viridis_c(direction = -1, name="CBD", na.value = "grey80") 

paoa = lay + geom_stars(data = data["aoa"], downsample = 1) +
  scale_fill_manual(values=c("lightgreen","firebrick", "grey80"), name="AOA")

P = pcbd / paoa + plot_annotation(tag_levels = "A")
P

ggsave(file.path(getwd(),"figures","CBD_and_AOA_vertical.png"), 
                 width = 14.5, height = 20, units = "cm")
