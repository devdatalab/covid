use $covidpub/agmark/agmark_clean, clear
drop if mi(lgd_state_id)

/* adjust formats of identifying variables */
format date %dM_d,_CY
tostring lgd_state_id, format("%02.0f") replace
tostring lgd_district_id, format("%03.0f") replace

/* indicate if something is a perishabel */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* save overall data file */
save $tmp/agmark_data, replace

/* replace quantity with 0 if it's a number, we can't convert this, it's 0.28% of total entries */
replace qty = . if unit == 1

/* first collapse to state and district level */
collapse (sum) qty, by(date lgd_state_id lgd_district_id)

/* merge in covid case data */
merge m:1 date lgd_state_id lgd_district_id using $covidpub/covid/covid_infected_deaths
drop _merge

/* now collapse to national-day level */
collapse (sum) qty cases death, by(date)

/* get year */
gen year = year(date)

/* save */
save $tmp/agmark_total_ts, replace
