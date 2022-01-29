library(rdwd)
library(dplyr)
library(sf)
library(openair)
data("geoIndex")
data("metaIndex")

## Wind speed and direction from hourly observations
dat = list.files(file.path(getwd(),"data"), pattern = "hourly_wind", full.names = T)
if (length(dat) > 0) { wind_dat = readDWD(dat)
} else {
  link <- selectDWD("Haltern (Wasserwerk)", res="hourly", var="wind", per="h")
  wind_dat <- dataDWD(link, dir=file.path(getwd(),"data"))
}

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

png(file.path(getwd(),"figures","windrose_haltern.png"), 1600, 1400, res = 300)
wind |> 
  filter(month %in% c("Juni","Juli","August")) |> 
  windRose(ws.int = 1, type="season", sub = "",
         breaks=5, key.position = "right", width = 1.3,
         grid.line = list(value = 10, lty = 5, col = "darkgrey"))
dev.off()

# check the 'figures' directory to see the plot!