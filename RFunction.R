library('move')
library('plyr')
library('dplyr')
library('lubridate')
library("foreach")
library('nestR')

#Select year example
#The last parameter with the name data is the result of the previous app
#   -> Should be removed if no data should be provided from previous app
rFunction = function(year, data, sea.start="2000-01-01", sea.end="2000-12-31", nest.cycle=0, buffer=0, min.pts=0, min.d.fix=0, min.consec=0, min.top.att=0, min.days.att=0,discard.overlapping=TRUE) {
  
  Sys.setenv(tz="GMT") 
  
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

  ### create output file
  nest.table=lapply(nest.output, function(x) x[-2])
  nest.table=lapply(nest.table,function(i) do.call("rbind",i))

  ## remove individuals that didn't breed
  data.bf.split.nn = data.bf.split[-which(unlist(lapply(nest.table,nrow))==0)]
  nest.table = nest.table[-which(unlist(lapply(nest.table,nrow))==0)]

  ## what to do if there were no nesting attempts
  if (length(nest.table)==0) 
    {
    logger.info("There were no nests detected in your data set. You might want to adapt your settings.") 
    result <- NULL
    } else
    {
    ## add age of birds (in days) to nest_location table
    nest.table.x <- foreach (nest.table.i = nest.table) %do% {
      data.bf.split.nn.i <- data.bf.split.nn[[which(names(data.bf.split.nn)==strsplit(nest.table.i$burst[1],"_")[[1]][1])]]
      nest.table.i$age = (difftime(nest.table.i$first_date,  min(as.Date(data.bf.split.nn.i$date)),units = "days"))
      
      ## count numbers of years that breeding has been attempted (0 is before any)
      data.bf.split.nn.i$breed_year = 0
      for (j in 1:nrow(nest.table.i)){
        data.bf.split.nn.i[as.Date(data.bf.split.nn.i$date)>nest.table.i[j,"first_date"],"breed_year"] = data.bf.split.nn.i[as.Date(data.bf.split.nn.i$date)>nest.table.i[j,"first_date"],"breed_year"]+1
      }
      
      ### calculate dispersal distance for each breeding attempt (distance to first point of individual GPS tracks)
      nest.table.i$dispersal_distance  <- apply(nest.table.i[,c("long","lat")],1,function(x) pointDistance(data.bf.split.nn.i[1,c("long","lat")],x,lonlat=TRUE))
      
      nest.table.i
    }
    names(nest.table.x) <- names(nest.table)
    
    nest.table.df = dplyr::bind_rows(nest.table.x, .id = "individual.local.identifier")
    #write.csv(nest.table.df,"nest_table.csv",row.names=FALSE)
    write.csv(nest.table.df,paste0(Sys.getenv(x = "APP_ARTIFACTS_DIR", "/tmp/"),"nest_table.csv"),row.names=FALSE)
    
    ## here need info about sex from Movebank
    ## boxplot of dispersal distance vs sex (maybe also vs fate/max age)
    
    nest.table.df$sex <- apply(nest.table.df, 1, function(x) idData(data)$sex[make.names(idData(data)$local_identifier,allow_=FALSE)==x[1]])
    
    pdf(paste0(Sys.getenv(x = "APP_ARTIFACTS_DIR", "/tmp/"), "boxplot_dispersal.vs.sex.pdf"))
    #pdf("boxplot_dispersal.vs.sex.pdf")
    boxplot(nest.table.df$dispersal_distance~nest.table.df$sex,colours=rainbow(n=length(unique(nest.table.df$sex))),ylab="dispersal distance from natal nest (m)",xlab="sex")
    dev.off()
    
    #plot breeding movement in map with nest location (+buffer circle). one page per ID
    data.split <- move::split(data)
    nest.data <- foreach (nest.table.b = nest.table.df$burst) %do% {
      nest.table.i <- nest.table.df[nest.table.df$burst==nest.table.b,]
      datai <- data.split[[which(names(data.split)==nest.table.i$individual.local.identifier)]]
      nest.data.i <- datai[timestamps(datai)>=nest.table.i$first_date & timestamps(datai)<(nest.table.i$last_date+1)]
      nest.data.i
    }
    names(nest.data) <- nest.table.df$burst
   
    nest.data.nozero <- nest.data[unlist(lapply(nest.data, length) > 0)]
    result <- moveStack(nest.data.nozero) #return track segments in breeding modus
  }
  
  return(result) 

}