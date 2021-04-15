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

use $tmp/district_vacc, clear

convert_ids, to_ids(pc11_state_id pc11_district_id) from_ids(lgd_state_id lgd_district_id) key($keys/lgd_pc11_district_key_weights.dta) weight_var(lgd_pc11_wt_pop)

save $tmp/vacc_all, replace

savesome if lgd_state_name == "maharashtra" using $tmp/vacc_mah, replace
savesome if lgd_state_name == "delhi" using $tmp/vacc_del, replace
savesome if lgd_state_name == "karnataka" using $tmp/vacc_ka, replace

/*************************************/
/* 2. State-wise vacc perk */
/*************************************/

insheet using $ddl/covid/e/pop_estimates_21.csv, clear                                                                                 
ren state_name lgd_state_name                                                                                                                                                                             
replace lgd_state_name = subinstr(lgd_state_name , "&", "and", .)                                                                      
save $tmp/pop_est_21, replace                                      

/* bring in district wise vaccinatoin data */
use $covidpub/covid/covid_vaccination, clear

/* keep most recent date */
keep if date == "12042021"

/* generate count of total vaccination */
egen tot_vacc = rowtotal(total_covaxin total_covishied)

/* combine daman diu and dadra and nagar haveli */
replace lgd_state_name = "dadra and nagar haveli and daman and diu" if inlist(lgd_state_name , "daman and diu", "dadra and nagar haveli")
replace lgd_state_name = "andaman and nicobar" if lgd_state_name == "andaman and nicobar islands"

/* collapse to state level */
collapse (sum) tot_vacc, by(lgd_state_name)

/* get 2021 population */
merge 1:1 lgd_state_name using $tmp/pop_est_21, keep(match)

/* replace a state name  */
replace lgd_state_name = "dnh & daman-diu" if lgd_state_name == "dadra and nagar haveli and daman and diu"

/* create vacc per k */
gen perk_denom = pop_2021_est/1000
gen vacc_perk = tot_vacc/perk_denom

/* bar graph */
set scheme pn
sort vacc_perk
gen axis = _n
labmask axis, values(lgd_state_name)
graph hbar (asis) vacc_perk, over(axis, label(labsize(vsmall))) ytitle("Vaccinations per 1000 people", margin(medium)) ylabel(0 (20) 300) ///
    note("Population data - 2020 estimates from UIDAI")
graphout vacc_perk
