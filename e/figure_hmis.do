/*
This do file creates graphs to explore hmis data.
Index

1. Scaled Vaccinations/Services per hospital (For districts reporting in May)
2. Scaled Vaccinations/Services per hospital (For districts reporting in June)
3. Hospitals reporting over time [For all Districts reporting]
4. Vaccinations/ Health Services over time(For districts reporting in May)
5. Scaled Hospital Services over time for districts reporting in May
6. Scaled Hospital Services Per Hospital over time for districts reporting in May
7. Vaccinations over time(For districts reporting in June)
8. Graph Scaled Hospital Services over time for districts reporting in June
9. Scaled Hospital Services Per Hospital over time for districts reporting in June
10. Scaled Inpatient Services per hospital over time for districts reporting in June

*/


/*********************************************************************************/
/* 1. Scaled Vaccinations/Services per hospital (For districts reporting in May) */
/*********************************************************************************/

/* Graph Scaled Vaccinations Per Hospital Over time */
/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in May */
keep if year == 2020 & month == 5 & category == "Total [(A+B) or (C+D)]"
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions) | mi(hm_hosp_total)
keep state district

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_vach_may `r(N)'

/* Merge with hmis data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Summarise Data at the month level */
collapse (sum) hm_vac* hm_hosp_total, by(month)

/* Scale vaccinations by the total number of hospitals reporting these */
foreach v of varlist  hm_vac*{
  replace `v' = `v'/hm_hosp_total  
}

/* Scale every vaccination variable by its first value(In January 2020) */
foreach v of varlist  hm_vac* hm_hosp_total {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data till May */
keep if month <= 5

/* List variables to Sanity Check */
li hm_vac_bcg-hm_hosp_total

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month) ///
    (line hm_hosp_total month), ///
    title("Vaccinations at Birth Per Hospital") ///
    subtitle("For The `number_of_districts_vach_may' Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions") label(5 "Total Hospitals Reporting (For This Sample)") ) 
    
graphout vaccinations_per_hospital_may

/**********************************************************************************/
/* 2. Scaled Vaccinations/Services per hospital (For districts reporting in June) */
/**********************************************************************************/

/* Graph Scaled Vaccinations Per Hospital Over time */
/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in June */
keep if year == 2020 & month == 6 & category == "Total [(A+B) or (C+D)]"
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions) | mi(hm_hosp_total)
keep state district

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_vach_june `r(N)'

/* Merge with HMIS data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Summarise Data at the month level */
collapse (sum) hm_vac* hm_hosp_total, by(month)

/* Scale vaccinations by the total number of hospitals reporting these */
foreach v of varlist  hm_vac*{
  replace `v' = `v'/hm_hosp_total  
}

/* Scale every vaccination variable by its first value(In January 2020) */
foreach v of varlist  hm_vac* hm_hosp_total{
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data till June  */
keep if month <= 6

/* List variables to Sanity Check */
li hm_vac_bcg-hm_hosp_total

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month) ///
    (line hm_hosp_total month), ///
    title("Vaccinations at Birth Per Hospital") ///
    subtitle("For The `number_of_districts_vach_june' Districts That Reported in June") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  label(5 "Total Hospitals Reporting (For This Sample") ) 

graphout vaccinations_per_hospital_june

/******************************************************************/
/* 3. Hospitals reporting over time [For all Districts reporting] */
/******************************************************************/

/* Graph Scaled Hospital Reporting over time for All Districts Reporting */
/* Note number of districts reporting thse could be differnt for differnt months,
  we just want to get an idea of how many hospitals are reporting as an aggregate*/

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_tot_hosp `r(N)'

/* Summarise Data at the month level */
collapse (sum) hm_hosp_chc hm_hosp_phc hm_hosp_sc hm_hosp_sdh hm_hosp_dh hm_hosp_total, by(month)

foreach v of varlist hm_hosp* {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep Data till April */
keep if month<= 6

/* Sanity Check Variables */
li hm_hosp_chc-hm_hosp_total

/* Graph twoway lineplot of changing hospital services over time in 2020 */
twoway (line hm_hosp_chc month) ///
    (line hm_hosp_phc  month) ///
    (line hm_hosp_sc month) ///
    (line hm_hosp_sdh month) ///
    (line hm_hosp_dh month) ///
    (line hm_hosp_total month), ///
    title("Total Hospitals Reporting Data") ///
    subtitle("For All Districts Reporting in that month") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend( label(1 "Community Health Centers") label(2 "Primary Health Centers") label(3 "Sub Centers") label(4 "Sub District Hospitals") label(5 "District Hospitals") label(6 "Total Hospital")  ) 
    
graphout hospitals_reporting_all

/******************************************************************************/
/* 4. Vaccinations/ Health Services over time(For districts reporting in May) */
/******************************************************************************/

/* Graph Scaled Vaccinations Over time */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in May */
keep if year == 2020 & month == 5 & category == "Total [(A+B) or (C+D)]"
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions)
keep state district

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_vac_may `r(N)'

/* Merge the districts with non-missing data for required variables with complete health data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Summarise Data at the month level */
collapse (sum) hm_vac*, by(month)

/* Scale every vaccination variable by its first value(In January 2020) */
foreach v of varlist  hm_vac*{
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data till May */
keep if month <= 5

/* Sanity Check Variables */
li hm_vac_bcg-hm_vac_sessions

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month), ///
    title("Vaccinations at Birth") ///
    subtitle("For The `number_of_districts_vac_may' Districts That Reported In May") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  )
    
graphout vaccinations_may

/************************************************************************/
/* 5. Scaled Hospital Services over time for districts reporting in May */
/************************************************************************/

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in May */
keep if year == 2020 & month == 5 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Keep only those districts in May that report for these hospital services */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient) 

/* Keep the state/district identifiers for districts in May reporting the chosen health services */
keep state district

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_hs_may `r(N)'

/* Merge to keep only these districts in main data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Summarise Data at the month level */
collapse (sum) hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient, by(month)

/* Scale Health Services by their value in January */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep Data Till May */
keep if month <= 5

/* Sanity Check Variables */
li hm_outpatient_diabetes-hm_inpatient

/* Graph twoway lineplot of changing hospital services over time in 2020 */
twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month), ///
    title("Health Services Provided") ///
    subtitle("For The `number_of_districts_hs_may' Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total")) 
    
graphout hospital_services_may

/*************************************************************************************/
/* 6. Scaled Hospital Services Per Hospital over time for districts reporting in May */
/*************************************************************************************/

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in May */
keep if year == 2020 & month == 5 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Keep only those districts in May that report for these hospital services */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient) | mi(hm_hosp_total)

/* Keep the state/district identifiers for districts in May reporting the chosen health services */
keep state district
count

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_hsh_may `r(N)'

/* Merge to keep only these districts in main data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Summarise Data at the month level */
collapse (sum) hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major hm_hosp_total, by(month)

/* Scale vaccinations by the total number of hospitals reporting these */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major  {
  replace `v' = `v'/hm_hosp_total  
}

/* Scale the hospital services by their value in January */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major hm_hosp_total {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data only till May */
keep if month <= 5

/* List out variable values for sanity check */
li hm_outpatient_diabetes-hm_hosp_total

/* Graph twoway lineplot of changing hospital services over time in 2020 */

twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month) ///
    (line hm_operation_major month) ///
    (line hm_hosp_total month), ///
    title("Health Services Provided Per Hospital") ///
    subtitle("For The `number_of_districts_hsh_may' Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total") label(4 "Operations(Major)") label(5 "Total Hospitals Reporting (For this Sample)") ) 
    
graphout hospital_services_per_hospital_may


/**************************************************************/
/* 7. Vaccinations over time(For districts reporting in June) */
/**************************************************************/

/* Graph Scaled Vaccinations Over time */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in June */
keep if year == 2020 & month == 6 & category == "Total [(A+B) or (C+D)]"
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions)
keep state district

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_vac_june `r(N)'

/* Merge with HMIS Data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Summarise Data at the month level */
collapse (sum) hm_vac*, by(month)

/* Scale every vaccination variable by its first value(In January 2020) */
foreach v of varlist  hm_vac*{
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data till June */
keep if month <= 6

/* Sanity Check Variables */
li hm_vac_bcg-hm_vac_sessions

/* Get month to display properly */

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month), ///
    title("Vaccinations at Birth") ///
    subtitle("For The `number_of_districts_vac_june' Districts That Reported in June") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  ) 
    
graphout vaccinations_june

/*******************************************************************************/
/* 8. Graph Scaled Hospital Services over time for districts reporting in June */
/*******************************************************************************/

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in June */
keep if year == 2020 & month == 6 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Keep only those districts in June that report for these hospital services */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient) 

/* Keep the state/district identifiers for districts in June reporting the chosen health services */
keep state district
count

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_hs_june `r(N)'

/* Merge to keep only these districts in main data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Summarise Data at the month level */
collapse (sum) hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient, by(month)

/* Scale Health Services by their value in January */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep Data Till June */
keep if month <= 6

/* Sanity Check Variables */
li hm_outpatient_diabetes-hm_inpatient

/* Graph twoway lineplot of changing hospital services over time in 2020 */
twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month), ///
    title("Health Services Provided") ///
    subtitle("For The `number_of_districts_hs_june' Districts That Reported in June") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total")) 
    
graphout hospital_services_june

/**************************************************************************************/
/* 9. Scaled Hospital Services Per Hospital over time for districts reporting in June */
/**************************************************************************************/

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in June */
keep if year == 2020 & month == 6 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m + hm_inpatient_respiratory
drop hm_inpatient_*

/* Keep only those districts in June that report for these hospital services */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient) | mi(hm_operation_major) | mi(hm_emergency_total) | ///
   mi( hm_hosp_total)

/* Keep the state/district identifiers for districts in June reporting the chosen health services */
keep state district
count

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_hsh_june `r(N)'

/* Merge to keep only these districts in main data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m + hm_inpatient_respiratory
drop hm_inpatient_*

/* Summarise Data at the month level */
collapse (sum) hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major hm_hosp_total, by(month)

li hm_outpatient_diabetes-hm_hosp_total

/* Scale vaccinations by the total number of hospitals reporting these */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major {
  replace `v' = `v'/hm_hosp_total  
}

li hm_outpatient_diabetes-hm_hosp_total

/* Scale the hospital services by their value in January */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major hm_hosp_total {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data only till June */
keep if month <= 6

/* List out variable values for sanity check */
li hm_outpatient_diabetes-hm_hosp_total

/* Graph twoway lineplot of changing hospital services over time in 2020 */

twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month) ///
    (line hm_operation_major month) ///
    (line hm_hosp_total month), ///
    title("Health Services Provided Per Hospital") ///
    subtitle("For The `number_of_districts_hsh_june' Districts That Reported in June") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion")  label(3 "Inpatient Total") label(4 "Operations(Major)") label(5 "Total Hospitals(For this sample)") ) 


graphout hospital_services_per_hospital_june

/***********************************************************************************************/
/* 10. Graph: Scaled Inpatient Services per hospital over time for districts reporting in June */
/***********************************************************************************************/

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in June */
keep if year == 2020 & month == 6 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
//gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m + hm_inpatient_respiratory
//drop hm_inpatient_*

/* Keep only those districts in June that report for these hospital services */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient_adult_f) | ///
    mi(hm_inpatient_adult_m) | mi(hm_inpatient_kids_f) | mi(hm_inpatient_kids_m) | mi(hm_inpatient_respiratory) | ///
    mi(hm_hosp_total)

/* Keep the state/district identifiers for districts in June reporting the chosen health services */
keep state district
count

/* Store count of unique districts to display in graph */
qui count
local number_of_districts_inpath_june `r(N)'

/* Merge to keep only these districts in main data */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
//gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m + hm_inpatient_respiratory
//drop hm_inpatient_*

/* Summarise Data at the month level */
collapse (sum) hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient_adult_f hm_inpatient_adult_m ///
    hm_inpatient_kids_f hm_inpatient_kids_m hm_inpatient_respiratory hm_operation_major hm_hosp_total, by(month)

/* Scale vaccinations by the total number of hospitals reporting these */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient_adult_f hm_inpatient_adult_m hm_inpatient_kids_f hm_inpatient_kids_m hm_inpatient_respiratory hm_operation_major  {
  replace `v' = `v'/hm_hosp_total  
}

/* Scale the hospital services by their value in January */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient_adult_f hm_inpatient_adult_m hm_inpatient_kids_f hm_inpatient_kids_m hm_inpatient_respiratory hm_operation_major hm_hosp_total {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data only till June */
keep if month<= 6

/* List out variable values for sanity check */
li hm_inpatient_adult_f-hm_inpatient_respiratory hm_hosp_total

/* Graph twoway lineplot of changing hospital services over time in 2020 */


twoway (line hm_inpatient_adult_m month) ///
    (line hm_inpatient_kids_m month) ///
    (line hm_inpatient_adult_f month) ///
    (line hm_inpatient_kids_f month) ///
    (line hm_hosp_total month), ///
    title("Inpatient Services Provided Per Hospital") ///
    subtitle("For The `number_of_districts_inpath_june' Districts That Reported in June") ///
    ytitle(" ")  ///
    xtitle("") ///
    xlabel(, valuelabels) ///
    ylabel(0(0.2)1) ///
    legend( label(1 "Inpatient Adult (Men)") label(2 "Inpatient Kids (Boys)")  label(3 "Inpatient Adults (Women)") label(4 "Inpatient Kids (Girls)")  label(5 "Total Hospitals Reporting (For This Sample)")) 

graphout inpatient_services_per_hospital_june

