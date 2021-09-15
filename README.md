# Nest Detection
MoveApps

Github repository: *github.com/movestore/Nest-Detection*

## Description
Detection of nest sites of attempted breeding with the function find_nests() of the R-package 'nestR'. Filters locations of breeding activity, provides a table of nesting properties and a boxplot comparing dispersal distance of males vs. females. Developed for white stork use case.

## Documentation
This App allows use of the find_nests() function of the R-package 'nestR' which is documented here: https://github.com/picardis/nestR and https://rdrr.io/github/picardis/nestR/. A scientific paper explaining and using the package can be found here: https://trello.com/c/NhVPfOIt/5-nest-site-detection.

All parameters that can be set in the function find_nests() can also be defined in the MoveApps settings. The range from the usual nesting duration of the species/population, the buffer area around the nest and the minimum percentage of locations per day necessary to be on the nest for it to be counted as breeding. See below for details.

The extraction of the attempted nest locations can take a while for larger data sets, follow the progress in the App's Logs. After the nest locations have been extracted, this App calculates additionally the age of the animals (assuming tagging in their natal nests), the number of breeding years and the dispersal distance of each breeding attempt from the natal nest. The latter is visualised as a boxplot of females and males (`boxplot_dispersal.pdf`). A csv table `nest_table.csv` of the nest properties is saved as an artefact, including information as the first and last day the nest was visited, the total number of nest visits, the attendance percentage in days and others (see find_nests() R documentation: https://rdrr.io/github/picardis/nestR/man/find_nests.html). Furthermore, age and dispersal_distance from the first location are provided in the csv file.

The output of the App is a data set of all the locations within each nesting attempt of each animal. Each year of each animal is thus handled as a separate track. These tracks can easily be explored in a mapping App like `Simple Leaflet Map`.

### Input data
moveStack in Movebank format

### Output data
moveStack in Movebank format


### Artefacts
`nest_table.csv`: Overview of all properties of detected nesting attempts.

`boxplot_dispersal.pdf`: boxplots of dispersal distances of all nesting attempts, separated by sex (extracted from Movebank).

### Parameters 
`sea_start`: Start date of breeding season. Narrowly specified breeding season windows give better results. The year of this provided date is irrelevant. Default 1 January.

`sea_end`: End date of breeding season. Narrowly specified breeding season windows give better results. The year of this provided date is irrelevant. Default 31 December.

`nest.cycle`: Duration (in days) of a complete nesting attempt, i.e. the time until the young have successfully hatched. Default 100 days.

`buffer`: Buffer radius (m) within which locations shall count as nest revisits. This often relates to your general location inaccuracy. Default 30.

`min.pts`: Minimum number of points within a buffer that need to fall within the buffer for a point to be considered as a potential nest candidate. Default 5.

`min.d.fit`: Minimum number of fixed locations that have to be available in a day with no visits for that day to be retained when counting consecutive days visited. (i.e. missed visit due to data sparseness). Default 5.

`min.consec`: Minimum necessary number of consecutive days visited in the longest series to be considered breeding attempt. Default 80.

`min.top.att`: Minimum necessary percentage of fixes at the location on the day with most visits to be considered a breeding attempt. Default 75.

`min.days.att`: Minimum percentage of days a buffer location has to be visited between the days of the first and last visit to be considered breeding attempt. Default 1.

`discard.overlapping`: Indication if to select only one breeding attempt if some of the detected breeding attempts temporally overlap. Default: true.


### Null or error handling:
**Data:** All locations in breeding attempts are returned as output. If there are no breeding attempts detected in your data set the output might be NULL leading to errors. A warning is given in the App Logs.