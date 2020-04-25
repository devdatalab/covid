/* predict district and subdistrict mortality distribution based on age distribution */

/* NOTE: this global needs to be the same as in gen_age_distribution.do */
global agebins age_0 age_5 age_10 age_15 age_20 age_25 age_30 age_35 age_40 age_45 age_50 age_55 age_60 age_65 age_70 age_75 age_80

/***************************************************/
/* ESTIMATE p(DEATH | INFECTION) at (SUB)DISTRICT LEVEL */
/***************************************************/

/* loop over subdistrict and district level data */
foreach level in district subdistrict {
  
  /* set location identifiers for this collapse level */
  if "`level'" == "district" local ids pc11_state_id pc11_district_id 
  if "`level'" == "subdistrict" local ids pc11_state_id pc11_district_id pc11_subdistrict_id 
  
  /* calculate for total, rural, and urban */
  foreach l in t r u {
    
    /* open the data */
    use pc11_pca_tot_`l' `ids' age_*_`l'_share age_*_`l' using $covidpub/demography/secc_age_bins_`level'_t, clear

    /* sort on identifiers */
    sort `ids'
    
    /* drop the population totals */
    drop age*_`l'
    
    /* rename the age bins so they can be reshaped */
    foreach i in $agebins {
      ren `i'_`l'_share `i'
    }
  
    /* reshape to long */
    reshape long age_, i(`ids' pc11_pca_tot_`l') j(age_bins)

    /* rename the age bin fraction variable */
    ren age_ pop_frac

    /* convert age bin variable to proper string */
    tostring age_bin, replace
    replace age_bin = "age_" + age_bin

    /* merge with cfr data - use italy rates - high end of CFR */
    merge m:1 age_bin using $covidpub/covid/cfr_age_bins, keepusing(italy) assert(match) nogen

    /* rename Italy rate to just be cfr */
    /* note: Italy aggregate CFR measured on March 24 was 12.3%, S.Korea was 1.33%,
             but most of this difference comes from age distribution. */
    ren italy cfr

    /* estimate probability of death given infection for each age bin in each (sub)district*/
    gen est_p_death_age =  cfr * pop_frac

    /* estimate the probability of death given infection at the district level */
    bys `ids': egen `level'_estimated_cfr_`l' = total(est_p_death_age)
    
    /* multiply the CFR by a multiplication factor to account for India's higher comorbidity population and weaker health system.
    NOTE: We have very little idea what this multiplier should be.
    Needs to be informed by Indian CFR data when we think it is reliable. */
    global india_multiplier 3
    replace `level'_estimated_cfr_`l' = `level'_estimated_cfr_`l' * $india_multiplier
    
    /* convert age_bins back to numeric */
    replace age_bins = subinstr(age_bins, "age_", "", .)
    destring age_bins, replace
    
    /* drop unneeded variables used in (sub)district cfr calculation */
    drop cfr est_p_death_age
    
    /* rename population fraction variable to age_ so the reshaped variables are named correctly */
    ren pop_frac age_
    
    /* reshape to wide so that each age bin is a variable */
    reshape wide age_, i(`ids' `level'* pc11_pca_tot_`l') j(age_bins)
    
    /* rename variables for export */
    foreach age in $agebins {
      ren `age' pop_share_`l'_`age'
    }
    
    /* set CFRs to missing for places where missing data caused zero CFRs */
    /* FIX: FIGURE OUT WHY THIS HAPPENS */
    replace `level'_estimated_cfr_`l' = . if `level'_estimated_cfr_`l' == 0
  
    /* save */
    save $tmp/cfr_`l', replace
  }
  
  /* combine urban, rural and total TFR */
  use $tmp/cfr_t
  merge 1:1 `ids' using $tmp/cfr_r, assert(match) nogen
  merge 1:1 `ids' using $tmp/cfr_u, assert(match) nogen
  
  order `ids' pc11_pca* `level'_estimated_cfr_*

  save $covidpub/estimates/`level'_age_dist_cfr, replace
}
