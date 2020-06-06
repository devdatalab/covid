/******************************************************/
/* AGGREGATE OVER AGES TO GET AN EXPECTED DEATH COUNT */
/******************************************************/
use $tmp/combined_risks_india_uk, replace

/* keep age and risk factors only */
keep age arisk_simple arisk_full arisk_gbd uk_risk

/* import population in each bin */
merge 1:1 age using $tmp/india_pop, keep(master match) nogen
merge 1:1 age using $tmp/uk_pop, keep(master match) nogen

/* drop ages missing in some datasets */
keep if inrange(age, 18, 84)

/* rescale all risks to be relative to UK people aged 65 */
/* this is my best guess at the point where the mortality risk is
   around 0.6%, which people think is the current IFR */
sum uk_risk if age == 65
local ref `r(mean)'
foreach v of varlist *risk* {
  replace `v' = `v' / `ref'
}

/* assume baseline mortality of 0.6% for the reference group  */
global mortrate 0.6

/* rescale UK population to same as India so we can be scale invariant.
   We care about rates, not total number of deaths. */
sum india_pop, meanonly
local ipop `r(mean)'
sum uk_pop, meanonly
local upop `r(mean)'
replace uk_pop = uk_pop * `ipop' / `upop'

/* predict death count in each age bin under each assumption */
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
    (line india_deaths_full   age, lwidth(medthick))      ///
    (line india_deaths_gbd    age, lwidth(medthick))      ///
, title("Predicted deaths given UK medical system, infection rate") ytitle("Predicted Deaths")
graphout pred_mort_model

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
