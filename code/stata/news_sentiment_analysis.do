* Convert publish_date to Stata date (adjust format if needed)
gen date = date(publish_date, "YMD")
format date %td

describe

preserve

collapse (mean) positive negative neutral compound

display "Overall Sentiment:"
list

restore
**# Sentiment by Country

preserve

collapse (mean) positive negative neutral compound, by(country)

sort compound
list

graph bar compound, over(country, sort(1)) ///
title("Average Sentiment by Country") ///
ytitle("Compound Score")

restore
**# By language

preserve

collapse (mean) positive negative neutral compound, by(language)

graph bar compound, over(language) ///
title("Average Sentiment by Language") ///
ytitle("Compound Score")

restore
**# Over time total

preserve

collapse (mean) compound, by(date)

tsset date

tsline compound, ///
title("Sentiment Over Time") ///
ytitle("Compound Score")

restore
**# Overtime per country

preserve

collapse (mean) compound, by(date country)

encode country, gen(country_id)

xtset country_id date

xtline compound, overlay ///
title("Sentiment by Country Over Time")

restore
**# Over time per language

preserve

collapse (mean) compound, by(date language)

encode language, gen(lang_id)

xtset lang_id date

xtline compound, overlay ///
title("Sentiment Over Time by Language")

restore

**# Articles over time

preserve
collapse (count) articles=compound, by(date)

tsset date

tsline articles, ///
title("Number of Articles Over Time") ///
ytitle("Count")

restore

**# Distribution of sentiment
histogram compound, normal ///
title("Distribution of Sentiment Scores")

**# Aggregated visualisation

preserve

keep if inlist(country, "Zimbabwe", "Mozambique") ///
    & inlist(language, "ENG", "PT")
	
collapse (mean) compound, by(date country language)

gen group = country + " - " + language

encode group, gen(group_id)
xtset group_id date

xtline compound, overlay ///
title("Sentiment Over Time: Country & Language Comparison") ///
ytitle("Compound Score")

restore
**# compound graph

preserve

collapse (mean) compound, by(country language)

graph bar compound, ///
over(language) over(country) ///
title("Average Sentiment by Country and Language")

restore
**# per country 

preserve

keep if inlist(country, "Zimbabwe", "Mozambique")

collapse (mean) compound, by(date country)
twoway ///
(line compound date if country=="Zimbabwe") ///
(line compound date if country=="Mozambique"), ///
legend(order(1 "Zimbabwe" 2 "Mozambique")) ///
title("Sentiment Over Time: Zimbabwe vs Mozambique") ///
ytitle("Compound Score")

restore