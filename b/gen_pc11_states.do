/* gen demographic and amenities data for bihar at lgd-pc11 district level */

/******************************************************************/
/* Define program for final cleaning steps after merging all data */
/******************************************************************/

cap prog drop finalsteps
prog def finalsteps
{

    /* gen area variable */
    replace area = pc11_td_area + area
    la var area "Total area of district (sq km)"

    /* create population density */
    gen pc11r_pdensity = pc11r_pca_tot_p/area
    gen pc11u_pdensity = pc11u_pca_tot_p/area
    gen pc11_pdensity = pc11_pca_tot_p/area

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
    la var pc11r_pca_main_cl_p "No. of main workers - cultivation (Rural)"
    la var pc11u_pca_main_cl_p "No. of main workers - cultivation (Urban)"
    la var pc11u_pca_main_cl_p "No. of main workers - cultivation"

    /* create no. of households with clean water */
    foreach x of var pc11r_hl_dw*{
      gen `x'sh = `x'/pc11r_pca_no_hh
    }

    foreach x of var pc11u_hl_dw*{
      gen `x'sh = `x'/pc11u_pca_no_hh
    }

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
    la var pc11_td_area "Area (sq km) urban"
    la var pc11_vd_area "Area (ha) rural"
    la var pc11r_pca_no_hh "No of hh (rural)"
    la var pc11u_pca_no_hh "No of hh (urban)"

    /* order dataset */
    order lgd* pc11_state_id pc11_district_id pc11_district_name
    order *pca_tot_p, after(pc11_district_name)
    order *ag_main_share *al_p, after(pc11_pca_tot_p)
    order *pdensity, after(pc11_pca_main_al_p)
    order *dw_loc*, after(pc11_pdensity)
    order pc11_tot*, after(pc11u_hl_dw_loc_far_no)
    order *no_hh *area *_mainwork_p, last
}

end
  
/*****************/
/* Prep PCA data */
/*****************/

foreach id in 10 36 {

  if `id' == 10 local state "bihar"
  if `id' == 36 local state "telangana"

  /* merge total/urban/rural pca district data together */
  use $pc11/pc11r_pca_clean.dta, clear
  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3

  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"
  
  /* keep necessary vars */
  keep *pca_tot_p *pca_no_hh *pca_main_cl_p *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* lgd*

  /* rename vars */
  ren pc11_pca* pc11r_pca*

  /* collapse at district level */
  collapse (sum) *pca_tot* *no_hh *al_p *cl_p *work_p, by(lgd_state_id pc11_state_id pc11_district_id)

  /* save */
  save $tmp/pc11r_pca_`state', replace

  use $pc11/pc11u_pca_clean.dta, clear
  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3
  
  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

  /* keep necessary vars */
  keep *pca_tot_p *pca_no_hh *pca_main_cl_p *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* lgd*

  /* rename vars */
  ren pc11_pca* pc11u_pca*

  /* collapse at district level */
  collapse (sum) *pca_tot* *no_hh *al_p *cl_p *work_p, by(lgd_state_id pc11_state_id pc11_district_id)

  /* save */
  save $tmp/pc11u_pca_`state', replace

  /* merge the three datasets */
  use $tmp/pc11r_pca_`state', clear
  merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11u_pca_`state', nogen

  /* create total vars */
  egen pc11_pca_tot_p = rowtotal(pc11r_pca_tot_p pc11u_pca_tot_p)
  egen pc11_pca_no_hh = rowtotal(pc11r_pca_no_hh pc11u_pca_no_hh)
  egen pc11_pca_main_al_p = rowtotal(pc11r_pca_main_al_p pc11u_pca_main_al_p)
  egen pc11_pca_main_cl_p = rowtotal(pc11r_pca_main_cl_p pc11u_pca_main_cl_p)
  egen pc11_pca_mainwork_p = rowtotal(pc11r_pca_mainwork_p pc11u_pca_mainwork_p)

  /* save */
  save $tmp/pc11_pca_district_`state', replace

  /****************************/
  /* Prep Town directory data */
  /****************************/

  use $pc11/pc11_td_clean.dta , clear

  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3
  
  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

  /* collapse to level: land area */
  collapse (sum) pc11_td_area , by(lgd_state_id pc11_state_id pc11_district_id)
  label var pc11_td_area "Total geographical area (sq km) - Urban"

  /* save level data */
  save $tmp/pc11_td_district_`state', replace

  /*******************************/
  /* Prep Village directory data */
  /*******************************/

  use $pc11/pc11_vd_clean.dta , clear

  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3
  
  /* keep obs for state */
  keep if lgd_state_id == "`id'"
  
  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

  /* generate area variable */
  gen area = pc11_vd_area/`id'0

  /* collapse to level: land area */
  collapse (sum) pc11_vd_area area, by(lgd_state_id pc11_state_id pc11_district_id)
  label var pc11_vd_area "Total geographical area (hectares) - Rural"

  /* save level data*/
  save $tmp/pc11_vd_district_`state', replace

  /********************************/
  /* Prep households listing data */
  /********************************/

  /* rural */

  use $pc11/houselisting_pca/pc11r_hpca_village.dta , clear

  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3
  
  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

  /* merge with pc11_pca to get number of households */
  merge 1:1 pc11_state_id pc11_village_id using $pc11/pc11r_pca_clean, keepusing(pc11_pca_no_hh) gen(hhmerge)
  keep if hhmerge == 3
  /* 260 obs get dropped */
  drop hhmerge

  /* create no. of households with clean water */
  ren pc11_pca_no_hh pc11r_pca_no_hh

  foreach x of var pc11r_hl_dw*{
    gen `x'_no = `x'*pc11r_pca_no_hh
  }

  /* save pre-collapse data */
  save $tmp/pc11r_water_precol_`state', replace

  /* collapse to level: access to water */
  collapse (sum) *_no *no_hh , by(lgd_state_id pc11_state_id pc11_district_id)

  /* save level data */
  save $tmp/pc11r_water_district_`state', replace

  /* urban */
  use $pc11/houselisting_pca/pc11u_hpca_town.dta , clear

  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3

  /* keep obs unique at town id level */
  bys pc11_state_id pc11_town_id : keep if _n == 1
  
  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

  save $tmp/master, replace

  /* pc11 pca urban is not unique  */
  use $pc11/pc11u_pca_clean, clear
  bys pc11_state_id pc11_town_id : keep if _n == 1
  save $tmp/using, replace

  use $tmp/master, clear

  /* merge with pc11_pca to get number of households */
  merge 1:1 pc11_state_id pc11_town_id using $tmp/using, keepusing(pc11_pca_no_hh) gen(hhmerge)
  keep if hhmerge == 3

  /* create no. of households with clean water */
  ren pc11_pca_no_hh pc11u_pca_no_hh

  foreach x of var pc11u_hl_dw*{
    gen `x'_no = `x'*pc11u_pca_no_hh
  }

  /* save pre-collapse data */
  save $tmp/pc11u_water_precol_`state', replace

  /* collapse to level: access to water */
  collapse (sum)  *_no *no_hh , by(lgd_state_id pc11_state_id pc11_district_id)

  /* save level data */
  save $tmp/pc11u_water_district_`state', replace

  /* merge rural and urban households data */
  merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11r_water_district_`state', nogen

  /* drop unnecessary vars */
  drop *hl_dwelling* *dw_source*

  /* save */
  save $tmp/pc11_water_district_`state', replace

  /************************/
  /* Health capacity data */
  /************************/

  /* Use cleaned health capacity dataset - check covid/b/prep_pc_hosp.do */
  /* Using this version bc outliers were checked and dropped in this version */
  use $tmp/precollapse, clear

  merge m:m pc11_district_id using $keys/lgd_pc11_district_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
  keep if _merge == 3
  
  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

  /* keep relevant vars */
  keep *nh *mh *_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot pc11_state_id pc11_district_id lgd*

  /* collapse at district level */
  collapse (sum)  pc11_td*, by(lgd_state_id pc11_state_id pc11_district_id)

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
  save $tmp/pc11_healthcapacity_district_`state', replace

  /***********************************************/
  /* Merge everything with lgd-pc11 district key */
  /***********************************************/

  use $keys/lgd_pc11_district_key_weights, clear

  /* keep obs for state */
  keep if lgd_state_id == "`id'"

  /* code to retain one obs for a multiparent lgd district  */
  drop if lgd_district_name == "siddipet" & pc11_district_id == "535"
  drop if lgd_district_name == "siddipet" & pc11_district_id == "540"

   /* merge pca data */
  merge m:1 lgd_state_id pc11_district_id using $tmp/pc11_pca_district_`state', gen(pcamerge)
  merge m:1 lgd_state_id pc11_district_id using $tmp/pc11_td_district_`state', gen(td_merge)
  merge m:1 lgd_state_id pc11_district_id using $tmp/pc11_vd_district_`state', gen(vd_merge)
  merge m:1 lgd_state_id pc11_district_id using $tmp/pc11_water_district_`state', gen(water_merge)
  merge m:1 lgd_state_id pc11_district_id using $tmp/pc11_healthcapacity_district_`state', gen(hosp_merge)

  /* everything merged */
  drop *merge

  /* final cleaningsteps */
  finalsteps

  /* save dataset */
  save $covidpub/`state'/`state'_district_pc11, replace

}

/***************************************************************************************************/
/* Repeat for blocks - this couldn't be put in a loop because blocks are not a normal location key */
/***************************************************************************************************/

/****************************/
/* Prep Town directory data */
/****************************/

use $pc11/pc11_td_clean.dta , clear
bys pc11_state_id pc11_district_id pc11_town_id : keep if _n == 1
save $tmp/master, replace

use $pc11/pc11u_pca_clean, clear
bys pc11_state_id pc11_district_id pc11_town_id : keep if _n == 1
save $tmp/using, replace

/* merge */
use $tmp/master, clear
merge 1:1 pc11_state_id pc11_district_id pc11_town_id using $tmp/using, gen(m)
drop if m == 2
/* 23 towns dropped */

/* replace empty pca total population variable with pc11 td total population */
replace pc11_pca_tot_p = pc11_tot_p if m == 1
drop m

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* process block name variable */
/* town block names are in all caps, vd block names are proper */
ren pc11_td_block_name pc11_vd_block_name
replace pc11_vd_block_name = proper(pc11_vd_block_name)

/* collapse to level: land area */
collapse (sum) pc11_td_tot_p pc11_td_area *pca_tot_p *pca_no_hh *pca_main_al_p *pca_main_cl_p *_mainwork_p, by(pc11_state_id pc11_district_id pc11_vd_block_name)
label var pc11_td_area "Total geographical area (sq km)"

/* ren vars */
ren pc11_pca* pc11u_pca*

/* save level data */
save $tmp/pc11_td_block_bihar, replace

/*******************************/
/* Prep Village directory data */
/*******************************/

use $pc11/pc11_vd_clean.dta , clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

merge 1:1 pc11_state_id pc11_village_id using $pc11/pc11r_pca_clean, gen(m)
keep if m == 3
drop m

/* generate area variable */
gen area = pc11_vd_area/100

/* collapse to level: land area */
collapse (sum) pc11_vd_area area *pca_tot_p *pca_no_hh *pca_main_al_p *pca_main_cl_p *_mainwork_p, by(pc11_state_id pc11_district_id pc11_vd_block_name)
label var pc11_vd_area "Total geographical area (ha)"

ren pc11_pca* pc11r_pca*

/* save level data */
save $tmp/pc11_vd_block_bihar, replace

/********************************/
/* Prep households listing data */
/********************************/

/* call rural pre-collapse data */
use $tmp/pc11r_water_precol_bihar, replace

/* merge with vd data to get block names and ids */
merge 1:1 pc11_state_id pc11_village_id using $pc11/pc11_vd_clean, keepusing(pc11_vd_block_name)
keep if _merge == 3
drop _merge

/* collapse to level: access to water */
collapse (sum) *_no *no_hh , by(pc11_state_id pc11_district_id pc11_vd_block_name)

/* save level data */
save $tmp/pc11r_water_block_bihar, replace

/* call rural pre-collapse data */
use $tmp/pc11u_water_precol_bihar, replace

/* merge with vd data to get block names and ids */
merge 1:1 pc11_state_id pc11_district_id pc11_town_id using $tmp/master, keepusing(pc11_td_block_name)
keep if _merge == 3
drop _merge

/* collapse to level: access to water */
collapse (sum) *_no *no_hh , by(pc11_state_id pc11_district_id pc11_td_block_name)

/* save level data */
save $tmp/pc11u_water_block_bihar, replace

ren pc11_td_block_name pc11_vd_block_name
replace pc11_vd_block_name = proper(pc11_vd_block_name)

/* merge rural and urban households data */
merge 1:1 pc11_state_id pc11_district_id pc11_vd_block_name using $tmp/pc11r_water_block_bihar, nogen

/* drop unnecessary vars */
drop *hl_dwelling* *dw_source*

/* save */
save $tmp/pc11_water_block_bihar, replace

/************************/
/* Health capacity data */
/************************/

/* Use pre-collapse health capacity data */
use $tmp/precollapse, clear

/* keep obs for bihar */
keep if pc11_state_id == "10"

/* keep relevant vars */
keep *nh *mh *_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot pc11_state_id pc11_district_id pc11_town_id urban pc11_village_id

/* extract block names for rural/urban health capacity data from vd */
preserve

/* keep rural obs */
keep if urban == 0

/* get pc11 vd block name */
merge 1:1 pc11_state_id pc11_village_id using $pc11/pc11_vd_clean, keepusing(pc11_vd_block_name)
keep if _merge == 3
drop _merge

/* save */
save $tmp/healthr_bihar, replace

restore

preserve

/* keep urban obs */
keep if urban == 1

/* get pc11 vd block name */
merge 1:m pc11_state_id pc11_district_id pc11_town_id using $pc11/pc11_td_clean, keepusing(pc11_td_block_name)
keep if _merge == 3
drop _merge

/* rename block name for merge */
ren pc11_td_block_name pc11_vd_block_name
replace pc11_vd_block_name = proper(pc11_vd_block_name)

/* save */
save $tmp/healthu_bihar, replace

restore

/* append rural and urban health datasets */
use $tmp/healthr_bihar, clear
append using $tmp/healthu_bihar

/* collapse at block level */
collapse (sum) pc11_td*, by(pc11_state_id pc11_district_id pc11_vd_block_name)

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
save $tmp/pc11_healthcapacity_block_bihar, replace

/***********************************************/
/* Merge everything with lgd-pc11 block key */
/***********************************************/

use $covidpub/bihar/lgd_pc11_block_key_bihar, clear

/* merge pca data */
merge 1:1 pc11_state_id pc11_district_id pc11_vd_block_name using $tmp/pc11_td_block_bihar, gen(td_merge)
merge 1:1 pc11_state_id pc11_district_id pc11_vd_block_name using $tmp/pc11_vd_block_bihar, gen(vd_merge)
merge 1:1 pc11_state_id pc11_district_id pc11_vd_block_name using $tmp/pc11_water_block_bihar, gen(water_merge)
merge 1:1 pc11_state_id pc11_district_id pc11_vd_block_name using $tmp/pc11_healthcapacity_block_bihar, gen(hosp_merge)

/* drop merge */
drop *_merge

/* create population total */
egen pc11_pca_tot_p = rowtotal(pc11r_pca_tot_p pc11u_pca_tot_p)
egen pc11_pca_mainwork_p = rowtotal(pc11r_pca_mainwork_p pc11u_pca_mainwork_p)
egen pc11_pca_main_al_p = rowtotal(pc11r_pca_main_al_p pc11u_pca_main_al_p)
egen pc11_pca_main_cl_p = rowtotal(pc11r_pca_main_cl_p pc11u_pca_main_cl_p)

/* final cleaning steps */
finalsteps
order *vd_block*, after(pc11_district_name)

/* save dataset */
save $covidpub/bihar/bihar_block_pc11, replace
