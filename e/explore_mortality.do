/*******************************************/
/* Exploratory analysis of COVID mortality */
/*******************************************/

global out "~/public_html"

/* load daily covid case-death data at district level */
use "$covidpub/covid/covid_infected_deaths.dta" , replace

/* generate time variables */
gen month = month( date)
gen year = year(date)

/* drop observations if there are empty district identifiers */
sort lgd_district_id date
drop if lgd_district_id == ""

/* generate daily case and death counts - currently cumulative */
bys lgd_district_id : gen cases = total_cases - total_cases[_n-1]
bys lgd_district_id : gen deaths = total_deaths - total_deaths[_n-1]

/* collapse on state-month-year to get total monthly case and deaths counts */
collapse (sum) cases deaths, by(lgd_state_id lgd_state_name month year)
ren deaths covid_deaths

/* save to scratch */
save "$tmp/covid_deaths_monthly", replace

/* load state mortality data */
use "$covidpub/mortality/state_mort_month.dta", replace

/* merge with state population totals */
merge m:1 pc11_state_id using "$pc11/pc11_pca_state_clean.dta"
keep if _merge == 3
drop _merge 

/* set as panel data */
egen id = group(state month year)
gen date = ym(year, month)
xtset id date, format(%tmMon_CCYY)

/* label months */
la def month 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
la val month month

/* merge with covid case + death data */
merge m:m lgd_state_id month year using "$tmp/covid_deaths_monthly.dta", force
drop if _merge == 2
drop _merge

/* calculate cases + deaths per million */
gen deaths_per_million = deaths * 1000000 / pc11_pca_tot_p
gen covid_deaths_per_million = covid_deaths * 1000000 / pc11_pca_tot_p
gen covid_cases_per_million = cases * 1000000 / pc11_pca_tot_p

/* calculate excess mortality */

* step 1: calculate baseline mortality: mean for pre-2020 years for similar month
bys state month: egen baseline = mean(deaths) if year < 2020
replace baseline = baseline[_n-1] if baseline == .

* same as reg deaths i.month##i.lgd_state_id if year < 2020
* predict baseline

* step 2 : calculate excess deaths as difference between actual and baseline mortality
bys state month : gen excess_deaths = deaths - baseline if covid_deaths != .

/* calculate underreporting multiplier as the ratio of excess deaths to covid deaths */
gen ur_multiplier = excess_deaths / covid_deaths

/* order and sort data, keep necessary vars only */
order lgd_state_id lgd_state_name state deaths month year cases covid_deaths covid_cases_per_million covid_deaths_per_million baseline excess_deaths ur_multiplier
sort state month year
drop pc11_pca_main_* pc11_pca_marg* pc11_pca_m* pc11_pca_f* pc11_pca_non* pc11_pca_tot_work* pc11_pca_level pc11_pca_p_06 pc11_pca_p_sc pc11_pca_p_st pc11_pca_tru 

/* Plots */

/* 1. Mortality trend for top 4 states in terms of total deaths */
xtline deaths_per_million if year > 2017 & date < 737 ///
& (pc11_state_id == "23" | pc11_state_id == "28" ///
| pc11_state_id == "29" | pc11_state_id == "33") ///
, overlay i(state) t(date) /// 
ytitle(Deaths per Million) ///
ttitle(Date) ///
tlabel(696(5)737, labsize(vsmall) tposition(outside)) ///
 legend(pos(6) col(4) order(1 "Andhra Pradesh" 2 "Karnataka" 3 "Madhya Pradesh" 4 "Tamil Nadu")) ///
 tline(722 735) ttext(2100 722 "National Lockdown", orient(vertical) placement(west) size(small))  ///
 ttext(2250 735 "Second Wave", orient(vertical) placement(west) size(small)) ///
 title("Total Reported Deaths per Million") ///
 note("States with highest reported deaths; Population Total from 2011 Census", size(vsmall))
graphout deaths_per_million, pdf

/* compare total deaths and covid deaths per million population for Kerala and TN */
xtline deaths_per_million covid_deaths_per_million if date > 721 & date < 737 & (pc11_state_id == "32" | pc11_state_id == "33"), i(state) t(date)  ytitle(Deaths per Million) ttitle(Date) tlabel(722(3)736, labsize(vsmall) tposition(outside)) legend(pos(6) col(4) order(1 "Reported Deaths (Total) per Million" 2 "COVID Deaths per Million")) byopts(imargin(large) title(Total Deaths v/s COVID deaths (per million)) note("Population Totals from 2011 Census", size(vsmall))) graphregion(margin(vlarge))
graphout deaths_vs_covid, pdf

/* deaths by month each state */

* Andhra Pradesh
twoway (line deaths month if lgd_state_id == "28" & year == 2018, sort) (line deaths month if lgd_state_id == "28" & year == 2019, sort) (line deaths month if lgd_state_id == "28" & year == 2020, sort) (line deaths month if lgd_state_id == "28" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2018" 2 "2019" 3 "2020" 4 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Andhra Pradesh") name(ap, replace)
graphout ap_deaths, pdf

* Bihar
twoway (line deaths month if lgd_state_id == "10" & year == 2018, sort) (line deaths month if lgd_state_id == "10" & year == 2019, sort) (line deaths month if lgd_state_id == "10" & year == 2020, sort) (line deaths month if lgd_state_id == "10" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2018" 2 "2019" 3 "2020" 4 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Bihar") name(bh, replace)
graphout bihar_deaths, pdf

* Karnataka
twoway (line deaths month if lgd_state_id == "29" & year == 2015, sort) (line deaths month if lgd_state_id == "29" & year == 2016, sort) (line deaths month if lgd_state_id == "29" & year == 2017, sort) (line deaths month if lgd_state_id == "29" & year == 2018, sort) (line deaths month if lgd_state_id == "29" & year == 2019, sort) (line deaths month if lgd_state_id == "29" & year == 2020, sort) (line deaths month if lgd_state_id == "29" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2015" 2 "2016" 3 "2017" 4 "2018" 5 "2019" 6 "2020" 7 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Karnataka") name(kn, replace)
graphout karnataka_deaths, pdf

* Kerala
twoway (line deaths month if lgd_state_id == "32" & year == 2015, sort) (line deaths month if lgd_state_id == "32" & year == 2016, sort) (line deaths month if lgd_state_id == "32" & year == 2017, sort) (line deaths month if lgd_state_id == "32" & year == 2018, sort) (line deaths month if lgd_state_id == "32" & year == 2019, sort) (line deaths month if lgd_state_id == "32" & year == 2020, sort) (line deaths month if lgd_state_id == "32" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2015" 2 "2016" 3 "2017" 4 "2018" 5 "2019" 6 "2020" 7 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Kerala") name(kerala, replace)
graphout kerala_deaths, pdf

* Tamil Nadu
twoway (line deaths month if lgd_state_id == "33" & year == 2018, sort) (line deaths month if lgd_state_id == "33" & year == 2019, sort) (line deaths month if lgd_state_id == "33" & year == 2020, sort) (line deaths month if lgd_state_id == "33" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2018" 2 "2019" 3 "2020" 4 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Tamil Nadu") name(tn, replace)
graphout tn_deaths, pdf

* UP
twoway (line deaths month if lgd_state_id == "09" & year == 2019, sort) (line deaths month if lgd_state_id == "09" & year == 2020, sort) (line deaths month if lgd_state_id == "09" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2019" 2 "2020" 3 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Uttar Pradesh") name(up, replace)
graphout up_deaths, pdf

* MP
twoway (line deaths month if lgd_state_id == "23" & year == 2018, sort) (line deaths month if lgd_state_id == "23" & year == 2019, sort) (line deaths month if lgd_state_id == "23" & year == 2020, sort) (line deaths month if lgd_state_id == "23" & year == 2021, sort) if date < 737, legend(pos(6) col(4) order(1 "2018" 2 "2019" 3 "2020" 4 "2021")) tlabel(1(1)12, labels labsize(vsmall) angle(forty_five) valuelabel) graphregion(margin(large)) title("Madhya Pradesh") name(mp, replace)
graphout mp_deaths, pdf

// graph combine ap bh kn kerala tn mp up

/* excess deaths vs covid deaths (March 2020 to May 2021) */
xtline excess_deaths covid_deaths if date >= 722, i(state) t(date) ttitle(Date) tlabel(722(2)736, labsize(vsmall) angle(forty_five)) byopts(legend(position(6))) legend(order(1 "Excess Deaths" 2 "COVID Deaths") cols(2)) byopts(cols(4) title("Excess Deaths v/s COVID Deaths"))
graphout excess_vs_covid_deaths, pdf

/* underreporting multiplier (May 2020 to May 2021) */
xtline ur_multiplier if date >= 724 & state != "Assam", i(state) t(date) ttitle(Date) tlabel(724(2)736, labsize(vsmall) angle(forty_five)) byopts(legend(position(6))) legend(cols(2)) byopts(cols(4) title("Underreporting Multiplier"))  ytitle(Excess Deaths / COVID Deaths) ylabel(-500(250)500)
graphout ur_multiplier, pdf
