use $covidpub/hospitals/ec_hosp_microdata, clear

/* require employment of at least 5 to be counted */
/* NOTE: National Health Profile used 20, we get better correlation with DLHS/PC
         on gov hospitals with smaller thresholds. */
keep if emp_all >= 5

/* collapse count and employment in each type of facility, by ec13 code */
/* note village id and town id are the same thing */
destring sector, replace
collapse (firstnm) sector (sum) count_all emp_all, by(gov nic ec13_state_id ec13_district_id ec13_subdistrict_id ec13_village_id ec13_town_id)

/* convert data into wide format so we can collapse to village/town level */
gen class = string(nic) + "_" + string(gov)
ren *all *all_
drop nic gov
reshape wide count_all_ emp_all_, i(ec13_state_id ec13_district_id ec13_subdistrict_id ec13_village_id ec13_town_id sector) j(class) string

ren *_1 *_gov
ren *_0 *_priv

/* get PC village codes */
merge m:1 ec13_state_id ec13_district_id ec13_subdistrict_id ec13_village_id using $covidpub/keys/pc11r_ec13r_key, keepusing(pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id)
drop if _merge == 2
foreach v in state district subdistrict village {
  ren pc11_`v'_id tmp_pc11_`v'_id
}
ren _merge _merge_v

/* get PC town codes */
merge m:1 ec13_state_id ec13_district_id ec13_subdistrict_id ec13_town_id using $covidpub/keys/pc11u_ec13u_key, keepusing(pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id)
drop if _merge == 2
ren _merge _merge_t

/* restore the variables from the first merge */
replace pc11_state_id = tmp_pc11_state_id if mi(pc11_state_id)
replace pc11_district_id = tmp_pc11_district_id if mi(pc11_district_id)
replace pc11_subdistrict_id = tmp_pc11_subdistrict_id if mi(pc11_subdistrict_id)
ren tmp_pc11_village_id pc11_village_id
drop tmp*

/* systematically rename all variables */
ren emp_all_* emp_*
ren count_all_* num_*

/* drop outpatient practices, psych hospitals, etc.. */
drop *862* *871* *872* *879* *869* *873*

ren *861* *hosp*
drop _merge*

/* label urban/rural sector */
recode sector 1=1 2=0
rename sector rural

/* label variables */
// label_from_gdoc, docid("1h6G4vYL3lvy4Bi8DTY3pMT2-5aVWOBoxAm3plx4M7qQ")

save $covidpub/hospitals/ec_hospitals_tv, replace

/* COLLAPSE TO DISTRICT LEVEL */
use $covidpub/hospitals/ec_hospitals_tv, clear

/* get district ids (can't use village/town match since we had some missing locations) */
ren pc11_state_id tmp_pc11_state_id
ren pc11_district_id tmp_pc11_district_id

/* get pc11 district ids */
merge m:1 ec13_state_id ec13_district_id using $covidpub/keys/pc11_ec13_district_key, keepusing(pc11_state_id pc11_district_id)
drop if _merge == 2
assert _merge == 3
drop _merge

/* see if they match (they better!) */
count if pc11_state_id != tmp_pc11_state_id & !mi(tmp_pc11_state_id)
count if pc11_district_id != tmp_pc11_district_id & !mi(tmp_pc11_district_id)

drop tmp*

list *hosp* if mi(pc11_district_id)

/* replace all delhi districts with missing so it all gets collapsed into 1 */
replace pc11_district_id = "" if ec13_state_id == "07"
collapse (sum) *hosp*, by(pc11_state_id pc11_district_id)

/* prefix all vars with EC prefix */
ren *hosp* ec_*hosp*

/* label from the google sheet dictionary */
// label_from_gdoc, docid("1h6G4vYL3lvy4Bi8DTY3pMT2-5aVWOBoxAm3plx4M7qQ")
save $covidpub/hospitals/ec_hospitals_dist, replace
