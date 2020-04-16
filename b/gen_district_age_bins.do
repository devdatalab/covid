/* Get age distribution for each district from the SECC */
global statelist andamannicobarislands andhrapradesh arunachalpradesh assam bihar chandigarh chhattisgarh dadranagarhaveli damananddiu goa gujarat haryana himachalpradesh jammukashmir jharkhand karnataka madhyapradesh maharashtra manipur meghalaya mizoram nagaland nctofdelhi odisha puducherry punjab rajasthan sikkim tamilnadu telangana tripura uttarakhand uttarpradesh westbengal
global agebins age_0 age_5 age_10 age_15 age_20 age_25 age_30 age_35 age_40 age_45 age_50 age_55 age_60 age_65 age_70 age_75 age_80

/* remove files that will store all age bins if it already exists */
cap rm $tmp/secc_age_bins_r.dta
cap rm $tmp/secc_age_bins_u.dta

/************************************************/
/* Calculate Rural and Urban Age Bins from SECC */
/************************************************/
/* cycle through rural and urban */
foreach sector in rural urban {
  disp_nice "`sector'"
  
  /* set letter that will distinguish urban and rural variables */
  if "`sector'" == "urban" local l = "u"
  if "`sector'" == "rural" local l = "r"
  
  /* cycle through each state */
  foreach state in $statelist {
    disp_nice "`state'"

    /* open the urban file */
    cap confirm file "$iec2/secc/parsed_draft/dta/`sector'/`state'_members_clean.dta"

    if _rc == 0 {
      use $iec2/secc/parsed_draft/dta/`sector'/`state'_members_clean, clear
    
      /* drop if missing geographic identifiers */
      drop if mi(pc11_state_id)
      drop if mi(pc11_district_id)
  
      /* keep only the state, district, and age variables */
      keep pc11_state_id pc11_district_id age birthyear 

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
      collapse (sum) age_, by(pc11_state_id pc11_district_id age_bin_`l')

      /* get total population */
      bys pc11_state_id pc11_district_id: egen secc_pop_`l' = sum(age_)
  
      /* reshape rural data to wide so that each age bin is a variable */
      reshape wide age_, i(pc11_state_id pc11_district_id secc_pop_`l') j(age_bin_`l')

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
      /* check to see if the output file exists yet */
      cap confirm file "$tmp/secc_age_bins_`l'.dta"
      local output_exists = _rc
  
      /* if the output does not exist, write data to file */
      if `output_exists' != 0 {
        save $tmp/secc_age_bins_`l'
      }

      /* if the output does exist, append the data to the file */
      else {
        append using $tmp/secc_age_bins_`l'
        save $tmp/secc_age_bins_`l', replace
      }
    }
  }
}

/******************************/
/* MERGE WITH PC11 POPULATION */
/******************************/
/* cycle through rural and urban data */
foreach l in r u{
 
  /* open the secc age bin data */
  use $tmp/secc_age_bins_`l', clear

  /* there is one duplicated pair in the rural data- need to figure out why, just drop for noa */
  ddrop pc11_state_id pc11_district_id

  /* merge in the pc11 district population estimates */
  merge 1:m pc11_state_id pc11_district_id using $iec1/pc11/pc11`l'_pca_district_clean, keepusing(pc11_pca_tot_p) keep(match master)
  drop _merge

  /* rename population to specify sector */
  ren pc11_pca_tot_p pc11_pca_tot_`l'

  /* there is a duplicated pair in the urban and rural keys- need to figure out why, just drop for now */
  ddrop pc11_state_id pc11_district_id
  
  /* save in permanent file */
  save $iec/health/covid_data/secc_age_bins_`l', replace
}

/***************************/
/* COMBINE RURAL AND URBAN */
/***************************/
/* open urban data */
use $iec/health/covid_data/secc_age_bins_u, clear

/* merge with rural data */
merge 1:1 pc11_state_id pc11_district_id using $iec/health/covid_data/secc_age_bins_r

/* rename merge to describe what sector the district appears in */
ren _merge sector_present
cap label drop sector_present
label define sector_present 1 "1 urban only " 2 "2 rural only" 3 "3 urban and rural"
label values sector_present sector_present

/* create the total population to match the rural/urban format */
gen pc11_pca_tot_t = pc11_pca_tot_u + pc11_pca_tot_r

/* calculate total population count and total population shares in each age bin */
foreach i in $agebins {
x  
  /* generate total population in age group using secc agebin shares multiplied by pc11 population for urban and rural*/
  gen `i'_t = (`i'_r_share * pc11_pca_tot_r) + (`i'_u_share * pc11_pca_tot_u)

  /* convert to an integer */
  replace `i'_t = int(`i'_t)

  /* calculate the age group share */
  gen `i'_t_share = `i'_t / pc11_pca_tot_t
}

/* drop all rural and urban data */
drop *_r *_r_share *_u *_u_share

/* save totals */
save $iec/health/covid_data/secc_age_bins_t, replace
 
/***************************************************/
/* ESTIMATE p(DEATH | INFECTION) at DISTRICT LEVEL */
/***************************************************/
/* calculate for totla, rural, and urban */
foreach l in t r u{

  /* open the data */
  use $iec/health/covid_data/secc_age_bins_`l', clear

  /* sort on identifiers */
  sort pc11_state_id pc11_district_id

  /* drop the population totals */
  drop *5_`l'
  drop *0_`l'

  /* rename the age bins so they can be reshaped */
  foreach i in $agebins {
    ren `i'_`l'_share `i'
  }
  
  /* reshape to long */
  reshape long age_, i(pc11_state_id pc11_district_id pc11_pca_tot_`l') j(age_bins)

  /* rename the age bin fraction variable */
  ren age_ pop_frac

  /* convert age bin variable to proper string */
  tostring age_bin, replace
  replace age_bin = "age_" + age_bin

  /* merge with cfr data - use south korea rates */
  merge m:1 age_bin using $iec/health/covid_data/cfr_age_bins, keepusing(south_korea)
  drop _merge

  /* rename south korea rate to just be cfr */
  ren south_korea cfr

  /* estimate probability of death given infection for each age bin in each district*/
  gen est_p_death_age =  cfr * pop_frac

  /* estimate the probability of death given infection at the district level */
  bys pc11_state_id pc11_district_id: egen est_p_death_district = sum(est_p_death_age)

  /* convert age_bins to numeric */
  replace age_bins = subinstr(age_bins, "age_", "", .)
  destring age_bins, replace

  /* drop unneeded variables used in district cfr calculation */
  drop cfr est_p_death_age

  /* rename population fraction variable to age_ so the reshaped variables are named correctly */
  ren pop_frac age_

  /* reshpae to wide so that each age bin is a variable */
  reshape wide age_, i(pc11_state_id pc11_district_id est* pc11_pca_tot_`l') j(age_bins)

  /* save */
  save $iec/health/covid_data/age_bins_death_estimates_`l', replace
}
