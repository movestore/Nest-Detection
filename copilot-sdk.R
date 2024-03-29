library(jsonlite)
source("logger.R")
source("RFunction.R")

inputFileName = "App-Output White_Storks_Germany__Filter_Data_by_Season__2022-07-05_09-43-59.rds"
#inputFileName = "App-Output Workflow_Instance_001__Remove_Outliers__2022-03-31_09-28-35.rds"
outputFileName = "output.rds"

args <- list()
#################################################################
########################### Arguments ###########################
# The data parameter will be added automatically if input data is available
# The name of the field in the vector must be exaclty the same as in the r function signature
# Example:
# rFunction = function(username, password)
# The paramter must look like:
#    args[["username"]] = "any-username"
#    args[["password"]] = "any-password"

# Add your arguments of your r function here
# LWFG: no nests detected with these settings
args[["sea.start"]] = "2016-03-01T00:00:00.000Z"
args[["sea.end"]] = "2016-08-30T00:00:00.000Z"
args[["nest.cycle"]] = 150
args[["buffer"]] = 40
args[["min.pts"]] = 5
args[["min.d.fix"]] = 5
args[["min.consec"]] = 80
args[["min.top.att"]] = 75
args[["min.days.att"]] = 1
args[["discard.overlapping"]] = TRUE

#################################################################
#################################################################
inputData <- NULL
if(!is.null(inputFileName) && inputFileName != "" && file.exists(inputFileName)) {
  cat("Loading file from", inputFileName, "\n")
  inputData <- readRDS(file = inputFileName)
} else {
  cat("Skip loading: no input File", "\n")
}

# Add the data paramter if input data is available
if (!is.null(inputData)) {
  args[["data"]] <- inputData
}

result <- tryCatch({
    do.call(rFunction, args)
  },
  error = function(e) {
    print(paste("ERROR: ", e))
    stop(e) # re-throw the exception
  }
)

if(!is.null(outputFileName) && outputFileName != "" && !is.null(result)) {
  cat("Storing file to", outputFileName, "\n")
  saveRDS(result, file = outputFileName)
} else {
  cat("Skip store result: no output File or result is missing", "\n")
}