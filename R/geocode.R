source('R/cst.R')

g <- NULL

geocode <- function(address, api = c('google', 'baidu'), key = '', 
                    ocs = c('WGS-84', 'GCJ-02', 'BD-09'), messaging = FALSE){
  # check parameters
  stopifnot(is.character(address))
  stopifnot(is.character(key))
  api <- match.arg(api)
  ocs <- match.arg(ocs)
  stopifnot(is.logical(messaging))
  
  # vectorize for many addresses
  if(length(address) > 1){
    
  }
  
  # format url
  if(api == 'google'){
    # http://maps.googleapis.com/maps/api/geocode/json?address=ADDRESS&sensor
    # =false&key=API_KEY
    url_string <- paste('http://maps.googleapis.com/maps/api/geocode/json?address=', 
                        address, '&sensor=false', sep = '')
    if(nchar(key) > 0){
      url_string <- paste(url_string, '&key=', key, sep = '')
    }
  }
  if(api == 'baidu'){
    # http://api.map.baidu.com/geocoder/v2/?address=ADDRESS&output=json&ak=API_KEY
    url_string <- paste('http://api.map.baidu.com/geocoder/v2/?address=', address, 
                        '&output=json&ak=', key, sep = '')
  }
  
  url_string <- URLencode(url_string)
  if(messaging) message(paste('calling ', url_string, ' ... ', sep = ''), appendLF = F)
  
  # gecode
  connect <- url(url_string)
  gc <- fromJSON(paste(readLines(connect, warn = FALSE), collapse = ''))
  if(messaging) message('done.')  
  close(connect)
  
  # format geocoded data
  NULLtoNA <- function(x){
    if(is.null(x)) return(NA)
    x
  }
  
  # geocoding results
  if(api == 'google'){
    # did geocode fail?
    if(gc$status != 'OK'){
      warning(paste('geocode failed with status ', gc$status, ', location = "', 
                    address, '"', sep = ''), call. = FALSE)
      return(data.frame(lat = NA, lng = NA))  
    }
    
    # more than one location found?
    if(length(gc$results) > 1 && messaging){
      message(paste('more than one location found for "', address, 
                    '", using address\n  "', tolower(gc$results[[1]]$formatted_address), 
                    '"\n', sep = ''))
    }
    
    gcdf <- with(gc$results[[1]], {
      data.frame(lat = NULLtoNA(geometry$location['lat']), 
                 lng = NULLtoNA(geometry$location['lng']), 
                 row.names = NULL)})
    
    return(conv(gcdf[, 'lat'], gcdf[, 'lng'], from = 'GCJ-02', to = ocs))
  }
  if(api == 'baidu'){
    # did geocode fail?
    if(gc$status != 0){
      warning(paste('geocode failed with status code ', gc$status, ', location = "', 
                    address, '". see more details in the response code table of Baidu Geocoding API', 
                    sep = ''), call. = FALSE)
      return(data.frame(lat = NA, lng = NA))  
    }
    
    gcdf <- with(gc$result, {
      data.frame(lat = NULLtoNA(location['lat']), 
                 lng = NULLtoNA(location['lng']), 
                 row.names = NULL)})
    
    return(conv(gcdf[, 'lat'], gcdf[, 'lng'], from = 'BD-09', to = ocs))
  }
}

# geocode('inexisting place', api = 'google', ocs = 'WGS-84', messaging = TRUE)
# geocode('Beijing railway station', api = 'google', ocs = 'GCJ-02', messaging = TRUE)
# geocode('北京火车站', api = 'google', ocs = 'GCJ-02', messaging = TRUE)
# geocode('北京站', api = 'google', ocs = 'WGS-84', messaging = TRUE)
# geocode('北京站', api = 'baidu', ocs = 'WGS-84', messaging = TRUE)
# geocode('北京火车站', api = 'baidu', key = 'kgR30zPz0Rp7f36obLDtiEjK', ocs = 'BD-09', 
#         messaging = TRUE)
# geocode('北京市北京火车站', api = 'baidu', key = 'kgR30zPz0Rp7f36obLDtiEjK', ocs = 'GCJ-02', 
#         messaging = TRUE)
# geocode('北京市北京火车站', api = 'baidu', key = 'kgR30zPz0Rp7f36obLDtiEjK', ocs = 'WGS-84', 
#         messaging = TRUE)