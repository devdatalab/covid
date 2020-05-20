/* gen demographic and amenities data for bihar at lgd-pc11 district level */

/* set context */
set_context covid

/******************************************************************/
/* Define program for final cleaning steps after merging all data */
/******************************************************************/

cap prog drop finalsteps
prog def finalsteps
{
    /* rename variables */
    ren pc11_td* pc11_tot*
    ren pc11_tot_area pc11_td_area

    /* clean health capacity variable */
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

    /* create total vars */
    egen pc11_pca_tot_p = rowtotal(pc11r_pca_tot_p pc11u_pca_tot_p)
    egen pc11_pca_no_hh = rowtotal(pc11r_pca_no_hh pc11u_pca_no_hh)
    egen pc11_pca_main_al_p = rowtotal(pc11r_pca_main_al_p pc11u_pca_main_al_p)
    egen pc11_pca_main_cl_p = rowtotal(pc11r_pca_main_cl_p pc11u_pca_main_cl_p)
    egen pc11_pca_mainwork_p = rowtotal(pc11r_pca_mainwork_p pc11u_pca_mainwork_p)


    /* gen area variable */
    egen pc11_area = rowtotal(pc11_vd_area pc11_td_area)
    la var pc11_area "Total area of district (sq km)"

    /* create population density */
    gen pc11r_pdensity = pc11r_pca_tot_p/pc11_area
    gen pc11u_pdensity = pc11u_pca_tot_p/pc11_area
    gen pc11_pdensity = pc11_pca_tot_p/pc11_area

    la var pc11_pdensity "Population density"
    la var pc11u_pdensity "Population density (Urban)"
    la var pc11r_pdensity "Population density (Rural)"

    /* create agri workers shares */
    foreach i in r u "" {
      gen pc11`i'_ag_main_share = (pc11`i'_pca_main_al_p + pc11`i'_pca_main_cl_p)/pc11_pca_mainwork_p
    }

    la var pc11r_ag_main_share "Share of main workers in agri (Rural)"
    la var pc11u_ag_main_share "Share of main workers in agri (Urban)"
    la var pc11_ag_main_share "Share of main workers in agriculture"

    la var pc11r_pca_main_al_p "No. of main workers - agri (Rural)"
    la var pc11u_pca_main_al_p "No. of main workers - agri (Urban)"
    la var pc11_pca_main_al_p "No. of main workers - agriculture"
    la var pc11r_pca_main_cl_p "No. of main workers - cultivation (Rural)"
    la var pc11u_pca_main_cl_p "No. of main workers - cultivation (Urban)"
    la var pc11_pca_main_cl_p "No. of main workers - cultivation"

    /* create no. of households with clean water */
    foreach x of var pc11r_hl_dw_loc*{
      gen `x'sh = `x'/pc11r_pca_no_hh
    }

    foreach x of var pc11u_hl_dw_loc*{
      gen `x'sh = `x'/pc11u_pca_no_hh
    }

    drop *premsh *farsh
    drop *prem *far
    ren *nosh *sh

    la var pc11r_hl_dw_loc_inprem_no "No. of hh with access to drinking water in premise (Rural)"
    la var pc11r_hl_dw_loc_nearprem_no "No. of hh with access to drinking water near premise (Rural)"
    la var pc11r_hl_dw_loc_far_no "No. of hh with access to drinking water far from premise (Rural)"

    la var pc11r_hl_dw_loc_inprem_sh "Share of hh with access to drinking water in premise (Rural)"
    la var pc11r_hl_dw_loc_nearprem_sh "Share of hh with access to drinking water near premise (Rural)"
    la var pc11r_hl_dw_loc_far_sh "Share of hh with access to drinking water far from premise (Rural)"

    la var pc11u_hl_dw_loc_inprem_no "No. of hh with access to drinking water in premise (Urban)"
    la var pc11u_hl_dw_loc_nearprem_no "No. of hh with access to drinking water near premise (Urban)"
    la var pc11u_hl_dw_loc_far_no "No. of hh with access to drinking water far from premise (Urban)"

    la var pc11u_hl_dw_loc_inprem_sh "Share of hh with access to drinking water in premise (Urban)"
    la var pc11u_hl_dw_loc_nearprem_sh "Share of hh with access to drinking water near premise (Urban)"
    la var pc11u_hl_dw_loc_far_sh "Share of hh with access to drinking water far from premise (Urban)"

    /* clean dataset */
    cap drop *version pc01* 
    la var pc11r_pca_tot_p "Rural population - total"
    la var pc11u_pca_tot_p "Urban population - total"
    la var pc11_pca_tot_p "Total population"
    la var pc11r_pca_mainwork_p "Total mainworkers - rural"
    la var pc11u_pca_mainwork_p "Total mainworkers - urban"
    la var pc11_pca_mainwork_p "Total mainworkers"
    la var pc11_td_area "Area (sq km) urban"
    la var pc11_vd_area "Area (sq km) rural"
    la var pc11r_pca_no_hh "No of hh (rural)"
    la var pc11u_pca_no_hh "No of hh (urban)"
    la var pc11_pca_no_hh "No of hh"

    /* order dataset */
    order lgd*
    order *pca_tot_p, after(lgd_district_name)
    order *ag_main_share *al_p, after(pc11_pca_tot_p)
    order *pdensity, after(pc11_pca_main_al_p)
    order *dw_loc*, after(pc11_pdensity)
    order pc11_tot*, after(pc11u_hl_dw_loc_far_no)
    order *no_hh *area *_mainwork_p, last
}

end

/**************************/
/* End program finalsteps */
/**************************/

/*********************************************/
/* Create rural lgd-pc11 demographic dataset */
/*********************************************/

/* Merges */

/* extract lgd state and district ids for pca rural */
use $pc11/pc11r_pca_clean.dta, clear

/* keep pca vars */
keep *pca_tot_p *pca_no_hh *pca_main_cl_p *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* pc11_village* pc11_subdistrict*

/* rename vars */
ren pc11_pca* pc11r_pca*

/* merge with lgd-pc11 village key */
merge 1:1 pc11_state_id pc11_village_id using $keys/lgd_pc11_village_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name) nogen keep(match master)

/* merge to get village area */
merge 1:1 pc11_state_id pc11_village_id using $pc11/pc11_vd_clean, keep(match master) keepusing(pc11_vd_area pc11_vd_block_name )

/* merge to get household water access data */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id using $pc11/houselisting_pca/pc11r_hpca_village, nogen keep(match master) keepusing(pc11r_hl_dw_loc*)

/* merge in rural hospital data */
merge 1:m pc11_state_id pc11_district_id pc11_state_id pc11_village_id using $tmp/precollapse, nogen keep(match master) keepusing(*_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot)

/* Cleaning */

/* In the hpca data households with access to water are represented as shares */
foreach x of var pc11r_hl_dw*{

/* create number of households with access to drinking water */
  gen `x'_no = `x'*pc11r_pca_no_hh
}

/* generate village are variable in hectares */
replace pc11_vd_area = pc11_vd_area/100
la var pc11_vd_area "Area (sq. km)"

/* keep necessary vars */
keep pc11* lgd*

/* rename */
ren pc11* pc11*

/* save temp dataset */
save $tmp/pc11r_covid_raw, replace

/*********************************************/
/* Create urban lgd-pc11 demographic dataset */
/*********************************************/

/* Merges */

/* extract lgd state and district ids for pca urban */
use $pc11/pc11u_pca_clean.dta, clear

/* keep pca vars */
keep *pca_tot_p *pca_no_hh *pca_main_cl_p *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* pc11_town* pc11_subdistrict*

/* rename vars */
ren pc11_pca* pc11u_pca*

/* merge with lgd-pc11 town key */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $keys/lgd_pc11_town_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name) nogen keep(match master)

/* merge to get town area */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $pc11/pc11_td_clean, keep(match master) keepusing(pc11_td_area pc11_td_block_name )

/* merge to get household water access data */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $pc11/houselisting_pca/pc11u_hpca_town, nogen keep(match master) keepusing(pc11u_hl_dw_loc*)

/* merge in urban hospital data */
merge 1:m pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $tmp/precollapse, nogen keep(match master) keepusing(*mh *nh *_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot)

/* Cleaning */

/* In the hpca data households with access to water are represented as shares */
foreach x of var pc11u_hl_dw*{

/* create number of households with access to drinking water */
  gen `x'_no = `x'*pc11u_pca_no_hh
}

/* keep necessary vars */
keep pc11* lgd*

/* save temp dataset */
save $tmp/pc11u_covid_raw, replace

/***********************/
/* Append and collapse */
/***********************/

/* append urban and rural raw datasets */
use $tmp/pc11r_covid_raw, clear
append using $tmp/pc11u_covid_raw

/* drop pc11 ids and names for collapse to work */
drop pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id pc11_town_id 
drop pc11_state_name pc11_district_name pc11_subdistrict_name pc11_village_name pc11_town_name *block_name

/* drop obs with missing lgd district id */
drop if lgd_district_id == ""

/* collapse at lgd state and district level */
collapse (sum) pc11*, by(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)

/* final cleaning steps - defined in program on top */
finalsteps

/* save final dataset */
save $tmp/lgd_pc11_demographics_district, replace

/* create state id locals */
levelsof lgd_state_id, local(levelstate)

/* save separate dataset for each state */
foreach s of local levelstate{
  savesome using $tmp/lgd_pc11_dem_district_`s' if lgd_state_id == "`s'", replace
}

/****************************************************************************************************************/
/* Repeat for blocks - this couldn't be put in a loop because we only have a complete block key for bihar so far*/
/****************************************************************************************************************/

/* append covid rural and urban datasets */
use $tmp/pc11r_covid_raw, clear
append using $tmp/pc11u_covid_raw

/* process block name */
replace pc11_vd_block_name = pc11_td_block_name if mi(pc11_vd_block_name)
drop pc11_td_block_name
replace pc11_vd_block_name = proper(pc11_vd_block_name)

/* keep obs for bihar */
keep if lgd_state_name == "bihar"

/* collapse at the block level */
drop lgd*
collapse (sum) pc11u* pc11r* pc11_vd_area pc11_td*, by(pc11_state_id pc11_district_id pc11_vd_block_name)

/* merge with lgd-pc11 block key for bihar */
merge 1:1 pc11_state_id pc11_district_id pc11_vd_block_name using $covidpub/bihar/lgd_pc11_block_key_bihar, nogen keep(match) keepusing(lgd_district_name lgd_block_name)

/* final cleaning steps */
finalsteps
order lgd_block_name pc11_state_id pc11_district_id pc11_vd_block_name, after(lgd_district_name)

/* save dataset */
save $covidpub/bihar/bihar_block_pc11, replace
