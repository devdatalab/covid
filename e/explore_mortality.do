/*******************************************/
/* Exploratory analysis of COVID mortality */
/*******************************************/

/* load daily covid case-death data at district level */
use "$covidpub/covid/covid_infected_deaths.dta" , replace

/* generate time variables */
gen month = month(date)
gen year = year(date)

/* generate daily case and death counts - currently cumulative */
sort lgd_state_id lgd_district_id date
bys lgd_state_id lgd_district_id: gen cases = total_cases - total_cases[_n-1]
bys lgd_state_id lgd_district_id: gen deaths = total_deaths - total_deaths[_n-1]
drop if date == mdy(01,30,2020)

/* collapse on state-month-year to get total monthly case and deaths counts */
collapse (sum) cases deaths, by(lgd_state_id lgd_state_name month year)
ren deaths covid_deaths

/* save to scratch */
save "$tmp/covid_deaths_monthly", replace

/* load state mortality data */
use "$covidpub/mortality/state_mort_month.dta", replace

/* merge with state population totals */
merge m:1 pc11_state_id using "$pc11/pc11_pca_state_clean.dta", keepusing(pc11_pca_tot_p) keep(match) nogen

/* set as panel data */
egen id = group(lgd_state_id month year)
gen date = ym(year, month)
xtset id date, format(%tmMon_CCYY)

/* label months */
la def month 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
la val month month

/* merge with covid case + death data */
merge m:1 lgd_state_id month year using "$tmp/covid_deaths_monthly.dta", force
drop if _merge == 2
drop _merge

/* calculate cases + deaths per million */
gen deaths_per_million = deaths * 1000000 / pc11_pca_tot_p
gen covid_deaths_per_million = covid_deaths * 1000000 / pc11_pca_tot_p
gen covid_cases_per_million = cases * 1000000 / pc11_pca_tot_p

/* calculate excess mortality */

* step 1: calculate baseline mortality: mean for pre-2020 years for similar month
bys lgd_state_id month: egen baseline = mean(deaths) if year < 2020
replace baseline = baseline[_n-1] if baseline == . & lgd_state_id[_n] == lgd_state_id[_n-1]

* same as reg deaths i.month##i.lgd_state_id if year < 2020
* predict baseline

* step 2 : calculate excess deaths as difference between actual and baseline mortality
bys lgd_state_id month : gen excess_deaths = deaths - baseline if covid_deaths != .

/* calculate underreporting multiplier as the ratio of excess deaths to covid deaths */
gen ur_multiplier = excess_deaths / covid_deaths

/* order and sort data, keep necessary vars only */
order lgd_state_id lgd_state_name state deaths month year cases covid_deaths covid_cases_per_million covid_deaths_per_million baseline excess_deaths ur_multiplier
sort state month year
//drop pc11_pca_main_* pc11_pca_marg* pc11_pca_m* pc11_pca_f* pc11_pca_non* pc11_pca_tot_work* pc11_pca_level pc11_pca_p_06 pc11_pca_p_sc pc11_pca_p_st pc11_pca_tru 

/* Plots */

la var deaths "Total reported deaths from registration system"

* Andhra Pradesh
twoway (line deaths month if lgd_state_id == "28" & year == 2018, sort lcolor(gs10)) (line deaths month if lgd_state_id == "28" & year == 2019, sort lcolor(gs10)) (line deaths month if lgd_state_id == "28" & year == 2020, sort lwidth(thick) lcolor(red)) (line deaths month if lgd_state_id == "28" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, text(140000 5 "2021", color(red) size(medsmall)) text(45000 12.3 "2020", color(red) size(medsmall)) text(30000 12.3 "2019", color(gray) size(medsmall)) text(20000 12.3 "2018", size(medsmall) color(gray)) legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Andhra Pradesh") name(ap, replace)
graphout ap_deaths

* Bihar
twoway (line deaths month if lgd_state_id == "10" & year == 2018, sort lcolor(gs10)) (line deaths month if lgd_state_id == "10" & year == 2019, sort lcolor(gs10)) (line deaths month if lgd_state_id == "10" & year == 2020, sort lwidth(thick) lcolor(red)) (line deaths month if lgd_state_id == "10" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Bihar") name(bh, replace) text(70000 5 "2021", color(red) size(medsmall)) text(52000 12.3 "2020", color(red) size(medsmall)) text(35000 12.3 "2019", size(medsmall) color(gray)) text(25000 12.3 "2018", size(medsmall) color(gray))
graphout bihar_deaths

* Karnataka
bys lgd_state_id month: egen mean_deaths = mean(deaths) if year < 2020
twoway (line deaths month if lgd_state_id == "29" & year == 2015, sort lwidth(vvthin) lcolor(gs10)) (line mean_deaths month if lgd_state_id == "29" & year < 2020, sort lcolor(gray) lwidth(thick) lcolor(gs10)) ///
    (line deaths month if lgd_state_id == "29" & year == 2016, sort lwidth(vvthin) lcolor(gs10)) ///
    (line deaths month if lgd_state_id == "29" & year == 2017, sort lwidth(vvthin) lcolor(gs10)) ///
    (line deaths month if lgd_state_id == "29" & year == 2018, sort lcolor(gray) lwidth(vvthin) lcolor(gs10)) ///
    (line deaths month if lgd_state_id == "29" & year == 2019, sort lcolor(gray) lwidth(vvthin) lcolor(gs10)) ///
    (line deaths month if lgd_state_id == "29" & year == 2020, sort lwidth(thick) lcolor(red)) ///
    (line deaths month if lgd_state_id == "29" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Karnataka") name(kn, replace) ///
    text(80000 5 "2021", color(red) size(medsmall)) text(42000 12.3 "2020", color(red) size(medsmall)) text(37000 12.1 "2015-2019", size(medsmall) color(gray))
graphout karnataka_deaths

* Kerala
twoway (line mean_deaths month if lgd_state_id == "32" & year < 2020, sort lcolor(gs10) lwidth(thick)) (line deaths month if lgd_state_id == "32" & year == 2015, sort lwidth(vvthin) lcolor(gs10)) (line deaths month if lgd_state_id == "32" & year == 2016, sort lwidth(vvthin) lcolor(gs10)) (line deaths month if lgd_state_id == "32" & year == 2017, sort lwidth(vvthin) lcolor(gs10)) (line deaths month if lgd_state_id == "32" & year == 2018, sort lcolor(gs10) lwidth(vvthin)) (line deaths month if lgd_state_id == "32" & year == 2019, sort lcolor(gs10) lwidth(vvthin)) (line deaths month if lgd_state_id == "32" & year == 2020, sort lwidth(thick) lcolor(red)) (line deaths month if lgd_state_id == "32" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Kerala") name(kerala, replace) ///
text(28500 5 "2021", color(red) size(medsmall)) text(23800 12.3 "2020", color(red) size(medsmall)) text(20000 12.1 "2015-2019", size(medsmall) color(gray))    
graphout kerala_deaths

* Tamil Nadu
twoway (line deaths month if lgd_state_id == "33" & year == 2018, sort lcolor(gs10)) (line deaths month if lgd_state_id == "33" & year == 2019, sort lcolor(gs10)) (line deaths month if lgd_state_id == "33" & year == 2020, sort lwidth(thick) lcolor(red)) (line deaths month if lgd_state_id == "33" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Tamil Nadu") name(tn, replace) ///
    text(96000 5 "2021", color(red) size(medsmall)) text(45000 12.2 "2020", color(red) size(medsmall)) text(38000 12.2 "2019", size(medsmall) color(gray)) text(32000 12.1 "2018", size(medsmall) color(gray))
graphout tn_deaths

* UP
twoway (line deaths month if lgd_state_id == "09" & year == 2019, sort lcolor(gs10)) (line deaths month if lgd_state_id == "09" & year == 2020, sort lwidth(thick) lcolor(red)) (line deaths month if lgd_state_id == "09" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Uttar Pradesh") name(up, replace) ///
    text(70000 4 "2021", color(red) size(medsmall)) text(102000 12.1 "2020", color(red) size(medsmall)) text(68500 12.1 "2019", size(medsmall) color(gray))
graphout up_deaths

* MP
twoway (line deaths month if lgd_state_id == "23" & year == 2018, sort lcolor(gs10)) (line deaths month if lgd_state_id == "23" & year == 2019, sort lcolor(gs10)) (line deaths month if lgd_state_id == "23" & year == 2020, sort lwidth(thick) lcolor(red)) (line deaths month if lgd_state_id == "23" & year == 2021, sort lwidth(thick) lcolor(red)) if date < 737, legend(off) tlabel(1(1)12, labels labsize(small) angle(forty_five) valuelabel) graphregion(margin(large)) title("Madhya Pradesh") name(mp, replace) ///
    text(170000 5 "2021", color(red) size(medsmall)) text(51000 12.2 "2020", color(red) size(medsmall)) text(40000 12.2 "2019", size(medsmall) color(gray)) text(20000 12.2 "2018", size(medsmall) color(gray))
graphout mp_deaths

// graph combine ap bh kn kerala tn mp up

/* excess deaths vs covid deaths (March 2020 to May 2021) */
xtline excess_deaths covid_deaths if date >= 722 & date <= 736 & lgd_state_name == "kerala", i(state) t(date) ttitle(Date) tlabel(722(2)736, labsize(small) angle(forty_five)) byopts(legend(position(6))) legend(order(1 "Excess Deaths" 2 "COVID Deaths") cols(2)) byopts(cols(4) title("Excess Deaths v/s COVID Deaths")) ///
    ylabel(-2000 (1000) 8000) yline(0) note("")
graphout excess_vs_covid_deaths

/* underreporting multiplier (May 2020 to May 2021) */
xtline ur_multiplier if date >= 724 & !inlist(lgd_state_name, "assam", "bihar", "uttar pradesh", "kerala"), ///
    i(state) t(date) ttitle(Date) tlabel(724(2)736, labsize(small) angle(forty_five)) byopts(legend(position(6))) legend(cols(2)) byopts(cols(2) title("Underreporting Multiplier"))  ///
    ytitle(Excess Deaths / COVID Deaths)
graphout ur_multiplier


tsline ur_multiplier if date>=724 & lgd_state_name == "kerala" ///
    title("Underreporting Multiplier"))  ///
    ytitle(Excess Deaths / COVID Deaths) name(kerala, replace)

/* table */
/* lets get excess deaths for 2021 annual-state */
keep if year == 2021
collapse (sum) excess_deaths, by(lgd_state_name)


/* lets get total COVID deaths by state */
use "$covidpub/covid/covid_infected_deaths.dta" , replace

keep if inlist(lgd_state_name , "andhra pradesh", "assam", ///
  "bihar", "karnataka", "kerala", "madhya pradesh", ///
  "tamil nadu", "uttar pradesh")

keep if inlist(date, mdy(6,29,2021), mdy(1,31,2020))

collapse (sum) total_deaths, by(lgd_state_name date)

sort date lgd_state_name
outsheet using $tmp/covid_deaths.csv, replace

use "$covidpub/mortality/state_mort_year.dta", clear

/* merge with state population totals */
merge m:1 pc11_state_id using "$pc11/pc11_pca_state_clean.dta", keepusing(pc11_pca_tot_p) keep(match) nogen

/* set as panel data */
egen id = group(lgd_state_id year)

/* calculate excess mortality */

* step 1: calculate baseline mortality: mean for pre-2020 years for similar month
bys lgd_state_id year: egen baseline = mean(deaths) if year < 2020
replace baseline = baseline[_n-1] if baseline == . & lgd_state_id[_n] == lgd_state_id[_n-1]

/* fix baseline for 2021 (only 4 months of data) */
replace baseline = baseline/4 if year == 2021

* same as reg deaths i.month##i.lgd_state_id if year < 2020
* predict baseline

* step 2 : calculate excess deaths as difference between actual and baseline mortality
bys lgd_state_id year : gen excess_deaths = deaths - baseline 

/* calculate underreporting multiplier as the ratio of excess deaths to covid deaths */
gen ur_multiplier = excess_deaths / covid_deaths

