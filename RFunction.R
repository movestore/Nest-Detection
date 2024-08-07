library('move2')
library('dplyr')
library("foreach")
library('nestR')
library('sf')

#Select year example
#The last parameter with the name data is the result of the previous app
#   -> Should be removed if no data should be provided from previous app
rFunction = function(data, sea.start="2000-01-01T00:00:00.000Z", sea.end="2000-12-31T23:59:59.999Z", nest.cycle=0, buffer=0, min.pts=0, min.d.fix=0, min.consec=0, min.top.att=0, min.days.att=0,discard.overlapping=TRUE) {
  
  Sys.setenv(tz="UTC") 
  options(scipen=999)
  
  id <- make.names(gsub(" ", "", mt_track_id(data)))
  date <- mt_time(data)
  
  ## add columns for find_nest function. burst: unique identifier of individual_year and date
  data.bf <- data.frame(id,"burst"=paste(id,as.POSIXlt(date)$year+1900,sep="_"),"date"=date,"long"=st_coordinates(data)[,1],"lat"=st_coordinates(data)[,2])
  
  data.bf.split = split(data.bf,data.bf$id)

  sea.start.f <- format(as.Date(as.POSIXct(sea.start)), "%m-%d")
  sea.end.f <- format(as.Date(as.POSIXct(sea.end)), "%m-%d")
  
  nest.output <- lapply(data.bf.split, function(datai)
  {
    nest_attempts=find_nests(gps_data = datai,
                             sea_start = sea.start.f,
                             sea_end = sea.end.f,
                             nest_cycle = nest.cycle, #days
                             buffer = buffer, #m
                             min_pts = min.pts,
                             min_d_fix = min.d.fix,
                             min_consec = min.consec,
                             min_top_att = min.top.att,
                             min_days_att = min.days.att,
                             discard_overlapping = discard.overlapping) #this function needs to be carfully tested in MoveApps, as it writes temp files to "output/" and fails to remove them afterwards
    return(nest_attempts)
  })
  #save(nest.output, file="nestR.output.RData")
  #load("nestR.output.RData")

  ### create output file
  nest.table <- lapply(nest.output, function(x) x[-2])
  nest.table <- lapply(nest.table,function(i) do.call("rbind",i))

  ## remove individuals that didn't breed
  leer <- which(unlist(lapply(nest.table,nrow))==0)
  if (length(leer)>0)
  {
    data.bf.split.nn = data.bf.split[-leer]
    nest.table = nest.table[-leer]
  } else data.bf.split.nn <- data.bf.split

  ## what to do if there were no nesting attempts for all individuals
  if (length(nest.table)==0) 
    {
    logger.info("There were no nests detected in your data set. You might want to adapt your settings. NULL (an empty object) is given back as output.") 
    result <-NULL
    } else
    {
      nest.table.df = dplyr::bind_rows(nest.table, .id = "track")
      nest.table.df$uburst <- make.names(nest.table.df$burst,allow_=FALSE,unique=TRUE)
      n <- dim(nest.table.df)[1]
      
      # add columns so that this csv can be read with Cloud Storage App
      nest.table.df$timestamp <- paste0(as.character(min(as.POSIXct(nest.table.df$first_date))+c(1:n)),".000") # place holder for import only
      
      names(nest.table.df)[names(nest.table.df) %in% c("long","lat")] <- c("location_long","location_lat")
      nest.table.df$sensor_type <- "nestR"
      nest.table.df$individual_taxon_canonical_name <- "nest" 
      nest.table.df$individual_local_identifier <- "nesting"
      
      nest.table.df$visit_dur <- difftime(nest.table.df$last_date,nest.table.df$first_date,units="days")
      nest.table.df$attempt_dur <- difftime(nest.table.df$attempt_end,nest.table.df$attempt_start,units="days")
      
      nest.table.df$first_date <- as.character(nest.table.df$first_date)
      nest.table.df$last_date <- as.character(nest.table.df$last_date)
      nest.table.df$attempt_start <- as.character(nest.table.df$attempt_start)
      nest.table.df$attempt_end <- as.character(nest.table.df$attempt_end)
      
      write.csv(nest.table.df,appArtifactPath("nest_table.csv"),row.names=FALSE)
      # --> this file can also be uploaded with the Cloud Storage App for further use
      
      # extract all locations between first_date and last_date of detected breeding attempts -> into results so that can plot in next App
      # first have to create unique burst names
      data.split <- split(data,mt_track_id(data))
      
      nest.data <- foreach (nest.table.b = nest.table.df$uburst) %do% {
        nest.table.i <- nest.table.df[nest.table.df$uburst==nest.table.b,]
        datai <- data.split[[which(make.names(gsub(" ", "",names(data.split)))==nest.table.i$track)]] #these names are trackIds of the incoming data set, ok
        nest.data.i <- datai[mt_time(datai)>=as.POSIXct(nest.table.i$first_date) & mt_time(datai)<(as.POSIXct(nest.table.i$last_date)+1),] #so, we get the track of each nesting attempt, i.e. quite some duplicate data (but ok, so that can visualise them in next App)
      }
      names(nest.data) <- nest.table.df$uburst #names are the breeding attempt unique burst IDs

      #nest.data.nozero <- nest.data[unlist(lapply(nest.data, length) > 0)] #not necessary for move2
      result <- mt_stack(nest.data,.track_combine="rename") #return track segments in breeding modus
    }
    
  #### 31 March 2022 have simplified the App here to only return nesting attempts (without age or sex of bird, dispersal distance and boxplot)

  return(result) 

}
