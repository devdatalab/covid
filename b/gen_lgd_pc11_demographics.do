/***** TABLE OF CONTENTS *****/
/* Define program for final cleaning steps used in the last setcion of the do file */
/* Generate demographic data at district and subdistrict levels */
/* Prep Datasets at Geographic Levels */
  /* town directory */
  /* village directory */
  /* PCA */
  /* slums */
  /* Merge Together Data for Posting */
/* Generate state-wise demographic, health capacity, and water access data at the district level */
/* Create rural lgd-pc11 demographic dataset */
/* Create urban lgd-pc11 demographic dataset */
/* Append and collapse */

/***********************************************************************************/
/* Define program for final cleaning steps used in the last setcion of the do file */
/***********************************************************************************/

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
    gen pc11r_pdensity = pc11r_pca_tot_p/pc11_vd_area
    gen pc11u_pdensity = pc11u_pca_tot_p/pc11_td_area
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

/****************************************************************/
/* Generate demographic data at district and subdistrict levels */
/****************************************************************/

/* settings */
set_context covid
cap mkdir $tmp/covid
cap mkdir $covidpub/demography
cap mkdir $covidpub/demography/csv

/**************************************/
/* Prep Datasets at Geographic Levels */
/**************************************/

/* collapse this to both districts and subdistricts */
foreach level in district subdistrict {

  /* set location identifiers for this collapse level */
  if "`level'" == "district" local ids pc11_state_id pc11_district_id 
  if "`level'" == "subdistrict" local ids pc11_state_id pc11_district_id pc11_subdistrict_id 
  
  /******************/
  /* town directory */
  /******************/
  
  use $pc11/pc11_td_clean.dta , clear

  /* collapse to level: land area */
  collapse (sum) pc11_td_area , by(`ids')
  label var pc11_td_area "Total geographical area (sq km)"

  /* save level data */
  save $tmp/covid/pc11_td_`level', replace

  /*********************/
  /* village directory */
  /*********************/
  
  use $pc11/pc11_vd_clean.dta , clear

  /* collapse to level: land area */
  collapse (sum) pc11_vd_area , by(`ids')

  /* convert area from hectares to sq km as in town directory */
  replace pc11_vd_area = pc11_vd_area / 100
  label var pc11_vd_area "Total geographical area (sq km)"

  /* save level data*/
  save $tmp/covid/pc11_vd_`level', replace

  /*******/
  /* PCA */
  /*******/
  
  /* merge collapsed urban/rural pca level data together */
  foreach i in r u {
  use $pc11/pc11`i'_pca_clean.dta, clear
  ren pc11_pca* pc11`i'_pca*

  /* drop unnecessary vars */  
  cap drop pc11*tru pc11*level
  drop pc11*name

  /* collapse to level */
  collapse (sum) pc11`i'_pca*, by(`ids')
  save $tmp/covid/pc11`i'_pca_`level', replace
  }

  /* merge urban and rural pca data */
  use $tmp/covid/pc11r_pca_`level', clear
  merge 1:1 `ids' using $tmp/covid/pc11u_pca_`level', gen(_m_pc11)
  drop _m*

  /* save */
  save $tmp/covid/pc11_pca_`level', replace

  /*********/
  /* slums */
  /*********/
  
  /* note: slum data is at the town level so needs to be allocated to districts/subdistricts */

  /* use slum data */
  use $pc11/slums/pc11u_slums, clear

  /* merge in pc11 population data */
  merge 1:m pc11_state_id pc11_town_id using $pc11/pc11u_pca_clean, nogen keep(master match) keepusing(`ids' pc11_pca_tot_p)

  /* allocate slum population over level, allocating proportional to proportion of town population in each level */
  
  /* generate town population share in each subdistrict */
  bys pc11_state_id pc11_town_id: egen town_pop_total = total(pc11_pca_tot_p)
  gen town_pop_`level'_share = pc11_pca_tot_p / town_pop_total

  /* allocate slum population to each subdistrict */
  gen pc11_slum_pop = pc11_slum_tot_p * town_pop_`level'_share

  /* collapse to level */
  collapse (sum) pc11_slum_pop, by(`ids')
  label var pc11_slum_pop "Total population living in slums (PC11)"

  /* save level slum file */
  save $tmp/covid/pc11_slum_`level', replace


  /***********************************/
  /* Merge Together Data for Posting */
  /***********************************/

  /* merge data */
  use $tmp/covid/pc11_pca_`level', clear
  merge 1:1 `ids' using $tmp/covid/pc11_vd_`level', gen(_m_vd)
  merge 1:1 `ids' using $tmp/covid/pc11_td_`level', gen(_m_td)
  merge 1:1 `ids' using $tmp/covid/pc11_slum_`level', gen(_m_slum)
  drop _m*
  
  /* make sure missing values are zero when they should be */
  foreach v in pc11_td_area pc11_vd_area pc11_slum_pop {
    replace `v' = 0 if mi(`v')
  }

  /* generate variables of interest */
  
  /* total population */
  egen pc11_pca_tot_p = rowtotal(pc11r_pca_tot_p pc11u_pca_tot_p)
  label var pc11_pca_tot_p "Total population (Urban and Rural)"

  /* total area */
  gen pc11_tot_area =  pc11_td_area + pc11_vd_area
  label var pc11_tot_area "Total area (sq km, PC11)"

  /* population density */
  gen pc11_pop_dens = pc11_pca_tot_p / (pc11_tot_area)
  label var pc11_pop_dens "Population per sq km (PC11)"

  /* urbanization */
  gen pc11_urb_share = pc11u_pca_tot_p / pc11_pca_tot_p
  label var pc11_urb_share "Urban population share"
  
  /* keep only needed variables */
  keep `ids' pc11_urb_share pc11_slum_pop pc11*area pc11_pop_dens pc11*pca_tot_p  pc11*pca_tot_m pc11*pca_tot_f pc11*pca_p_lit pc11*pca_m_lit pc11*pca_f_lit  pc11*pca_p_sc pc11*pca_m_sc pc11*pca_f_sc   pc11*pca_p_st pc11*pca_m_st pc11*pca_f_st 
  
  /* order */
  order `ids' pc11_urb_share pc11_slum_pop pc11*area pc11_pop_dens  pc11*pca_tot_p  pc11*pca_tot_m pc11*pca_tot_f pc11*pca_p_lit pc11*pca_m_lit pc11*pca_f_lit  pc11*pca_p_sc pc11*pca_m_sc pc11*pca_f_sc   pc11*pca_p_st pc11*pca_m_st pc11*pca_f_st 

  /* save */
  compress
  save $covidpub/demography/pc11_demographics_`level', replace
  export delimited $covidpub/demography/csv/pc11_demographics_`level'.csv, replace

}

/*************************************************************************************************/
/* Generate state-wise demographic, health capacity, and water access data at the district level */
/*************************************************************************************************/

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

/* save final datasets */
save $tmp/lgd_pc11_demographics_district, replace

/* demographics data - population, ag share, pop density */
savesome lgd* *pca*p *pdensity *ag* *area using $covidpub/lgd_pc11_dem_district, replace

/* health capacity data */
savesome lgd* pc11_tot* using $covidpub/lgd_pc11_health_district, replace

/* household access to water data */
savesome lgd* *dw* *no_hh using $covidpub/lgd_pc11_water_district, replace

/*
/***************************/
/* Save statewise datasets */
/***************************/

/* create shortened version of lgd state name to label files */
gen statelabel = substr(lgd_state_name, 1, 8)
replace statelabel = subinstr(statelabel, " ", "", .)
label var statelabel "Shortened state name"

/* create state id locals */
levelsof statelabel, local(levelstate)

/* save separate datasets for each state */
foreach s of local levelstate{

  /* demographics data - population, ag share, pop density */
  savesome lgd* *pca* *pdensity *ag* *area using $tmp/lgd_pc11_dem_district_`s' if statelabel == "`s'", replace

  /* health capacity data */
  savesome lgd* pc11_tot* using $tmp/lgd_pc11_health_district_`s' if statelabel == "`s'", replace

  /* household access to water data */
  savesome lgd* *dw* using $tmp/lgd_pc11_water_district_`s' if statelabel == "`s'", replace

}
*/
