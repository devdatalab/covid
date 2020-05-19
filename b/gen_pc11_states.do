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
    ren pc11r_td* pc11r_tot*
    ren pc11_td* pc11u_tot*
    ren pc11u_tot_area pc11_td_area

    /* create health capacity total vars  */
    foreach i in all_hosp all_hosp_doc_tot all_hosp_pmed_tot disp {
      egen pc11_tot_`i' = rowtotal(pc11r_tot_`i' pc11u_tot_`i')
    }

    foreach i in ch_cntr ph_cntr phs_cntr mcw_cntr tb_cln mh_cln fwc_cntr{
      egen pc11_tot_`i' = rowtotal(pc11r_tot_`i' pc11u_tot_`i')
    }

    gen pc11_tot_nh = pc11u_tot_nh
    gen pc11_tot_mh = pc11u_tot_mh
    
    drop pc11r_tot* pc11u_tot*
        
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
    egen area_final = rowtotal(area pc11_td_area)
    drop area
    ren area_final area
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
    la var pc11_vd_area "Area (ha) rural"
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

/*****************/
/* Prep PCA data */
/*****************/

/* extract lgd state and district ids for pca rural */
use $pc11/pc11r_pca_clean.dta, clear

/* merge with lgd-pc11 village key */
merge 1:1 pc11_state_id pc11_village_id using $keys/lgd_pc11_village_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)
keep if _merge == 3

drop _merge

/* keep necessary vars */
keep *pca_tot_p *pca_no_hh *pca_main_cl_p *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* lgd* pc11_village* pc11_subdistrict*

/* rename vars */
ren pc11_pca* pc11r_pca*

/* save */
save $tmp/pc11r_pca_lgd, replace

/* extract lgd state and district ids for pca urban */
use $pc11/pc11u_pca_clean.dta, clear

/* merge with lgd-pc11 town key */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $keys/lgd_pc11_town_key, keepusing(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)

/* everything merged */
drop _merge
  
/* keep necessary vars */
keep *pca_tot_p *pca_no_hh *pca_main_cl_p *pca_main_al_p *_mainwork_p pc11_state* pc11_dist* lgd* pc11_town* pc11_subdistrict*

/* rename vars */
ren pc11_pca* pc11u_pca*

/* save */
save $tmp/pc11u_pca_lgd, replace

/********************************/
/* Prep households listing data */
/********************************/

/* rural */
use $pc11/houselisting_pca/pc11r_hpca_village.dta , clear

/* merge with pca rural data merged with lgd */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id using $tmp/pc11r_pca_lgd, nogen

/* In the hpca data households with access to water are represented as shares */
foreach x of var pc11r_hl_dw*{

/* create number of households with access to drinking water */
  gen `x'_no = `x'*pc11r_pca_no_hh

}

/* drop unnecessary vars */
keep pc11r_hl_dw_loc* lgd* pc11_state* pc11_district* pc11_subd* pc11_village* pc11r_pca*

/* save merged dataset  */
save $tmp/pc11r_pca_water_lgd, replace

/* urban */
use $pc11/houselisting_pca/pc11u_hpca_town.dta , clear

/* merge with pca urban data merged with lgd */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $tmp/pc11u_pca_lgd, nogen

/* In the hpca data households with access to water are represented as shares */
foreach x of var pc11u_hl_dw*{

/* create number of households with access to drinking water */
  gen `x'_no = `x'*pc11u_pca_no_hh

}

/* drop unnecessary vars */
keep pc11u_hl_dw_loc* lgd* pc11_state* pc11_district* pc11_subd* pc11_town* pc11u_pca*

/* save merged dataset  */
save $tmp/pc11u_pca_water_lgd, replace

/****************************/
/* Prep Town directory data */
/****************************/

use $pc11/pc11_td_clean.dta , clear

/* keep necessary vars */
keep pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id pc11_td_area

/* merge with the merged pca-water-lgd dataset */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $tmp/pc11u_pca_water_lgd, nogen

/* save data */
save $tmp/pc11u_pca_water_td_lgd, replace

/*******************************/
/* Prep Village directory data */
/*******************************/

use $pc11/pc11_vd_clean.dta , clear

/* keep necessary vars */
keep pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id pc11_vd_area

/* merge with the merged pca-water-lgd dataset */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id using $tmp/pc11r_pca_water_lgd, nogen

/* generate village are variable in hectares */
gen area = pc11_vd_area/100

/* save data */
save $tmp/pc11r_pca_water_vd_lgd, replace

/************************/
/* Health capacity data */
/************************/

/* Use cleaned health capacity dataset - check covid/b/prep_pc_hosp.do */
/* Using this version bc outliers were checked and dropped in this version */
use $tmp/precollapse, clear

/* create rural health capacity dataset */
keep if urban == 0

/* keep relevant vars */
keep *_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id

/* merge with other rural variables dataset */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id using $tmp/pc11r_pca_water_vd_lgd, nogen

/* save data */
save $tmp/pc11_all_rural, replace

use $tmp/precollapse, clear

/* create rural health capacity dataset */
keep if urban == 1

/* keep relevant vars */
keep *mh *nh *_cln *cntr *disp *all_hosp *all_hosp_doc_tot *all_hosp_pmed_tot pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id

/* merge with other rural variables dataset */
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id pc11_town_id using $tmp/pc11u_pca_water_td_lgd, nogen

/* save data */
save $tmp/pc11_all_urban, replace

/***********************************************************/
/* Merge rural and urban datasets and final cleaning steps */
/***********************************************************/

/* collapse at district level */
foreach i in rural urban{

  use $tmp/pc11_all_`i', clear

  if "`i'" == "rural" local vars pc11r* *area pc11_td*
  if "`i'" == "urban" local vars pc11u* pc11_td*

  /* drop obs with no lgd var  */
  drop if lgd_district_id == ""
  
  /* collapse at district level */
  collapse (sum) `vars', by(lgd_state_id lgd_state_name lgd_district_id lgd_district_name)

  /* save */
  save $tmp/pc11_all_`i'_district, replace

}

/* import rural district level dataset */
use $tmp/pc11_all_rural_district, clear

/* rename health capacity vars  */
ren pc11_td* pc11r_td*

/* merge with urban district level dataset */
merge 1:1 lgd_state_id lgd_district_id using $tmp/pc11_all_urban_district, nogen

/* final cleaning steps */
finalsteps

/* save district level clean dataset */
save $tmp/pc11_district_capacity, replace

/* save statewise datasets */
levelsof lgd_state_id, local(levelstate)

foreach s of local levelstate {

/* save statewise file */
savesome using $tmp/pc11_district_capacity_`s' if lgd_state_id == "`s'", replace
  
}


/* Aditi - start here */


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
