cap mkdir $tmp/covid_district
global out $tmp/covid_district

/* prepare demographic district level data */
use $covidpub/demography/pc11/dem_district_pc11, clear

/* keep necessary vars */
keep pc11_state_id pc11_district_id *pca_tot_p *_pdensity *dw_loc*

/* save as tempfile */
save $out/dem_water_district_pc11, replace

/* extract caste and religion data from pca */
use $pc11/pc11r_pca_clean, clear

/* append urban pca data */
append using $pc11/pc11u_pca_clean

/* collapse caste vars at the district level */
collapse_save_labels
collapse (sum) pc11*sc pc11*st, by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save as tempfile */
save $out/dem_caste_district_pc11, replace

/* extract share of pop > 65 yrs */
use $covidpub/demography/pc11/age_bins_district_t_pc11, clear

/* keep necessary vars */
keep *65* *70* *75* *80* pc11_state_id pc11_district_id

/* order vars */
order *r_share *u_share, last

/* save as tempfile */
save $out/dem_age_share_district_pc11, replace

/* prep pc11 town key for merge with slums data */
use $keys/pc11_town_key, clear

/* keep unique combination of pc11_state_id and pc11_town_id  */
bys pc11_state_id pc11_town_id : keep if _n == 1

/* save as tempfile */
save $tmp/pc11_town_key_unique, replace

/* extract share living in slums */
use $pc11/slums/pc11u_slums, clear

/* keep necessary vars */
keep *slum_tot* pc11_state_id pc11_town_id

/* merge with pc11 key to get district id */
merge 1:1 pc11_state_id pc11_town_id using $tmp/pc11_town_key_unique, keepusing(pc11_district_id) keep(match master) nogen

/* collapse at district level */
collapse_save_labels
collapse (sum) *slum_tot*, by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save as tempfile */
save $out/dem_slum_share_district_pc11, replace

/* extract household size data */
foreach i in r u {
  if "`i'" == "r" local level village
  if "`i'" == "u" local level town

/* import data */
  use $pc11/houselisting_pca/pc11`i'_hpca_`level', clear

/* rename vars */
  ren pc11`i'* pc11*
  
/* merge to extract hh size */
  merge m:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_`level'_id using $pc11/pc11`i'_pca_clean, keepusing(pc11_pca_no_hh) keep(match) nogen
  
/* keep necessary vars */
  keep *no_hh* *hl_dwelling_r* *hhsize* pc11_state_id pc11_district_id

/* save as tempfile */
  save $tmp/hh_`i', replace
}

/* append and collapse to district level */
use $tmp/hh_r, clear
append using $tmp/hh_u

/* convert household size to total before collapse */
egen pc11_pca_total_hh = sum(pc11_pca_no_hh)

/* collapse at district level */
collapse_save_labels
collapse (mean) *hl_dwelling_r* *hhsize* *total_hh, by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* rename variable to calculate avg dwelling size */
ren pc11_hl_dwelling_r_6p pc11_hl_dwelling_r_6

/* average dwelling size */
gen pc11_avg_room_no = 0

/* calculate numerator */
forval i = 1/6{
  replace pc11_avg_room_no = pc11_avg_room_no + `i' * pc11_hl_hhsize_`i'
  }

/* calculate avg no of rooms in each house */
replace pc11_avg_room_no = pc11_avg_room_no/100
la var pc11_avg_room_no "Avg no. of rooms in a house"

/* keep necessary vars */
keep pc11_avg_room_no pc11_pca_total_hh pc11_state_id pc11_district_id 

/* save as tempfile */
save $out/hh_size_district, replace

/* get distance variables */
use $iec/misc_data/india_GIS/distances/pc01_village_highway_distances, clear

/* keep relevant vars */
keep pc01_state_id pc01_district_id pc01_village_id dist_mumb

/* merge with pc11 key to get pc11 ids */
merge 1:m pc01_state_id pc01_district_id pc01_village_id using $keys/pcec/pc01r_pc11r_key, keepusing(pc11_state_id pc11_district_id pc11_village_id) nogen keep(match)

/* merge with population data for population weighting */
merge 1:1 pc11_state_id pc11_district_id pc11_village_id using $pc11/pc11r_pca_clean, nogen keep(match) keepusing(pc11_pca_tot_p)

/* collapse at district level */
collapse_save_labels
collapse (mean) dist_mumb [aw = pc11_pca_tot_p], by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save as tempfile */
save $out/dist_mumb, replace

/* get shrug distance variables */
use $iec/covid/idi_survey/survey_shrid_data, clear

/* keep necessary vars */
keep shrid tdist* 

/* merge to get pc11 ids */
merge 1:1 shrid using $shrug/keys/shrug_pc11_district_key, keep(match) nogen keepusing(pc11_state_id pc11_district_id)

/* collapse */
collapse_save_labels
collapse (mean) tdist*, by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save */
save $out/shrid_tdist_district, replace

/* get case data */
use $covidpub/covid/pc11/covid_infected_deaths_pc11, clear

/* collapse cases to district level */
collapse_save_labels
collapse (sum) total_cases total_deaths, by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save as tempfile */
save $out/cases_district, replace

/* merge all datasets */
local filelist: dir "$out/" files "*dta"

/* merge all the files in the output directory to save a single clean file */
use $out/cases_district, clear

foreach file in `filelist' {
  merge 1:1 pc11_state_id pc11_district_id using $out/`file', nogen
}

/* save final dataset */
save $iec/output/covid/covid_district_clean, replace

/* save data dictionary to share */
write_data_dict using $tmp/covid_dist.csv, replace


