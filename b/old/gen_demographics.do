/* generate demographic data at district and subdistrict levels */

/* settings */
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
  
  /* merge total/urban/rural pca level data together */
  use $pc11/pc11r_pca_`level'_clean.dta, clear
  ren pc11_pca* pc11r_pca*
  merge 1:1 `ids' using $pc11/pc11u_pca_`level'_clean, gen(_m_pc11u)
  ren pc11_pca* pc11u_pca*
  merge 1:1 `ids' using $pc11/pc11_pca_`level'_clean, gen(_m_pc11r)
  drop _m*

  /* drop unnecessary variables */
  drop pc11*tru pc11*level

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
  
  /* urbanization */
  gen pc11_urb_share = pc11u_pca_tot_p / pc11_pca_tot_p
  label var pc11_urb_share "Urban population share"
  
  /* total area */
  gen pc11_tot_area =  pc11_td_area + pc11_vd_area
  label var pc11_tot_area "Total area (sq km, PC11)"
  
  /* population density */
  gen pc11_pop_dens = pc11_pca_tot_p / (pc11_tot_area)
  label var pc11_pop_dens "Population per sq km (PC11)"

  /* keep only needed variables */
  keep `ids' pc11_urb_share pc11_slum_pop pc11*area pc11_pop_dens pc11*pca_tot_p  pc11*pca_tot_m pc11*pca_tot_f pc11*pca_p_lit pc11*pca_m_lit pc11*pca_f_lit  pc11*pca_p_sc pc11*pca_m_sc pc11*pca_f_sc   pc11*pca_p_st pc11*pca_m_st pc11*pca_f_st 
  
  /* order */
  order `ids' pc11_urb_share pc11_slum_pop pc11*area pc11_pop_dens  pc11*pca_tot_p  pc11*pca_tot_m pc11*pca_tot_f pc11*pca_p_lit pc11*pca_m_lit pc11*pca_f_lit  pc11*pca_p_sc pc11*pca_m_sc pc11*pca_f_sc   pc11*pca_p_st pc11*pca_m_st pc11*pca_f_st 

  /* save */
  compress
  save $covidpub/demography/pc11_demographics_`level', replace
  export delimited $covidpub/demography/csv/pc11_demographics_`level'.csv, replace

}


