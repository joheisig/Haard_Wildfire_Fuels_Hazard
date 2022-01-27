library(tidybayes)
library(patchwork)
library(ggplot2)
library(cowplot)
library(ggpattern)
library(dplyr)
library(tidyr)

# boxplots --------------------
s = readxl::read_xlsx("data/edward_data_merged.xlsx") |> 
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

#table
s  |> 
  summarise(across(everything(), function(x) round(median(x),2))) |> 
  knitr::kable()

# plot
s= s |> 
  tidyr::pivot_longer(-Species) |> 
  mutate(name = factor(name, c("1hr","10hr","100hr","Live Herb",
                               "Live Shrub","Fuelbed Depth"))) 

facs <- levels(s$name)
grau = "chocolate2"
ggplot(s, aes(x=name,y=value,fill=Species, groups=Species)) +
  geom_rect(aes(ymin=0, ymax=3), alpha=0.4,
            xmin=which(facs=="Fuelbed Depth")-0.5, 
            xmax=which(facs=="Fuelbed Depth")+0.5, 
            color=grau, fill=NA) +
  geom_boxplot(outlier.alpha = 0.4, notch = T) +
  #scale_fill_viridis_d(begin = 0.2) +
  scale_fill_manual(values=c("gold2", "springgreen4", "palevioletred1"), name="") +
  theme_minimal_hgrid() +
  theme(legend.position = c(0.3,0.8),
        legend.direction = "horizontal", 
        legend.margin = margin(2,2,2,2),
        legend.background = element_rect(color = "black"), 
        axis.text.y.right = element_text(color = grau), 
        axis.title.y.right = element_text(color = grau), 
        plot.background = element_rect(fill="white") ) +
  labs(x="",y="Fuel Loading [kg/m²]") +
  scale_y_continuous(sec.axis = sec_axis(~ .,name = "Fuelbed Depth [m]")) 

ggsave("figures/surface_fuel_samples.png",scale = 1.7, width = 12, height=7, units="cm")  

##############################################################################
# plot fuel model prediction and AOA

fm = stars::read_stars("results/tifs/haard_fuelmodel_majority3.tif") |> 
  dplyr::transmute(fmc = haard_fuelmodel_majority3.tif,
                   # fmc = recode_factor(fmc, Beech = "Beech", Pine = "Pine",
                   #                     "Red Oak" = "Red Oak", "Non-Burnable" = "NB"))
                   fmc = factor(fmc, levels = c(1:4), 
                                labels = c("Beech", "Pine", "Red Oak", "NB")))

aoa.fm = stars::read_stars("results/tifs/AOA_Haard_fuel_types.tif") |> 
  dplyr::mutate(aoa = factor(AOA_Haard_fuel_types.tif, labels = c("outside", "inside")))

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

p1 = lay + stars::geom_stars(data=fm) +
  scale_fill_manual(values=c("gold2",
                             "springgreen4",
                             "palevioletred1", 
                             "grey80"), 
                    name="Fuel Models") +
  guides(fill=guide_legend(ncol=1))
p2 = lay +  stars::geom_stars(data=aoa.fm[2,,]) +
  scale_fill_manual(values=c("firebrick","lightgreen", "grey80"), name="AOA") +
  guides(fill=guide_legend(ncol=1))

# 116044/(116044+783956) = 0.1289 (outside AOA)

PL = patchwork::wrap_plots(p1, p2, nrow = 2) + 
  patchwork::plot_annotation(tag_levels = "A")
PL
ggsave("figures/fuelmodel-and-AOA_vertical_maj3.png", height =20, width = 14.5, units = "cm")
saveRDS(p1, "figures/fuelmodel_pred.rds")
saveRDS(p2, "figures/fuelmodel_AOA.rds")

