% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/validate_arguments.R
\name{validate_site}
\alias{validate_site}
\title{Validate site name (for NEON data products only)}
\usage{
validate_site(site, id)
}
\arguments{
\item{site}{(character; NEON data only) A character vector of site codes to filter 
data on. Sites are listed in the "sites" column of the 
\code{search_data()} output.}

\item{id}{(character) A data package/product identifier.}
}
\description{
Validate site name (for NEON data products only)
}
\details{
If invalid (i.e. not listed in the return of \code{search_data()}), then
    an error is returned.
}
