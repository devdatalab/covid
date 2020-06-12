/* Set $out for graphs to $tmp */
global out $tmp

/***************************************************************************/
/* 1. Vaccinations/ Health Services over time(For districts reporting in May) */
/***************************************************************************/

/* Graph Scaled Vaccinations Over time */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in May */
keep if year == 2020 & month == 5 & category == "Total [(A+B) or (C+D)]"
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions)
keep state district
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
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  ) 
    
graphout vaccinations_may

/* Graph Scaled Hospital Services over time for districts reporting in May */

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
count

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
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total")) 
    
graphout hospital_services_may

/***************************************************************/
/* Hospitals reporting over time [For all Districts reporting] */
/***************************************************************/

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

/* Summarise Data at the month level */
collapse (sum) hm_hosp_chc hm_hosp_phc hm_hosp_sc hm_hosp_sdh hm_hosp_dh hm_hosp_total, by(month)

foreach v of varlist hm_hosp* {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep Data till April */
keep if month<= 4

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
    xtitle("Month") ///
    legend( label(1 "Community Health Centers") label(2 "Primary Health Centers") label(3 "Sub Centers") label(4 "Sub District Hospitals") label(5 "District Hospitals") label(6 "Total Hospital")  ) 
    
graphout hospitals_reporting_all


/******************************************************************************/
/* Scaled Vaccinations/Services per hospital (For districts reporting in May) */
/******************************************************************************/

/* Graph Scaled Vaccinations Per Hospital Over time */
/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in May */
keep if year == 2020 & month == 5 & category == "Total [(A+B) or (C+D)]"
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions)
keep state district
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
foreach v of varlist  hm_vac*{
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data till April(Since no hospital data in May) */
keep if month <= 4

/* List variables to Sanity Check */
li hm_vac_bcg-hm_hosp_total

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month), ///
    title("Vaccinations at Birth Per Hospital") ///
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  ) 
    
graphout vaccinations_per_hospital_may


/* Graph Scaled Hospital Services over time for districts reporting in May */

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
count

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
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Keep data only till May */
keep if month<= 4

/* List out variable values for sanity check */
li hm_outpatient_diabetes-hm_hosp_total

/* Graph twoway lineplot of changing hospital services over time in 2020 */

twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month) ///
    (line hm_operation_major month), ///
    title("Health Services Provided") ///
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total") label(4 "Operations(Major)") ) 
    
graphout hospital_services_per_hospital_may

/********************************************************************************/
/* Scaled Vaccinations/Services per hospital (For districts reporting in April) */
/********************************************************************************/

/* Graph Scaled Vaccinations Per Hospital Over time */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in April */
keep if year == 2020 & month == 4 & category == "Total [(A+B) or (C+D)]"

/* Drop districts not reporting vaccination data or total hospitals data */
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions) | mi(hm_hosp_total)

/* Keep a key of the districts reporting data */
keep state district
count

/* Merge the kwy of districts in april with non-missing data into main dataset
to filter on those districts */
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
foreach v of varlist  hm_vac*{
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* List out variable values for a sanity check */
li hm_vac_bcg-hm_hosp_total

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month), ///
    title("Vaccinations at Birth Per Hospital") ///
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  ) 
    
graphout vaccinations_per_hospital_april


/* Graph Scaled Hospital Services over time for districts reporting in April */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in April */
keep if year == 2020 & month == 4 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Keep only those districts in April that report for these hospital services and total hospitals */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient) | mi(hm_operation_major) | mi(hm_hosp_total)

/* Keep the state/district identifiers for districts in May reporting the chosen health services */
keep state district
count

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

/* Scale hospital services by the total number of hospitals reporting these */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major  {
  replace `v' = `v'/hm_hosp_total  
}

/* Scale hospital services by their january value */
foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/*List out variable values for a sanity check */
li hm_outpatient_diabetes-hm_hosp_total

/* Graph twoway lineplot of changing hospital services over time in 2020 */

twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month) ///
    (line hm_operation_major month), ///
    title("Health Services Provided") ///
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total") label(4 "Operations(Major)") ) 
    
graphout hospital_services_per_hospital_april


/**********************************************************************/
/* Vaccinations/Services over time (For districts reporting in April) */
/**********************************************************************/

/* Graph Scaled Vaccination Over time */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in April */
keep if year == 2020 & month == 4 & category == "Total [(A+B) or (C+D)]"

/* Only Keep those districts in April, that report the following vaccinations */
drop if mi(hm_vac_bcg) | mi(hm_vac_opv) | mi(hm_vac_opv0) | mi(hm_vac_sessions) 

/* Create a key of state district to keep in master data */
keep state district
count

/* Merge state district key from April for non_missing vaccination variables into main dataset */
merge 1:m state district using $health/hmis/hmis_dist_clean.dta 
keep if _merge == 3

/* Drop Extra Variables */
drop hm_v_* hm_ev_*

/* Keep only 2020 data */
keep if year == 2020

/* Keep only Total Data (and not Public/Private/Urban/Rural Breakdowns */
keep if category == "Total [(A+B) or (C+D)]"

/* Summarise Data at the month level */
collapse (sum) hm_vac* , by(month)

/* Scale every vaccination variable by its first value(In January 2020) */
foreach v of varlist  hm_vac*{
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}
 
/* Only Keep data till April */
keep if month <=4

/* List out variable values for a sanity check */
li hm_vac_bcg-hm_vac_sessions

/* Graph twoway lineplot of decreasing vaccine production over time */
twoway (line hm_vac_bcg month) ///
    (line hm_vac_opv0 month) ///
    (line hm_vac_hepb month) ///
    (line hm_vac_sessions month), ///
    title("Vaccinations at Birth") ///
    subtitle("For Districts That Reported in April") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend(label(1 "BCG Vaccination") label(2 "Polio Vaccination") label(3 "Hepatitis B Vaccination") label(4 "Number of Vaccination Sessions")  ) 
    
graphout vaccinations_april

/* Graph Scaled Hospital Services over time for districts reporting in April */

/* Input Data */
use $health/hmis/hmis_dist_clean.dta, clear

/* Only Keep districts that report in April */
keep if year == 2020 & month == 4 & category == "Total [(A+B) or (C+D)]"

/* Generate a new inpatient variable that sums over all adults and children */
gen hm_inpatient = hm_inpatient_adult_f + hm_inpatient_adult_m + hm_inpatient_kids_f + hm_inpatient_kids_m
drop hm_inpatient_*

/* Keep only those districts in April that report for these hospital services */
drop if mi(hm_outpatient_diabetes) | mi(hm_outpatient_hypertension) | mi(hm_inpatient) | mi(hm_operation_major)

/* Keep the state/district identifiers for districts in May reporting the chosen health services */
keep state district
count

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

/* Summarise health services Data at the month level */
collapse (sum) hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major, by(month)

foreach v in hm_outpatient_diabetes hm_outpatient_hypertension hm_inpatient hm_operation_major {
  di "`v'"
  gen `v'_first = `v'[_n == 1]
  replace `v'_first = `v'_first[_n-1] if `v'_first == .
  replace `v' = `v'/`v'_first  
}

/* Only Keep data till April */
keep if month <=4

/*List out variable values for a sanity check */
li hm_outpatient_diabetes-hm_operation_major

/* Graph twoway lineplot of changing hospital services over time in 2020 */

twoway (line hm_outpatient_diabetes month) ///
    (line hm_outpatient_hypertension month) ///
    (line hm_inpatient month) ///
    (line hm_operation_major month), ///
    title("Health Services Provided") ///
    subtitle("For Districts That Reported in May") ///
    ytitle(" ")  ///
    xtitle("Month") ///
    legend( label(1 "Outpatient Diabetes") label(2 "Outpatient Hypertesion") label(3 "Inpatient Total") label(4 "Operations(Major)") ) 
    
graphout hospital_services_april
