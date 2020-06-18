/***********/
/* TABLE 1 */
/***********/

/* create csv file */
cap !rm -f $ddl/covid/como/a/covid_como_sumstats.csv
do $ddl/covid/como/a/calc_outcomes_generic.do

/* open the data */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear
drop if age > 100

/* get all DLHS India values */
foreach var in age18_40 age40_50 age50_60 age60_70 age70_80 age80_ male diabetes_uncontr diabetes_contr hypertension_both obese_3 obese_1_2 {
  qui sum `var' [aw=wt]
  local mu = `r(mean)'*100

  /* add the count and mean to the csv that will feed the latex table values */
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(india_`var'_mu) value("`mu'") format(%2.1f)
}

/* do the UK demographics */
import delimited $covidpub/demography/csv/uk_gender_age.csv, clear 
keep if age >= 18
save $tmp/uk_age_18_plus, replace

/* get total population total */
qui sum total
local tot_pop = `r(sum)'

/* get each age bracket */
qui sum total if age >= 18 & age < 40
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_18_40) value("`pop_frac'") format(%2.1f)

qui sum total if age >= 40 & age < 50
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_40_50) value("`pop_frac'") format(%2.1f)

qui sum total if age >= 50 & age < 60
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_50_60) value("`pop_frac'") format(%2.1f)

qui sum total if age >= 60 & age < 70
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_60_70) value("`pop_frac'") format(%2.1f)

qui sum total if age >= 70 & age < 80
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_70_80) value("`pop_frac'") format(%2.1f)

qui sum total if age >= 80
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_80) value("`pop_frac'") format(%2.1f)

/* get female */
qui sum male
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_male) value("`pop_frac'") format(%2.1f)

/* Do the GBD comorbidities */
foreach geo in india uk {

  use $health/gbd/gbd_nhs_conditions_`geo', clear

  /* keep only the age standardized data  */
  keep if age == -90

  foreach var in gbd_chronic_heart_dz gbd_chronic_resp_dz gbd_kidney_dz gbd_liver_dz gbd_asthma_ocs gbd_cancer_non_haem_1 gbd_haem_malig_1  gbd_autoimmune_dz gbd_immuno_other_dz gbd_stroke_dementia gbd_neuro_other {
    qui sum `var'_granular
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(`geo'_`var'_mu) value("`mu'") format(%2.1f)
  }
}


/* do the UK prevalence */
use $tmp/uk_prevalences, clear
drop if age > 90
merge 1:1 age using $tmp/uk_age_18_plus, nogen

foreach var in uk_prev_diabetes_contr uk_prev_diabetes_uncontr uk_prev_hypertension_both uk_prev_obese_3 uk_prev_obese_1_2 {
  qui sum `var' [aw=total]
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(`var') value("`mu'") format(%2.1f)
}

/* create the prevalence table 1 */
table_from_tpl, t($ddl/covid/como/a/covid_como_sumstats_tpl.tex) r($ddl/covid/como/a/covid_como_sumstats.csv) o($tmp/covid_como_sumstats.tex)

/* create the risk table 2 */
table_from_tpl, t($ddl/covid/como/a/covid_como_sumhr_tpl.tex) r($ddl/covid/como/a/covid_como_sumstats.csv) o($tmp/covid_como_sumhr.tex)

/* isolate risk vars for plot */
import delimited $ddl/covid/como/a/covid_como_sumstats.csv, clear
keep if strpos(v1, "ratio") != 0
drop if v1 == "health_ratio"
ren v1 variable
ren v2 coef
save $tmp/coefs_to_plot, replace
