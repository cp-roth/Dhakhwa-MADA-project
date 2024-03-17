###############################
# analysis script
#
#this script loads the processed, cleaned data, does a simple analysis
#and saves the results to the results folder

#loading packages needed. 
library(here) #for data loading/saving
library(tidymodels) # for the parsnip package, along with the rest of tidymodels
library(ggplot2) #for plotting
library(dplyr) #for data wrangling
library(broom) #for cleaning up output from lm()
library(lubridate)
library(glmnet) #for fitting GLM via penalized maximum likelihood
library(vip) # for visualizing the variable importance scores for the top 20 features
#library(ranger) #for random forest. Unable to sync this in renv

#path to data using the here() package
data_location <- here::here("data","processed-data","processed_superstore_RFM.rds")

#load data. 
mydata <- readRDS(data_location)

#Checking data
skimr::skim(mydata)
head(mydata)

#This study aims to use logistic regression to segment customers based on the their purchasing behavior reflected by 
#the monetary purchase amount and loyalty of the customer   
#In absence of a readily available classification variable in the data, one will be created based on three factors:
# Recency, Frequency and Monetary. 
#Recency is the number of days since the last purchase by a customer. 
#Frequency is the no. of purchases by a customer over a given period.
#Monetary is the total amount of purchase a customer has made over a period. 

# For determining recency of a transaction, a reference date past the study period is required. The data covers transactions till 2011-12-09.
# The next day i.e. 2011-12-10 is considered as the reference date to define recency.

ref_date <- as.Date("2011-12-10")

# Next, a new data frame is created which includes the segments, Recency, Frequency and Monetary
rfm_data <- mydata %>%
  group_by(CustomerID) %>%
  summarise(
    Recent_Purchase_Date=last(InvoiceDate),
    Recency = as.numeric(ref_date - as.Date(max(InvoiceDate))),
    Frequency = n_distinct(InvoiceNo),
    Monetary = sum(InvoiceValue)
    
  ) %>%
  ungroup()

skimr::skim(rfm_data)

#Density Plot of Recency

p1 <- ggplot(rfm_data, aes(x = Recency)) +
  geom_density(fill = "blue", alpha = 0.5) +
  labs(title = "Density of Recency", x = "No. of days since last purchase", y = "Density")

plot(p1)

figure_file = here("results","figures","Recency.png")
ggsave(filename = figure_file, plot=p1)

#Each segment is additionally divided into 4 categories based on which quartile of Recency, Frequency and Monetary value the customer belongs to.
#For example a customer belonging to 3rd quartile of Recency, 1st quartile of Frequency and 4th quartile of Monetary value, will 
# get a value of 3 for Recency, 1 for Frequency and 4 for Monetary value columns.

# Creating quartiles
rfm_data <- rfm_data %>%
  mutate(
    R_Quartile = ntile(Recency, 4),
    F_Quartile = ntile(Frequency, 4),
    M_Quartile = ntile(Monetary, 4)
  )


# The value of 4 for F_Quartile and M_Quartile represents the preferred customer outcomes which are higher frequency and values of purchases respectively.  
# Contrarily, the value of 4 for R-Quartile indicates that the customer had not made a purchase in long time which is not a favorable outcome.
#To create a uniform direction of all three metric values, the original value of R_Quartile is subtracted by 5.
#With this adjustment, now the value 4 for R_Quartile indicates that the customer has recently purchased from the store.  

#Adjusting the quartile ranking for Recency metric
rfm_data$R_Quartile_adj <- 5 - rfm_data$R_Quartile

#Checking the data
skimr::skim(rfm_data)

#The customers are ranked in the order of their purchase amount, frequency of purchase and recent purchases, 
#a combined score (RFM_Score) is derived based on which quartile the customer falls in for each of these metrics.
#This score will be used to label valued customers.
 
rfm_data <- rfm_data %>%
  mutate(RFM_Score = M_Quartile*100 + F_Quartile * 10 + R_Quartile_adj)%>%
  arrange(desc(RFM_Score))

#Checking unique RFM_score in the data
unique_score <- unique(rfm_data$RFM_Score)
print(unique_score)
length(unique_score)

#Counting the no. of observations in unique RFM_scores
score_counts <- table(rfm_data$RFM_Score)
score_counts

summary(rfm_data$RFM_Score)
#There were 55 unique RFM scores identified.The top 25% percentage of customers have a RFM_score above 344.
#Setting 344 as a threshold for classifying customers as valued customers.
rfm_data$ValuedCust <- as.factor(ifelse(rfm_data$RFM_Score > 344, 1, 0))

#glimpse(rfm_data)

p2 <- ggplot(rfm_data, aes(x = ValuedCust)) +
  geom_bar(fill='light blue') +
  labs(title = "Customer Segment", x="Valued Customers",y = "Count")+
  theme_minimal()
plot(p2)

figure_file = here("results","figures","Customer_Segment.png")
ggsave(filename = figure_file, plot=p2)

#Creating data set for analysis
final_data <- rfm_data %>% select(Monetary, Frequency, Recency, ValuedCust)

################################################################
#Using penalized logistic regression with the help of tidymodels package (https://www.tidymodels.org/start/case-study/)

#Checking proportion of Valued Customers
final_data %>% 
  count(ValuedCust) %>%
  mutate(prop = n/sum(n))

set.seed(123) #For reproducibility

#using stratified random sampling as 'Valued Customer' is imbalanced
splits <- initial_split(final_data, strata = ValuedCust)

final_data_other <- training(splits)
final_data_test <- testing(splits)

#training set proportions by 'ValuedCust'

final_data_other %>%
  count(ValuedCust)%>%
  mutate(prop = n/sum(n))

#test set proportions by 'ValuedCust'
final_data_test %>%
  count(ValuedCust) %>%
  mutate(prop=n/sum(n))


set.seed(234)
#val_set <- validation_split(final_data_other,
 #                           strata = ValuedCust,
  #                          prop = 0.80)

#val_set

#Defining 4-fold cross-validation on the training data, using stratification

cv_folds<-vfold_cv(final_data_other, v=4, strata = ValuedCust)

#Using glmnet engine to specify a penalized logistic regression model
#tune()is model hyperparameter that will be used to tune to find the best 
#value for making predictions with the data.
#Setting mixture=1 potentially remove irrelevant predictors and choose a simple model

lr_mod <- 
  logistic_reg(penalty = tune(), mixture = 1)%>%
  set_engine("glmnet")

#Creating recipe. It helps preprocess the data before training the model.It is built as
# a series of pre-processing steps.
lr_recipe <- 
  recipe(ValuedCust ~ ., data = final_data_other)%>%
  #step_rm(CustomerID, Recent_Purchase_Date)%>% #removes variables
  #step_dummy(all_nominal_predictors())%>% #converts characters or factors into numeric binary model terms
  #step_zv(all_date_predictors())%>%  #remoces indicator variables that only contain a single unique value
  step_normalize(all_date_predictors()) #centers and scales numeric variable

#Creating the workflow: bundling the model and recipe into a single workflow()
#this makes management of the R objects easier.
lr_workflow <- 
  workflow() %>%
  add_model(lr_mod) %>%
  add_recipe(lr_recipe)

#Creating the grid for tuning using a one-column tibble with 30 candidate values:
lr_reg_grid <- tibble(penalty=10^seq(-4, -1, length.out=30))
lr_reg_grid %>% top_n(-5) #lowest penalty values
lr_reg_grid %>% top_n(5) # highest penalty values

#Training and tuning the model. Control_grid() saves the validation set predictions
#so that diagnostic information is available after the model fit.
#Area under ROC Curve measures the model performance across a continuum of event thresholds
lr_res <-
 # lr_workflow %>%
  #tune_grid(val_set,
   tune_grid(lr_workflow,
             resamples=cv_folds, #Using CV folds
             grid = lr_reg_grid,
            control = control_grid(save_pred = TRUE),
            metrics = metric_set(roc_auc))

#Visualizing the validation set metrics by plotting the area under the ROC curve
#against the range of penalty values
lr_plot <-
    lr_res%>%
    collect_metrics()%>%
    ggplot(aes(x=penalty, y=mean))+
    geom_point()+
    geom_line() +
    ylab("Area under the ROC Curve")+
    scale_x_log10(labels= scales::label_number())

lr_plot 

figure_file = here("results","figures","ROC(AUC)_Penalty.png")
ggsave(filename = figure_file, plot=lr_plot)

#The Area under ROC curve plot appeared unusual with extreme high values all over 0.9995. 

#Again using roc_auc metric to view multiple options for the "best" value

top_models <- 
  lr_res %>% 
  show_best("roc_auc", n=15) %>%
  arrange(penalty)
top_models

#Choosing the model where the curve start to decline 
lr_best <- lr_res %>% collect_metrics()%>% arrange(penalty) %>%
  slice(8)
lr_best

#Visualizing the validation set ROC curve
lr_auc <-
  lr_res %>% 
  collect_predictions(parameters = lr_best) %>%
  #names()
  roc_curve(ValuedCust, .pred_1)%>%
  mutate(model="Logistic Regression")

p4<-autoplot(lr_auc)

p4

figure_file = here("results","figures","ROC(AUC)_Validation.png")
ggsave(filename = figure_file, plot=p4)

#The curve stays below the diagonal line for the entire range of 1-specificity.
#The model choice does not seem to be appropriate for the data.
##############################################################################

#Re-checking the application of logistic regression without using cross-validation

data_split <- initial_split(final_data, prop = 0.80)
train_data <- training(data_split)
test_data <- testing(data_split)

#Checking proportion of Customer composition in training set
train_data %>% 
  count(ValuedCust)%>%
  mutate(prop=n/sum(n))

#Checking proportion of Customer composition in testing set
test_data%>%
  count(ValuedCust)%>%
  mutate(prop=n/sum(n))

# Defining the logistic regression model specification
logistic_spec <- logistic_reg() %>%
  set_engine("glm") %>%
  set_mode("classification")

# Fitting the model to the training data 
logistic_fit_all <- logistic_spec %>%
  fit(ValuedCust ~ Monetary + Frequency + Recency , data = train_data)

#The algorithm did not converge.
