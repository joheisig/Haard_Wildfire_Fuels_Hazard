library(stars)
library(tidyverse)
library(viridis)
library(patchwork)

##----------- Rate of Spread ---------------
setwd("~/sciebo/haard_fire_hazard/FlamMap_output/Run_2_4scenarios/")
ros = list.files(full.names = T, pattern = "_ros") |> 
  read_stars()  |> 
  #select(1,3,5,7) |> 
  na_if(0)
ros2 = transmute(ros, across(.fns = ~findInterval(.x, c(0,2,4,6,8,10))))
ros3 = mutate(ros2, 
              across(.fns = ~replace_na(.x, 0)),
              across(.fns = ~factor(.x, 
                                    #levels = c(6:4,0,3:1),
                                    levels = c(6:0),
                                    labels = c(">10","8-10","6-8"
                                               ,"4-6", "2-4", "<2"
                                               ,"NB"
                                               ))))
##------------- Flame Length----------------
fl = list.files(full.names = T, pattern = "_fl.tif") |> 
  read_stars() |> 
  #select(1,3,5,7) |> 
  na_if(0)

# more sensible categories in meters
fl2 = transmute(fl, across(.fns = function(x) 
  findInterval(x, c(0,2,3,4,6,10))|> replace_na(0)))

fl3 = mutate(fl2, across(.fns = function(x) 
  factor(x, 
         #levels = c(6:4,0,3:1), 
         levels = c(6:0), 
         labels = c(">10","6-10","4-6"
                    ,"3-4", "2-3", "<2"
                    ,"NB"
         ))))
#----------- Burn Probability -----------------------

bpclass = function(x) replace_na(x, 0) |> 
  factor(levels = c(5:0), labels = c("Highest", "Higher", "Middle", "Lower", "Lowest","NB"))

#------------ Integrated Fire Hazard -------------

fhclass = function(f,b){
  case_when(
  f < 3 & b < 3 ~ 1,
  f < 2 & b < 4 ~ 1,
  between(f,3,4) & b == 1 ~ 2,
  f == 3 & b == 3 ~ 2,
  f == 2 & between(b,3,4) ~ 2,
  f == 1 & between(b,4,5) ~ 2,
  f == 5 & between(b,1,2) ~ 3,
  f == 4 & between(b,2,3) ~ 3,
  f == 3 & between(b,3,4) ~ 3,
  f == 2 & b == 5 ~ 3,
  f == 6 & between(b,1,2) ~ 4,
  f == 5 & between(b,3,4) ~ 4,
  f == 4 & between(b,4,5) ~ 4,
  f == 3 & b == 5 ~ 4,
  f == 6 & between(b,3,5) ~ 5,
  f == 5 & b == 5 ~ 5,
  TRUE ~ 0
)
}

# FL + ROS => 2x4 tiles ---------------------------------------------

pl = ggplot() +
  coord_equal() +
  theme_void() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme(legend.position="bottom", legend.box.just = "top", 
        text = element_text(size = 9), 
        plot.tag.position = "left",
        plot.tag = element_text(size=8),
        plot.margin = margin(0,-30,0,-30)) + 
  guides(fill = guide_legend(ncol = 1, title.position = "top", 
                             keywidth = unit(0.2,"cm"), keyheight = unit(0.3,"cm")))

grau = 'grey80'
fcol = plasma(6)
fcol = c(fcol, grau)
plf = pl + scale_fill_manual(values = fcol, drop=F, name="FL [m]")
f1 = plf + geom_stars(data=fl3[1])
f2 = plf + geom_stars(data=fl3[2])
f3 = plf + geom_stars(data=fl3[3])
f4 = plf + geom_stars(data=fl3[4])

rcol = mako(6, end = 0.9)
#rcol = c(rcol[1:3], "grey50", rcol[4:6])
rcol = c(rcol, grau)
plr = pl + scale_fill_manual(values = rcol, drop=F, name="ROS\n[m/min]")
r1 = plr + geom_stars(data=ros3[1])
r2 = plr + geom_stars(data=ros3[2])
r3 = plr + geom_stars(data=ros3[3])
r4 = plr + geom_stars(data=ros3[4])


Theme = theme(plot.margin = margin(5,0,5,0), legend.margin = margin(0,0,0,0))


# ((f1/f2/f3/f4/guide_area() + Lay) & Theme | 
#     (r1/r2/r3/r4/guide_area() + Lay) & Theme) +
#   plot_annotation(tag_levels = c('A','1')) 

((f1/f2/f3/f4+ plot_layout(tag_level = 'new') & Theme) |  
    (r1/r2/r3/r4+ plot_layout(tag_level = 'new') & Theme)) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = c('A','1')) 

fbpath = "~/PhD_home/repos/fire_hazard_haard/figures/firebehavior_2x4_legend-right.png"
ggsave(fbpath, height = 15, width = 10.5, units = "cm")



# Conditional FL and BP ----------------------------
setwd("~/sciebo/haard_fire_hazard/FlamMap_output/Run_2_4scenarios/")
bpmax = 0.012845

calc_conditional = function(csv){
  x = readr::read_csv(csv, progress = F) |>
    st_as_stars() 
  bp = dplyr::select(x, BP = 1) |> 
    na_if(0)
  fl = dplyr::select(x, 2:21) |> 
    merge() |> 
    st_apply(1:2, function(a) sum(a*seq(0.5, 10, 0.5), na.rm = T), 
             .fname = "FL") |> 
    na_if(0)
  x = c(bp, fl) |> 
    mutate(BP = BP / bpmax,
           BP = findInterval(BP, seq(0,0.8,0.2)) ,
           BP_class = BP |> 
             replace_na(0) |> 
             factor(levels = c(5:0), 
                    labels = c("Highest","Higher","Middle",
                               "Lower","Lowest", "NB")),
           FL = findInterval(FL, c(0,0.6,1.2,1.8,2.4,3.6)),
           FL_class = FL |> 
             replace_na(0) |> 
             factor(levels = c(6:0),
                    labels = c(">3.6","2.4-3.6","1.8-2.4"
                               ,"1.2-1.8", "0.6-1.2", "<0.6"
                               ,"NB"
                               )),
           IFH = fhclass(as.numeric(FL), as.numeric(BP)) |> 
             bpclass())
  return(x)
}

pl = ggplot() +
  coord_equal() +
  theme_void() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme(legend.position="bottom", legend.box.just = "top", 
        text = element_text(size = 9), 
        plot.tag.position = "left",
        plot.tag = element_text(size=8),
        plot.margin = margin(0,-30,0,-30)) + 
  guides(fill = guide_legend(ncol = 1, title.position = "top", 
                             keywidth = unit(0.2,"cm"), keyheight = unit(0.3,"cm")))



(s1 = calc_conditional("s1_flp.csv"))
s3 = calc_conditional("s3_flp.csv")
s5 = calc_conditional("s5_flp.csv")
s7 = calc_conditional("s7_flp.csv")

fcol = plasma(6)
fcol = c(fcol, grau)
plf = pl + scale_fill_manual(values = fcol, drop=F, name="CFL [m]")

ff1 = plf + geom_stars(data=s1[4])
ff2 = plf + geom_stars(data=s3[4])
ff3 = plf + geom_stars(data=s5[4])
ff4 = plf + geom_stars(data=s7[4])

bcol = rocket(5, end = 0.8) 
bcol = c(bcol, grau)
plb = pl + scale_fill_manual(values = bcol, drop=F, name="CBP")

b1 = plb + geom_stars(data=s1[3])
b2 = plb + geom_stars(data=s3[3])
b3 = plb + geom_stars(data=s5[3])
b4 = plb + geom_stars(data=s7[3])

# ((f1/f2/f3/f4 + Lay) & Theme | 
#     (b1/b2/b3/b4 + Lay) & Theme) +
#   plot_annotation(tag_levels = c('A','1')) 

((ff1/ff2/ff3/ff4 + plot_layout(tag_level = 'new') & Theme) | 
    (b1/b2/b3/b4 + plot_layout(tag_level = 'new') & Theme)) + 
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = c('A','1')) 

mttpath = "~/PhD_home/repos/fire_hazard_haard/figures/CFL_CBP_2x4_Legend_right.png"
ggsave(mttpath,  height = 15, width = 10.5, units = "cm")

#------------- FH -------------------------------------

#x = colorspace::choose_color()
#fhpal <- c('#A53C17', '#D28D1F', '#4E967A', '#82CAD1', '#3D7187', "grey50")

# custom palette (self-designed)
#fhpal <- c('#A53C17', '#D28D1F', '#FBE359', '#83EDA5', '#1CB5BA', "grey50")

# IFTDSS color scheme (blue to yellow to red)
fhpal <- c('#e0001b','#f4853b','#faf96a', '#93ffbc','#4adcff',"grey80")

  ph = ggplot() +
  coord_equal() +
  theme_void() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme(legend.position="bottom", legend.box.just = "top", 
        text = element_text(size = 9), 
        plot.tag.position = "left",
        plot.tag = element_text(size=8),
        plot.margin = margin(0,-30,0,-30)) + 
  guides(fill = guide_legend(nrow = 1, 
                             title.position = "left", direction = "horizontal",
                             keywidth = unit(0.2,"cm"), keyheight = unit(0.3,"cm"))) + 
  scale_fill_manual(values = fhpal, drop=F, name="FH")

h1 = ph + geom_stars(data=s1[5])
h2 = ph + geom_stars(data=s3[5])
h3 = ph + geom_stars(data=s5[5])
h4 = ph + geom_stars(data=s7[5])


Lay = plot_layout(guides = "collect", ncol=2)
Theme = theme(plot.margin = margin(5,0,5,5), 
              legend.margin = margin(0,0,0,0),
              legend.position = "bottom")

(((h1+h2+h3+h4) + Lay) & Theme) +
  plot_annotation(tag_levels ='A')

fhpath = "~/PhD_home/repos/fire_hazard_haard/figures/FH_2x2_Legend_right.png"
ggsave(fhpath, height = 10.8, width = 11, units = "cm")

# Wind --------------------------------
setwd("~/sciebo/haard_fire_hazard/FlamMap_output/Run_1_8scenarios/")  # sciebo
wd = list.files(full.names = T, pattern = "_wd") |> read_stars() |> select(WD = 1)
ws = list.files(full.names = T, pattern = "_ws") |> read_stars() |> select(WS = 1) |> 
  mutate(WS = WS / 2.2)

pw = ggplot() +
  coord_equal() +
  theme_void() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme(legend.position="bottom", legend.box.just = "top", 
        text = element_text(size = 9), 
        plot.tag.position = "left",
        plot.tag = element_text(size=8),
        plot.margin = margin(0,5,0,5)) + 
  guides(fill = guide_colorbar(title.position = "left", direction = "horizontal"
                               ,barheight = unit(0.4, 'cm')))

w1 = pw + geom_stars(data=wd) + 
  scale_fill_viridis_c(name="WD [°N]", option = "E", direction = -1)
w2 = pw + geom_stars(data=ws) + 
  scale_fill_viridis_c(name="WS [m/s]", option = "G", direction = -1)

(w1 + w2) + plot_annotation(tag_levels = 'A')

wpath = "~/PhD_home/repos/fire_hazard_haard/figures/WS_WD.png"
ggsave(wpath, height = 5.7, width = 11, units = "cm")


# compare differences of scenarios -------------------

y = c(ros[1]-ros[2], ros[3]-ros[4]) |> 
  setNames(c("s1_minus_s3", "s5_minus_s7")) |> merge()
y[y>10] = 10; x[x<0] = 0 
plot(y, col=terrain.colors(6), breaks = "equal")

x = c(fl[1]-fl[2], fl[3]-fl[4]) |> 
  setNames(c("s1_minus_s3", "s5_minus_s7")) |> merge()
x[x>10] = 10; x[x<0] = 0 
plot(x, col=terrain.colors(6), breaks = "equal")







