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
keep pc01_state_id pc01_district_id pc01_village_id dist_mumb dist_delhi

/* merge with pc11 key to get pc11 ids */
merge 1:m pc01_state_id pc01_district_id pc01_village_id using $keys/pcec/pc01r_pc11r_key, keepusing(pc11_state_id pc11_district_id pc11_village_id) nogen keep(match)

/* merge with population data for population weighting */
merge 1:1 pc11_state_id pc11_district_id pc11_village_id using $pc11/pc11r_pca_clean, nogen keep(match) keepusing(pc11_pca_tot_p)

/* collapse at district level */
collapse_save_labels
collapse (mean) dist_mumb dist_delhi [aw = pc11_pca_tot_p], by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save as tempfile */
save $out/dist_mumb_delhi, replace

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


exit



/* explore */
use $out/covid_district_clean, clear
merge 1:1 pc11_state_id pc11_district_id  using $covidpub/migration/pc11/district_migration_pc11, keepusing(outstmigrationshare outstmigrantstotal) keep(master match) nogen

/* calculate average household size */
merge 1:1 pc11_state_id pc11_district_id using $pc11/pc11_pca_district_clean, keepusing(pc11_pca_no_hh) nogen keep(master match)
gen hh_size = pc11_pca_tot_p / pc11_pca_no_hh

/* generate migration district data (share in national total*total national migrants) */
gen outmigrants = outstmigrationshare * outstmigrantstotal

/* gen per capita outmigration rate */
gen outmigrant_share = outstmigration / pc11_pca_tot_p * 1000000

/* get district names */
merge 1:1 pc11_state_id pc11_district_id using $keys/pc11_district_key, keepusing(pc11_district_name)

/* create ed vars */
gen ln_cases = ln(total_cases + 1)
gen ln_deaths = ln(total_deaths + 1)
gen ln_pop = ln(pc11_pca_tot_p + 1)
gen ln_pop_u = ln(pc11u_pca_tot_p + 1)
gen ln_pop_r = ln(pc11r_pca_tot_p + 1)
gen ln_density_u = ln(pc11u_pdensity)
gen ln_density_r = ln(pc11r_pdensity)
gen sc_share = pc11_pca_p_sc / pc11_pca_tot_p

/* drinking water access */
gen ln_pop_r_with_water = ln(pc11r_hl_dw_loc_inprem_no + 1)
gen ln_pop_u_with_water = ln(pc11u_hl_dw_loc_inprem_no + 1)

/* calculate old population */
egen pop_over_65_r = rowtotal(age_65_r age_70_r age_75_r age_80_r)
egen pop_over_65_u = rowtotal(age_65_u age_70_u age_75_u age_80_u)
egen pop_over_65 = rowtotal(age_65_t age_70_t age_75_t age_80_t)
gen ln_pop_over_65_r = ln(pop_over_65_r + 1)
gen ln_pop_over_65_u = ln(pop_over_65_u + 1)
gen ln_pop_over_65 = ln(pop_over_65 + 1)

/* slum share */
gen slum_share = pc11_slum_tot_p / pc11_pca_tot_p

/* share with clean water */
gen water_share_r = pc11r_hl_dw_loc_inprem_no / pc11r_pca_tot_p
gen water_share_u = pc11u_hl_dw_loc_inprem_no / pc11u_pca_tot_p
gen water_share_t = (pc11u_hl_dw_loc_inprem_no + pc11r_hl_dw_loc_inprem_no) / pc11_pca_tot_p
/* rescale to 0->1 since a scaling error with these */
foreach v in r u t {
  sum water_share_`v'
  replace water_share_`v' = water_share_`v' / `r(max)'
}

/* urbanization rate */
gen urban_share = pc11u_pca_tot_p / pc11_pca_tot_p

/* elderly share */
gen over65_share_r = pop_over_65_r / pc11r_pca_tot_p
gen over65_share_u = pop_over_65_u / pc11u_pca_tot_p
gen over65_share_t = pop_over_65 / pc11_pca_tot_p

/* identify mumbai */
gen mumbai = inlist(pc11_district_name, "mumbai", "mumbai suburban", "thane")

/* log distance to mumbai */
gen ln_dist_mumb = ln(dist_mumb + 1)
replace ln_dist_mumb = 0 if mumbai == 1
gen ln_dist_delhi = ln(dist_delhi + 1)
replace ln_dist_delhi = 0 if pc11_district_name == "new delhi"

/* many big cities don't have these distances, so just use means */
replace ln_dist_mumb = 7 if mi(ln_dist_mumb)
replace ln_dist_delhi = 6.6 if mi(ln_dist_delhi)
replace dist_mumb = 1272 if mi(dist_mumb)
replace dist_delhi = 1019 if mi(dist_delhi)


/* label variables */
label var ln_cases "Log Infections"
label var ln_pop "Log Population" 
label var urban_share "Urban pop share"
label var ln_density_u "Log Urban Pop Density"
label var slum_share "Share Pop in Slums"
label var sc_share "Share Scheduled Caste"
label var over65_share_t "Share Over Age 65"
label var water_share_t "Share with clean water"
label var ln_dist_mumb "Log distance to Mumbai"
label var hh_size "Avg Household Size"

/* run ed regression */
eststo clear
eststo: reg ln_cases ln_pop
eststo: reg ln_cases ln_pop urban_share ln_density_u 
eststo: reg ln_cases ln_pop urban_share ln_density_u slum_share sc_share over65_share_t water_share_t ln_dist_mumb hh_size 

eststo: reg ln_deaths ln_pop
eststo: reg ln_deaths ln_pop urban_share ln_density_u 
eststo: reg ln_deaths ln_pop urban_share ln_density_u slum_share sc_share over65_share_t water_share_t ln_dist_mumb hh_size
estout_default using $tmp/ed

/* slum binscatters */
binscatter ln_cases slum_share, xtitle("Pop share in slums") ytitle("# Infections") 
graphout slum_share

binscatter ln_cases over65_share_t, xtitle("Pop share over age 65") ytitle("# Infections") 
graphout over65_share






