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
collapse (sum) qd213_r qd214_c, by(pc11_state_id pc11_district)

/* rename and label variables */
ren qd213_r doc_reg
label var doc_reg "General Duty Doctor (regular)"
ren qd214_c doc_contract
label var doc_contract "General Duty Doctor (contractual)"

/* save */
save $ra/dlhs4_dh_docs, replace

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
collapse (sum) qc22a qc22b, by(pc11_state_id pc11_district)

/* label and rename variables */
ren qc22a  doc_reg
label var doc_reg "number of regular physician in position at CHC"
ren qc22b doc_contract
label var doc_contract "number of contractual physician in position at CHC"

/* save */
save $ra/dlhs4_chc_docs, replace

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

/* collapse */
collapse (sum) qp21a qp21b, by(pc11_state_id pc11_district)

/* label and rename variables */
ren qc22a  doc_reg
label var doc_reg "Regular MO in position at PHC"
ren qc22b doc_contract
label var doc_contract "contactual MO in position at PHC"

/* save */
save $ra/dlhs4_phc_docs, replace

/******************/
/* merge together */
/******************/

