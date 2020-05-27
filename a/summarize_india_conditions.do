/********************************/
/* create a fast sample dataset */
/********************************/
use $tmp/combined, clear
keep if uniform() < .1
save $tmp/combined_short, replace

/*****************************************/
/* transform NHS incidence data into dta */
/*****************************************/
import delimited using $covidpub/covid/csv/uk_nhs_incidence.csv, clear varnames(1)
replace prevalence = prevalence / 100

/* reshape it to wide */
gen x = 1
ren prevalence uk_prev_
reshape wide uk_prev_, i(x) j(condition) string
drop x

/* save NHS prevalence */
gen v1 = 0
save $tmp/uk_nhs_incidence, replace

/*******************************************************************/
/* graph relative mortality risk under different adjustment models */
/*******************************************************************/
use $tmp/tmp_hr_data, clear

sum risk_ratio [aw=wt] if hr == "hr_age_sex", d
sum risk_ratio [aw=wt] if hr == "hr_fully_adj", d

/* put risk ratio on log scale */
gen ln_risk_ratio = ln(risk_ratio)

/* collapse to age*model for result comparison */
winsorize age 18 95, replace
collapse (mean) ln_risk_ratio [aw=wt], by(hr age)

/* line graph of risk profiles by age using the two kinds of adjustments */
sort age
twoway ///
    (line ln_risk_ratio age if hr == "hr_age_sex",  ylabel(-6(2)6) lwidth(medthick)) ///
    (line ln_risk_ratio age if hr == "hr_fully_adj", ylabel(-6(2)6) lwidth(medthick)) ///
    , legend(lab(1 "Age-Sex Adjusted") lab(2 "Fully adjusted")) 

graphout death_risk

/* add UK data */
append using $tmp/uk_sim
sort age

save $tmp/uk_india_combined, replace

twoway ///
    (line ln_risk_ratio age if hr == "hr_fully_adj", ylabel(-6(2)6) lwidth(medthick)) ///
    (line ln_uk_risk    age                        , ylabel(-6(2)6) lwidth(medthick)) ///
    , ytitle("Log relative risk") legend(lab(1 "India Fully adjusted") lab(2 "UK aggregates")) 

graphout death_risk_india_uk


/***************************************************************************************************/
/* How much do comorbidities matter at all vs. age? Compare risk ratios if we ignore comorbidities */
/***************************************************************************************************/
use $tmp/combined_short, clear

/* set risk ratios */
gen risk_ratio_full = 1 if hr == "hr_fully_adj"
gen risk_ratio_agesex = 1 if hr == "hr_fully_adj"
gen risk_ratio_full_hr2 = 1 if hr == "hr_age_sex"
gen risk_ratio_agesex_hr2 = 1 if hr == "hr_age_sex"

/* multiply all of each individual's risk factors, for the fully adjusted model group */
foreach condition in $comorbid_vars {
  replace risk_ratio_full     = risk_ratio_full     * `condition' if hr == "hr_fully_adj"
  replace risk_ratio_full_hr2 = risk_ratio_full_hr2 * `condition' if hr == "hr_age_sex"
}

/* repeat the process but for the age-sex adjustment only */
foreach condition in age18_40 age18_40 age50_60 age60_70 age70_80 age80_ male female {
  replace risk_ratio_agesex     = risk_ratio_agesex     * `condition' if hr == "hr_fully_adj"
  replace risk_ratio_agesex_hr2 = risk_ratio_agesex_hr2 * `condition' if hr == "hr_age_sex"
}

sum risk_ratio*

/* put risk ratio on log scale */
gen ln_rr_full = ln(risk_ratio_full)
gen ln_rr_agesex = ln(risk_ratio_agesex)
gen ln_rr_full_hr2 = ln(risk_ratio_full_hr2)
gen ln_rr_agesex_hr2 = ln(risk_ratio_agesex_hr2)

/* collapse to age*model for result comparison */
winsorize age 18 95, replace
collapse (mean) ln_rr_* [aw=wt], by(age)

/* line graph of risk profiles by age using the two kinds of adjustments */
sort age
twoway ///
    (line ln_rr_agesex age , ylabel(-6(2)6) lwidth(medthick)) ///
    (line ln_rr_full age ,  ylabel(-6(2)6) lwidth(medthick)) ///
    , legend(lab(1 "Age-Sex Adjustment only (full model)") lab(2 "Fully adjusted (full model)")) ytitle("mean ln_risk_ratio")
graphout death_risk_age_test

/* hr2 results */
twoway ///
    (line ln_rr_agesex_hr2 age , ylabel(-6(2)6) lwidth(medthick)) ///
    (line ln_rr_full_hr2   age , ylabel(-6(2)6) lwidth(medthick)) ///
    , legend(lab(1 "Age-Sex Adjustment only (age-sex model)") lab(2 "Fully Adjusted (bivariate model, never used)") ) ytitle("mean ln_risk_ratio")
graphout hr2


/*********************************************/
/* compare india conditions to UK conditions */
/*********************************************/
use $tmp/tmp_hr_data, clear

gen x = 1
collapse (mean) $comorbid_vars [pw=wt], by(x)

save $tmp/india_averages, replace

/* merge to UK */
gen v1 = 0
merge 1:1 v1 using $tmp/uk_nhs_incidence

/* list india numbers */
list age-diab

/* list uk numbers */
list uk_prev
