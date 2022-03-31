library('move')
library('dplyr')
library("foreach")
library('nestR')

#Select year example
#The last parameter with the name data is the result of the previous app
#   -> Should be removed if no data should be provided from previous app
rFunction = function(data, sea.start="2000-01-01", sea.end="2000-12-31", nest.cycle=0, buffer=0, min.pts=0, min.d.fix=0, min.consec=0, min.top.att=0, min.days.att=0,discard.overlapping=TRUE) {
  
  Sys.setenv(tz="UTC") 
  options(scipen=999)
  
  id <- trackId(data)
  date <- timestamps(data)
  
  ## add columns for find_nest function. burst: unique identifier of individual_year and date
  data.bf <- data.frame(id,"burst"=paste(id,as.POSIXlt(date)$year+1900,sep="_"),"date"=date,"long"=coordinates(data)[,1],"lat"=coordinates(data)[,2])
  
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
                             discard_overlapping = discard.overlapping)
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
    logger.info("There were no nests detected in your data set. You might want to adapt your settings. The full data set is given back as output.") 
    result <- data
    } else
    {
      nest.table.df = dplyr::bind_rows(nest.table, .id = "individual.local.identifier")
      write.csv(nest.table.df,paste0(Sys.getenv(x = "APP_ARTIFACTS_DIR", "/tmp/"),"nest_table.csv"),row.names=FALSE)
      
      # extract all locations between first_date and last_date of detected breeding attempts -> into results so that can plot in next App
      # first have to create unique burst names
      data.split <- move::split(data)
      
      nest.table.df$uburst <- make.names(nest.table.df$burst,allow_=FALSE,unique=TRUE)
      
      nest.data <- foreach (nest.table.b = nest.table.df$uburst) %do% {
        nest.table.i <- nest.table.df[nest.table.df$uburst==nest.table.b,]
        datai <- data.split[[which(names(data.split)==nest.table.i$individual.local.identifier)]]
        nest.data.i <- datai[timestamps(datai)>=nest.table.i$first_date & timestamps(datai)<(nest.table.i$last_date+1)]
        nest.data.i
      }
      names(nest.data) <- nest.table.df$uburst
      
      nest.data.nozero <- nest.data[unlist(lapply(nest.data, length) > 0)]
      result <- moveStack(nest.data.nozero,forceTz="UTC") #return track segments in breeding modus
    }
    
  #### 31 March 2022 have simplified the App here to only return nesting attempts (without age or sex of bird, dispersal distance and boxplot)

  return(result) 

}
