### Introduction
This project aims to develop a predictive model for classifying those customers who returned during the holiday season versus those who did not return, by using a retail store data 'superstoredata.csv'.

### Acknowledgement
I followed the recommended template for file and folder organization from Dr. Andreas Handel, utilizing R, Quarto, and GitHub.

### Required Tools
To replicate this project, one needs to have a few programs on their computer: R and Quarto for analysis, GitHub to keep track of changes, and a reference manager that works with bibtex for organizing the sources. One will also need something like MS Word or LibreOffice to write and edit text. 

### Project Layout

* 'data' folder is the repository for all datasets used in the project. 
* 'R' folder and its subfolders store the programming scripts for data processing, exploratory analysis and main data analysis.
* 'results' folder and subfolders store outcomes, e.g. figures, tables.
* 'products' folder include manuscrits, supplementary materials, presentation slides, web apps, etc. 
* 'renv' folder is created by the renv package to manage package versions and dependencies.
* Additional README.md files within the folders contain additional information about the respective folders.

### Sequence of execution

(1) Run the processing file 'processing_superstore.qmd' at R\processing-code\ to clean the raw data 'superstoredata'. This step cleans the raw data and saves the cleaned data as processed_superstore.rds in data\processed-data\ which is ready for further analysis. 

(2) Run the eda_superstore.qmd at R\eda-code\ for exploratory analysis. 

(3) Run the file statistical-analysis_all.qmd in R\analysis-code to run the model. 

(4) Run Manuscript.qmd to see the final product of the project. This files store the results and display them. This file also pulls in references from the `bibtex` file and format them according to the CSL style.


