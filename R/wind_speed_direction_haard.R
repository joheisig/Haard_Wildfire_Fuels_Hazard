library(rdwd)
library(tidyverse)
library(sf)
library(mapview)
library(openair)
data("geoIndex")
data("metaIndex")

# filter suitable DWD stations by distance to Haard forest
haard = st_point(c(7.2, 51.7)) |> st_sfc(crs=4326)
geoIndex |> st_as_sf(coords=c("lon","lat"), crs=4326) -> geoIndex
geoIndex$distance = st_distance(geoIndex, haard) |> as.numeric()

metaIndex = inner_join(metaIndex, geoIndex, by=c("Stations_id" = "id")) |> 
  st_as_sf()

metaIndex |> 
  filter(var == "kl",
         res == "daily",
         von_datum < as.Date("1990-01-01"), 
         bis_datum > as.Date("2010-01-01"),
         distance < 50000) -> metaIndex_sub

mapview(metaIndex_sub)


################
# daily wind speed
link <- selectDWD("Haltern (Wasserwerk)", res="daily", var="kl", per="h")
clim <- dataDWD(link, dir=tempdir())

haltern = filter(clim, MESS_DATUM > as.Date("2000-01-01")) |> 
  mutate(FM_kmh = FM * 3.6,
         FX_kmh = FX * 3.6,
         day = as.integer(MESS_DATUM),
         year = as.numeric(substr(MESS_DATUM, 1,4)),
         month = factor(months(MESS_DATUM), 
                        levels = c("Januar","Februar", "März", "April",
                                   "Mai", "Juni", "Juli", "August",
                                   "September", "Oktober", "November", "Dezember"))) |> 
  select(MESS_DATUM, day, year,month, FM_kmh, FX_kmh) |> 
  pivot_longer(starts_with("F"), names_to = "measure", values_to = "windspeed")

# daily means/maxs by month
ggplot(haltern, aes(x=month, y=windspeed, color=year)) +
  geom_jitter(width = 0.3, alpha = 0.2) +
  scale_color_continuous(type="viridis") +
  geom_boxplot(width=0.2, alpha=0.5) +
  facet_wrap(~measure, nrow = 2, scales = "free") + 
  theme_dark() +
  ggtitle("Haltern am See Mean & Max Windspeed 2000 - 2021")

group_by(haltern, year, month, measure) |>  
  summarise(windspeed = median(windspeed, na.rm = T))

group_by(haltern, year, month, measure) |>  
  summarise(windspeed = median(windspeed, na.rm = T)) |> 
  ggplot(aes(x=month, y=windspeed, color=year)) +
  geom_jitter(alpha=0.6, width = 0.2) +
  scale_color_continuous(type="viridis") +
  facet_wrap(~measure, nrow = 2, scales = "free") + 
  theme_dark() +
  ggtitle("Haltern am See Mean & Max Windspeed 2000 - 2021")


##############
# wind speed and direction from hourly observations
link <- selectDWD("Haltern (Wasserwerk)", res="hourly", var="wind", per="h")
wind_dat <- dataDWD(link, dir=tempdir())

select(wind_dat, MESS_DATUM, F, D) |> 
mutate(ws = F,
       wd = D,
       date=MESS_DATUM,
       day = as.integer(MESS_DATUM),
       year = as.numeric(substr(MESS_DATUM, 1,4)),
       month = factor(months(MESS_DATUM), 
                      levels = c("Januar","Februar", "März", "April",
                                 "Mai", "Juni", "Juli", "August",
                                 "September", "Oktober", "November", 
                                 "Dezember"))) |> 
  filter(MESS_DATUM >= as.Date("2000-01-01"),
         D < 361) |> 
  drop_na() -> wind

png("figures/windrose_haltern.png", 1600, 1400, res = 300)
wind |> 
  filter(month %in% c("Juni","Juli","August")) |> 
  windRose(ws.int = 1, type="season", sub = "",
         breaks=5, key.position = "right", width = 1.3,
         grid.line = list(value = 10, lty = 5, col = "darkgrey"))
dev.off()

windRose(wind, type = "daylight", longitude = 7, latitude=52)

polarFreq(wind)


wind |> 
  filter(month %in% c("Juni","Juli","August")) |> 
  ggplot(aes(x=month, y=ws*3.6, color=year)) +
  geom_jitter(width = 0.3, alpha = 0.1, size = 0.1) +
  scale_color_continuous(type="viridis") +
  geom_boxplot(width=0.2, alpha=0.5) +
  theme_dark() +
  ggtitle("Haltern am See Windspeed Summer 2000 - 2021")

summary(wind)
quantile(wind$ws,c(0.5,0.75, 0.8, 0.85, 0.9, 0.95, 0.999))

         