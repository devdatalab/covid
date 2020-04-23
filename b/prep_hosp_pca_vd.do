/************/
/* Villages */
/************/
use $pc11/pc11_vd_clean.dta, clear

/* keep the demographic and health infrastructure variables */

/* check missing data percent for various health center variables */
keep *id pc11_vd_nc* pc11_vd_asha pc11_vd_med* pc11_vd_fwc_cntr pc11_vd_mh_cln pc11_vd_disp pc11_vd_altmed_hosp pc11_vd_all_hosp pc11_vd_tb_cln pc11_vd_mcw_cntr pc11_vd_phs_cntr pc11_vd_ph_cntr pc11_vd_ch_cntr  *_doc_* *_pmed_* pc11_vd_ch_cntr pc11_vd_ph_cntr pc11_vd_phs_cntr pc11_vd_tb_cln pc11_vd_all_hosp pc11_vd_disp pc11_vd_mh_cln pc11_vd_med_in_out_pat pc11_vd_med_c_hosp_home

/* merge with pca clean data at village level */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id using $pc11/pc11r_pca_clean.dta, keepusing(pc11_pca_tot_p)
keep if _merge == 3
drop _merge

/* save rural PCA and VD subset in git repo */
compress
save $covidpub/pc11r_hosp, replace

/*********/
/* Towns */
/*********/
use $pc11/pc11_td_clean.dta, clear

/* keep the town directory hospital and clinic fields */
keep *id pc11_td_med* pc11_td_disp pc11_td_all_hosp pc11_td_alt_hospital *_doc_* *_pmed_* *_beds *clinic pc11_td_all_hospital pc11_td_disp pc11_td_tb_clinic pc11_td_nur_homes pc11_td_mh_clinic pc11_td_in_out_pat pc11_td_c_hosp_home

/* rename badly named allh to all for consistency with rural  */
ren *_allh_* *_all_hosp_*
ren pc11_td_all_hospital pc11_td_all_hosp

/* make a few other fields consistent */
ren pc11_td_tb_clinic pc11_td_tbc
ren pc11_td_nur_homes pc11_td_nh
ren pc11_td_mh_clinic pc11_td_mh

/* merge with pca clean data at village level */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $pc11/pc11u_pca_clean.dta, keepusing(pc11_pca_tot_p)
keep if _merge == 3
drop _merge

/* save urban PCA and VD subset in git repo */
compress
save $covidpub/pc11u_hosp, replace
