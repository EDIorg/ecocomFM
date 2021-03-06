#' Plot community metrics
#'
#' @param dataset (list) Data object returned by \code{read_data()} (? list of named datapackage$tables)
#' @param path (character) Path to directory where plots will be written
#' @param alpha (numeric) Alpha-transparency scale between 0 and 1, where 1 is 100% opaque
#'
#' @return
#' \item{alpha_diversity.pdf}{Alpha diversity (species richness) over time and space}
#' \item{sampling_effort.pdf}{Spatiotemporal sampling effort}
#' \item{sp_accumulation_over_space.pdf}{Species accumulation curve over space}
#' \item{sp_accumulation_over_time.pdf}{Species accumulation curves over time (site-specific and total)}
#' \item{sp_shared_among_sites.pdf}{Species shared among sites}
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' # Plot one dataset
#' dataset <- read_data(
#'   id = "neon.ecocomdp.20166.001.001", 
#'   site = c("MAYF", "PRIN"), 
#'   startdate = "2016-01", 
#'   enddate = "2018-11")
#' plot_community(dataset, path = "/user/me/ecocomDP/plots")
#' 
#' # Plot multiple datasets
#' dataset <- read_data(c("edi.124.4", "edi.356.1"))
#' plot_community(dataset, path = "/user/me/ecocomDP/plots")
#' }
#' 
plot_community <- function(dataset, path, alpha) {
  ds <- lapply(dataset, format_for_comm_plots, id = names(dataset))     # intermediate format for plotting
  for (id in names(ds)) {
    dslong <- subset(ds[[id]], OBSERVATION_TYPE == "TAXON_COUNT") %>% # long form
      dplyr::mutate_at(dplyr::vars(c(VALUE)), as.numeric) %>%
      dplyr::mutate_at(dplyr::vars(SITE_ID), as.character)
    dswide <- dslong %>%                                              # wide form
      dplyr::select(-VARIABLE_UNITS) %>%
      tidyr::pivot_wider(names_from = VARIABLE_NAME, values_from = VALUE)
    vunit <- unique(dslong$VARIABLE_UNITS)                            # variable unit
    plot_alpha_diversity(dslong, id,  path, vunit, alpha)
    plot_sampling_effort(dslong, id, path, alpha)
    plot_sp_accumulation_over_space(dslong, id, path, vunit)
    plot_sp_accumulation_over_time(dslong, id, path, vunit, alpha)
    plot_sp_shared_among_sites(dswide, id, path, vunit)
  }
}








#' Plot alpha diversity (species richness) over time and space
#'
#' @param dslong (data.frame) Long form of return from \code{format_for_comm_plots()}
#' @param id (character) Dataset id
#' @param path (character) Path to where plots will be written
#' @param vunit (character) Unit of measurement variable
#' @param alpha (numeric) Alpha-transparency scale between 0 and 1, where 1 is 100% opaque
#'
#' @return
#' \item{alpha_diversity.pdf}{Alpha diversity (species richness) over time and space}
#' 
#' @import dplyr
#' @import ggplot2
#' 
plot_alpha_diversity <- function(dslong, id, path, vunit, alpha) {
  message("Plotting ", id, " alpha diversity")
  # Calculate num unique taxa at each site through time and num unique taxa among all sites through time
  calc_ntaxa <- function(ex) {
    ntaxa <- ex %>%
      filter(VALUE > 0) %>% 
      select(DATE, VARIABLE_NAME, SITE_ID) %>% 
      unique() %>% 
      mutate(ntaxa = 1) %>% 
      group_by(SITE_ID, DATE) %>% 
      summarize(ntaxa = sum(ntaxa))
    total_ntaxa <- ex %>%
      filter(VALUE > 0) %>%
      select(DATE, VARIABLE_NAME) %>%
      unique() %>%
      mutate(ntaxa = 1) %>%
      group_by(DATE) %>%
      summarize(ntaxa = sum(ntaxa))
    return(list(ntaxa = ntaxa, total_ntaxa = total_ntaxa))
  }
  ntaxa <- calc_ntaxa(dslong)
  # Plot
  ggplot(data = ntaxa$ntaxa, aes(x = DATE, y = ntaxa)) +
    geom_point(aes(color = SITE_ID), alpha = alpha) +
    geom_line(aes(color = SITE_ID), alpha = alpha) +
    geom_point(data = ntaxa$total_ntaxa, aes(x = DATE, y = ntaxa, fill = ""), color="black") +
    geom_line(data = ntaxa$total_ntaxa, aes(x = DATE, y = ntaxa), color = "black") +
    labs(title = "Alpha diversity (species richness) over time and space", subtitle = id) +
    xlab("Year") +
    ylab(paste0("Taxa observed (", vunit, ")")) +
    guides(
      color = guide_legend(title = "Site", label.theme = element_text(size = 6)),
      fill = guide_legend(title = "All sites")) + 
    ylim(c(0, max(ntaxa$total_ntaxa$ntaxa))) +
    theme_bw()
  ggsave(
    filename = paste(path, "/", id, '_alpha_diversity.pdf',sep=''), 
    width = 12, 
    height = 7, 
    units = "in")
}








#' Plot spatiotemporal sampling effort
#'
#' @param dslong (data.frame) Long form of return from \code{format_for_comm_plots()}
#' @param id (character) Dataset id
#' @param path (character) Path to where plots will be written
#' @param alpha (numeric) Alpha-transparency scale between 0 and 1, where 1 is 100% opaque
#' 
#' @return
#' \item{sampling_effort.pdf}{Spatiotemporal sampling effort}
#' 
#' @import ggplot2
#' 
plot_sampling_effort <- function(dslong, id, path, alpha) {
  message("Plotting ", id, " spatiotemporal sampling effort")
  # Scale font size
  uniy <- length(unique(dslong$SITE_ID))
  if (uniy < 30) {
    txty <- NULL
  } else if (uniy < 60) {
    txty <- 6
  } else if (uniy >= 60) {
    txty <- 4
  }
  # Plot
  ggplot(data = dslong, aes(x = DATE, y = SITE_ID)) +
    geom_point(alpha = alpha) +
    theme_bw() +
    labs(title = "Spatiotemporal sampling effort", subtitle = id) +
    xlab("Year") +
    ylab("Site") +
    theme_bw() +
    theme(
      axis.text.y.left = element_text(size = txty),
      plot.margin = margin(0.1, 0.25, 0.1, 0.1, "in"))
  ggsave(
    file = paste(path, "/", id, '_sampling_effort.pdf',sep = ''),
    width = 12,
    height = 7,
    units = "in")
}








#' Plot species accumulation curve over space
#'
#' @param dslong (data.frame) Long form of return from \code{format_for_comm_plots()}
#' @param id (character) Dataset id
#' @param path (character) Path to where plots will be written
#' @param vunit (character) Unit of measurement variable
#'
#' @return
#' \item{sp_accumulation_over_space.pdf}{Species accumulation curve over space}
#' 
plot_sp_accumulation_over_space <- function(dslong, id, path, vunit) {
  message("Plotting ", id, " species accumulation over space")
  # Calculate cumulative number of taxa
  calc_cuml_taxa_space <- function(ex) {
    taxa.s.list <- list()
    sites <- unique(ex$SITE_ID)
    for(t in 1:length(unique(ex$SITE_ID))){                            # unique taxa found in each year
      tmp.dat <- subset(ex, ex$SITE_ID == sites[t])
      tmp.dat.pres <- subset(tmp.dat, tmp.dat$VALUE > 0) 
      taxa.s.list[[t]] <- unique(tmp.dat.pres$VARIABLE_NAME)
    }
    cuml.taxa.space <- list()                                          # cumulative list of taxa over space
    cuml.taxa.space[[1]] <- taxa.s.list[[1]]
    for(t in 2:length(unique(ex$SITE_ID))){                            # list cumulative taxa, with duplicates
      cuml.taxa.space[[t]] <- c(cuml.taxa.space[[t - 1]], taxa.s.list[[t]])
    }
    cuml.taxa.space <- lapply(cuml.taxa.space, function(x) {unique(x)})# rm duplicates
    cuml.no.taxa.space <- data.frame("site" = unique(ex$SITE_ID))      # total unique taxa over space
    cuml.no.taxa.space$no.taxa <- unlist(lapply(cuml.taxa.space, function(x) {length(x)}))
    return(cuml.no.taxa.space)
  }
  comm.dat <- dslong %>% arrange(SITE_ID)                              # order by site
  no.taxa.space <- calc_cuml_taxa_space(comm.dat)
  no.taxa.space$no.site <- as.numeric(rownames(no.taxa.space))
  # Plot
  ggplot(data = no.taxa.space) + 
    geom_point(aes(x = no.site, y = no.taxa)) +
    geom_line(aes(x = no.site, y = no.taxa)) +
    labs(title = "Species accumulation curve over space", subtitle = id) +
    xlab("Cumulative number of sites") +
    ylab(paste0("Cumulative taxa observed (", vunit, ")")) +
    theme_bw()
  ggsave(
    file = paste(path, "/", id,'_sp_accumulation_over_space.pdf', sep=''),
    width = 12,
    height = 7,
    units = "in")
}








#' Plot species accumulation curves over time (site-specific and total)
#'
#' @param dslong (data.frame) Long form of return from \code{format_for_comm_plots()}
#' @param id (character) Dataset id
#' @param path (character) Path to where plots will be written
#' @param vunit (character) Unit of measurement variable
#' @param alpha (numeric) Alpha-transparency scale between 0 and 1, where 1 is 100% opaque
#'
#' @return
#' \item{sp_accumulation_over_time.pdf}{Species accumulation curves over time (site-specific and total)}
#' 
#' @import dplyr
#' @import ggplot2
#' @import tidyr
#' 
plot_sp_accumulation_over_time <- function(dslong, id, path, vunit, alpha) {
  message("Plotting ", id, " species accumulation over time")
  # Calculate cumulative number of taxa 
  cuml.taxa.fun <- function(ex){
    taxa.t.list <- list()
    dates <- unique(ex$DATE)
    for(t in 1:length(unique(ex$DATE))) {                                          # unique taxa found in each year
      tmp.dat <- subset(ex, ex$DATE == dates[t])
      tmp.dat.pres <- subset(tmp.dat, tmp.dat$VALUE > 0) 
      taxa.t.list[[t]] <- unique(tmp.dat.pres$VARIABLE_NAME)
    }
    cuml.taxa <- list()                                                            # cumulative taxa through time
    cuml.taxa[[1]] <- taxa.t.list[[1]]
    if (length(unique(ex$DATE)) > 1) {                                             # create list of the cumulative taxa, with duplicates
      for(t in 2:length(unique(ex$DATE))){ 
        cuml.taxa[[t]] <- c(cuml.taxa[[t - 1]], taxa.t.list[[t]])
      }
    }
    cuml.taxa <- lapply(cuml.taxa, function(x){unique(x)})                         # rm duplicates
    cuml.no.taxa <- data.frame("year" = unique(ex$DATE), stringsAsFactors = FALSE) # number of unique taxa through time
    cuml.no.taxa$no.taxa <- unlist(lapply(cuml.taxa, function(x){length(x)}))
    return(cuml.no.taxa)
  }
  cuml.taxa.all.sites <- cuml.taxa.fun(ex = dslong)   # species accumulation across all sites pooled together
  comm.dat <- dslong %>% arrange(SITE_ID)             # order by site
  X <- split(comm.dat, as.factor(comm.dat$SITE_ID))   # cumulative number of taxa for each site
  out <- lapply(X, cuml.taxa.fun)
  out[names(out) %in% "lo_2_115"]                     # list to dataframe
  output <- do.call("rbind", out)
  output$rnames <- row.names(output)                  # create SITE_ID column
  cuml.taxa.by.site <- suppressWarnings(              # Clean up the SITE_ID column. Warning sent when site_id only has one observation (non-issue), an artifact of do.call("rbind", out)
    output %>%
      tbl_df() %>%
      separate(rnames, c("SITE_ID", "todrop"), sep = "\\.") %>%
      select(-todrop))
  # Plot
  ggplot(data = cuml.taxa.by.site, aes(x = year, y = no.taxa)) +
    geom_point(aes(color = SITE_ID), alpha = alpha) +
    geom_line(aes(color = SITE_ID), alpha = alpha) +
    geom_point(data = cuml.taxa.all.sites, aes(x = year, y = no.taxa, fill = "")) +
    geom_line(data = cuml.taxa.all.sites, aes(x = year, y = no.taxa)) +
    labs(title = "Species accumulation curves over time (site-specific and total)", subtitle = id) +
    xlab("Year") +
    ylab(paste0("Cumulative taxa observed (", vunit, ")")) +
    guides(color = guide_legend(title = "Site", label.theme = element_text(size = 6)),
           fill = guide_legend(title = "All sites")) +
    ylim(c(0, max(cuml.taxa.all.sites$no.taxa))) +
    theme_bw()
  ggsave(
    file = paste(path, "/", id,'_sp_accumulation_over_time.pdf', sep = ''),
    width = 12,
    height = 7,
    units = "in")
}








#' Plot species shared among sites
#' 
#' @param dswide (data.frame) Wide form of return from \code{format_for_comm_plots()}
#' @param id (character) Dataset id
#' @param path (character) Path to where plots will be written
#' @param vunit (character) Unit of measurement variable
#'
#' @return
#' \item{sp_shared_among_sites.pdf}{Species shared among each site}
#' 
#' @import vegan
#' 
plot_sp_shared_among_sites <- function(dswide, id, path, vunit) {
  message("Plotting ", id, " species shared among sites")
  heat_pal_spectral <- colorRampPalette(rev( RColorBrewer::brewer.pal(11, "Spectral")))
  # Count species shared between sites in a site by species matrix
  shared.species <- function(comm, output = "matrix"){
    sites <- comm[, 1]
    share.mat <- matrix(NA, nrow = length(sites), ncol = length(sites), dimnames = list(sites, sites))
    site.pairs <- expand.grid(site1 = sites, site2 = sites)
    for(pair in 1:nrow(site.pairs)){
      site1 <- comm[site.pairs$site1[pair],][,-1] # pull out each site combo
      site2 <- comm[site.pairs$site2[pair],][,-1]
      if(output == "matrix"){                     # count shared species
        share.mat[site.pairs$site1[pair],site.pairs$site2[pair]] <- sum(site1 == 1 & site2 == 1)
      }
      if(output == "dataframe"){
        site.pairs[pair,"shared"] <- sum(site1 == 1 & site2 == 1)
      }
    }
    if(output == "matrix") return(share.mat)
    if(output == "dataframe") return(site.pairs)
  }
  comm.cumul <- dswide %>%                  # aggregate years by cumulative abundances
    group_by(SITE_ID) %>% 
    select(-OBSERVATION_TYPE, -DATE) %>%
    summarise_all(sum)
  comm.cumul[is.na(comm.cumul)] <- 0
  dswide.pa <- cbind(comm.cumul[,1], decostand(comm.cumul[,-1], method = "pa", na.rm = TRUE))
  shared.taxa <- shared.species(dswide.pa, output = "dataframe")
  uniy <- length(unique(shared.taxa$site1)) # scale font size
  if (uniy < 30) {
    txty <- NULL
  } else if (uniy < 60) {
    txty <- 6
  } else if (uniy >= 60) {
    txty <- 4
  }
  # Plot
  ggplot(shared.taxa, aes(x = site1, y = site2, fill = shared)) +
    geom_raster() +
    scale_fill_gradientn(colours = heat_pal_spectral(100), name = paste0("Taxa shared (", vunit, ")")) +
    theme_bw() +
    labs(title = "Plot species shared among each site", subtitle = id) +
    xlab("Site") +
    ylab("Site") +
    theme(
      aspect.ratio = 1, 
      axis.text.x.bottom = element_text(size = txty, angle = 90, hjust = 1, vjust = 0.5),
      axis.text.y.left = element_text(size = txty))
  ggsave(
    file = paste(path, "/", id,'_sp_shared_among_sites.pdf', sep=''),
    width = 12,
    height = 7,
    units = "in")
}








#' Format dataset for community plotting functions
#'
#' @param d (list) Data object returned by \code{read_data()} or passed through \code{lapply()}
#' @param id (character) Dataset id
#' 
#' @details Downsteam plotting functions are based on \href{https://github.com/sokole/ltermetacommunities/tree/master/Group2-explore-data}{LTER Metacommunities code} and use their intermediate data input format.
#'
#' @return (data.frame) Tabular data of \code{id} in a format compatible with plotting functions
#' 
format_for_comm_plots <- function(d, id) {
  if (!is.null(d[[1]]$tables)) {
    d <- d[[1]]$tables # Input is from read_data()
  } else {
    d <- d$tables      # Input is from lapply()
  }
  
  # Constraints
  varname <- unique(d$observation$variable_name) # Can only handle one variable
  if (length(varname) > 1) {
    warning(
      "The observation table of ", id, " has more than one variable name (", 
      paste(varname, collapse = ", "), "). ", "Plotting operations can only ",
      "handle one. Consider splitting this dataset before passing to ",
      "plot_community(). Defaulting to ", varname[1], ".", call. = FALSE)
    d$observation <- dplyr::filter(d$observation, variable_name == varname[1])
  }
  dups <- d$observation %>% dplyr::select(-observation_id, -value) %>% duplicated()
  if (any(dups)) {                               # Only unique observations allowed
    warning(
      "The observation table of ", id, " has duplicate observations (",
      paste(which(dups), collapse = ", "), "). Consider fixing with ",
      "summarize_variable_name().", call. = FALSE)
    d$observation <- d$observation %>%
      dplyr::distinct(across(-c(observation_id, value)), .keep_all = TRUE)
  }
  
  obs <- d$observation
  loc <- d$location
  obs$observation_datetime
  taxon_count <- data.frame(
    OBSERVATION_TYPE = "TAXON_COUNT",
    SITE_ID = obs$location_id,
    DATE = obs$observation_datetime,
    VARIABLE_NAME = obs$taxon_id,
    VARIABLE_UNITS = obs$variable_name,
    VALUE = obs$value,
    stringsAsFactors = FALSE)
  spatial_coordinate <- data.frame(
    OBSERVATION_TYPE = "SPATIAL_COORDINATE",
    SITE_ID = c(loc$location_id, loc$location_id),
    DATE = NA,
    VARIABLE_NAME = c(
      rep("latitude", length(loc$latitude)), 
      rep("longitude", length(loc$longitude))),
    VARIABLE_UNITS = "dec.degrees",
    VALUE = c(loc$latitude, loc$longitude),
    stringsAsFactors = FALSE)
  res <- rbind(taxon_count, spatial_coordinate)
  return(res)
}
