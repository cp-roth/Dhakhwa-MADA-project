# Introduction
This project aims to develop a predictive model for customer segmentation by using a retail store data 'superstoredata.csv'.

# Acknowledgement
I followed the recommended template for file and folder organization from Dr. Andreas Handel, utilizing R, Quarto, and GitHub for this purpose.

# Required Tools
To replicate this project, one needs to have a few programs on their computer: R and Quarto for analysis, GitHub to keep track of changes, and a reference manager that works with bibtex for organizing the sources. One will also need something like MS Word or LibreOffice to write and edit text. 

# Project Layout

* 'Data' folder is the repository for all datasets used in the project. 
* 'Code' folder and its subfolders store the programming scripts for data processing, exploratory analysis and main data analysis.
* Results folder and subfolders store outcomes, e.g. figures, tables.
* Products folder include manuscrits, supplementary materials, presentation slides, web apps, etc. 
* The renv folder is created by the renv package to manage package versions and dependencies.
* Additional README.md files within the folders contain additional information about the respective folders.

#Sequence of execution

(1) Run the processing file 'processing_superstore-v1.qmd' at R\processing-code\ to clean the raw data 'superstoredata'. This step cleans the raw data and saves the cleaned data as processed_superstore_RFM.rds in data\processed-data\ which is ready for further analysis. 

(2) Run the eda_superstore.qmd at R\eda-code\ for exploratory analysis. 

(3) Run the file statistical-analysis_superstoreRFM in R\analysis-code to run the model. 

(4) Run Manuscript, poster and/or slides to see the final product of the project. Those files store the results and display them. These files also pull in references from the `bibtex` file and format them according to the CSL style.


Following the analysis, the manuscript, poster, and slides example files can be executed in any sequence. These documents incorporate the results obtained from the analysis. Each of these documents (manuscript, poster, slides) will also extract references from the bibtex file, organizing them according to the chosen CSL style, ensuring that citations are correctly formatted.