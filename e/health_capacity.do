/************/
/* Villages */
/************/


use $pc11/pc11_vd_clean.dta, clear


/* check missing data percent for various health center variables */
mdesc pc11_vd_nc_icds pc11_vd_nc_agwd pc11_vd_asha pc11_vd_med_in_out_pat pc11_vd_med_c_hosp_home pc11_vd_med_prac_* pc11_vd_med_trad_fth pc11_vd_fwc_cntr pc11_vd_mh_cln pc11_vd_disp pc11_vd_altmed_hosp pc11_vd_all_hosp pc11_vd_tb_cln pc11_vd_mcw_cntr pc11_vd_phs_cntr pc11_vd_ph_cntr pc11_vd_ch_cntr

/* merge with pca data */
isid pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id

/* merge with pca clean data at village level */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id using $pc11/pc11r_pca_clean.dta, update
keep if _merge>2
drop _merge

/* drop unnecessary vars to make dataset manageable */
drop pc11_pca_marg* pc11_pca_main* pc11_pca_non*
drop pc11_vd_power* pc11_vd_land*
drop pc11_vd_mgt_inst_gov_status - pc11_vd_oth_sch_rang
drop pc11_vd_wat_tap_trt - pc11_vd_poll_st_rang
drop pc11_vd_agr_comm1- pc11_vd_hc_comm3


/* drop outliers */

sum pc11_vd_ph_cntr, d
gen flag=1 if pc11_vd_ph_cntr >= 30000

sum pc11_vd_phs_cntr, d
replace flag=1 if pc11_vd_phs_cntr >= 70000

sum pc11_vd_all_hosp, d
replace flag=1 if pc11_vd_all_hosp >= 300

sum pc11_pca_tot_p, d
replace flag=1 if pc11_pca_tot_p >= 9039

drop if flag==1

/* rename vd vars for append with town data*/
ren pc11_vd_* pc11_td_*

compress

/* save merged dataset */

save $tmp/healthcare_pca_r.dta, replace


/*********/
/* Towns */
/*********/

use $pc11/pc11_td_clean.dta, clear

/* merge with pca clean data at village level */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $pc11/pc11u_pca_clean.dta, update
keep if _merge>2
drop _merge

/* drop unnecessary vars to make dataset manageable */
drop pc11_pca_marg* pc11_pca_main* pc11_pca_non*
drop pc11_td_sys_drain-pc11_td_el_others
drop pc11_td_primary_gov_status-pc11_td_n_a_c_soc

/* drop outliers */

sum pc11_td_all_hospital, d
gen flag=1 if pc11_td_all_hospital >= 100

sum pc11_td_alt_hospital, d
replace flag=1 if pc11_td_alt_hospital>=38

sum pc11_td_disp, d
replace flag=1 if pc11_td_disp>=341

sum pc11_pca_tot_p, d
replace flag=1 if pc11_pca_tot_p >= 505693

drop if flag==1


compress

save $tmp/healthcare_pca_u.dta, replace



/*******************************************/
/* combine rural and urban healthcare data */
/*******************************************/


use $tmp/healthcare_pca_u.dta, clear

gen urban = 1

append using $tmp/healthcare_pca_r.dta

replace urban = 0 if urban==.

/************************************/
/* create health capacity variables */
/************************************/

/* doctors (total, urban and rural) */
egen doctors_pos_r = rowtotal(*_doc_pos) if urban==0
egen doctors_pos_u = rowtotal(*_doc_pos) if urban==1

egen doctors_tot_r = rowtotal(*_doc_tot) if urban==0
egen doctors_tot_u = rowtotal(*_doc_tot) if urban==1


/* paramedics (total, urban and rural) */
egen pmed_pos_r = rowtotal(*_pmed_pos) if urban==0
egen pmed_pos_u = rowtotal(*_pmed_pos) if urban==1

egen pmed_tot_r = rowtotal(*_pmed_tot) if urban==0
egen pmed_tot_u = rowtotal(*_pmed_tot) if urban==1


/* clinics (total, urban and rural) */
egen clinics_r = rowtotal(pc11_td_ch_cntr pc11_td_ph_cntr pc11_td_phs_cntr pc11_td_tb_cln pc11_td_all_hosp pc11_td_disp pc11_td_mh_cln pc11_td_med_in_out_pat pc11_td_med_c_hosp_home) if urban==0
egen clinics_u = rowtotal(pc11_td_all_hospital pc11_td_disp pc11_td_tb_clinic pc11_td_nur_homes pc11_td_mh_clinic pc11_td_in_out_pat pc11_td_c_hosp_home) if urban==1                                      


/* beds (total and allopathic)*/
egen beds_tot = rowtotal(*_beds)
egen beds_all = rowtotal(*_allh_beds)



/*******************************************/
/* district and subdistrict level collapse */
/*******************************************/

preserve

/* collapse to sub district level */

collapse (sum) pmed_* doctors_* clinics_* beds_* pc11_pca_tot_p, by(pc11_state_id pc11_state_name pc11_district_id pc11_district_name pc11_subdistrict_id pc11_subdistrict_name)

/* label vars */
/* note beds data only available for urban areas */
la var beds_tot "No. of beds across all hospitals/facilities"
la var beds_all "No. of beds across allopathic facilities"
la var doctors_pos_r "No. of doctors in position - rural"
la var doctors_pos_u "No. of doctors in position - urban"
la var doctors_tot_r "No. of doctors (total)- rural"
la var doctors_tot_u "No. of doctors (total)- urban"
la var pmed_pos_r "No. of paramedics in position (rural)"
la var pmed_tot_u "No. of paramedics (total) - urban"
la var pmed_pos_u "No. of paramedics in position (urban)"
la var pmed_tot_r "No. of paramedics (total) - rural"
la var pc11_pca_tot_p "Total population"

/* Note: maternal and child welfare, family welfare centers, alternative medicine and faith healers excluded */
la var clinics_r "No. of rural clinics"
la var clinics_u "No. of urban clinics"

/* aggregate rural and urban vars */
egen clinics = rowtotal(clinics_*)
egen doctors_tot = rowtotal(doctors_tot_*)
egen pmed_tot = rowtotal(pmed_tot_*)
egen doctors_pos = rowtotal(doctors_pos_*)
egen pmed_pos = rowtotal(pmed_pos_*)


/* label new vars */
la var clinics "Total clinics in subdistrict"
la var doctors_tot "Total doctors in subdistrict"
la var pmed_tot "Total paramedics in subdistrict"
la var pmed_pos "Total paramedics in position in subdistrict"
la var doctors_pos "Total doctors in position in subdistrict"


/* generate per 1000 capacity vars */

foreach x of var pmed_* doctors_* clinics_* beds_*{
  gen pc_`x'=(`x'/pc11_pca_tot_p)*1000
  }

/* check distributions of per 1000 capacity vars */

foreach x of var pc_*{
  kdensity `x'
  graphout `x'_dist
  }

/* save dataset */

save $tmp/health_capacity_subdistrict_clean.dta, replace

restore

preserve

/* collapse to district level */

collapse (sum) pmed_* doctors_* clinics_* beds_* pc11_pca_tot_p, by(pc11_state_id pc11_state_name pc11_district_id pc11_district_name)

/* label vars */
/* note beds data only available for urban areas */
la var beds_tot "No. of beds across all hospitals/facilities"
la var beds_all "No. of beds across allopathic facilities"
la var doctors_pos_r "No. of doctors in position - rural"
la var doctors_pos_u "No. of doctors in position - urban"
la var doctors_tot_r "No. of doctors (total)- rural"
la var doctors_tot_u "No. of doctors (total)- urban"
la var pmed_pos_r "No. of paramedics in position (rural)"
la var pmed_tot_u "No. of paramedics (total) - urban"
la var pmed_pos_u "No. of paramedics in position (urban)"
la var pmed_tot_r "No. of paramedics (total) - rural"
la var pc11_pca_tot_p "Total population"

/* Note: maternal and child welfare, family welfare centers, alternative medicine and faith healers excluded */
la var clinics_r "No. of rural clinics"
la var clinics_u "No. of urban clinics"

/* aggregate rural and urban vars */
egen clinics = rowtotal(clinics_*)
egen doctors_tot = rowtotal(doctors_tot_*)
egen pmed_tot = rowtotal(pmed_tot_*)
egen doctors_pos = rowtotal(doctors_pos_*)
egen pmed_pos = rowtotal(pmed_pos_*)


/* label new vars */
la var clinics "Total clinics in district"
la var doctors_tot "Total doctors in district"
la var pmed_tot "Total paramedics in district"
la var pmed_pos "Total paramedics in position in district"
la var doctors_pos "Total doctors in position in district"


/* generate per 1000 capacity vars */

foreach x of var pmed_* doctors_* clinics_* beds_*{
  gen pc_`x'=(`x'/pc11_pca_tot_p)*1000
  }

/* check distributions of per 1000 capacity vars */

foreach x of var pc_*{
  kdensity `x'
  graphout `x'_dist
  }

/* save dataset */

save $tmp/health_capacity_district_clean.dta, replace

restore





                       

