import delimited using IHME_GBD_2015_OBESITY_PREVALENCE_1980_2015_Y2017M06D12.CSV , clear

keep if location_name == "United Kingdom" & sex == "Both" & year == 2015 & metric == "Percent"
capdrop location* sex* year measure metric
list


import delimited using IHME_GBD_2015_OVERWEIGHT_PREVALENCE_1980_2015_Y2017M06D12.CSV , clear

keep if location_name == "United Kingdom" & sex == "Both" & year == 2015 & metric == "Percent"
capdrop location* sex* year measure metric
list

