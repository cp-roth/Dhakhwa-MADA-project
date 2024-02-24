## ---- packages --------
#load needed packages. make sure they are installed.
library(here) #for data loading/saving
library(dplyr)
library(skimr)
library(ggplot2)

## ---- loaddata --------
#Path to data. Note the use of the here() package and not absolute paths
data_location <- here::here("data","processed-data","processed_superstore.rds")
#load data
mydata <- readRDS(data_location)

## ---- table1 --------
summary_df = skimr::skim(mydata)
print(summary_df)
# save to file
summarytable_file = here("results", "summarytable.rds")
saveRDS(summary_df, file = summarytable_file)

## ---- Invoice Sales --------

# Histogram of Invoice values
## First calculate total invoice value per invoice
invoice_values <- mydata %>%
  group_by(InvoiceNo) %>%
  summarise(TotalInvoiceValue = sum(Sales, na.rm = TRUE))

##Create histogram
p1 <- ggplot(invoice_values, aes(x = TotalInvoiceValue)) +
  geom_histogram(binwidth = 50, fill = "lightblue", color = "darkblue") + # Adjust binwidth as needed
  labs(title = "Histogram of Total Invoice Values",
       x = "Total Invoice Value", 
       y = "Frequency") +
  theme_minimal()
plot(p1)

figure_file = here("results","figures","Sales_distribution.png")
ggsave(filename = figure_file, plot=p1) 

# Histogram of Invoice Quantity
## First calculate total invoice quantity per invoice
invoice_quantity <- mydata %>%
  group_by(InvoiceNo) %>%
  summarise(TotalInvoiceQuantity = sum(Quantity, na.rm = TRUE))

p2 <- ggplot(invoice_quantity, aes(x = TotalInvoiceQuantity)) +
  geom_histogram(binwidth = 50, fill = "lightblue", color = "darkblue") + # Adjust binwidth as needed
  labs(title = "Histogram of Total Invoice Quantity",
       x = "Total Invoice Quantity", 
       y = "Frequency") +
  theme_minimal()
plot(p2)

figure_file = here("results","figures","Quantity_distribution.png")
ggsave(filename = figure_file, plot=p2)

## ---- UnitPrice-Price range of products --------
# Create histogram of Unit Price

p3 <- ggplot(mydata, aes(x = UnitPrice)) +
  geom_histogram(binwidth = 1, fill = "lightblue", color = "darkblue") + # Adjust binwidth as needed
  labs(title = "Histogram of Unit Price",
       x = "Unit Price", 
       y = "Frequency") +
  theme_minimal()
plot(p3)

figure_file = here("results","figures","UnitPrice_distribution.png")
ggsave(filename = figure_file, plot=p3)


## ---- Sales per Customer --------
# Aggregate sales by CustomerID
sales_per_customer <- mydata %>%
  group_by(CustomerID) %>%
  summarise(TotalSales = sum(Sales, na.rm = TRUE)) %>%
  arrange(desc(TotalSales))

#Density Plot of Sales per Customer
# Assuming sales_per_customer is already calculated
p4 <- ggplot(sales_per_customer, aes(x = TotalSales)) +
  geom_density(fill = "blue", alpha = 0.5) +
  labs(title = "Density of Sales Across Customers", x = "Total Sales", y = "Density")

plot(p4)


figure_file = here("results","figures","Customer_AggregateSales.png")
ggsave(filename = figure_file, plot=p4)

## ---- Purchase frequency of customers --------
# Calculate purchase frequency per customer
purchase_frequency <- mydata %>%
  distinct(CustomerID, InvoiceNo) %>% # Ensure unique InvoiceNo per CustomerID
  count(CustomerID, name = "PurchaseFrequency") # Count the number of invoices per customer
library(ggplot2)

# Histogram of purchase frequencies
p5 <- ggplot(purchase_frequency, aes(x = PurchaseFrequency)) +
  geom_histogram(binwidth = 1, fill = "lightblue", color = "darkblue") + # Adjust binwidth as needed
  labs(title = "Histogram of Customer Purchase Frequencies",
       x = "Purchase Frequency", 
       y = "Count of Customers") +
  theme_minimal()
plot(p5)
figure_file = here("results","figures","Customer_purchasefreq.png")
ggsave(filename = figure_file, plot=p5)

## ---- Sales by Purchase frequency --------

# Calculate purchase frequency and total invoice value per customer
customer_stats <- mydata %>%
  group_by(CustomerID) %>%
  summarise(PurchaseFrequency = n_distinct(InvoiceNo),
            TotalInvoiceValue = sum(Sales, na.rm = TRUE)) %>%
  ungroup()  # Ensure the data is ungrouped for further analysis

# Scatter plot of Total Invoice Value by Purchase Frequency
p6 <- ggplot(customer_stats, aes(x = PurchaseFrequency, y = TotalInvoiceValue)) +
  geom_point(alpha = 0.5) +  # Adjust alpha for point transparency, if needed
  geom_smooth(method = "lm", se = FALSE, color = "red") +  # Add a linear regression line without standard error
  labs(title = "Total Invoice Value by Purchase Frequency",
       x = "Purchase Frequency",
       y = "Total Invoice Value") +
  theme_minimal()
plot(p6)


figure_file = here("results","figures","Sales_trend.png")
ggsave(filename = figure_file, plot=p6)




#Sales Over Time: Line chart to visualize sales trend
p7 <- ggplot(mydata, aes(x = InvoiceDate, y = Sales)) + 
  geom_line() + 
  scale_x_datetime(date_breaks = "1 month", date_labels = "%b %Y") + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

plot(p7)


figure_file = here("results","figures","Sales_trend.png")
ggsave(filename = figure_file, plot=p7)

#Sales Distribution by Country: A bar chart can be useful to compare total sales across different countries.
p8 <- mydata %>% 
  group_by(Country) %>% 
  summarise(TotalSales = sum(Sales)) %>%
  ggplot(aes(x = reorder(Country, TotalSales), y = TotalSales, fill = Country)) + 
  geom_bar(stat = "identity") + 
  coord_flip() + 
  theme(legend.position = "none")

plot(p8)

figure_file = here("results","figures","Countrywise_Sales.png")
ggsave(filename = figure_file, plot=p8)


