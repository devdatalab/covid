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

/*****************************************************************/
/* explore state-by-state correlation in hazard factors in india */
/*****************************************************************/
use $tmp/tmp_hr_data, clear

collapse (mean) hr_age_cts_full hr_full_*, by(pc11_state_id pc11_district_id)

/* combine age hazards */
gen hr_age_discrete = hr_full_age18_40 * hr_full_age40_50 * hr_full_age50_60 * hr_full_age60_70 * hr_full_age70_80 * hr_full_age80_
drop hr_full_age18_40 hr_full_age40_50 hr_full_age50_60 hr_full_age60_70 hr_full_age70_80 hr_full_age80_

/* drop the reference groups */
drop hr_full_female hr_full_bmi_not_obese hr_full_bp_not_high 

/* see which hazards are correlated with age and which go in the other direction */
rename hr_full_* hrf_*

sum hrf*

group pc11_state_id 
foreach v of varlist hrf_* {
  quireg `v' hr_age_discrete, title(`v') cluster(sgroup)
}
foreach v of varlist hrf_* {
  quireg `v' hr_age_cts_full, title(`v') cluster(sgroup)
}


/**********************************/
/* explore risk factors over time */
/**********************************/

/* collapse to age-specific data for plotting */
use $tmp/tmp_hr_data, clear

/* create some other risk factors to compare the graph */
gen hr_full_age_discrete = hr_full_age18_40 * hr_full_age40_50 * hr_full_age50_60 * hr_full_age60_70 * hr_full_age70_80 * hr_full_age80_

gen ln_d = ln(hr_full_age_discrete)
gen ln_c = ln(hr_full_age_cts)

collapse (mean) ln_c ln_d hr_full_age_discrete hr_full_age_cts, by(age)
sort age
twoway ///
    (line ln_c age) ///
    (line ln_d age)
graphout collapse_log

twoway ///
    (line hr_full_age_discrete age) ///
    (line hr_full_age_cts age), yscale(log)
graphout collapse_level


/* note: collapsing odds ratios here-- i'm still a bit unclear on what is correct. */
collapse (mean) risk_factor_* [aw=wt], by(age)

keep if age < 85
sort age
save $tmp/foo, replace

/* 1. compare continuous age distributions to discrete to confirm they are ok */
twoway (line risk_factor_simple_cts age) (line risk_factor_simple age), yscale(log) ylabel(0.1 0.5 1 2 5 10 50)
graphout simple_comp

twoway (line risk_factor_full_cts age) (line risk_factor_full age), yscale(log) ylabel(0.1 0.5 1 2 5 10 50) 
graphout full_comp

/* 2. compare fully adjusted, age-sex, comorbid conditions only  */
twoway (line risk_factor_full_cts age, lwidth(medthick)) (line risk_factor_simple_cts age, lwidth(medthick)) , yscale(log) ylabel(0.1 0.5 1 2 5 10 50)
graphout risk_factors

/* 3. compare the discrete graphs */
twoway (line risk_factor_full age, lwidth(medthick)) (line risk_factor_simple age, lwidth(medthick)) , yscale(log) ylabel(0.1 0.5 1 2 5 10 50)
graphout risk_factors_discrete

twoway (line risk_factor_age_weird age, lwidth(medthick)) (line risk_factor_full_cts age, lwidth(medthick)) (line risk_factor_full age, lwidth(medthick)) , yscale(log) ylabel(0.1 0.5 1 2 5 10 50)
graphout risk_factors_full_agesex_part_only

/* review some results */
sum risk_factor* if age == 20, d
sum risk_factor* if age == 65, d
sum risk_factor* if age == 20 & male == 1, d
sum risk_factor* if age == 65 & male == 1, d
sum risk_factor* if age == 65 & male == 0, d


/*****************************************/
/* compare discrete and cts risk factors */
/*****************************************/
use $tmp/combined, clear

/* compare discrete vs. continuous risk factors */
keep hr_age_*_age* hr_full*age* age

/* create combined discrete age factors */
gen hr_age_discrete_full = hr_full_age18_40 * hr_full_age40_50 * hr_full_age50_60 * hr_full_age60_70 * hr_full_age70_80 * hr_full_age80_
gen hr_age_discrete_age_sex = hr_age_sex_age18_40 * hr_age_sex_age40_50 * hr_age_sex_age50_60 * hr_age_sex_age60_70 * hr_age_sex_age70_80 * hr_age_sex_age80_

gen ln_d_full = ln(hr_age_discrete_full)
gen ln_d_age_sex = ln(hr_age_discrete_age_sex)
gen ln_c_full = ln(hr_full_age_cts)
gen ln_c_age_sex = ln(hr_age_sex_age_cts)

binscatter ln_d_full ln_c_full age, linetype(none) xq(age)
graphout hr_comp_full

binscatter ln_d_age_sex ln_c_age_sex age, linetype(none) xq(age) legend(off)
graphout hr_comp_age_sex
