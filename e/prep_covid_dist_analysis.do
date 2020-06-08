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

/* convert shares into numbers */
foreach x of var *hl_dwelling_r* *hhsize* {
  replace `x' = `x' * pc11_pca_no_hh
  }

/* collapse at district level */
collapse_save_labels
collapse (sum) *hl_dwelling_r* *hhsize*, by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save as tempfile */
save $out/hh_size_district, replace

/* get case data */
use $covidpub/pc11/covid_infected_deaths_pc11, clear

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
save $out/covid_district_clean, replace

/* save data dictionary to share */
write_data_dict using $tmp/covid_dist.csv, replace


