#############################################
##           ENTIRE SAMPLE SCRIPT          ##
#############################################

#Step 1: Prep and Import Data
#Initialize some variables to specify the data sets.
github <- "https://raw.githubusercontent.com/Microsoft/RTVS-docs/master/examples/MRS_and_Machine_Learning/Datasets/"
inputFileFlightURL <- paste0(github, "Flight_Delays_Sample.csv")
inputFileWeatherURL <- paste0(github, "Weather_Sample.csv")

#Create a temporary directory to store the intermediate XDF files. 
td <- tempdir()
outFileFlight <- paste0(td, "/flight.xdf")
outFileWeather <- paste0(td, "/weather.xdf")
outFileOrigin <- paste0(td, "/originData.xdf")
outFileDest <- paste0(td, "/destData.xdf")
outFileFinal <- paste0(td, "/finalData.xdf")

#Import the flight data.
flight_mrs <- rxImport(
  inData = inputFileFlightURL, outFile = outFileFlight,
  missingValueString = "M", stringsAsFactors = FALSE,
  # Remove columns that are possible target leakers from the flight data.
  varsToDrop = c("DepDelay", "DepDel15", "ArrDelay", "Cancelled", "Year"),
  # Define "Carrier" as categorical.
  colInfo = list(Carrier = list(type = "factor")),
  # Round down scheduled departure time to full hour.
  transforms = list(CRSDepTime = floor(CRSDepTime/100)),  
  overwrite = TRUE
)

#Review the first 6 rows of flight data.
head(flight_mrs)

#Summarize the flight data.
rxSummary(~., data = flight_mrs, blocksPerRead = 2)

#Import the weather data.
xform <- function(dataList) {
  # Create a function to normalize some numerical features.
  featureNames <- c(
    "Visibility", 
    "DryBulbCelsius", 
    "DewPointCelsius", 
    "RelativeHumidity", 
    "WindSpeed", 
    "Altimeter"
  )
  dataList[featureNames] <- lapply(dataList[featureNames], scale)
  return(dataList)
}

weather_mrs <- rxImport(
  inData = inputFileWeatherURL, outFile = outFileWeather,
  missingValueString = "M", stringsAsFactors = FALSE,
  # Eliminate some features due to redundance.
  varsToDrop = c("Year", "Timezone", 
                 "DryBulbFarenheit", "DewPointFarenheit"),
  # Create a new column "DestAirportID" in weather data.
  transforms = list(DestAirportID = AirportID),
  # Apply the normalization function.
  transformFunc = xform,  
  transformVars = c(
    "Visibility", 
    "DryBulbCelsius", 
    "DewPointCelsius", 
    "RelativeHumidity", 
    "WindSpeed", 
    "Altimeter"
  ),
  overwrite = TRUE
)

#Review the variable information for the weather data.
rxGetVarInfo(weather_mrs)


#Step 2: Pre-process Data
#Rename some column names in the weather data to prepare it for merging.
newVarInfo <- list(
  AdjustedMonth = list(newName = "Month"),
  AdjustedDay = list(newName = "DayofMonth"),
  AirportID = list(newName = "OriginAirportID"),
  AdjustedHour = list(newName = "CRSDepTime")
)
rxSetVarInfo(varInfo = newVarInfo, data = weather_mrs)

#Concatenate/Merge flight records and weather data.
##Join flight records and weather data at origin of the flight `OriginAirportID`.
originData_mrs <- rxMerge(
  inData1 = flight_mrs, inData2 = weather_mrs, outFile = outFileOrigin,
  type = "inner", autoSort = TRUE, 
  matchVars = c("Month", "DayofMonth", "OriginAirportID", "CRSDepTime"),
  varsToDrop2 = "DestAirportID",
  overwrite = TRUE
)

##Join flight records and weather data using the destination of the flight `DestAirportID`.
destData_mrs <- rxMerge(
  inData1 = originData_mrs, inData2 = weather_mrs, outFile = outFileDest,
  type = "inner", autoSort = TRUE, 
  matchVars = c("Month", "DayofMonth", "DestAirportID", "CRSDepTime"),
  varsToDrop2 = c("OriginAirportID"),
  duplicateVarExt = c("Origin", "Destination"),
  overwrite = TRUE
)

##Call `rxFactors()` function to convert `OriginAirportID` and `DestAirportID` as categorical.
rxFactors(inData = destData_mrs, outFile = outFileFinal, sortLevels = TRUE,
          factorInfo = c("OriginAirportID", "DestAirportID"),
          overwrite = TRUE)


#Step 3: Prepare Training and Test Datasets
#Randomly split data (80% for training, 20% for testing).
rxSplit(inData = outFileFinal,
        outFilesBase = paste0(td, "/modelData"),
        outFileSuffixes = c("Train", "Test"),
        splitByFactor = "splitVar",
        overwrite = TRUE,
        transforms = list(
          splitVar = factor(sample(c("Train", "Test"),
                                   size = .rxNumRows,
                                   replace = TRUE,
                                   prob = c(.80, .20)),
                            levels = c("Train", "Test"))),
        rngSeed = 17,
        consoleOutput = TRUE)

#Point to the XDF files for each set.
train <- RxXdfData(paste0(td, "/modelData.splitVar.Train.xdf"))
test <- RxXdfData(paste0(td, "/modelData.splitVar.Test.xdf"))


#Step 4: Predict using Logistic Regression
#Choose and apply the Logistic Regression learning algorithm.

#Build the formula.
modelFormula <- formula(train, depVars = "ArrDel15",
                        varsToDrop = c("RowNum", "splitVar"))

#Fit a Logistic Regression model.
logitModel_mrs <- rxLogit(modelFormula, data = train)

#Review the model results.
summary(logitModel_mrs)

#Predict using new data.
#Predict the probability on the test dataset.
rxPredict(logitModel_mrs, data = test,
          type = "response",
          predVarNames = "ArrDel15_Pred_Logit",
          overwrite = TRUE)

#Calculate Area Under the Curve (AUC).
paste0("AUC of Logistic Regression Model:",
       rxAuc(rxRoc("ArrDel15", "ArrDel15_Pred_Logit", test)))

#Plot the ROC curve.
#rxRocCurve("ArrDel15", "ArrDel15_Pred_Logit", data = test,
#           title = "ROC curve - Logistic regression")

#Step 5: Predict using Decision Tree
#Choose and apply the Decision Tree learning algorithm.
#Build a decision tree model.
dTree1_mrs <- rxDTree(modelFormula, data = train, reportProgress = 1)

#Find the Best Value of cp for Pruning rxDTree Object.
treeCp_mrs <- rxDTreeBestCp(dTree1_mrs)

#Prune a decision tree created by rxDTree and return the smaller tree.
dTree2_mrs <- prune.rxDTree(dTree1_mrs, cp = treeCp_mrs)

#Predict using new data.
#Predict the probability on the test dataset.
rxPredict(dTree2_mrs, data = test, 
          overwrite = TRUE)

#Calculate Area Under the Curve (AUC).
paste0("AUC of Decision Tree Model:",
       rxAuc(rxRoc("ArrDel15", "ArrDel15_Pred", test)))

#Plot the ROC curve.
#rxRocCurve("ArrDel15",
#           predVarNames = c("ArrDel15_Pred", "ArrDel15_Pred_Logit"),
#           data = test,
#           title = "ROC curve - Logistic regression")          
