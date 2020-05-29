/**********************************************************************************/
/* program clean_collapsed_data : Insert description here */
/***********************************************************************************/
cap prog drop clean_collapsed_data
prog def clean_collapsed_data

  /* label vars */
  /* note beds data only available for urban areas */
  la var clinic_beds_u "No. of beds across all urban clinics and hospitals"
  la var hosp_beds_u "No. of beds across urban allopathic hospitals"
  la var docs_pos_r "No. of doctors in position - rural"
  la var docs_pos_u "No. of doctors in position - urban"
  la var pmed_pos_r "No. of paramedics in position (rural)"
  la var pmed_pos_u "No. of paramedics in position (urban)"
  la var pc11_pca_tot_p "Total population"
  la var hospitals_r "No. of allopathic hospitals - rural"
  la var hospitals_u "No. of allopathic hospitals - urban"
  la var docs_hosp_r "No. of doctors in allopathic hospitals - rural"
  la var docs_hosp_u "No. of doctors in allopathic hospitals - urban"
  la var clinics_r "No. of rural clinics"
  la var clinics_u "No. of urban clinics"
  
  /* aggregate rural and urban vars */
  egen clinics = rowtotal(clinics_*)
  egen docs = rowtotal(docs_pos_*)
  egen docs_hosp = rowtotal(docs_hosp_*)
  egen pmeds = rowtotal(pmed_pos_*)
  egen num_hospitals = rowtotal(hospitals_*)
  
  /* label new vars */
  la var clinics "Total clinics "
  la var pmeds "Total paramedics in position"
  la var docs "Total doctors in hospitals and clinics"
  la var docs "Total doctors in hospitals only"
  la var num_hospitals "Total hospitals"
  
  ren * pc_*
  ren pc_pc11* pc11*

end
/* *********** END program clean_collapsed_data ***************************************** */

/* open rural hospital/clinic dataset */
use $covidpub/hospitals/pc11r_hosp, clear

/* rename vd vars for append with town data*/
ren pc11_vd_* pc11_td_*

/* separate urban and rural populations */
gen pc11_pca_tot_p_r = pc11_pca_tot_p

compress

/* save temp file ready to be merged with urban dataset */
save $tmp/healthcare_pca_r, replace

/*********/
/* Towns */
/*********/
use $covidpub/hospitals/pc11u_hosp, clear

/* separate urban and rural populations */
gen pc11_pca_tot_p_u = pc11_pca_tot_p

compress
save $tmp/healthcare_pca_u, replace

/******************************************/
/* append rural and urban healthcare data */
/******************************************/
use $tmp/healthcare_pca_u, clear

gen urban = 1

append using $tmp/healthcare_pca_r

replace urban = 0 if mi(urban)

/* drop the veterinary hospitals variables */
drop pc11_td_vet_* pc11_td_veth_*

/* define urban and rural clinic types that will be collapsed into total beds */
local centers_r pc11_td_ch_cntr pc11_td_ph_cntr pc11_td_phs_cntr pc11_td_tb_cln pc11_td_all_hosp pc11_td_disp pc11_td_mh_cln pc11_td_med_in_out_pat pc11_td_med_c_hosp_home
local centers_u pc11_td_all_hosp pc11_td_disp pc11_td_tbc pc11_td_nh pc11_td_mh pc11_td_in_out_pat pc11_td_c_hosp_home

/*****************************************/
/* drop outliers after manual inspection */
/*****************************************/

/* drop villages that are too small to plausibly have a clinic */
drop if pc11_pca_tot_p < 50

/* REVIEW CENTERS/CLINICS OUTLIERS */

/* general logic - you cannot have more than 1 center for every 10 people */
/* we make an exception for very small villages in case the clinic is somehow defined as the village.
  the bed counts will be low for these places anyway, so it won't bias things much.
*/

/* review potential outliers on clinic numbers */
foreach x of var `centers_r' {
  disp_nice "`x'"
  
  /* calculate clinics per person */
  gen `x'_pc = (`x' / pc11_pca_tot_p) if urban == 0

  /* calculate docs per person (if available) */
  cap gen `x'_doc_pc = (`x'_doc_pos / pc11_pca_tot_p) if urban == 0

  /* list clinic outliers */
  noi cap list `x'_pc `x'_doc_pc `x' `x'_doc_pos pc11_pca_tot_p if `x'_pc > 0.1 & !mi(`x'_pc) & urban == 0
  if _rc {
    list `x'_pc `x' pc11_pca_tot_p if `x'_pc > 0.1 & !mi(`x'_pc) & urban == 0
  }
  else {
    list `x'_pc `x'_doc_pc `x' `x'_doc_pos pc11_pca_tot_p if `x'_doc_pc > 0.1 & !mi(`x'_doc_pc) & urban == 0
  }

  /* dropping at 1 clinic for every 10 people is clearly not dropping too many places. */
  /* The few places that might be correct have a really small nubmer of docs anyway so won't break the estimates */
  replace `x' = . if `x'_pc > .1 & urban == 0
  cap replace `x'_doc_tot = . if `x'_pc > .1 & urban == 0
  cap replace `x'_doc_pos = . if `x'_pc > .1 & urban == 0
}

/* drop the village with exactly 50 docs in every type of hospital */
drop if pc11_td_ch_cntr_doc_pos == 50 & pc11_pca_tot_p == 551
capdrop *_pc

/* REPEAT ON URBAN SIDE */
foreach x of var `centers_u' {
  disp_nice "`x'"
  
  /* calculate clinics per person */
  gen `x'_pc = (`x' / pc11_pca_tot_p) if urban == 1

  /* calculate docs per person (if available) */
  cap gen `x'_doc_pc = (`x'_doc_pos / pc11_pca_tot_p) if urban == 1

  /* calculate beds per capita */
  cap gen `x'_beds_pc = (`x'_beds / pc11_pca_tot_p) if urban == 1
  
  /* skip outpatient facilities and hospices which we don't use below anyway */
  if _rc continue

  /* list clinic outliers */
  sum `x'_pc if urban == 1, d
  list `x'_pc `x'_doc_pc `x'_beds_pc `x' `x'_doc_pos `x'_beds pc11_pca_tot_p if `x'_pc > 0.1 & !mi(`x'_pc) & urban == 1
  
  /* list doc outliers */
  sum `x'_doc_pc if urban == 1, d
  list `x'_pc `x'_doc_pc `x'_beds_pc `x' `x'_doc_pos `x'_beds pc11_pca_tot_p if `x'_doc_pc > 0.1 & !mi(`x'_doc_pc) & urban == 1

  /* list bed outliers */
  sum `x'_beds_pc if urban == 1, d
  list `x'_pc `x'_doc_pc `x'_beds_pc `x' `x'_doc_pos `x'_beds pc11_pca_tot_p if `x'_doc_pc > 0.1 & !mi(`x'_doc_pc) & urban == 1
}

/*****************************************/
/* IMPUTE BIG CITIES WITH ZERO BEDS/DOCS */
/*****************************************/

/* the upper limit of hospital beds per capita seems fine-- these are mainly driven by small
  towns and are thus plausible and won't affect our district counts that much.  The lower
  limit is more of a concern-- there are 35 towns with pop > 100,000 and zero reported hospitals.
  These probably reflect incorrect zeroes but it's hard to know how to fill them in. */
list pc11_td_all_hosp_pc pc11_td_all_hosp_doc_pc pc11_td_all_hosp_beds_pc pc11_td_all_hosp pc11_td_all_hosp_doc_pos pc11_td_all_hosp_beds pc11_pca_tot_p if pc11_td_all_hosp_pc > 0.001 & !mi(pc11_td_all_hosp_pc) & urban == 1
list pc11_td_all_hosp_doc_pc pc11_td_all_hosp_doc_pc pc11_td_all_hosp_beds_pc pc11_td_all_hosp pc11_td_all_hosp_doc_pos pc11_td_all_hosp_beds pc11_pca_tot_p if pc11_td_all_hosp_doc_pc > 0.01 & !mi(pc11_td_all_hosp_doc_pc) & urban == 1
list pc11_td_all_hosp_beds_pc pc11_td_all_hosp_doc_pc pc11_td_all_hosp_beds_pc pc11_td_all_hosp pc11_td_all_hosp_doc_pos pc11_td_all_hosp_beds pc11_pca_tot_p if pc11_td_all_hosp_beds_pc > 0.01 & !mi(pc11_td_all_hosp_beds_pc) & urban == 1

/* review places with high dispensary beds per capita */
/* nothing way out of the ballpark and numbers are way lower than hospitals, so unlikely to cause district-level errors */
sort pc11_td_disp_pc 
list pc11_td_disp_pc pc11_td_disp_beds_pc pc11_td_disp_beds_pc pc11_td_disp pc11_td_disp_beds pc11_td_disp_beds pc11_pca_tot_p if pc11_td_disp_beds_pc > 0.005 & !mi(pc11_td_disp_beds_pc) & urban == 1

/* TB clinics */
sum pc11_td_tbc_beds_pc, d
sort pc11_td_tbc_pc 
list pc11_td_tbc_pc pc11_td_tbc_beds_pc pc11_td_tbc_beds_pc pc11_td_tbc pc11_td_tbc_beds pc11_td_tbc_beds pc11_pca_tot_p if pc11_td_tbc_beds_pc > 0.005 & !mi(pc11_td_tbc_beds_pc) & urban == 1

/* Mobile health clinics */
sum pc11_td_mh_beds_pc, d
sort pc11_td_mh_pc 
list pc11_td_mh_pc pc11_td_mh_beds_pc pc11_td_mh_beds_pc pc11_td_mh pc11_td_mh_beds pc11_td_mh_beds pc11_pca_tot_p if pc11_td_mh_beds_pc > 0.005 & !mi(pc11_td_mh_beds_pc) & urban == 1

/* Flag obs with high population and 0 allo beds and docs per thousand ppl */
/* High population defined as pop >= 100,000  */
/* Note: we are focusing just on allopathic hosp as they are the most prevalent facility type in towns */
/* For flagged obs, doc and bed vars were replaced with district means */

/* doctors */
gen docs_impute = 1 if pc11_td_all_hosp_doc_pc == 0 & !mi(pc11_td_all_hosp_doc_pc) & pc11_pca_tot_p >= 100000 & urban == 1 & !mi(pc11_pca_tot_p)

/* note - 38 towns have been flagged by the docs_impute variable */

/* beds */
gen beds_impute = 1 if pc11_td_all_hosp_beds_pc == 0 & !mi(pc11_td_all_hosp_beds_pc) & pc11_pca_tot_p >= 100000 & urban == 1 & !mi(pc11_pca_tot_p)

/* note - 37 towns have been flagged, these overlap with towns flagged above */
drop *_pc

/* calculate means at the district level to impute values */

/* beds */
foreach x of var *_beds {

  /* calculate district level means for each variable */
  bys pc11_state_id pc11_district_id: egen m_`x' = mean(`x') if urban == 1

  /* replace values with mean in flagged vars in obs with missing/zero content*/
  replace `x' = m_`x' if beds_impute == 1 & (`x' == 0 | mi(`x'))
}

/* doctors */
foreach x of var *_doc_tot *_doc_pos {
  
  /* calculate district level means for each variable */
  bys pc11_state_id pc11_district_id: egen m_`x' = mean(`x') if urban == 1

  /* replace values with mean in flagged vars */
  replace `x' = m_`x' if docs_impute == 1
}

/* drop unnecessary vars */
drop m_* *_impute


/* in the end, we didn't drop any urban outliers because all of these were either
  in the ballpark or were very low numbers in levels and thus don't affect district
  numbers much. */

/************************************/
/* create health capacity variables */
/************************************/

/* doctors (total, urban and rural) */
egen docs_pos_r = rowtotal(*_doc_pos) if urban == 0
egen docs_pos_u = rowtotal(*_doc_pos) if urban == 1

/* paramedics (total, urban and rural) */
egen pmed_pos_r = rowtotal(*_pmed_pos) if urban == 0
egen pmed_pos_u = rowtotal(*_pmed_pos) if urban == 1

/* clinics (total, urban and rural) */
egen clinics_r = rowtotal(pc11_td_ch_cntr pc11_td_ph_cntr pc11_td_phs_cntr pc11_td_tb_cln pc11_td_all_hosp pc11_td_disp pc11_td_mh_cln pc11_td_med_in_out_pat pc11_td_med_c_hosp_home) if urban == 0
egen clinics_u = rowtotal(pc11_td_all_hosp pc11_td_disp pc11_td_tbc pc11_td_nh pc11_td_mh pc11_td_in_out_pat pc11_td_c_hosp_home) if urban == 1
gen hospitals_r = pc11_td_all_hosp if urban == 0
gen hospitals_u = pc11_td_all_hosp if urban == 1

/* beds (total and allopathic) (note: no beds in rural data) */
egen clinic_beds_u = rowtotal(*_beds)
egen hosp_beds_u = rowtotal(*_all_hosp_beds)

/* rename and store doctors in allopathic hospitals -- same variable for urban and rural */
gen docs_hosp_u = pc11_td_all_hosp_doc_pos if urban == 1
gen docs_hosp_r = pc11_td_all_hosp_doc_pos if urban == 0

/* this gets used by gen_lgd_pc11_demographics.do */
save $covidpub/intermediate/pc_hosp_precollapse, replace

/*******************************************/
/* district and subdistrict level collapse */
/*******************************************/
use $covidpub/intermediate/pc_hosp_precollapse, clear

/* collapse to sub district level */
collapse (sum) hosp* pmed_* docs_* clinics_* clinic_beds_u  pc11_pca_tot_p, by(pc11_state_id pc11_district_id pc11_subdistrict_id)

/* label vars, create urban + rural aggregates, set PC prefix */
clean_collapsed_data

/* save subdistrict dataset */
save $covidpub/hospitals/pc/pc_hospitals_subdist_pc11, replace
export delimited $covidpub/hospitals/csv/pc_hospitals_subdist_pc11.csv, replace

/* REPEAT COLLAPSE AT DISTRICT LEVEL */
use $covidpub/intermediate/pc_hosp_precollapse, clear
collapse (sum) hosp* pmed_* docs_* clinics_* clinic_beds_u  pc11_pca_tot_p, by(pc11_state_id pc11_district_id )
clean_collapsed_data
save $covidpub/hospitals/pc11/pc_hospitals_dist_pc11, replace
export delimited $covidpub/hospitals/csv/pc_hospitals_dist_pc11.csv, replace

/* create LGD version */
convert_ids, from_ids(pc11_state_id pc11_district_id) to_ids(lgd_state_id lgd_district_id) key($keys/lgd_pc11_district_key_weights.dta) weight_var(pc11_lgd_wt_pop) metadata_urls(https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pub?gid=1900447643&single=true&output=csv)
save $covidpub/hospitals/pc_hospitals_dist, replace
export delimited $covidpub/hospitals/csv/pc_hospitals_dist.csv, replace

