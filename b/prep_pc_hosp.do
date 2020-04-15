/* open rural hospital/clinic dataset */
use $covidpub/pc11r_hosp, clear

/* drop outliers */
sum pc11_vd_ph_cntr, d
gen flag = 1 if pc11_vd_ph_cntr >= 30000

sum pc11_vd_phs_cntr, d
replace flag = 1 if pc11_vd_phs_cntr >= 70000

sum pc11_vd_all_hosp, d
replace flag = 1 if pc11_vd_all_hosp >= 300

sum pc11_pca_tot_p, d
replace flag = 1 if pc11_pca_tot_p >= 9039

drop if flag == 1
drop flag

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
use $covidpub/pc11u_hosp, clear

/* drop outliers */
sum pc11_td_all_hospital, d
gen flag = 1 if pc11_td_all_hospital >= 100

sum pc11_td_alt_hospital, d
replace flag = 1 if pc11_td_alt_hospital >= 38

sum pc11_td_disp, d
replace flag = 1 if pc11_td_disp >= 341

sum pc11_pca_tot_p, d
replace flag = 1 if pc11_pca_tot_p >= 505693

drop if flag == 1
drop flag

/* separate urban and rural populations */
gen pc11_pca_tot_p_r = pc11_pca_tot_p

compress
save $tmp/healthcare_pca_u, replace

/*******************************************/
/* combine rural and urban healthcare data */
/*******************************************/
use $tmp/healthcare_pca_u, clear

gen urban = 1

append using $tmp/healthcare_pca_r

replace urban = 0 if mi(urban)

/************************************/
/* create health capacity variables */
/************************************/

/* doctors (total, urban and rural) */
egen doctors_pos_r = rowtotal(*_doc_pos) if urban == 0
egen doctors_pos_u = rowtotal(*_doc_pos) if urban == 1

egen doctors_tot_r = rowtotal(*_doc_tot) if urban == 0
egen doctors_tot_u = rowtotal(*_doc_tot) if urban == 1


/* paramedics (total, urban and rural) */
egen pmed_pos_r = rowtotal(*_pmed_pos) if urban == 0
egen pmed_pos_u = rowtotal(*_pmed_pos) if urban == 1

egen pmed_tot_r = rowtotal(*_pmed_tot) if urban == 0
egen pmed_tot_u = rowtotal(*_pmed_tot) if urban == 1

/* clinics (total, urban and rural) */
egen clinics_r = rowtotal(pc11_td_ch_cntr pc11_td_ph_cntr pc11_td_phs_cntr pc11_td_tb_cln pc11_td_all_hosp pc11_td_disp pc11_td_mh_cln pc11_td_med_in_out_pat pc11_td_med_c_hosp_home) if urban == 0
egen clinics_u = rowtotal(pc11_td_all_hospital pc11_td_disp pc11_td_tb_clinic pc11_td_nur_homes pc11_td_mh_clinic pc11_td_in_out_pat pc11_td_c_hosp_home) if urban == 1
gen allhospitals_r = pc11_td_all_hosp if urban == 0
gen allhospitals_u = pc11_td_all_hospital if urban == 1

/* beds (total and allopathic) */
egen beds_urb_tot = rowtotal(*_beds)
egen beds_urb_allo = rowtotal(*_allh_beds)

/*******************************************/
/* district and subdistrict level collapse */
/*******************************************/

preserve

/* collapse to sub district level */
collapse (sum) allhosp* pmed_* doctors_* clinics_* beds_* pc11_pca_tot_p, by(pc11_state_id pc11_district_id pc11_subdistrict_id)

/* label vars */
/* note beds data only available for urban areas */
la var beds_urb_tot "No. of beds across all hospitals/facilities"
la var beds_urb_all "No. of beds across allopathic facilities"
la var doctors_pos_r "No. of doctors in position - rural"
la var doctors_pos_u "No. of doctors in position - urban"
la var doctors_tot_r "No. of doctors (total)- rural"
la var doctors_tot_u "No. of doctors (total)- urban"
la var pmed_pos_r "No. of paramedics in position (rural)"
la var pmed_tot_u "No. of paramedics (total) - urban"
la var pmed_pos_u "No. of paramedics in position (urban)"
la var pmed_tot_r "No. of paramedics (total) - rural"
la var pc11_pca_tot_p "Total population"
la var allhospitals_r "No. of allopathic hospitals - rural"
la var allhospitals_u "No. of allopathic hospitals - urban"

/* Note: maternal and child welfare, family welfare centers, alternative medicine and faith healers excluded */
la var clinics_r "No. of rural clinics"
la var clinics_u "No. of urban clinics"

/* aggregate rural and urban vars */
egen clinics = rowtotal(clinics_*)
egen doctors_tot = rowtotal(doctors_tot_*)
egen pmed_tot = rowtotal(pmed_tot_*)
egen doctors_pos = rowtotal(doctors_pos_*)
egen pmed_pos = rowtotal(pmed_pos_*)
egen num_allo_hospitals = rowtotal(allhospitals_*)

/* label new vars */
la var clinics "Total clinics in subdistrict"
la var doctors_tot "Total doctors in subdistrict"
la var pmed_tot "Total paramedics in subdistrict"
la var pmed_pos "Total paramedics in position in subdistrict"
la var doctors_pos "Total doctors in position in subdistrict"
la var num_allo_hospitals "Total allopathic hospitals in subdistrict"

/* generate per 1000 capacity vars */
foreach x of var pmed_* doctors_* clinics* beds_* allhosp* num_all*{
  gen perk_`x'=(`x'/pc11_pca_tot_p)*1000
}

/* label per thousand vars */
la var perk_pmed_pos_r "Paramedics per thousand rural - in position"
la var perk_pmed_pos_u "Paramedics per thousand urban - in position"
la var perk_pmed_tot_r "Paramedics per thousand rural"
la var perk_pmed_tot_u "Paramedics per thousand urban"
la var perk_pmed_tot "Paramedics per thousand"
la var perk_pmed_pos "Paramedics per thousand - in position"
la var perk_doctors_pos_r "Paramedics per thousand rural - in position"
la var perk_doctors_pos_u "Paramedics per thousand urban - in position"
la var perk_clinics_r "Clinics per thousand - rural"
la var perk_clinics_u "Clinics per thousand - urban"
la var perk_clinics "Clinics per thousand"
la var perk_beds_urb_tot "Beds per thousand - urban only"
la var perk_beds_urb_all "Beds per thousand - allopathic hosp - urban only"
la var perk_allhospitals_r "Allopathic hosp per thousand - rural"
la var perk_allhospitals_u "Allopathic hosp per thousand - urban"
la var perk_num_allo_hospitals "Allopathic hosp per thousand"
la var perk_doctors_pos_r "Doctors per thousand - rural - in position"
la var perk_doctors_pos_u "Doctors per thousand - urban - in position"
la var perk_doctors_pos "Doctors per thousand in position"
la var perk_doctors_tot_r "Doctors per thousand - rural"
la var perk_doctors_tot_u "Doctors per thousand - urban"
la var perk_doctors_tot "Doctors per thousand"

ren * pc_*

/* save subdistrict dataset */
save $covidpub/pc_hospitals_subdist, replace

restore

preserve

/* collapse to district level */

collapse (sum) allhosp* pmed_* doctors_* clinics_* beds_* pc11_pca_tot_p, by(pc11_state_id pc11_district_id)

/* label vars */
/* note beds data only available for urban areas */
la var beds_urb_tot "No. of beds across all urban hospitals/facilities"
la var beds_urb_allo "No. of beds across urban allopathic facilities"
la var doctors_pos_r "No. of doctors in position - rural"
la var doctors_pos_u "No. of doctors in position - urban"
la var doctors_tot_r "No. of doctors (total)- rural"
la var doctors_tot_u "No. of doctors (total)- urban"
la var pmed_pos_r "No. of paramedics in position (rural)"
la var pmed_tot_u "No. of paramedics (total) - urban"
la var pmed_pos_u "No. of paramedics in position (urban)"
la var pmed_tot_r "No. of paramedics (total) - rural"
la var pc11_pca_tot_p "Total population"
la var allhospitals_r "No. of allopathic hospitals - rural"
la var allhospitals_u "No. of allopathic hospitals - urban"

/* Note: maternal and child welfare, family welfare centers, alternative medicine and faith healers excluded */
la var clinics_r "No. of rural clinics"
la var clinics_u "No. of urban clinics"

/* aggregate rural and urban vars */
egen clinics = rowtotal(clinics_*)
egen doctors_tot = rowtotal(doctors_tot_*)
egen pmed_tot = rowtotal(pmed_tot_*)
egen doctors_pos = rowtotal(doctors_pos_*)
egen pmed_pos = rowtotal(pmed_pos_*)
egen num_allo_hospitals = rowtotal(allhospitals_*)

/* label new vars */
la var clinics "Total clinics in district"
la var doctors_tot "Total doctors in district"
la var pmed_tot "Total paramedics in district"
la var pmed_pos "Total paramedics in position in district"
la var doctors_pos "Total doctors in position in district"
la var num_allo_hospitals "Total allopathic hospitals in district"

/* generate per 1000 capacity vars */

foreach x of var pmed_* doctors_* clinics* beds_* allhosp* num_all*{
  gen perk_`x'=(`x'/pc11_pca_tot_p)*1000
}

/* label per thousand vars */
la var perk_pmed_pos_r "Paramedics per thousand rural - in position"
la var perk_pmed_pos_u "Paramedics per thousand urban - in position"
la var perk_pmed_tot_r "Paramedics per thousand rural"
la var perk_pmed_tot_u "Paramedics per thousand urban"
la var perk_pmed_tot "Paramedics per thousand"
la var perk_pmed_pos "Paramedics per thousand - in position"
la var perk_doctors_pos_r "Paramedics per thousand rural - in position"
la var perk_doctors_pos_u "Paramedics per thousand urban - in position"
la var perk_clinics_r "Clinics per thousand - rural"
la var perk_clinics_u "Clinics per thousand - urban"
la var perk_clinics "Clinics per thousand"
la var perk_beds_urb_tot "Beds per thousand - urban only"
la var perk_beds_urb_allo "Beds per thousand - allopathic hosp - urban only"
la var perk_allhospitals_r "Allopathic hosp per thousand - rural"
la var perk_allhospitals_u "Allopathic hosp per thousand - urban"
la var perk_num_allo_hospitals "Allopathic hosp per thousand"
la var perk_doctors_pos_r "Doctors per thousand - rural - in position"
la var perk_doctors_pos_u "Doctors per thousand - urban - in position"
la var perk_doctors_pos "Doctors per thousand in position"
la var perk_doctors_tot_r "Doctors per thousand - rural"
la var perk_doctors_tot_u "Doctors per thousand - urban"
la var perk_doctors_tot "Doctors per thousand"

ren * pc_*
ren pc_pc11* pc11*

/* save dataset */
save $covidpub/pc_hospitals_dist, replace

restore
