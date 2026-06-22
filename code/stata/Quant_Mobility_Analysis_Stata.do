**# Uploade DataSet

**#convert date to readable format
gen date2 = date(Date, "DMY")
format date2 %td

describe

gen site_name = SiteName
replace SiteName = lower(site_name)
replace site_name = trim(site_name)


**# Dropping the variables I am not using 

drop site_name Classification SiteType SSID Date

**# convert and ind to int


 destring Individuals, replace force

 
 rename Households households
 rename Individuals individuals
 rename SiteName site_name
 rename Country country
 rename date2 date
 
 
**# creting new site id in case some sites have the sam ename across countries
gen site_unique = country + "_" + site_name
encode site_unique, gen(site_id)

**# Check duplicates
 
 duplicates report site_name date
 duplicates report site_id date

**# Deal with duplicates
collapse (sum) households individuals, by(country date site_name site_id)

**# declare panel data
xtset site_id date

**# generate the change
gen change = individuals - L.individuals

summarize change

**# whether movement is mostly inflow or outflow how extreme movements are. the lines werent so clear so this was better

histogram change, normal ///
title("Distribution of Population Change Across IDP Sites") ///
xtitle("Change in Number of Individuals (Inflow / Outflow)") ///
ytitle("Frequency (Number of Observations)") ///
xlabel(-7000(2000)6000)

**#Change per country
histogram change, normal ///
by(country, title("Distribution of Population Change by Country")) ///
xtitle("Change in Number of Individuals (Inflow / Outflow)") ///
ytitle("Frequency (Number of Observations)") ///
xlabel(-7000(2000)6000)

**# if extreme values distort the graph

histogram change if change > -2000 & change < 2000, normal

**# Classify movement (makes it interpretable)
gen movement = ""
replace movement = "inflow" if change > 0
replace movement = "outflow" if change < 0
replace movement = "stable" if change == 0


**# then tabulate the change TOTAL
tab movement

**# tabulate change per country Shows movement distribution within each country Column percentages = ideal for comparison

tab movement country, col

**# Visualise the table better with both countries

graph bar (percent), over(movement) over(country) ///
title("Mobility Types by Country") ///
ytitle("Percentage")

**# ALternative dual visualisation Table

graph bar (percent), over(movement) by(country) ///
title("Mobility Types by Country") ///
ytitle("Percentage")

**# Visualite the table better TOTAL

graph bar (count), over(movement) ///
title("Distribution of Mobility Types") ///
ytitle("Number of Observations")

**# Better visulaisation with percentages instead

graph bar (percent), over(movement) ///
title("Proportion of Mobility Types") ///
ytitle("Percentage")

**# view mobility over time shows which country had more movement & when peaks happened
**# create country level averages

bysort country date: egen mean_change = mean(change)

**# Plot

twoway ///
(line mean_change date if country=="Mozambique") ///
(line mean_change date if country=="Zimbabwe"), ///
legend(label(1 "Mozambique") label(2 "Zimbabwe")) ///
title("Average Mobility Over Time") ///
ytitle("Average Change in Individuals")


**# Better visualisation by standadising
egen mean_ind = mean(individuals)
egen sd_ind = sd(individuals)

gen standardized = (individuals - mean_ind) / sd_ind

**# Then plotting
bysort country date: egen mean_std = mean(standardized)

twoway ///
(line mean_std date if country=="Mozambique") ///
(line mean_std date if country=="Zimbabwe")

**# Clearer plot for layman

twoway ///
(line mean_std date if country=="Mozambique") ///
(line mean_std date if country=="Zimbabwe"), ///
legend(label(1 "Mozambique") label(2 "Zimbabwe")) ///
title("Relative Population Change Compared to Typical Site Size") ///
subtitle("Values show how unusual changes are relative to normal site populations") ///
ytitle("Relative Change (Standardised Units)") ///
xtitle("Date")


**# Create stability  indicator(safe, no issue)
bysort site_id: egen sd_pop = sd(individuals)

**# TEMPORARY collapse for comparison **# Country comparison Interpretation: low variation → immobility high variation → mobility 👉 Directly answers: "spectrum from immobility to movement"
preserve
collapse (mean) sd_pop, by(country)
list
restore


**# Return Dynamics 🧠 Interpretation: higher return_rate → more return movement compare timing across countries
**# Generate Proxy: declining site populations
gen return_proxy = change < 0

tab return_proxy country

**# Over time

bysort country date: egen return_rate = mean(return_proxy)

**# Plot 

twoway ///
(line return_rate date if country=="Mozambique") ///
(line return_rate date if country=="Zimbabwe")

**# Governance Comparison
**# 1. Speed of change Shows reporting / intervention rhythm This measures how frequently sites are updated / change is recorded
bysort site_id (date): gen time_diff = date - L.date

**# Clean it first

drop if missing(time_diff)

**# visualise distribution of reporting gaps

histogram time_diff, ///
title("Time Between Observations at IDP Sites") ///
xtitle("Number of Days Between Reports") ///
ytitle("Frequency")

**# Country Comparison

graph box time_diff, over(country) ///
title("Reporting Frequency by Country") ///
ytitle("Days Between Observations")

**#Interpretation:Smaller values → more frequent monitoring / intervention Larger values → less oversight / slower response This links directly to governance capacity


**# 2. Volatility by country (More volatility = less controlled system) 
bysort country: egen volatility = sd(change)
**# Visualise it with graph

graph bar (mean) volatility, over(country) ///
title("Volatility of Population Change by Country") ///
ytitle("Standard Deviation of Population Change")

**# Explanation. High volatility → chaotic / reactive movement Low volatility → stable / controlled mobility

graph bar (mean) volatility, over(country) ///
title("Instability of Population Movements by Country") ///
subtitle("Higher values indicate more unpredictable changes in site populations") ///
ytitle("Variation in Population Change")

**# E. SCALE vs DISTRIBUTION (important insight)You already noticed this:👉 Mozambique = larger numbers👉 Zimbabwe = smaller / flatter
bysort country: egen mean_pop = mean(individuals)
bysort country: egen sd_pop2 = sd(individuals)

**# Average Population (SCALE)
graph bar (mean) mean_pop, over(country) ///
title("Average IDP Site Population by Country") ///
ytitle("Average Number of Individuals per Site")

**# Variation in site size
graph bar (mean) sd_pop2, over(country) ///
title("Variation in Site Population Sizes") ///
ytitle("Standard Deviation of Site Population")

**# Scatter Plot to combine both

twoway ///
(scatter sd_pop2 mean_pop if country=="Mozambique") ///
(scatter sd_pop2 mean_pop if country=="Zimbabwe"), ///
legend(label(1 "Mozambique") label(2 "Zimbabwe")) ///
title("Scale vs Distribution of IDP Sites") ///
xtitle("Average Site Population") ///
ytitle("Variation in Site Population")

**# Reporting
**# it's messy I will likely not use it but good for missing data section

bysort country date: gen reports = 1
bysort country date: egen total_reports = sum(reports)

twoway ///
(line total_reports date if country=="Mozambique") ///
(line total_reports date if country=="Zimbabwe"), ///
title("Number of Reporting Sites Over Time") ///
ytitle("Number of Active Site Reports") ///
xtitle("Date")

gen missing_data = missing(individuals) | missing(site_name) 

tab missing_data country