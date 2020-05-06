/* comparing different definitions of "doctor" in DLHS4 with PC estimates (Issue #8) */

/**********************/
/* district hospitals */
/**********************/

/* import and combine data */
use $health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_dh, clear
append using $health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/DH_NONAHS

/* merge in pc11 districts */
merge m:1 state dist using $health/DLHS4_FacilitySurveyData/dlhs4_district_key, keepusing(pc11_state_id pc11_state_name pc11_district_id pc11_district_name)
drop if _merge == 2
drop _merge

/* collapse */
collapse (sum) qd213_r qd214_c, by(pc11_state_id pc11_district_id)

/* rename and label variables */
ren qd213_r dh_doc_reg
label var dh_doc_reg "General Duty Doctor (regular)"
ren qd214_c dh_doc_contract
label var dh_doc_contract "General Duty Doctor (contractual)"

/* save */
save $tmp/dlhs4_dh_docs, replace

/****************************/
/* community health centers */
/****************************/

/* import and combine data */
use $health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_chc.dta , clear
append using $health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/CHC_NONAHS.dta

/* merge in pc11 districts */
merge m:1 state dist using $health/DLHS4_FacilitySurveyData/dlhs4_district_key.dta, keepusing(pc11_state_id pc11_state_name pc11_district_id pc11_district_name)
drop if _merge == 2
drop _merge

/* collapse */
collapse (sum) qc22a qc22b, by(pc11_state_id pc11_district_id)

/* label and rename variables */
ren qc22a chc_doc_reg
label var chc_doc_reg "number of regular physician in position at CHC"
ren qc22b chc_doc_contract
label var chc_doc_contract "number of contractual physician in position at CHC"

/* save */
save $tmp/dlhs4_chc_docs, replace

/**************************/
/* primary health centers */
/**************************/

/* import and combine data */
use $health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_phc.dta , clear
append using $health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/PHC_NONAHS.dta

/* merge in pc11 districts */
merge m:1 state dist using $health/DLHS4_FacilitySurveyData/dlhs4_district_key.dta, keepusing(pc11_state_id pc11_state_name pc11_district_id pc11_district_name)
drop if _merge == 2
drop _merge

/* generate population served for calculation of multiplier */
gen phc_pop = qp3

/* drop if bad data (zero pop/staff, or missing data) -- assuming random bad data so multiplier accurate */
drop if mi(phc_pop) | phc_pop == 0

/* collapse */
collapse (sum) phc_pop qp21a qp21b, by(pc11_state_id pc11_district_id)

/* label and rename variables */
ren qp21a phc_doc_reg
label var phc_doc_reg "Regular MO in position at PHC"
ren qp21b phc_doc_contract
label var phc_doc_contract "contactual MO in position at PHC"

/* save */
save $tmp/dlhs4_phc_docs, replace

/******************/
/* merge together */
/******************/

/* merge all three temporary datasets */
use $tmp/dlhs4_dh_docs, clear
merge 1:1 pc11_state_id pc11_district_id using $tmp/dlhs4_chc_docs, gen(_m_chc)
drop _m_chc
merge 1:1 pc11_state_id pc11_district_id using $tmp/dlhs4_phc_docs, gen(_m_phc)
drop _m_phc

/* get district population */
merge 1:1 pc11_district_id using $pc11/pc11_pca_district_clean, keepusing(pc11_pca_tot_p) gen(_m_pca)
drop if _m_pca == 2
drop _m_pca
describe
/* replace missing with 0 */
foreach i in dh chc phc {
  foreach j in doc_reg doc_contract  {
    replace `i'_`j' = 0 if mi(`i'_`j')
    }
}

/* generate multiplier for PHC numbers */
gen phc_mult = pc11_pca_tot_p / phc_pop
replace phc_mult = 0 if mi(phc_mult)
label var phc_mult "Sampling weight on PHCs"

/* generate total doctors in district */
gen total_doc_reg = dh_doc_reg + chc_doc_reg + (phc_doc_reg * phc_mult)
gen total_doc_contract = dh_doc_contract + chc_doc_contract + (phc_doc_contract * phc_mult)
gen total_doc = total_doc_reg + total_doc_contract

/* label new variables */
label var total_doc_reg "Total regular general duty doctors"
label var total_doc_contract "Total contract general duty doctors"
label var total_doc "Total general duty doctors"

/* clean up */
ren * dlhs4_*
ren dlhs4_pc11* pc11*
sort pc11_state_id pc11_district_id pc11_pca_tot_p

/* save */
label var pc11_state_id "PC11 state id"
label var pc11_district_id "PC11 district id"
compress
save $ra/dlhs4_doctors, replace

/****************************/
/* analyze new definitions  */
/****************************/

/* open DLHS4 dataset */
use $ra/dlhs4_doctors.dta, clear

/* merge with PC data */
merge 1:1 pc11_district_id using $covidpub/hospitals/pc_hospitals_dist.dta
drop if _merge != 3

/* collapse to state level */
collapse (sum) dlhs4* pc11_pca_tot_p pc_*, by(pc11_state_id)

/* add state names */
get_state_names, y(11)

/* drop states with populations less than 5m */
drop if pc11_pca_tot_p < 5000000

/* generate absolute values table */
sort pc_docs_hosp
list pc11_state_name pc_docs_hosp dlhs4_total_doc
