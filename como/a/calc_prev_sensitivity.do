/*
Alternate form of main analysis that bootstraps prevalences.

*/

/* set a randomization seed so results can replicate, using the auspicious year 2020 */
set seed 2020

cap erase $tmp/prrs_prev_b.csv
append_to_file using $tmp/prrs_prev_b.csv, s(prr_ratio)
cap erase $tmp/deaths_prev_b.csv
append_to_file using $tmp/deaths_prev_b.csv, s(country,death_share)

/* run 1000 boostraps */
forval b = 1/1000 {
  di "`b'"
  
  /* loop over prevalence files. For this sensitivity test, we only care about
    uk_nhs_matched and india. */
  qui foreach prev in india uk_nhs_matched {
  
    /* use the fully adjusted HRs */
    foreach hr in full_cts {
  
      /* open the hazard ratio file */
      use $tmp/hr_`hr', clear

      /* merge the prevalence file */
      merge 1:1 age using $tmp/prev_se_`prev', nogen

      /* loop over all conditions and replace prevalence with a draw from the distribution */
      foreach v in $hr_biomarker_vars $hr_gbd_vars {
        local draw = rnormal()

        /* if this is a log10 se, calculate a draw in logs */
        noi disp_nice "`prev'"
        cap confirm variable logse_`v'
        if !_rc {
          replace prev_`v' = 10 ^ (log10(prev_`v') + `draw' * logse_`v')
        }

        /* if this is a straight SE, take a draw in levels */
        else {
          replace prev_`v' = prev_`v' + `draw' * se_`v'
        }
      }
      
      /* calculate the all-comorbidity population relative risk at each age, multiplying prevalence by hazard ratio */
      gen prr_health = 1
      foreach v in male $hr_biomarker_vars $hr_gbd_vars {
        gen prr_`v' = prev_`v' * hr_`v' + (1 - prev_`v')
        qui replace prr_health = prr_health * prr_`v'
        qui sum prr_health
        di "`v': " %5.2f `r(mean)'
      }
  
      /* renormalize the cts age hazard ratio around age 50 */
      if strpos("`hr'", "cts") {
        qui sum hr_age if age == 50
        qui replace hr_age = hr_age / `r(mean)'
      }
      
      /* create another one that has age */
      gen prr_all = prr_health * hr_age
      save $tmp/prr_`prev'_`hr'_boot, replace
    }
  }
  
  qui {
    /* combine the India and the UK joint risk factors */
    clear
    set obs 82
    gen age = _n + 17
    foreach prev in india uk_nhs_matched {
      foreach hr in full_cts {
        merge 1:1 age using $tmp/prr_`prev'_`hr'_boot, keepusing(prr_all prr_health) nogen
        ren prr_all prr_all_`prev'_`hr'
        ren prr_health prr_h_`prev'_`hr'
      }
    }
    
    /* bring in population shares */
    merge 1:1 age using $tmp/india_pop, keep(master match) nogen keepusing(india_pop)
    merge 1:1 age using $tmp/uk_pop, keep(master match) nogen keepusing(uk_pop)
    
    /* RESULT 1: AGGREGATE RISK FACTOR ACROSS ALL CONDITIONS AND AGES */
    qui sum prr_h_india_full_cts [aw=india_pop]
    gen india_prr = `r(mean)'
    qui sum prr_h_uk_nhs_matched_full_cts [aw=uk_pop]
    gen uk_prr = `r(mean)'
    gen prr_ratio = uk_prr / india_prr
    
    /* write the prr_ratio to a file */
    qui sum prr_ratio
    append_to_file using $tmp/prrs_prev_b.csv, s(`r(mean)')
  }
  
  /*********************************/
  /* now compare density of deaths */
  /*********************************/
  qui { 
    /* rename the models to make life easier */
    ren *india_full_cts* *india_full*
    ren *uk_nhs_matched_full_cts* *uk_full*
    
    global modellist india_full uk_full
    
    /* Calculate the distribution of deaths in the model */
    global mortrate 1
    foreach model in full {
      foreach country in uk india {
        gen `country'_`model'_deaths = $mortrate * `country'_pop * prr_all_`country'_`model'
      }
    }
    
    /* rescale sum of deaths in each model to 1 (to show density) */
    global sim_n 1
    foreach model in $modellist {
      local v `model'_deaths
      sum `v'
      replace `v' = `v' / (`r(mean)' * `r(N)') * $sim_n
    }
    
    /* smooth the deaths series */
    sort age
    gen x = 1
    xtset x age
    foreach v of varlist *deaths {
      replace `v' = (L2.`v' + L1.`v' + `v' + F.`v' + F2.`v') / 5 if !mi(L2.`v') & !mi(F2.`v')
      replace `v' = (L1.`v' + `v' + F.`v' + F2.`v') / 4 if mi(L2.`v') & !mi(F2.`v') & !mi(L1.`v')
      replace `v' = (L2.`v' + L1.`v' + `v' + F.`v') / 4 if mi(F2.`v') & !mi(L2.`v') & !mi(F1.`v')
    }
    
    /* store share of deaths under age 60 for india and england */
    sum india_full_deaths if age < 60
    local share = (`r(N)' * `r(mean)' * 100)
    append_to_file using $tmp/deaths_prev_b.csv, s(india,`share')
    sum uk_full_deaths if age < 60
    local share = (`r(N)' * `r(mean)' * 100)
    append_to_file using $tmp/deaths_prev_b.csv, s(england,`share')
  }
}

/* plot PRR bootstrap distribution */
import delimited using $tmp/prrs_prev_b.csv, clear
sum prr_ratio, d
kdensity prr_ratio, xline(`r(mean)')
graphout prr_ratio_prev_bootstrap

/* plot deaths under 60 bootstrap distribution */
import delimited using $tmp/deaths_prev_b.csv, clear
bys country: sum death_share, d
twoway ///
    (kdensity death_share if country == "england") ///
    (kdensity death_share if country == "india") ///
    , legend(lab(1 "England") lab(2 "India")) title("Share of deaths under 60")
graphout deaths_prev_bootstrap


exit

/**********************************************************/
/* compare UK health conditions and risk factors to India */
/**********************************************************/
use $tmp/prr_india_full_cts, clear
ren prev* iprev*
ren rf* irf*
merge 1:1 age using $tmp/prr_uk_nhs_matched_full_cts, nogen
ren prev* uprev*
ren rf* urf*

/* calculate relative difference in prevalence and risk factor for each condition */
foreach v in male $hr_biomarker_vars $hr_gbd_vars $hr_os_only_vars {
  gen rfdiff_`v' = iprr_`v' / uprr_`v'
  gen prevdiff_`v' = iprev_`v' / uprev_`v'
}

/* report */
foreach v in male $hr_biomarker_vars $hr_gbd_vars $hr_os_only_vars {
  qui sum rfdiff_`v' if age == 50
  local rfd `r(mean)'
  qui sum prevdiff_`v' if age == 50
  local prevd `r(mean)'
  
  di %40s "`v' : " %5.2f `rfd' %10.2f `prevd'
}

/* calculate aggregate risk factor diffs between india and uk */
merge 1:1 age using $tmp/india_pop, keep(master match) nogen keepusing(india_pop)
merge 1:1 age using $tmp/uk_pop, keep(master match) nogen keepusing(uk_pop)

/* Show final results and save to file */

local t 1
foreach v in male $hr_biomarker_vars $hr_gbd_vars health {

  /* show title only if it's the first pass thru the loop */
  if `t' {
    di %25s " " "  UK    India   India/UK"
    di %25s " " "------------------------"
    }
  local t 0
  
  /* UK aggregate risk factor */
  qui sum uprr_`v' [aw=uk_pop]
  local umean = `r(mean)'
  
  /* India aggregate risk factor */
  qui sum iprr_`v' [aw=india_pop]
  local imean = `r(mean)'

  /* percent difference India over UK */
  local perc = (`imean'/`umean' - 1) * 100

  /* Get the sign on the % */
  if `perc' > 0 local sign " +"
  else local sign " "

  /* show everything */
  di %25s "`v': " %5.2f (`umean') "  " %5.2f (`imean') "  `sign'" %2.1f (`perc') "%"
}
