fast_countover <- function(x, t) {
  .Call(`_lidR_fast_countover`, x, t)
}
fast_table <- function(x, size = 5L) {
  .Call(`_lidR_fast_table`, x, size)
}

lidar_height_metrics = function(x, y, z, dz = 1, th = 2){
  z = z[z < 50 & z >= 0] # exclude outliers
  z = na.omit(z)
  n = length(z)
  zmax = max(z)
  zmean = mean(z)
  zsd = stats::sd(z)
  zcv = zsd / zmean * 100
  ziqr = IQR(z)
  probs = c(0.01, seq(0.05, 0.95, 0.05), 0.99)    # modified for 1 and 99%
  zq = as.list(stats::quantile(z, probs))
  names(zq) = paste0("zq", probs * 100)
  pzabovex = lapply(th, function(x) sum(z > x)/n *100)
  names(pzabovex) = paste0("pzabove", th)
  pzabovemean = sum(z > zmean)/n * 100
  if (zmax <= 0) {
    d = rep(0, 9)
  }
  else {
    breaks = seq(0, zmax, zmax/10)
    d = findInterval(z, breaks)
    #d = fast_table(d, 10)
    d = table(d)
    d = d/sum(d) * 100
    d = cumsum(d)[1:9]
    d = as.list(d)
  }
  names(d) = paste0("zpcum", 1:9)
  
  s = as.numeric(zq)[c(-1,-21)]
  cbh = round(s[which.max(diff(s))+1], 2)  # after Chamberlain et al 2021
  
  zmean_grass = mean(z[z < 0.4])
  zmean_shrub = mean(z[z > 0.4 & z < 4])
  zmean_tree = mean(z[z > 4])
  vert_gap = zmean_tree - zmean_shrub
  
  metrics = list(zmax = zmax, zmean = zmean, cbh = cbh, 
                 zsd = zsd, zcv = zcv, ziqr = ziqr, 
                 zskew = (sum((z - zmean)^3)/n)/(sum((z - zmean)^2)/n)^(3/2), 
                 zkurt = n * sum((z - zmean)^4)/(sum((z - zmean)^2)^2), 
                 zentropy = entropy(z, dz), pzabovezmean = pzabovemean,
                 zmean_grass = zmean_grass, zmean_shrub = zmean_shrub, 
                 zmean_tree = zmean_tree, vert_gap = vert_gap)
  metrics = c(metrics, pzabovex, zq, d, N = n)
  return(metrics)
}

.lidar_height_metrics = ~lidar_height_metrics(X, Y, Z, dz = 1, th = 2)

#============================================================

lidar_cover_metrics = function(z, cl){
  n = length(z)
  z = z[cl!=2]
  cover = list(cover = length(z) / n * 100)
  
  bins = c(-Inf,0, 0.4, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, Inf)
  zcov = as.list(cumsum(hist(z, breaks=bins, plot=F)$counts / n * 100))
  names(zcov) = c(paste0("cov_", bins[-c(1,length(bins))], "m"), "cov_30m_plus")
  
  # after Novo et al. 2020
  veg_classes = list(
    zcov_grass = zcov$cov_0.4m - zcov$cov_0m,
    zcov_shrub = zcov$cov_4m - zcov$cov_0.4m,
    zcov_tree = zcov$cov_30m_plus - zcov$cov_4m)
  
  return(c(cover, zcov, veg_classes))
}

.lidar_cover_metrics = ~lidar_cover_metrics(Z, Classification)


.rumple_index = ~rumple_index(X,Y,Z)
#============================================================

lidar_density_metrics = function(rn, cl){
  n = length(cl)
  n_ground = sum(cl == 2)
  n_canopy = sum(cl != 2)
  n_canopy_rn1 = sum(cl[rn==1] != 2)
  
  D = n_canopy_rn1 / n_canopy * 100
  pground = n_ground / n * 100
  
  return(list(D = D, pground = pground))
}

.lidar_density_metrics = ~lidar_density_metrics(ReturnNumber, Classification)

#============================================================

# create sf hole-polygons from two unequal buffers around points
make_rings = function(points, inner_buffer, outer_buffer){
  stopifnot(all(st_is(plots, "POINT")))
  require(dplyr)
  circ.in = sf::st_buffer(sf::st_geometry(points), inner_buffer)
  circ.out = sf::st_buffer(sf::st_geometry(points), outer_buffer)
  
  ring = lapply(1:nrow(points), 
                function(x) sf::st_sf(sf::st_difference(circ.out[x], 
                                                        circ.in[x]))) %>% 
    do.call(rbind, .) %>% 
    setNames('geometry') %>% 
    sf::st_set_geometry('geometry')
  return(ring)
}

























