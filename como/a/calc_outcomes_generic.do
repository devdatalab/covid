/* program to calculate generic outcomes given:

1. a set of condition-specific (and possibly age-specific) hazard ratios (i.e. the model)
$tmp/hr_[full|simple]_[cts|dis]

2. a set of prevalences
$tmp/prev_india, $tmp/prev_uk_os, $tmp/prev_uk_nhs, $tmp/prev_uk_nhs_matched

3. a population distribution
[later]

Outcomes
---------
1. age-specific mortality curve (Fig. 2A)
1A. age-specific health contribution to mortality curve
2. share of deaths under age 60
3. total number of deaths given a mortality rate for women aged 50-59.

*/

local hr full_cts
local prev india

/* loop over prevalence files -- nhs is age-specific, o/s is just pop means */
/* uk_nhs_matched is the UK one we use for everything. */
foreach prev in india uk_os uk_nhs uk_nhs_matched {

  /* loop over hazard ratio sets -- cts means age is cts and not in bins */
  /* full_cts is the main one that we use. */
  foreach hr in simple_dis full_dis simple_cts full_cts {

    /* open the hazard ratio file */
    use $tmp/hr_`hr', clear
    
    /* merge the prevalence file */
    merge 1:1 age using $tmp/prev_`prev', nogen
    
    /* calculate the risk factor at each age, multiplying prevalence by hazard ratio */
    gen rf_health = 1
    foreach v in male $hr_biomarker_vars $hr_gbd_vars $hr_os_only_vars {
      /* rf <-- rf * (prev_X * hr_X + (1 - prev_X) * hr_notX), but hr_notX is always 1 */
      gen rf_`v' = prev_`v' * hr_`v' + (1 - prev_`v')
      replace rf_health = rf_health * rf_`v'
      qui sum rf_health
      di "`v': `r(mean)'"
    }

    /* create another one that has age */
    gen rf_all = rf_health * hr_age
    
    save $tmp/rf_`prev'_`hr', replace

    /* save a version on iec for santosh */
    export delimited using ~/iec/output/pn/rf_`prev'_`hr'.csv, replace
  }
}

/* combine the joint risk factors */
clear
set obs 72
gen age = _n + 17
foreach prev in india uk_os uk_nhs uk_nhs_matched {
  foreach hr in simple_dis full_dis simple_cts full_cts {
    merge 1:1 age using $tmp/rf_`prev'_`hr', keepusing(rf_all rf_health) nogen
    ren rf_all rf_all_`prev'_`hr'
    ren rf_health rf_h_`prev'_`hr'
  }
}

/* bring in population shares */
merge 1:1 age using $tmp/india_pop, keep(master match) nogen keepusing(india_pop)
merge 1:1 age using $tmp/uk_pop, keep(master match) nogen keepusing(uk_pop)

/* save an analysis file */
save $tmp/como_analysis, replace

/*****************************************/
/* compare health condition risk factors */
/*****************************************/
/* compare India and UK health condition risk factors */
// scp rf_h_india_full_cts rf_h_uk_os_full_cts rf_h_uk_nhs_matched_full_cts rf_h_uk_nhs_full_cts, ///
//     ytitle("Combined Health Risk Factor") ///
//     legend(lab(1 "India") lab(2 "UK OpenSafely Coefs") lab(3 "UK full matched") lab(4 "UK full full")) name(rf_health_all)

/* india vs. uk matched */
sort age
twoway ///
    (line rf_h_india_full_cts age, lwidth(medthick) lcolor(black)) ///
    (line rf_h_uk_nhs_matched_full_cts age, lwidth(medthick) lcolor(gs8) lpattern(-)), ///
    ytitle("Risk Factor from Population Health Conditions") xtitle("Age") ///
    legend(lab(1 "India") lab(2 "United Kingdom") ring(0) pos(5) cols(1) region(lcolor(black))) ///
    name(rf_health, replace)  ylabel(1(.5)4)
graphout rf_health

// /*************************************/
// /* compare age * health risk factors */
// /*************************************/
// /* compare three UK models: OS fixed age, full-prevalences, simple */
// sc rf_all_uk_os_simple_cts rf_all_uk_os_full_cts rf_all_uk_nhs_matched_full_cts rf_all_uk_nhs_full_cts, ///
//     legend(lab(1 "Simple") lab(2 "Full O.S. coefs") lab(3 "Full (matched conditions)") lab(4 "Full (all conditions)")) name(rf_uk_compare) yscale(log)
// 
// /* full vs. full, India vs. UK */
// sc rf_all_india_full_cts rf_all_uk_nhs_matched_full_cts, ///
//     name(rf_all_full) yscale(log) legend(lab(1 "India") lab(2 "UK"))
// 
// /* simple vs. simple, India vs. UK */
// sc rf_all_india_simple_cts rf_all_uk_nhs_simple_cts, ///
//     name(rf_all_simple) yscale(log) legend(lab(1 "India") lab(2 "UK"))

/*****************************/
/* compare density of deaths */
/*****************************/
/* rename the models to make life easier */
ren *india_full_cts* *india_full*
ren *uk_nhs_matched_full_cts* *uk_full*
ren *india_simple_cts* *india_simple*
ren *uk_nhs_simple_cts* *uk_simple*
global modellist india_full uk_full india_simple uk_simple

/* Calculate the distribution of deaths in the model */
global mortrate 1
foreach model in full simple {
  foreach country in uk india {
    gen `country'_`model'_deaths = $mortrate * `country'_pop * rf_all_`country'_`model'
  }
}

global sim_n 1

/* rescale so there are 100,000 deaths in each model */
foreach model in $modellist {
  local v `model'_deaths
  sum `v'
  replace `v' = `v' / (`r(mean)' * `r(N)') * $sim_n
}

// /* plot uk vs. india death density, simple */
// sort age
// label var age "Age"
// twoway ///
//     (line uk_simple_deaths    age, lcolor(orange) lwidth(medium) lpattern(.-))     ///
//     (line india_simple_deaths age, lcolor(gs8) lpattern(-) lwidth(medthick))       ///
//     , ytitle("Distribution of Deaths" "Normalized population: 100,000") xtitle(Age)  ///
//     legend(lab(1 "United Kingdom (simple)") ///
//     lab(2 "India (simple)"))
// graphout mort_density_simple

/* smooth the deaths series */
sort age
gen x = 1
xtset x age
foreach v in uk_full_deaths india_full_deaths {
  replace `v' = (L2.`v' + L1.`v' + `v' + F.`v' + F2.`v') / 5 if !mi(L2.`v') & !mi(F2.`v')
  replace `v' = (L1.`v' + `v' + F.`v' + F2.`v') / 4 if mi(L2.`v') & !mi(F2.`v') & !mi(L1.`v')
  replace `v' = (L2.`v' + L1.`v' + `v' + F.`v') / 4 if mi(F2.`v') & !mi(L2.`v') & !mi(F1.`v')
}

/* add a line representing maharashtra's data in the May 8 report */
capdrop mh_deaths
gen mh_deaths = 0
/* total deaths: 356. Total years: 89-18+1=72 */
/* 18-29: 12 deaths  */
replace mh_deaths = $sim_n * 12/356 / (29 - 18 + 1) if inrange(age, 18, 29)
/* 30-39: 27 */
replace mh_deaths = $sim_n * 27/356 / 10 if inrange(age, 30, 39)
/* ... */
replace mh_deaths = $sim_n * 63/356  / 10 if inrange(age, 40, 49)
replace mh_deaths = $sim_n * 108/356 / 10 if inrange(age, 50, 59)
replace mh_deaths = $sim_n * 101/356 / 10 if inrange(age, 60, 69)
replace mh_deaths = $sim_n * 34/356  / 10 if inrange(age, 70, 79)
replace mh_deaths = $sim_n * 11/356  / 10 if inrange(age, 80, 89)

/* same graph, full model */
twoway ///
    (line uk_full_deaths    age, lcolor(gs8) lwidth(medium) lpattern(-))     ///
    (line india_full_deaths age, lcolor(black) lpattern(solid) lwidth(medthick))       ///
    (line mh_deaths         age, lcolor(orange) lwidth(medium) lpattern(.-))     ///
    , ytitle("Density Function of Deaths (%)") xtitle(Age)  ///
    legend(lab(1 "United Kingdom (full)") ///
    lab(2 "India (full)") lab(3 "Maharasthra (May 8)") ///
    ring(0) pos(11) cols(1) region(lcolor(black))) ///
    xscale(range(18 90)) xlabel(20 40 60 80)
graphout mort_density_full

// /* all 4 lines */
// twoway ///
//     (line uk_simple_deaths    age, lcolor(orange) lwidth(medium) lpattern(-))     ///
//     (line india_simple_deaths age, lcolor(gs8) lpattern(-) lwidth(medthick))       ///
//     (line uk_full_deaths      age, lcolor(orange) lwidth(medium) lpattern(solid))     ///
//     (line india_full_deaths   age, lcolor(gs8) lpattern(solid) lwidth(medthick))       ///
//     , ytitle("Distribution of Deaths" "Normalized population: 100,000") xtitle(Age)  ///
//     legend(lab(1 "United Kingdom (simple)") lab(2 "India (simple)") ///
//     lab(3 "United Kingdom (full)") lab(4 "India (full)"))
// graphout mort_density_all

/******************************************/
/* calculate share of deaths under age 60 */
/******************************************/
foreach model in $modellist {
  qui sum `model'_deaths if age < 60
  di %25s "`model': " %5.1f (`r(N)' * `r(mean)' / 1000)
}



/**********************************************************/
/* compare UK health conditions and risk factors to India */
/**********************************************************/
use $tmp/rf_india_full_cts, clear
ren prev* iprev*
ren rf* irf*
merge 1:1 age using $tmp/rf_uk_nhs_matched_full_cts, nogen
ren prev* uprev*
ren rf* urf*

/* calculate relative difference in prevalence and risk factor for each condition */
foreach v in male $hr_biomarker_vars $hr_gbd_vars $hr_os_only_vars {
  gen rfdiff_`v' = irf_`v' / urf_`v'
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
foreach v in male $hr_biomarker_vars $hr_gbd_vars health {
  qui sum urf_`v' [aw=uk_pop]
  local umean = `r(mean)'
  qui sum irf_`v' [aw=india_pop]
  local imean = `r(mean)'
  local perc (`imean'/`umean' - 1) * 100
  if `perc' > 0 local sign "+"
  else local sign
  di %45s "`v' : `sign'" %2.1f (`perc') "%"
}
