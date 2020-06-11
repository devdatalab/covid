/* predict district and subdistrict mortality distribution based on age distribution */

/* NOTE: this global needs to be the same as in gen_age_distribution.do */
global agebins age_0 age_5 age_10 age_15 age_20 age_25 age_30 age_35 age_40 age_45 age_50 age_55 age_60 age_65 age_70 age_75 age_80

/***************************************************/
/* ESTIMATE p(DEATH | INFECTION) at (SUB)DISTRICT LEVEL */
/***************************************************/

/* loop over subdistrict and district level data */
foreach level in subdistrict district {
  
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

  /* NOTE: We have no idea what the aggregate CFR should be in India. Rather than provide
           a misleading aggregate number when we don't know, we just normalize the data
           to a median value of 1. 1.7 means 70% more than the median (sub)district. */
  sum `level'_estimated_cfr_t, d
  replace `level'_estimated_cfr_t = `level'_estimated_cfr_t / `r(p50)'
  replace `level'_estimated_cfr_r = `level'_estimated_cfr_r / `r(p50)'
  replace `level'_estimated_cfr_u = `level'_estimated_cfr_u / `r(p50)'

  /* If you wanted to match Italy's age-specific mortality exactly, you would multiply by 0.00784 */
  
  /* If you wanted to match South Korea's age-specific mortality, you would multiply by about 0.00392  */
  
  /* If you wanted the median district to match India's aggregate CFR
  of 3.1%, you would multiply by 0.031. But this CFR is likely biased
  upward-- note that this is assuming India's age-specific mortality
  rate would be 10x that of South Korea.  */
  order `ids' pc11_pca* `level'_estimated_cfr_*

  /* write dta and csv */
  save $covidpub/estimates/pc11/`level'_age_dist_cfr_pc11, replace
  cap mkdir $covidpub/estimates/csv
  export delimited $covidpub/estimates/csv/`level'_age_dist_cfr_pc11.csv, replace

  /* district data also gets saved to lgd */
  if "`level'" == "district" {

    /* first build variable globals to define the aggregation method */
    foreach type in u r t {
      global pc11_pca_tot_`type'_ sum
      forval i = 0(5)80 {
        global pop_share_`type'_age_`i'_ sum
      }
    }

    /* convert to LGD, weighted by population */
    convert_ids, from_ids(pc11_state_id pc11_district_id) to_ids(lgd_state_id lgd_district_id) key($keys/lgd_pc11_district_key_weights.dta) weight_var(pc11_lgd_wt_pop) 
    save $covidpub/estimates/`level'_age_dist_cfr, replace
    export delimited $covidpub/estimates/csv/`level'_age_dist_cfr.csv, replace
  }
}
