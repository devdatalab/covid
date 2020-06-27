/*
Alternate form of main analysis that bootstraps hazard ratios.

*/

/* set a randomization seed so results can replicate, using the auspicious year 2020 */
set seed 2020

cap erase $tmp/prrs_hr_b.csv
append_to_file using $tmp/prrs_hr_b.csv, s(prr_ratio)
cap erase $tmp/deaths_hr_b.csv
append_to_file using $tmp/deaths_hr_b.csv, s(country,death_share)

/* run 1000 boostraps */
forval b = 1/1000 {
  di "`b'"
  
  /* loop over prevalence files. For this sensitivity test, we only care about
    uk_nhs_matched and india. */
  qui foreach prev in india uk_nhs_matched {
  
    /* use fully adjusted HRs */
    foreach hr in full_cts {
  
      /* open the hazard ratio file */
      use $tmp/hr_`hr', clear

      /* replace each hazard ratio with a draw from the distribution */
      /* loop over all conditions */
      foreach v in male $hr_biomarker_vars $hr_gbd_vars {
        local draw = rnormal()
        replace hr_`v' = exp(ln(hr_`v') + `draw' * hr_lnse_`v')
      }
      
      /* merge the prevalence file */
      merge 1:1 age using $tmp/prev_`prev', nogen
      
      /* calculate the all-comorbidity population relative risk at each age, multiplying prevalence by hazard ratio */
      gen prr_health = 1
      foreach v in $hr_biomarker_vars $hr_gbd_vars {
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
      
      /* create a prr for male gender */
      gen prr_male = (prev_male * hr_male + (1 - prev_male))

      /* create prr for combined health, age and gender */
      gen prr_all = prr_health * hr_age * prr_male

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
    gen prr_ratio = india_prr / uk_prr
    
    /* write the prr_ratio to a file */
    qui sum prr_ratio
    append_to_file using $tmp/prrs_hr_b.csv, s(`r(mean)')
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
    append_to_file using $tmp/deaths_hr_b.csv, s(india,`share')
    sum uk_full_deaths if age < 60
    local share = (`r(N)' * `r(mean)' * 100)
    append_to_file using $tmp/deaths_hr_b.csv, s(england,`share')
  }
}

/* get the aggregate PRR England/India difference used in the paper */
use $tmp/prr_result, clear
qui sum uprr_health [aw=uk_pop]
local umean = `r(mean)'
qui sum iprr_health [aw=india_pop]
local imean = `r(mean)'
global prr_paper = ((((`imean'/`umean' - 1) * 100) + 100) / 100)

/* get the aggregate death share under 60 for each country used in the paper */
use $tmp/mort_density_full, clear
qui sum india_full_deaths if age < 60
global ideaths = (`r(N)' * `r(mean)' * 100)
qui sum uk_full_deaths if age < 60
global edeaths = (`r(N)' * `r(mean)' * 100)

/* plot PRR bootstrap distribution */
import delimited using $tmp/prrs_hr_b.csv, clear
sum prr_ratio, d
histogram prr_ratio, xline($prr_paper, lwidth(thick)) xtitle("") percent ytitle("Percent of draws (N=1000)")  ylabel(0(2)12)
graphout hr_sens_prr_ratio, pdf

/* plot deaths under 60 bootstrap distribution */
import delimited using $tmp/deaths_hr_b.csv, clear
sum death_share if country == "england"
histogram death_share if country == "england", xline($edeaths, lwidth(thick)) xtitle("") percent ytitle("Percent of draws (N=1000)") ylabel(0(2)12)
graphout hr_sens_deaths_e, pdf

sum death_share if country == "india"
histogram death_share if country == "india", xline($ideaths, lwidth(thick)) xtitle("") percent ytitle("Percent of draws (N=1000)") ylabel(0(2)12)
graphout hr_sens_deaths_i, pdf

