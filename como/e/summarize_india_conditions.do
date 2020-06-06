/**************************************************************/
/* explore different risk factors across the age distribution */
/**************************************************************/
use $tmp/combined, clear
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


/* run some HR comparisons [obsolete i think] */
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
