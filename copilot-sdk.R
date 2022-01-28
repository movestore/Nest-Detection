library(jsonlite)
source("logger.R")
source("RFunction.R")

inputFileName = "App-Output Workflow_Instance_001__Movebank__2022-01-28_10-50-08.rds"
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
args[["sea.start"]] = "2017-04-01T00:00:00.000Z"
args[["sea.end"]] = "2014-07-31T00:00:00.000Z"
args[["nest.cycle"]] = 28
args[["buffer"]] = 30
args[["min.pts"]] = 5
args[["min.d.fix"]] = 5
args[["min.consec"]] = 2
args[["min.top.att"]] = 75
args[["min.days.att"]] = 1
args[["discard.overlapping"]] = TRUE
args[["make.boxplot"]] = TRUE

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