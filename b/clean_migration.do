/* Clean district migration in/outflow data */


/*****************************/
/* Create population weights */
/*****************************/

/* pc01 district population */
use $pc01/pc01_pca_district_pop.dta, clear
collapse (sum) pc01_pca_tot_p, by(pc01_state_id pc01_district_id)
ren pc01_pca_tot_p pop01
save $tmp/pc01_pop_fm, replace

/* pc11 district population */
use $pc11/pc11u_pca_district_clean.dta, clear
collapse (sum) pc11_pca_tot_p, by(pc11_state_id pc11_district_id)
ren pc11_pca_tot_p pop_u
save $tmp/pc11_u_pop, replace
use $pc11/pc11r_pca_district_clean.dta, clear
collapse (sum) pc11_pca_tot_p, by(pc11_state_id pc11_district_id)
ren pc11_pca_tot_p pop_r
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_u_pop
assert _merge == 3
drop _merge
gen pop11 = pop_u + pop_r
drop pop_u pop_r

/* merge and create weights */
merge 1:1 pc11_state_id pc11_district_id using $keys/pc11_district_key, keep(master match) keepusing(pc01_state_id pc01_district_id)
assert _merge == 3
drop _merge

/* note that in the pc11 district key, "kanshiram nagar" in UP is missing the correct PC01 district code */
replace pc01_district_id = "17" if pc11_state_id == "09" & pc11_district_id == "202"

/* now merge in pc01 pop */
merge m:1 pc01_state_id pc01_district_id using $tmp/pc01_pop_fm, keepusing(pop01)
assert _merge == 3
drop _merge

/* pc01 districts exclusively split (no rightward combinations over time) */
isid pc11_state_id pc11_district_id

/* create population weight for each pc11 district component */
bysort pc01_state_id pc01_district_id: egen pop_denom = total(pop11)
gen pc11_pc01_pop_wt = pop11 / pop_denom
drop pop_denom
assert pc11_pc01_pop_wt <= 1

/* save for weighting migration data */
compress
save $tmp/pc11_pc01_pop_weights, replace


/******************/
/* Basic cleaning */
/******************/

/* read in raw CSV data (source: Clement Imbert */
import delimited using $covidpub/migration/district_migration_raw.csv, clear varn(1)

/* format census identifiers */
ren statecodecensus2001 pc01_state_id
tostring pc01_state_id, format(%02.0f) replace

/* district is the second component of state-dist compiled codecensus2011 var */
ren codecensus2001 pc01_district_id
tostring pc01_district_id, replace
replace pc01_district_id = substr(pc01_district_id, (strlen(pc01_district_id) - 1),2)

/* merge to pc11 districts, dropping unmatched districts (missing data) */
merge 1:m pc01_state_id pc01_district_id using $keys/pc11_district_key, keep(master match) keepusing(pc11_state_id pc11_district_id) nogen


/********************************/
/* Weight-adjust PC11 migration */
/********************************/

/* merge in weights */
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_pc01_pop_weights, keep(master match) keepusing(pc11_pc01_pop_wt) nogen

/* scale down pc01-dist-based migration numbers by pc11 population for split pc01->pc11 dists */
foreach var of varlist *share {
  replace `var' = `var' * pc11_pc01_pop_wt
}

/* label */
foreach way in in out {
  foreach type in st lt {
    if "`type'" == "st" local typestring "Short-term"
    label var `way'`type'migrationrate "`typestring' district `way'-migration rate (district-wise)"
    label var `way'`type'migrationshare "`typestring' district `way'-migration share (of national `way'-migration)"
    label var `way'`type'migrantstotal "`typestring' total district `way'-migration"
  }
}

/* save */
order _all, alphabetic
order pc11_state_id pc11_district_id, first
drop pc01* pc11_pc01_pop_wt
compress
save $covidpub/migration/pc11/district_migration_pc11, replace

/* use covidsave to push to LGD */
covidsave, native(pc11) out($covidpub/migration/district_migration) metadata_urls("https://docs.google.com/spreadsheets/d/e/2PACX-1vTu79uiVKSFv8c1oZvx7WARrWXSfbwfLakiukoezDaH0spMM_MQalkm5fr4bnkBQVNRs2aiU7x41oi3/pub?gid=0&single=true&output=csv")
