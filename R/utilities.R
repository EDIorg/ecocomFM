#' Convert \code{character(0)} to \code{""}
#'
#' @param txt (character) Character string
#'
#' @return (character) Return \code{txt} if not empty else ""
#'
cnvmt <- function(txt) {
  if (length(txt) == 0) {
    return("")
  } else {
    return(txt)
  }
}








#' Increment data package version number
#'
#' @param package.id (character) Data package identifier
#'
#' @return (character) Package identifier with version number incremented by 1.
#' 
#' @details Supports repository specific methods.
#'
#' @examples
#' increment_package_version("edi.100.1")
#' 
increment_package_version <- function(package.id) {
  
  # Load Global Environment config --------------------------------------------
  
  if (exists("config.repository", envir = .GlobalEnv)) {
    repository <- get("config.repository", envir = .GlobalEnv)
  } else {
    repository <- "EDI"
  }
  
  # Repository specific methods -----------------------------------------------
  
  if (repository == "EDI") {
    
    parts <- unlist(stringr::str_split(package.id, "\\."))
    parts[3] <- as.character(as.numeric(parts[3]) + 1)
    parts <- paste(parts, collapse = ".")
    return(parts)
    
  }
}








#' Is empty nodeset?
#'
#' @param nodeset (xml_nodeset) Any nodeset returned by the xml2 library
#' 
#' @return (logical) TRUE if nodeset length = 0
#' 
is_empty_nodeset <- function(nodeset) {
  res <- length(nodeset) == 0
  return(res)
}








#' Parse datetime
#'
#' @param vals (character) Vector of datetimes
#' @param frmt (character) Datetime format string
#' 
#' @details A wrapper to to \code{lubridate::ymd()}, \code{lubridate::ymd_h()}, \code{lubridate::ymd_hm()}, and \code{lubridate::ymd_hms()}.
#' 
#' @return (POSIXct POSIXt) Datetimes parsed
#' 
parse_datetime <- function(vals, frmt) {
  res <- "ymd"
  t <- unlist(stringr::str_split(frmt, "T|[:blank:]"))[2] # time format
  if (!is.na(t)) {                                        # build time component of lubridate func call
    if (stringr::str_detect(tolower(t), "hh")) {
      res <- paste0(res, "_h")
    }
    if (stringr::str_detect(tolower(t), "mm")) {
      res <- paste0(res, "m")
    }
    if (stringr::str_detect(tolower(t), "ss")) {
      res <- paste0(res, "s")
    }
  }
  res <- eval(parse(text = paste0("lubridate::", res, "(vals)")))
  return(res)
}








#' Get XML values
#'
#' @param nodeset (xml_node/xml_nodeset) Nodeset
#' @param xpath (character) xpath
#' 
#' @return (character) Value of \code{xpath} within \code{nodeset}. Returns "" if returned character string has length = 1.
#' 
#' @details Simplifies code by wrapping \code{cnvmt(xml2::xml_text(xml2::xml_find_all(...), trim = T))}
#' 
xml_val <- function(nodeset, xpath) {
  res <- cnvmt(
    xml2::xml_text(
      xml2::xml_find_all(nodeset, xpath),
      trim = T))
  return(res)
}







 
#' Get previous data package version
#'
#' @param package.id (character) Data package identifier
#'
#' @return (character) Previous data package version
#' 
#' @details Supports repository specific methods.
#'
#' @examples
#' \dontrun{
#' #' get_previous_data_package_version("edi.100.2")
#' }
#' 
get_previous_version <- function(package.id) {
  
  # Load Global Environment config --------------------------------------------
  
  if (exists("config.repository", envir = .GlobalEnv)) {
    repository <- get("config.repository", envir = .GlobalEnv)
  } else {
    repository <- "EDI"
  }
  
  if (exists("config.environment", envir = .GlobalEnv)) {
    environment <- get("config.environment", envir = .GlobalEnv)
  } else {
    environment <- "production"
  }
  
  # Repository specific methods -----------------------------------------------
  
  if (repository == "EDI") {
    
    parts <- unlist(stringr::str_split(package.id, "\\."))
    
    vers <- suppressMessages(
      EDIutils::api_list_data_package_revisions(
        scope = parts[1],
        identifier = parts[2],
        environment = environment))
    
    if (length(vers) == 1) {
      return("0")
    }
    
    parts[3] <- vers[length(vers) - 1]
    parts <- paste(parts, collapse = ".")
    return(parts)
    
  }
}