/**********************************************/
/* District-level analysis of COVID Mortality */
/**********************************************/

global out "~/public_html/pdf"
global HTMLVIEW 1

/*************************************/
/* Prep covid case counts and deaths */
/*************************************/

use "$covidpub/covid/covid_infected_deaths.dta" , replace

gen month = month(date)
gen year = year(date)

/* drop missing observations and only keep data for upto June 28, 2021 */
drop if lgd_district_id == ""
keep if date < 22461
sort lgd_state_id lgd_district_id date

/* calculate daily case counts and deaths */
bys lgd_state_id lgd_district_id: gen cases = total_cases - total_cases[_n-1]
bys lgd_state_id lgd_district_id: gen deaths = total_deaths - total_deaths[_n-1]

/* calculate monthly case counts and deaths by districts */
collapse (sum) cases deaths, by(lgd_state_id lgd_district_id lgd_state_name lgd_district_name month year)
ren deaths covid_deaths

/* save to scratch */
save "$tmp/covid_deaths_district", replace

/*********************************/
/* Prep SECC district-level data */
/*********************************/

/* NOTE: Data for Kolkata is missing in the SECC */

/* load urban block data */
use ~/secc/seg/clean/secc_urban_collapsed_block, replace

/* append with rural block data */
append using ~/secc/seg/clean/secc_rural_collapsed_block

/* collapse on PC11 districts - obtain total population by education level and mean consumption per capita and poverty rates by PC11 districts */
collapse (sum) ed1-ed7 (mean) cons_pc pov_rate, by(pc11_state_id pc11_district_id)

/* save to scratch */
save "$tmp/secc_district_collapse.dta", replace

/*********************************************************************/
/* Merge SECC and COVID case + death count data with reported deaths */
/*********************************************************************/

/* load district-month-year data for reported deaths */
use "$covidpub/mortality/district_mort_month.dta", replace

/* merge with monthly COVID case counts and deaths */
merge m:m lgd_district_id month year using "$tmp/covid_deaths_district.dta", force
drop if _merge == 2

/* obtain pre-COVID mortality baseline for calculating excess deaths by taking district-month fixed effects */
destring lgd_district_id , replace
reghdfe deaths i.month##i.lgd_district_id if year < 2020, noabsorb
predict baseline
gen excess_deaths = deaths - baseline
replace excess_deaths = . if year < 2020

/* set as panel data and save to scratch */
egen id = group(lgd_state_id lgd_district_id month year)
gen date = ym(year, month)
xtset id date, format(%tmMon_CCYY)
save "$tmp/district_excess_deaths", replace

/* Calculate outcome totals from March 2020 to May 2021 */
collapse (sum) cases covid_deaths deaths excess_deaths if date >= 722 & date < 737, by(lgd_state_id lgd_district_id pc11_state_id pc11_district_id lgd_state_name lgd_district_name state district)

/* merge with district demography data */
tostring lgd_district_id , replace
merge m:1 lgd_*_id using "$covidpub/demography/dem_district.dta"
keep if _merge == 3
drop _merge

/* merge with SECC district-level data */
merge m:1 pc11_*_id using "$tmp/secc_district_collapse.dta"
keep if _merge != 2
la var cons_pc "SECC Consumption per Capita"
la var pov_rate "SECC Poverty Rate"

/* Generate covariates of interest */

/* urban and rural population shares */
gen urban_p = pc11u_pca_tot_p / pc11_pca_tot_p
la var urban_p "% Urban Population"

gen rural_p = pc11r_pca_tot_p / pc11_pca_tot_p
la var rural_p "% Rural Population"

/* proportion of population with higher secondary education */
gen high_ed = ((ed6 + ed7) / (ed1 + ed2 + ed3 + ed4 + ed5 + ed6 + ed7))
la var high_ed "% Higher Secondary Education"

/* underreporting multiplier */
gen ur_multiplier = excess_deaths / covid_deaths
la var ur_multiplier "Underreporting Multiplier (Excess Deaths / COVID Deaths)"

/***********************/
/* Regression analysis */
/***********************/

/* multivariate regressions with underreporting multiplier as outcome */

/* Notes:
1. Assam districts will drop out due to 0 covid death totals
2. SECC data not available for Kolkata
*/

local outcome "excess_deaths ur_multiplier"

foreach i in `outcome' {

if "`i'" == "excess_deaths" local abbr "ed"
else local abbr "ur"

eststo `abbr'1: reghdfe `i' urban_p, noabsorb vce(robust)
eststo `abbr'2: reghdfe `i' urban_p pov_rate, noabsorb vce(robust)
eststo `abbr'3: reghdfe `i' urban_p pov_rate high_ed, noabsorb vce(robust)
eststo `abbr'4: reghdfe `i' urban_p pov_rate high_ed cons_pc, noabsorb vce(robust)
eststo `abbr'5: reghdfe `i' urban_p pov_rate high_ed cons_pc cases, noabsorb vce(robust)

}

esttab ur* using $out/ur_reg.html, r2 label replace
esttab ed* using $out/ed_reg.html, r2 label replace

/* compile bivariate scatterplots for excess deaths and underreporting multiplier */
local outcome "excess_deaths ur_multiplier"
local covariates "urban_p rural_p high_ed cons_pc pov_rate"

foreach i in `outcome' {
  foreach j in `covariates' {

    if "`i'" == "excess_deaths" local label "Total Excess Deaths since March 2020"
    else local label "Underreporting Multiplier (Excess Deaths / COVID Deaths)"

    twoway (lfit `i' `j') (scatter `i' `j'), legend(off) ytitle(`label')
    graphout `i'_`j', pdf

  }
}

/***********************/
/* Additional analysis */
/***********************/

/* 1. underreporting multiplier */
sum ur_multiplier, det
kdensity ur_multiplier
graphout ur_kdensity, pdf

/* plot graphs */
twoway (lfit ur_multiplier  urban_p) (scatter ur_multiplier urban_p), legend(off) ytitle("Underreporting Multiplier") name(ur1, replace)

/* plot graphs */
twoway (lfit ur_multiplier  urban_p) (scatter ur_multiplier urban_p ) if ur_multiplier > -200 & ur_multiplier < 250, legend(off) ytitle("Underreporting Multiplier") name(ur2, replace) note("Outliers are dropped from sample")

binscatter ur_multiplier urban_p, control(cons_pc pov_rate cases high_ed) xtitle(% Urban Population) ytitle("Underreporting Multiplier") note("Controlled for consumption, education, poverty rate and case counts", size(vsmall)) name(ur3, replace) ylabel(0(20)100)

binscatter ur_multiplier urban_p if ur_multiplier > -200 & ur_multiplier < 250, control(cons_pc pov_rate cases high_ed) xtitle(% Urban Population) ytitle("Underreporting Multiplier ") note("Controlled for consumption, education, poverty rate and case counts; dropped outliers", size(vsmall)) ylabel(0(20)100) name(ur4, replace)

graph combine ur1 ur2 ur3 ur4, col(2)
graphout ur_multiplier_combined, pdf

/* regressions */
eststo ur_add_1: reghdfe ur_multiplier urban_p, noabsorb // uncontrolled spec
eststo ur_add_2: reghdfe ur_multiplier urban_p if ur_multiplier > -200 & ur_multiplier < 250, noabsorb // uncontrolled spec; drop outliers

eststo ur_add_3: reghdfe ur_multiplier urban_p cons_pc pov_rate high_ed cases, noabsorb // controlled spec
eststo ur_add_4: reghdfe ur_multiplier urban_p cons_pc pov_rate high_ed cases if ur_multiplier > -200 & ur_multiplier < 250, noabsorb // dropped outliers in controlled spec
eststo ur_add_5: reghdfe ur_multiplier urban_p cons_pc pov_rate high_ed cases if ur_multiplier > -200 & ur_multiplier < 250, absorb(lgd_state_id) // controlled spec with state fixed effects and dropped outliers

esttab ur_add_* using $out/ur_reg_add.html, r2 label replace

/* excess deaths */
sum excess_deaths, det
kdensity excess_deaths
graph hbox excess_deaths, over(state, sort(excess_deaths)) // huge variation within and across states, UP in particular
graphout box_ed, pdf

/* plot graphs */
twoway (lfit excess_deaths  urban_p) (scatter excess_deaths urban_p), legend(off) ytitle("Excess Deaths") name(ed1, replace)

twoway (lfit excess_deaths  urban_p) (scatter excess_deaths urban_p ) if excess_deaths > -10000, legend(off) ytitle("Excess Deaths") name(ed2, replace) note("Outliers are dropped from sample")

binscatter excess_deaths urban_p, control(cons_pc pov_rate cases high_ed) xtitle(% Urban Population) ytitle("Excess Deaths") note("Controlled for consumption, education, poverty rate and case counts", size(vsmall)) name(ed3, replace)

binscatter excess_deaths urban_p if excess_deaths > -10000 , control(cons_pc pov_rate cases high_ed) xtitle(% Urban Population) ytitle("Excess Deaths") note("Controlled for consumption, education, poverty rate and case counts; dropped outliers", size(vsmall)) name(ed4, replace)

graph combine ed1 ed2 ed3 ed4, col(2)
graphout excess_deaths_combined, pdf

/* regressions */
eststo ed_add_1: reghdfe excess_deaths urban_p, noabsorb // uncontrolled spec
eststo ed_add_2: reghdfe excess_deaths urban_p if excess_deaths > -10000, noabsorb // uncontrolled spec; drop outliers

eststo ed_add_3: reghdfe excess_deaths urban_p cons_pc pov_rate high_ed cases, noabsorb // controlled spec
eststo ed_add_4: reghdfe excess_deaths urban_p cons_pc pov_rate high_ed cases if excess_deaths > -10000, noabsorb // dropped outliers in controlled spec
eststo ed_add_5: reghdfe excess_deaths urban_p cons_pc pov_rate high_ed cases if excess_deaths > -10000, absorb(lgd_state_id) // controlled spec with state fixed effects and dropped outliers

esttab ed_add_* using $out/ed_reg_add.html, r2 label replace

/***************************/
/* Additional Analysis -2  */
/***************************/

/* take the inverse hyperbolic sine transformation for excess deaths and covid deaths */
foreach i in excess_deaths covid_deaths {
  gen ihs_`i' = asinh(`i')
}

la var ihs_excess_deaths "IHS (Excess Deaths)"
la var ihs_covid_deaths "IHS (COVID Deaths)"

/* plot a twoway scatter */

/* notes:
1. All the 0 covid deaths are for Assam districts since they don't report district-wise disaggregated deaths
2. UP districts have negative excess deaths
*/
twoway scatter ihs_excess_deaths ihs_covid_deaths
graphout ihs_excess_covid

/* replot the twoway scatter after dropping outliers */
twoway (scatter ihs_excess_deaths ihs_covid_deaths) (lfit ihs_excess_deaths ihs_covid_deaths) if covid_deaths > 0 & state != "Uttar Pradesh", legend(pos(6) col(2)) ytitle("IHS (Excess Deaths)")
graphout ihs_excess_covid_2

