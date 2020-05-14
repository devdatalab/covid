/* gen demographic and amenities data for bihar at lgd-pc11 district level */

/*****************/
/* Prep PCA data */
/*****************/

/* merge total/urban/rural pca district data together */
use $pc11/pc11r_pca_district_clean.dta, clear
ren pc11_pca* pc11r_pca*
merge 1:1 pc11_state_id pc11_district_id using $pc11/pc11u_pca_district_clean, gen(_m_pc11u)
ren pc11_pca* pc11u_pca*
merge 1:1 pc11_state_id pc11_district_id using $pc11/pc11_pca_district_clean, gen(_m_pc11r)
drop _m*

/* drop unnecessary variables */
drop pc11*tru pc11*level

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* keep necessary vars */
keep *pca_tot_p *pca_no_hh *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* 

/* save */
save $tmp/pc11_pca_district_bihar, replace

/****************************/
/* Prep Town directory data */
/****************************/

use $pc11/pc11_td_clean.dta , clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* collapse to level: land area */
collapse (sum) pc11_td_area , by(pc11_state_id pc11_district_id)
label var pc11_td_area "Total geographical area (sq km)"

/* save level data */
save $tmp/pc11_td_district_bihar, replace

/*******************************/
/* Prep Village directory data */
/*******************************/

use $pc11/pc11_vd_clean.dta , clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* collapse to level: land area */
collapse (sum) pc11_vd_area , by(pc11_state_id pc11_district_id)
label var pc11_vd_area "Total geographical area (hectares)"

/* save level data*/
save $tmp/pc11_vd_district_bihar, replace

/********************************/
/* Prep households listing data */
/********************************/

use $pc11/houselisting_pca/pc11r_hpca_village.dta , clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* collapse to level: access to water */
collapse (mean) pc11r_hl_dw_loc_* , by(pc11_state_id pc11_district_id)
label var pc11r_hl_dw_loc_inprem "Prop. of households with drinking water in premise"
label var pc11r_hl_dw_loc_nearprem "Prop. of households with drinking water near premise"
label var pc11r_hl_dw_loc_far "Prop. of households with drinking water far from premise"

/* save level data */
save $tmp/pc11r_water_district_bihar, replace


use $pc11/houselisting_pca/pc11u_hpca_town.dta , clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* collapse to level: access to water */
collapse (mean) pc11u_hl_dw_loc_* , by(pc11_state_id pc11_district_id)
label var pc11u_hl_dw_loc_inprem "Prop. of households with drinking water in premise"
label var pc11u_hl_dw_loc_nearprem "Prop. of households with drinking water near premise"
label var pc11u_hl_dw_loc_far "Prop. of households with drinking water far from premise"

/* save level data */
save $tmp/pc11u_water_district_bihar, replace

/* merge rural and urban households data */
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11r_water_district_bihar, nogen

/* save */
save $tmp/pc11_water_district_bihar, replace

/************************/
/* Health capacity data */
/************************/

/* Use cleaned health capacity dataset - check covid/b/prep_pc_hosp.do */
/* Using this version bc outliers were checked and dropped in this version */
use $tmp/precollapse, clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* keep relevant vars */
keep *nh *mh *_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot pc11_state_id pc11_district_id

/* collapse at district level */
collapse (sum) pc11_td*, by(pc11_state_id pc11_district_id)

/* clean */
ren pc11_td* pc11_tot*
la var pc11_tot_all_hosp "Total allopathic hospitals in district"
la var pc11_tot_all_hosp_doc_tot "Total doctors in allopathic hospitals"
la var pc11_tot_all_hosp_pmed_tot "Total paramedics in allopathic hospitals"
la var pc11_tot_disp "Total dispensaries"
la var pc11_tot_ch_cntr "Total community health centers - rural only"
la var pc11_tot_ph_cntr "Total public health centers - rural only"
la var pc11_tot_phs_cntr "Total public health sub centers - rural only"
la var pc11_tot_mcw_cntr "Total maternal/child welfare centers"
la var pc11_tot_tb_cln "Total TB clinics"
la var pc11_tot_mh_cln "Total mobile health clinics"
la var pc11_tot_fwc_cntr "Total family and welfare centers"
la var pc11_tot_nh "Total nursing homes - urban only"
la var pc11_tot_mh "Total maternity homes - urban only"

/* data is already at district level */
save $tmp/pc11_healthcapacity_district_bihar, replace

/***********************************************/
/* Merge everything with lgd-pc11 district key */
/***********************************************/

use $keys/lgd_pc11_district_key, clear

/* keep obs for bihar */
keep if lgd_state_id == "10"

/* merge pca data */
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_pca_district_bihar, gen(pcamerge)
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_td_district_bihar, gen(td_merge)
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_vd_district_bihar, gen(vd_merge)
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_water_district_bihar, gen(water_merge)
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_healthcapacity_district_bihar, gen(hosp_merge)

/* everything merged */
drop *merge

/* gen area variable */
gen area = pc11_td_area + (pc11_vd_area/100)
la var area "Total area of district (sq km)"

/* create population density */
gen pc11r_pdensity = pc11r_pca_tot_p/(pc11_vd_area/100)
gen pc11u_pdensity = pc11u_pca_tot_p/pc11_td_area
gen pc11_pdensity = pc11_pca_tot_p/area

la var pc11_pdensity "Population density"
la var pc11u_pdensity "Population density (Urban)"
la var pc11r_pdensity "Population density (Rural)"

/* create agri workers shares */
foreach i in r u {
gen pc11`i'_ag_main_share = pc11`i'_pca_main_al_p/pc11_pca_mainwork_p
}

gen pc11_ag_main_share = pc11_pca_main_al_p/pc11_pca_mainwork_p

la var pc11r_ag_main_share "Share of main workers in agri (Rural)"
la var pc11u_ag_main_share "Share of main workers in agri (Urban)"
la var pc11_ag_main_share "Share of main workers in agriculture"

la var pc11r_pca_main_al_p "No. of main workers - agri (Rural)"
la var pc11u_pca_main_al_p "No. of main workers - agri (Urban)"

/* create no. of households with clean water */
foreach x of var pc11r_hl_dw*{
  gen `x'_no = `x'*pc11r_pca_no_hh
}

foreach x of var pc11u_hl_dw*{
  gen `x'_no = `x'*pc11u_pca_no_hh
}

la var pc11r_hl_dw_loc_inprem_no "No. of hh with access to drinking water in premise (Rural)"
la var pc11r_hl_dw_loc_nearprem_no "No. of hh with access to drinking water near premise (Rural)"
la var pc11r_hl_dw_loc_far_no "No. of hh with access to drinking water far from premise (Rural)"

la var pc11r_hl_dw_loc_inprem "Share of hh with access to drinking water in premise (Rural)"
la var pc11r_hl_dw_loc_nearprem "Share of hh with access to drinking water near premise (Rural)"
la var pc11r_hl_dw_loc_far_no "Share of hh with access to drinking water far from premise (Rural)"

la var pc11u_hl_dw_loc_inprem_no "No. of hh with access to drinking water in premise (Urban)"
la var pc11u_hl_dw_loc_nearprem_no "No. of hh with access to drinking water near premise (Urban)"
la var pc11u_hl_dw_loc_far_no "No. of hh with access to drinking water far from premise (Urban)"

la var pc11u_hl_dw_loc_inprem "Share of hh with access to drinking water in premise (Urban)"
la var pc11u_hl_dw_loc_nearprem "Share of hh with access to drinking water near premise (Urban)"
la var pc11u_hl_dw_loc_far "Share of hh with access to drinking water far from premise (Urban)"

/* clean dataset */
drop *version pc01* 
la var pc11r_pca_tot_p "Rural population - total"
la var pc11u_pca_tot_p "Urban population - total"
la var pc11_pca_tot_p "Total population"
la var pc11r_pca_mainwork_p "Total mainworkers - rural"
la var pc11u_pca_mainwork_p "Total mainworkers - urban"
la var pc11_td_area "Area (sq km) urban"
la var pc11_vd_area "Area (ha) rural"
la var pc11r_pca_no_hh "No of hh (rural)"
la var pc11u_pca_no_hh "No of hh (urban)"

/* order dataset */
order lgd* pc11_state_id pc11_district_id pc11_state_name pc11_district_name
order *pca_tot_p, after(pc11_district_name)
order *ag_main_share *al_p, after(pc11_pca_tot_p)
order *pdensity, after(pc11_pca_main_al_p)
order *dw_loc*, after(pc11_pdensity)
order pc11_tot*, after(pc11u_hl_dw_loc_far_no)
order *no_hh *area *_mainwork_p, last

/* save dataset */
save $iec/covid/bihar/bihar_district_pc11, replace
