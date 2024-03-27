
The subfolders in this folder contains R and Quarto script files executing differnt actions. 

Processing-code folder contains a QMD file which loads the raw data superstoredata.csv, cleans it and stores it as processed_superstore_RFM.rds in the processed-data folder of the data folder. This script SHOULD BE RUN first before the exploratory and/or statistical analysis. 

eda-code folder contains a Quarto file which runs exploratory analysis of the processed data, processed_superstore_RFM.rds and stores figures in results/figures folder and tables in the  results/tables folder. 

analysis-code folder contains a R file which performs statistical analysis of the processed data, processed_superstore_RFM.rds. 