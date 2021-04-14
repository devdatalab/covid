setc covid

/********************************************/
/* 1. Map of total vacc/eligible population */
/********************************************/

/* bring in district wise vaccinatoin data */
use $covidpub/covid/covid_vaccination, clear

/* work with the date variable */
gen day = substr(date, 1, 2)
gen month = substr(date, 3, 2)
gen year = "2021"
destring day month year, replace
gen date_fmt = mdy(month, day, year)
format date_fmt %td

/* sort data by date */
sort date_fmt

/* keep most recent date */
keep if date == "12042021"

/* generate count of total vaccination */
egen tot_vacc= rowtotal(total_covaxin total_covishied)

/* duplicates */
duplicates tag lgd_state_name lgd_district_name, gen(tag)
replace tag = 0 if lgd_district_name == lower(cowinkey)
keep if tag == 0

/* get ids */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match) nogen
merge m:1 lgd_state_id lgd_district_name using $keys/lgd_district_key, keepusing(lgd_district_id) keep(match) nogen

/* saved */
savesome tot_vacc lgd* using $tmp/district_vacc, replace

/* get eligible population share */
use $covidpub/demography/pc11/age_bins_district_t_pc11, clear

/* calculate total eligible population */
gen tot_old = age_45_t

forval i = 50 (5) 85 {
  replace tot_old = tot_old + age_`i'_t
}

gen group = 1
collapse (sum) tot_old pc11_pca_tot_t, by(group) 
gen share = tot_old/
keep tot_old pc11*id

/* get lgd ids - note 10 districts get dropped in the process */
/* bc i dont know how to handle the weights for them */
convert_ids, from_ids(pc11_state_id pc11_district_id) to_ids(lgd_state_id lgd_district_id) key($keys/lgd_pc11_district_key_weights.dta) weight_var(pc11_lgd_wt_pop)

/* drop 10 districts that were split between pc11 and lgd */
duplicates tag lgd_state_id lgd_district_id , gen(tag)
keep if tag == 0

/* merge with district vaccinaton data */
merge 1:1 lgd_state_id lgd_district_id using $tmp/district_vacc, nogen keep(match using)

/* calculate vaccinations/eligible pop */
gen vacc_eligible = tot_vacc/tot_old

/* get number of health care centers */
merge 1:1 lgd_state_id lgd_district_id using $covidpub/hospitals/ec_hospitals_dist, nogen keep(match master) keepusing(ec_num*)

/* calculate vaccinations/#healthcare centers */
gen vacc_hc = tot_vacc/(ec_num_hosp_priv + ec_num_hosp_gov)

save $tmp/vacc_eligible, replace

/*************************************/
/* 2. State-wise weekly vaccinations */
/*************************************/

/* bring in district wise vaccinatoin data */
use $covidpub/covid/covid_vaccination, clear

/* work with the date variable */
gen day = substr(date, 1, 2)
gen month = substr(date, 3, 2)
gen year = "2021"
destring day month year, replace
gen date_fmt = mdy(month, day, year)
format date_fmt %td

/* sort data by date */
sort date_fmt

/* create week indicator */
gen week = date_fmt if dow(date_fmt) == 1
replace week = week[_n-1] if mi(week)
format week %td

/* drop most recent week since its incomplete */
drop if week == mdy(04, 12, 2021)

/* generate count of total vaccination */
egen tot_vacc = rowtotal(total_covaxin total_covishied)

/* keep only weekly data */
keep if week == date_fmt

/* generate weekly requirement in each district from cdf */
sort lgd_state_name lgd_district_name week

/* gen week_tot */
group lgd_state_name lgd_district_name 
gen week_tot = tot_vacc[_n] - tot_vacc[_n-1] if llgroup[_n] == llgroup[_n-1]
drop if week_tot == .

/* generate weekly sum */
bys lgd_state_name week: egen week_sum = total(week_tot)
destring week_sum, replace

/* collapse weekly vaccines used to state level */
format week_sum %10.0f

/* collapse to week level */
collapse (mean) week_sum, by(lgd_state_name week)

/* save week level data */
save $tmp/vacc_state_week, replace

/* collapse */
collapse (mean) week_sum, by(lgd_state_name)

/* sort by value */
sort week_sum

/* outsheet */
outsheet using $tmp/vacc.csv, replace comma

/* save */
save $tmp/vacc_state, replace

