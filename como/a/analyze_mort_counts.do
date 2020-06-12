/******************************************************/
/* AGGREGATE OVER AGES TO GET AN EXPECTED DEATH COUNT */
/******************************************************/

/* create combined UK / India dataset */

/* get fixed and flexible UK age datasets */
use age uk_risk uk_risk_simple using $tmp/uk_sim_age_fixed, clear
ren uk_risk uk_risk_age_fixed
merge 1:1 age using $tmp/uk_sim_age_flex, keepusing(age uk_risk) nogen

merge 1:1 age using $tmp/india_models, nogen
label var uk_risk "Aggregate risk (UK, flex age)"
label var uk_risk_simple "Aggregate risk (UK, age-sex only)"
label var uk_risk_age_fixed "Aggregate risk (UK, fixed age)"

save $tmp/combined_risks_india_uk, replace
use $tmp/combined_risks_india_uk, replace

/* keep age and risk factors only */
keep age arisk_simple arisk_full arisk_gbd uk_risk uk_risk_age_fixed uk_risk_simple

/* import population in each bin */
merge 1:1 age using $tmp/india_pop, keep(master match) nogen keepusing(india_pop_smooth)
merge 1:1 age using $tmp/uk_pop, keep(master match) nogen keepusing(uk_pop_smooth)
ren *_smooth *

/* drop ages missing in some datasets */
keep if inrange(age, 18, 84)

/* rescale all risks to population-weighted average UK risk */
sum uk_risk [aw=uk_pop]
local ref `r(mean)'
foreach v of varlist *risk* {
  replace `v' = `v' / `ref'
}

/* rescale UK population to same as India so we can be scale invariant.
   We care about rates, not total number of deaths. */
// sum india_pop, meanonly
// local ipop `r(mean)'
// sum uk_pop, meanonly
// local upop `r(mean)'
// replace uk_pop = uk_pop * `ipop' / `upop'

/* TEST: rescale all populations to size 100000, so the graph shows the density of expected deaths */
qui sum india_pop
replace india_pop = india_pop / (`r(mean)' * `r(N)') * 100000
qui sum uk_pop
replace uk_pop = uk_pop / (`r(mean)' * `r(N)') * 100000

/* predict death count in each age bin under each assumption */
/* population is measure 1. We want the density function of deaths, so set the UK mortality rate to 100%. */
global mortrate 1
gen uk_deaths = uk_risk * $mortrate * uk_pop
gen uk_deaths_age_fixed = uk_risk_age_fixed * $mortrate * uk_pop
foreach model in full simple gbd {
  gen india_deaths_`model' = arisk_`model' * $mortrate * india_pop
}
save $tmp/test, replace

/* plot the number of deaths from each model by age */
label var uk_deaths "UK age distribution and comorbidities"
label var uk_deaths_age_fixed "UK FIXED age distribution and comorbidities"
label var india_deaths_simple "India, age distribution only"
label var india_deaths_full "India, age distribution + biomarkers"
label var india_deaths_gbd "India, age distribution + biomarkers + GBD"

sort age
twoway ///
    (line uk_deaths           age, lwidth(medthick))                ///
    (line uk_deaths_age_fixed age, lwidth(medthick))                ///
    , yscale(log)
graphout fixed_flex

sort age
label var age "Age"
twoway ///
    (line uk_deaths           age, lwidth(medthick))                ///
    (line india_deaths_simple age, lwidth(medthick))      ///
    (line india_deaths_gbd    age, lwidth(medthick))      ///
, title("Modeled distribution of deaths, given UK medical system / infection rate") ytitle("Predicted Deaths" "Normalized population size 100,000")
graphout pred_mort_model

// /* log model */
// twoway ///
//     (line uk_deaths           age, lwidth(medthick))                ///
//     (line india_deaths_simple age, lwidth(medthick))      ///
//     (line india_deaths_gbd    age, lwidth(medthick))      ///
// , title("Distribution of expected deaths, given UK medical system and infection distribution") ytitle("Share of Deaths at each Age") yscale(log)
// graphout pred_mort_model_log

/* alternate graph --- number of india deaths relative to UK deaths */
gen india_deaths_simple_rel = india_deaths_simple / uk_deaths
gen india_deaths_gbd_rel = india_deaths_gbd / uk_deaths
sort age
twoway ///
    (line india_deaths_simple_rel age, lwidth(medthick))      ///
    (line india_deaths_gbd_rel    age, lwidth(medthick))      ///
    , title("Distribution of Deaths: India relative to U.K.") ytitle("Proportional Change in Number of Deaths" "between UK and India") yline(1, lcolor(gs8) lpattern(-)) ///
    legend(lab(1 "Age-Sex Adjustment Only") lab(2 "Age, Sex, and Comorbidity Adjustment")) ///
    text(1.05 65 "1 = Density of deaths at this age is the same in U.K. and India", size(vsmall) color(gs8))    
graphout deaths_relative_to_uk



drop *rel

/* convert to YLLs */
gen uk_yll = uk_deaths * (86 - age)
foreach model in simple full gbd {
  gen india_`model'_yll = india_deaths_`model' * (86 - age)
}

/* graph YLLs */
sort age
twoway ///
    (line uk_yll           age, lwidth(medthick))                ///
    (line india_gbd_yll    age, color("249 188 13") lwidth(medthick))      ///
, title("Predicted years life lost given UK medical system, infection rate") ytitle("Predicted YLLs")
graphout pred_yll_model

/* collapse across age bins to get total predicted deaths and death rate */
preserve
gen x = 1
collapse (sum) india_pop uk_pop *deaths* *yll*, by(x)
drop x

/* calculate death rates */
gen uk_mortrate = uk_deaths / uk_pop
foreach model in full simple gbd {
  gen india_mortrate_`model' = india_deaths_`model' / india_pop
}
list *mortrate*

/* rescale ylls to millions */
foreach v of varlist *yll* {
  replace `v' = `v' / 1000000
}

format *yll* %10.0f
list *yll*
restore

/* count the number of deaths over 60 and under 60 in both countries */
gen young = age < 60
collapse (sum) india_pop uk_pop *deaths*, by(young)

foreach v of varlist *death* *pop {
  replace `v' = `v' / 1000000
}
list young uk_deaths uk_deaths_age_fixed india_deaths_gbd india_deaths_simple

/* calculate share of deaths under 60 in the UK */
sort young
gen uk_young_mort_share = uk_deaths[2] / (uk_deaths[1] + uk_deaths[2])
gen india_gbd_young_mort_share = india_deaths_gbd[2] / (india_deaths_gbd[1] + india_deaths_gbd[2])
gen india_simple_young_mort_share = india_deaths_simple[2] / (india_deaths_simple[1] + india_deaths_simple[2])
gen india_full_young_mort_share = india_deaths_full[2] / (india_deaths_full[1] + india_deaths_full[2])

d *share, f
sum *share


/* how about a density function of deaths under the different models */
use $tmp/test, clear

foreach v in india_deaths_simple india_deaths_gbd uk_deaths {
  sum `v'
  replace `v' = `v' / (`r(mean)' * `r(N)') * 100000
}

sort age
label var age "Age"
twoway ///
    (line uk_deaths           age, lwidth(medthick))                ///
    (line india_deaths_simple age, lwidth(medthick))      ///
    (line india_deaths_gbd    age, lwidth(medthick))      ///
, title("Modeled distribution of deaths, given UK medical system / infection rate") ytitle("Predicted Deaths" "Normalized population size 100,000")
graphout mort_density

line india_pop age
graphout x
