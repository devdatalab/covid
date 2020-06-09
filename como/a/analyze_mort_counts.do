/******************************************************/
/* AGGREGATE OVER AGES TO GET AN EXPECTED DEATH COUNT */
/******************************************************/

/* create combined UK / India dataset */
use $tmp/uk_sim, clear
gen round_age = floor(age)
collapse (mean) uk_risk, by(round_age)
ren round_age age

merge 1:1 age using $tmp/india_models
label var uk_risk "Aggregate risk (UK)"
save $tmp/combined_risks_india_uk, replace
use $tmp/combined_risks_india_uk, replace

/* keep age and risk factors only */
keep age arisk_simple arisk_full arisk_gbd uk_risk

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
sum india_pop, meanonly
local ipop `r(mean)'
sum uk_pop, meanonly
local upop `r(mean)'
replace uk_pop = uk_pop * `ipop' / `upop'

/* predict death count in each age bin under each assumption */
/* assume baseline mortality of 1% for the reference group -- the UK population */
global mortrate .01
gen uk_deaths = uk_risk * $mortrate * uk_pop
foreach model in full simple gbd {
  gen india_deaths_`model' = arisk_`model' * $mortrate * india_pop
}

/* plot the number of deaths from each model by age */
label var uk_deaths "UK age distribution and comorbidities"
label var india_deaths_simple "India, age distribution only"
label var india_deaths_full "India, age distribution + biomarkers"
label var india_deaths_gbd "India, age distribution + biomarkers + GBD"


sort age
twoway ///
    (line uk_deaths           age, lwidth(medthick))                ///
    (line india_deaths_simple age, lwidth(medthick))      ///
    (line india_deaths_gbd    age, lwidth(medthick))      ///
, title("Predicted deaths at each age given UK medical system, infection rate") ytitle("Predicted Deaths")
graphout pred_mort_model

/* log model */
twoway ///
    (line uk_deaths           age, lwidth(medthick))                ///
    (line india_deaths_simple age, lwidth(medthick))      ///
    (line india_deaths_gbd    age, lwidth(medthick))      ///
, title("Predicted deaths given UK medical system, infection rate") ytitle("Predicted Deaths") yscale(log)
graphout pred_mort_model_log

/* alternate graph --- number of india deaths relative to UK deaths */
gen india_deaths_simple_rel = india_deaths_simple / uk_deaths
gen india_deaths_gbd_rel = india_deaths_gbd / uk_deaths
sort age
twoway ///
    (line india_deaths_simple_rel age, lwidth(medthick))      ///
    (line india_deaths_gbd_rel    age, lwidth(medthick))      ///
, title("Predicted number of deaths at each age compared with UK, given UK medical system, infection rate") ytitle("Predicted Deaths")
graphout deaths_relative_to_uk

/* alternate graph: mortality at each age */
global l lwidth(medthick)
twoway (line uk_risk age, $l) (line arisk_gbd age, $l) (line arisk_simple age, $l), yscale(log) 
graphout mort_risk_age

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
list

/* calculate share of deaths under 60 in the UK */
sort young
gen uk_young_mort_share = uk_deaths[2] / (uk_deaths[1] + uk_deaths[2])
gen india_gbd_young_mort_share = india_deaths_gbd[2] / (india_deaths_gbd[1] + india_deaths_gbd[2])
gen india_simple_young_mort_share = india_deaths_simple[2] / (india_deaths_simple[1] + india_deaths_simple[2])
gen india_full_young_mort_share = india_deaths_full[2] / (india_deaths_full[1] + india_deaths_full[2])


sum *share
