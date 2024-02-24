library(readxl) #for loading Excel files
library(dplyr) #for data processing/cleaning
library(tidyr) #for data processing/cleaning
library(skimr) #for nice visualization of data
library(here)  #to set paths
library(ggplot2)

#path to data
data_location <- here::here("data","raw-data","superstoredata.csv")
raw_data <- read.csv(data_location)
#Check data
dplyr::glimpse(raw_data)
head(raw_data)
tail(raw_data)
summary(raw_data)
str(raw_data)
skimr::skim(raw_data) #gives missing nos., completion rate, min, max, empty, n_unique, whitespace,mean, standard deviaiont and percentile 

#By inspecting the data, we find some problems that need to be addressed:

#First, there are 135080 missing values in CustomerID. The analysis looks into customer behaviors for which the unique customer ID is an essential part of the study.
#Hence, the observations without CustomerID do not provide meaningful analysis. Such observations are dropped for analyses. Further 
#CustomerID is loaded as a numerical variable in the data and it needs to be converted to categorical/factor variable
#Further Country is also converted to a factor.


# Subset the data by excluding rows where CustomerID is NA
  clean_data_step1 <- raw_data %>%
  filter(!is.na(CustomerID)) %>%
  mutate(CustomerID = as.factor(CustomerID),
         Country = as.factor(Country),
         Description = as.factor(Description),
         StockCode = as.factor(StockCode))

# Check the dimensions of the cleaned dataset
dim(clean_data_step1)

#There are negative values in quantity, unit price and sales due to order cancellation. Let's inspect how many of such data are there
# Filter observations where Quantity, UnitPrice, and Sales are negative
negative_sales <- clean_data_step1 %>%
  filter (Quantity < 0 & Sales < 0)

# View the filtered observations
count(negative_sales)
#There are 8905 observations where either Quantity and Sales are negative.

#I check to see if there is a corresponding sales (+ve entry) for these returned items. 

positive_sales <- clean_data_step1 %>%
  filter(Quantity > 0 & Sales > 0)
count(positive_sales)

#Attempt to match each negative Sale/Quantity with a corresponding positive sale by CustomerID and StockCode
matched_sales <- negative_sales %>%
  rowwise() %>%
  mutate(match_found = any(StockCode %in% positive_sales$StockCode &
                             CustomerID %in% positive_sales$CustomerID))

count(matched_sales)

#There are 8905 observations in sales which matched the observations with the -ve numbers. 
#My next attempt is to match returns to their original sales and get rid of the matched transactions.
#However, this needs further work as the stated codes are not resulting 8905 observations in original sales.
#The code below gives only 3072 matches which is inconsistent with the 8905 original -ve quantities and Sales.


# Add an identifier to each row in both datasets to track them
"negative_sales <- negative_sales %>% mutate(neg_id = row_number())
positive_sales <- positive_sales %>% mutate(pos_id = row_number())

# Initialize a vector to keep track of matched negative_sales' IDs
matched_neg_ids <- integer(0)

# Initialize an empty data frame to store matches
matches <- data.frame(neg_id = integer(), pos_id = integer())"

# Iterate over positive_sales to find matches in  (Marked as comment because it takes a longer time to run this code)
"for (pos_row in 1:nrow(positive_sales)) {
  pos_sale <- positive_sales[pos_row, ]
  
  # Attempt to match with negative_sales, excluding already matched rows
  potential_matches <- negative_sales %>%
    filter(
      !neg_id %in% matched_neg_ids, # Exclude already matched
      CustomerID == pos_sale$CustomerID,
      StockCode == pos_sale$StockCode,
      Quantity == -pos_sale$Quantity, # Matching negative of Quantity
      Sales == -pos_sale$Sales # Matching negative of Sales
    )
  
  if (nrow(potential_matches) > 0) {
    # If a match is found, take the first one
    first_match <- potential_matches[1, ]
    matched_neg_ids <- c(matched_neg_ids, first_match$neg_id)
    
    # Record the match
    matches <- rbind(matches, data.frame(neg_id = first_match$neg_id, pos_id = pos_sale$pos_id))
  }
}

# Extract matched rows based on IDs 
#matched_negative_sales <- negative_sales %>% filter(neg_id %in% matches$neg_id)
#matched_positive_sales <- positive_sales %>% filter(pos_id %in% matches$pos_id)"

# I dropped the observations with -ve Quantity and -ve Sales. As I was unable to find exact matches of original 
#transactions, I could not get rid of the matching original transactions. I will make further attempts in due course of this project. 

clean_data_step2 <- clean_data_step1 %>%
  filter(Quantity > 0, Sales > 0)

#Additional scrutiny is required in the distribution of Quantity, unit price and Sales, the higher values of these variable are
#concentrated at 100 percentile. I focused on distribution of UnitPrice at small intervals from 75% to 100%.

# Calculate higher percentiles within the 3rd quartile to max range
percentiles <- quantile(clean_data_step2$UnitPrice, probs = c(0.75, 0.90, 0.95, 0.99, 0.995, 0.996, 0.997, 0.998, 0.999, 1))
print(percentiles)

#From the results, it appears that there are only limited items that are above the unit price of 41.89. 
#So, I filtered the observations wherein UnitPrice is above 50. To find the description of those products,
#I filtered the observations with unit price above 50. It resulted into 241 observations

# Filter rows where UnitPrice is greater than 50
UnitPrice_above50 <- clean_data_step2[clean_data_step2$UnitPrice > 50, ]

#My next attempt was to check the no. of categoriesis description by running the following code which showed 14 categories.
n_distinct(UnitPrice_above50$Description)

#I wanted to see the uniqe descriptions, hence run the followig code.However, it showed more 3896 levels for 241 observations.
unique(UnitPrice_above50$Description)

# With the help of ChatGPT, I came to know that in R, when a subset of a data frame is created, the factor levels
#in the subset are not automatically dropped even if they are not present in the subset. To resolve this,
#the unused levels required to be dropped using the droplevels() function. 

# Dropping unused factor levels in the Description column
UnitPrice_above50$Description <- droplevels(UnitPrice_above50$Description)

# Finding the unique categories again
unique_categories <- unique(UnitPrice_above50$Description)

# Print the unique categories
print(unique_categories)

#The above code resulted into 14 categories of product description. Most of the high UnitPrice are related 
#to the descriptions such as Manual, POSTAGE, DOTCOM POSTAGE, appearing to be related to logistics. 
#I got rid of observations with all of those categories of description since those are less
#likely to be directly related to customer purchase.  

# Remove observations with specified descriptions
clean_data_step3 <- clean_data_step2[!grepl("Manual", clean_data_step2$Description) &
                                !grepl("POSTAGE", clean_data_step2$Description) &
                                !grepl("DOTCOM POSTAGE", clean_data_step2$Description), ]

# Convert InvoiceDate from character to POSIXct datetime format
clean_data_step3$InvoiceDate <- as.POSIXct(clean_data_step3$InvoiceDate, format = "%m/%d/%Y %H:%M")

# Inspect the cleaned data
skimr::skim(clean_data_step3)

#As this study focuses on only on the international sales, a sub-set excluding United Kingdom is created

# Exclude "United Kingdom" from the data set first
data_without_uk <- subset(clean_data_step3, Country != "United Kingdom")

skimr::skim(data_without_uk)

unique(clean_data_step3$Country)
sum(clean_data_step3$Country=="USA")
sum(clean_data_step3$Country=="United Kingdom")












