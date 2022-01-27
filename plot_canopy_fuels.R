library(tidybayes)
library(patchwork)
library(ggpattern)
library(dplyr)
library(tidyr)

y = read.csv("data/haard_canopy_fuels_field_obs.csv") |> 
  select(plot_id, DBH, tree_height, base_height) |> 
  group_by(plot_id) |> 
  summarize(across(1:3, median))

x = read.csv("results/plot_level_CBD.csv") |> 
  inner_join(y)
x = x |> select(-plot_id, -FC_CC, -FC_CBH, -FC_SH) |> 
  rename("Species" = "dom_spp", "CBD"="FC_CBD",
         "CBH"="base_height","CH"="tree_height") |> 
  pivot_longer(-Species) |> 
  mutate(Species = recode_factor(Species,"Be"="Beech","RO"="Red Oak","Pi"="Pine"),
         Species = factor(Species, levels = c("Beech", "Pine", "Red Oak")),
         #name = factor(name, levels = c("CH","CBH","DBH","CBD"))
         ) 
  
# 
P =function(d){ 
  ggplot(d, mapping = aes(name, value, fill=Species, groups=Species)) +
  geom_boxplot(outlier.alpha = 0.4) +
  #geom_jitter(width=0.2, alpha=0.4) +
  # facet_wrap(~name, scales = "free",
  #            labeller = as_labeller(c(CBD = "CBD [kg/m²]", CBH = "CBH [m]",
  #                                      CH = "CH [m]", DBH = "DBH [cm]"))) +
  #scale_fill_viridis_d(begin = 0.2) +
  scale_fill_manual(values=c("gold2", "springgreen4", "palevioletred1"), name="") +
  theme_minimal_hgrid() +
  theme(axis.text.x = element_blank(), 
        strip.text = element_text(face="bold"),
        legend.position = c(0.2, -0.1),
        legend.direction = "vertical",
        legend.margin = margin(2,2,2,2),
        axis.ticks.x = element_blank(),
        #plot.margin = margin(10,10,50,0,unit = "pt")
        #legend.background = element_rect(color = "black")
        ) +
  labs(x="",y="") 
}
p0 = x |> filter(name %in% c("CBH")) |> P() +
  scale_y_continuous(limits = c(0,38)) +
  facet_grid(~name, scales = "free", 
             labeller = as_labeller(c(CBH = "CBH [m]")))
p0                                    
                                      
p1 = x |> filter(name %in% c("CH")) |> P() +
  scale_y_continuous(limits = c(0,38)) +
   facet_grid(~name, scales = "free", 
              labeller = as_labeller(c( CH = "CH [m]"))) 
p1
p2 = x |> filter(name %in% c("DBH")) |> P() + 
  facet_grid(~name, scales = "free", 
             labeller = as_labeller(c(DBH = "DBH [cm]")))
p2
p3 = x |> filter(name %in% c("CBD")) |> P() + 
  facet_grid(~name, scales = "free", 
             labeller = as_labeller(c(CBD = "CBD [kg/m³]")))
p3


pp = (p0+p1)/(p2+p3)+ #guide_area() + 
  plot_layout(guides = "collect", nrow = 2) +
  plot_annotation(tag_levels = "A")
pp

ggsave("figures/canopy_fuel_samples.png",scale = 1.7, width = 9, height=7, units="cm")  
saveRDS(pp, "figures/canopy_fuel_samples.rds")

######################################################################
# plot CBD model prediction
setwd(rstudioapi::getActiveProject())
cbd = stars::read_stars("results/tifs/haard_CBD.tif")
AOA = stars::read_stars("results/tifs/AOA_haard_CBD.tif")
data = c(cbd, AOA) |> setNames(c("cbd","aoa"))
data = data |> mutate(aoa = as.character(aoa),
                      aoa = case_when(is.na(cbd) ~ "NB", TRUE ~ aoa) |> 
                        factor(levels = c("inside","outside","NB")))

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

pcbd = lay + stars::geom_stars(data = cbd, downsample = 1) +
  scale_fill_viridis_c(direction = -1, name="CBD", na.value = "grey80") 

paoa = lay +  stars::geom_stars(data = data["aoa"], downsample = 1) +
  scale_fill_manual(values=c("lightgreen","firebrick", "grey80"), name="AOA")

P = pcbd / paoa + patchwork::plot_annotation(tag_levels = "A")
P

ggsave("figures/CBD_and_AOA_vertical.png", width = 14.5, height = 20, units = "cm")
#saveRDS(P, "figures/CBD_and_AOA.rds")

