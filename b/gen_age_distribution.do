/* Get age distribution for each district from the SECC, and use PC11 population to
   turn into age numbers at each age. */
global statelist andamannicobarislands andhrapradesh arunachalpradesh assam bihar chandigarh chhattisgarh dadranagarhaveli damananddiu goa gujarat haryana himachalpradesh jammukashmir jharkhand karnataka madhyapradesh maharashtra manipur meghalaya mizoram nagaland nctofdelhi odisha puducherry punjab rajasthan sikkim tamilnadu telangana tripura uttarakhand uttarpradesh westbengal

/* Note: agebin list needs to be the same in predict_age_cfr.do */
global agebins age_0 age_5 age_10 age_15 age_20 age_25 age_30 age_35 age_40 age_45 age_50 age_55 age_60 age_65 age_70 age_75 age_80

/************************************************/
/* Calculate Rural and Urban Age Bins from SECC */
/************************************************/

/* collapse this to both districts and subdistricts */
foreach level in district subdistrict {

  /* set location identifiers for this collapse level */
  if "`level'" == "district" local ids pc11_state_id pc11_district_id 
  if "`level'" == "subdistrict" local ids pc11_state_id pc11_district_id pc11_subdistrict_id 
  
  /* cycle through rural and urban */
  foreach sector in rural urban {
    
    /* set some urban and rural parameters: */
    /* - one letter suffix to distinguish urban and rural variables */
    /* - path: use parsed_draft for urban, final for rural */
    if "`sector'" == "urban" {
      local l = "u"
      local path $secc/parsed_draft/dta/urban
    }
    if "`sector'" == "rural" {
      local l = "r"
      local path $secc/final/dta
    }
    
    /* save an empty output file so we can append to it state by state */
    clear
    save $tmp/secc_age_bins_`level'_`l'_tmp, emptyok replace

    /* cycle through each state */
    foreach state in $statelist {
      disp_nice "`sector'-`level'-`state'"

      /* use telangana from parsed_draft/ folder */
      if "`state'" == "telangana" & "`sector'" == "rural" {
        use $secc/parsed_draft/dta/rural/`state'_members_clean, clear
      }
      else {
        
        /* open the members file */
        cap confirm file "`path'/`state'_members_clean.dta"
        
        /* skip loop if this file doesn't exist */
        if _rc != 0 continue
        
        /* open the file if it exists */
        use `path'/`state'_members_clean, clear
      }
      
      /* drop if missing geographic identifiers */
      drop if mi(pc11_state_id) | mi(pc11_district_id)
      if "`level'" == "subdistrict" drop if mi(pc11_subdistrict_id)
  
      /* keep only the ids and age variables */
      /* birthyear doesn't exist in the final/ data */
      cap gen birthyear = 2012 - age
      keep `ids' age birthyear 
      drop if age < 0
        
      /****************/
      /* Age Cleaning */
      /****************/
      /* create a clean age variable */
      gen age_clean = age

      /* assume that birthyears below 100 are actually the age, if the age is missing  */
      replace age_clean = birthyear if mi(age) & birthyear < 100
      replace birthyear = . if mi(age) & birthyear < 100

      /* assume the birthyears under 100 and ages over 1000 have been swapped */
      replace age_clean = birthyear if age > 1000 & birthyear < 100
      replace birthyear = age if age > 1000 & birthyear < 100

      /* assume birthyear is off by 1000 if less than 1900 */
      replace birthyear = birthyear + 100 if birthyear < 1900 & birthyear > 1800
      replace age_clean = 2012 - birthyear if age > 100

      /* replace age_clean with missing if it is unreasonable */
      replace age_clean = . if age_clean > 200

      /* replace age with age_clean */
      drop age birthyear
      ren age_clean age

      /* drop if missing age */
      drop if mi(age)
      drop if age < 0

      qui count
      if `r(N)' == 0 {
        continue
      }
      
      /***************/
      /* Age Binning */
      /***************/
      /* create age bins */
      egen age_bin_`l' = cut(age), at(0(5)85)

      /* fill in the 80+ age bin */
      replace age_bin_`l' = 80 if age >= 80

      /* drop age */
      drop age

      /* create counter to collapse over */
      gen age_ = 1

      /* collapse to count people in the age bins */
      collapse (sum) age_, by(`ids' age_bin_`l')

      /* get total population */
      bys `ids': egen secc_pop_`l' = total(age_)
  
      /* reshape rural data to wide so that each age bin is a variable */
      reshape wide age_, i(`ids' secc_pop_`l') j(age_bin_`l')

      foreach i in $agebins {
        
        /* if the age bin doesn't exist, set it to 0 */
        cap gen `i' = 0
        
        /* rename the age bin variables to be rural/urban specific */
        ren `i' `i'_`l'
      }

      /* calculate age bin population share */
      foreach i in $agebins {
        gen `i'_`l'_share = `i'_`l' / secc_pop_`l'
      }
  
      /********/
      /* Save */
      /********/
      /* append the data to the file */
      append using $tmp/secc_age_bins_`level'_`l'_tmp

      /* drop a weird broken rural district (almost no data)  */
      if "`sector'" == "rural" {
        drop if pc11_state_id == "12" & pc11_district_id == "246" & secc_pop_r == 198
      }
      bys `ids': assert _N == 1

      save $tmp/secc_age_bins_`level'_`l'_tmp, replace
    }
    
    /* save the appended file */
    save $tmp/secc_age_bins_`level'_`l', replace
  }
}

/*********************************************/
/* COMBINE URBAN AND RURAL AGE DISTRIBUTIONS */
/*********************************************/
foreach level in district subdistrict {
  
  /* set location identifiers for this collapse level */
  if "`level'" == "district" local ids pc11_state_id pc11_district_id 
  if "`level'" == "subdistrict" local ids pc11_state_id pc11_district_id pc11_subdistrict_id 
  
  /* open urban data and merge with rural */
  use $tmp/secc_age_bins_`level'_u, clear
  merge 1:1 `ids' using $tmp/secc_age_bins_`level'_r

  /* rename merge to describe what sector the (sub)district appears in */
  ren _merge sector_present
  cap label drop sector_present
  label define sector_present 1 "1 urban only " 2 "2 rural only" 3 "3 urban and rural"
  label values sector_present sector_present
  
  /***********************************************/
  /* merge with PC11 urban and rural populations */
  /***********************************************/
  
  /* urban */
  merge 1:1 `ids' using $iec1/pc11/pc11u_pca_`level'_clean, keepusing(pc11_pca_tot_p) assert(match using)
  ren pc11_pca_tot_p pc11_pca_tot_u
  ren _merge _merge_u

  /* rural */
  merge 1:1 `ids' using $iec1/pc11/pc11r_pca_`level'_clean, keepusing(pc11_pca_tot_p) assert(match)
  ren pc11_pca_tot_p pc11_pca_tot_r
  drop _merge

  /* calculate total PCA population  */
  egen pc11_pca_tot_t = rowtotal(pc11_pca_tot_u pc11_pca_tot_r)

  /* flag places with missing age bins. These are zeroes, and they are places in SECC
  that have very small numbers of rural or urban observations. */
  gen flag_r = 0
  gen flag_u = 0
  foreach age in $agebins {
    replace flag_r = 1 if mi(`age'_r)
    replace flag_u = 1 if mi(`age'_u)
  }
  sum secc_pop_r if flag_r == 1, d
  sum secc_pop_u if flag_u == 1, d
  
  /* wipe SECC age data for these. We'll replace with state means below */
  foreach age in $agebins {
    replace `age'_r = . if flag_r == 1
    replace `age'_u = . if flag_u == 1
  }
  drop flag_r flag_u
  
  /* make sure we don't have zeros left */
  foreach age in $agebins {
    assert `age'_r != 0
    assert `age'_u != 0
  }
  
  /* assign them the mean state age shares for (sub)districts with no data. */
  foreach loc in r u {
    foreach age in $agebins {
      bys pc11_state_id: egen state_`age'_`loc' = total(`age'_`loc')
    }
    egen state_pop_`loc' = rowtotal(state_age_*_`loc')
    foreach age in $agebins {
      replace `age'_`loc' = state_`age'_`loc' / state_pop_`loc' if mi(`age'_`loc')
    }
  }
  drop state*

  /* drop states where we don't have good data */
  tab pc11_state_id if mi(age_40_r) & !mi(pc11_pca_tot_r)
  tab pc11_state_id if mi(age_40_u) & !mi(pc11_pca_tot_u)
  drop if inlist(pc11_state_id, "26", "31", "32", "34", "35")
  
  /* recalculate age shares from data now that missing age-bins/(sub)districts have been imputed */
  drop *share
  foreach loc in r u {
    egen secc_pop_`loc'_calc_total = rowtotal(age_*_`loc')
    foreach age in $agebins {
      gen `age'_`loc'_share = `age'_`loc' / secc_pop_`loc'_calc_total
    }
  }
  
  /* drop SECC populations, because using PC aggregate populations from here */
  drop age_*_u age_*_r

  /* impute population in each age bin as SECC age share * PC11 total population */
  foreach i in $agebins {
    
    /* generate total population in age group using secc agebin shares
    multiplied by pc11 population for urban and rural */
    gen `i'_r = round(`i'_r_share * pc11_pca_tot_r)
    gen `i'_u = round(`i'_u_share * pc11_pca_tot_u)
    egen `i'_t = rowtotal(`i'_r `i'_u)
    
    /* calculate the age group share for the total population */
    gen `i'_t_share = `i'_t / pc11_pca_tot_t
  }

  /* drop SECC populations which are not used and are less reliable than the pop census */
  drop secc_pop_*

  /* drop other extraneous fields */
  drop _merge_u
  
  /* save totals */
  label data ""
  cap mkdir $covidpub/demography
  save $covidpub/demography/secc_age_bins_`level'_t, replace
}

