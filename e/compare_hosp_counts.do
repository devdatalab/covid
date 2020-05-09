/********************************************************************************************/
/* COPY CODE FROM HOSPITAL ESTIMATES TO GET DLHS LINKED WITH PC, AND SCALE UP PC BED COUNTS */
/********************************************************************************************/

/* combine DLHS, Population Census, Economic Census, to estimate hospital
  capacity at the district and subdistrict level. */

/* merge DLHS, PC, EC together at district level */
use $covidpub/hospitals/dlhs4_hospitals_dist.dta, clear
merge 1:1 pc11_state_id pc11_district_id using $covidpub/hospitals/ec_hospitals_dist.dta, gen(_m_ec13)
merge 1:1 pc11_state_id pc11_district_id using $covidpub/hospitals/pc_hospitals_dist.dta, gen(_m_pc11)

/* drop if missing pc11 ids */
drop if mi(pc11_state_id) | mi(pc11_district_id)

/* reconcile variable names (though really should do this in the build files above) */
ren dlhs4* dlhs*

/* key variables */
/* dlhs: dlhs4_total_beds, dlhs4_total_count, dlhs4_total_staff */
/* ec13: ec_emp_hosp_priv, ec_emp_hosp_gov */
/* pc11: pc_hosp_beds_u pc_clinic_beds_u */

/* generate private share from EC */
gen ec_priv_hosp_share = ec_emp_hosp_priv / (ec_emp_hosp_priv + ec_emp_hosp_gov)
sum ec_priv_hosp_share,d
/* tons of variation, from 0 to 1, med .52, close to uniform */

/* generate total ec emp in hospitals */
gen ec_emp_hosp_tot = ec_emp_hosp_priv + ec_emp_hosp_gov

/* gen urban to rural doctor share */
gen pc_doc_u_share = pc_docs_pos_u / (pc_docs_pos_r + pc_docs_pos_u)

/* gen urban to rural doctor in hospital share */
gen pc_hosp_doc_u_share = pc_docs_hosp_u / (pc_docs_hosp_r + pc_docs_hosp_u)

/* scale up urban beds in pop census using rural share of doctors */

/* use overall doc share for clinic beds */
gen pc_clinic_beds = pc_clinic_beds_u / pc_doc_u_share

/* use hospital doc share for hospital beds */
gen pc_hosp_beds = pc_hosp_beds_u / pc_hosp_doc_u_share

/* scale up DLHS primary health clinics */
foreach v in beds count staff pop {
  replace dlhs_phc_`v' = dlhs_phc_`v' * dlhs_phc_mult
}

/* combine two DLHS clinic types */
egen dlhs_clinic_beds = rowtotal(dlhs_chc_beds dlhs_phc_beds)

/* compare different clinic type counts */
corr dlhs_dh_beds dlhs_chc_beds dlhs_phc_beds dlhs_clinic_beds pc_clinic_beds pc_hosp_beds


/* log correlation */
foreach v in dlhs_dh_beds dlhs_chc_beds dlhs_phc_beds dlhs_clinic_beds pc_clinic_beds pc_hosp_beds {
  gen ln_`v' = ln(`v' + 1)
}

corr ln_*



dlhs4_dh_beds   int     %9.0g                 Total beds in district hospitals
dlhs4_dh_count  byte    %9.0g                 Total district hospitals
dlhs4_dh_staff  int     %9.0g                 Total staff district hospitals
dlhs4_chc_beds  int     %9.0g                 Total beds in community health centers
dlhs4_chc_count byte    %9.0g                 Total community health centers
dlhs4_chc_staff int     %9.0g                 Total staff in community health centers
dlhs4_phc_beds  int     %9.0g                 Total beds in primary health centers
dlhs4_phc_count byte    %9.0g                 Total primary health centers
dlhs4_phc_staff int     %9.0g                 Total staff in primary health centers
dlhs4_phc_pop   long    %9.0g                 Population covered by sampled primary health centers













/***********************/
/* explore ICU shares  */
/***********************/
use $health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_dh, clear
append using $health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/DH_NONAHS

/* merge in pc11 districts */
merge m:1 state dist using $health/DLHS4_FacilitySurveyData/dlhs4_district_key, keepusing(pc11_state_id pc11_state_name pc11_district_id pc11_district_name)
drop if _merge == 2
drop _merge

collapse (sum) qd2 qd68_total, by(pc11_state_name pc11_state_id)

gen ratio = qd68_total / qd2

sort ratio
list

merge 1:1 pc11_state_id using $pc11/pc11_pca_state_clean, keepusing(pc11_pca_tot_p)

gen icu_per_100k = qd68_total / pc11_pca_tot_p * 100000
gen bed_per_k = qd2 / pc11_pca_tot_p * 1000

sort icu_per_100k
list pc11_state_name icu_per_100k bed_per_k
