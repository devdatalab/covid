/* create csv files */
cap !rm -f $ddl/covid/como/a/covid_como_agerisks.csv
cap !rm -f $ddl/covid/como/a/covid_como_sumstats.csv

/**************/
/* PRR Values */
/**************/
use $tmp/prr_result, clear

/* save all india and uk aggregate prr values by comorbidity, and ratio */
foreach v in male $hr_biomarker_vars $hr_gbd_vars health {
  
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

  /* save everying in csv for table */
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_`v'_risk) value("`umean'") format(%3.2f)  
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(india_`v'_risk) value("`imean'") format(%3.2f)
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(`v'_ratio_sign) value("`sign'")
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(`v'_ratio) value("`perc'") format(%3.2f)  
}

/***************/
/* Prevalences */
/***************/
/* get prevalences from DLHS/AHS */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear
drop if age > 100

/* get all total population prevalences for table 1 */
foreach var in age18_40 age40_50 age50_60 age60_70 age70_80 age80_ male diabetes_uncontr diabetes_contr hypertension_both obese_3 obese_1_2{
  qui sum `var' [aw=wt]
  local mu = `r(mean)'*100

  /* add the  mean to the csv that will feed the latex table values */
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(india_`var'_mu) value("`mu'") format(%2.1f)
}

/* get age-bracketed prevalences */
use $tmp/prev_india, clear
ren prev_* *
gen hypertension_both = hypertension_uncontr + hypertension_contr
merge 1:1 age using $tmp/india_pop, keep(match) nogen

/* get all the age-specific prevalences for the appendix table */
foreach var in male diabetes_uncontr diabetes_contr hypertension_both obese_3 obese_1_2  {

  /* 18-40 */
  qui sum `var' [aw=india_pop] if age >=18 & age < 40
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(india_`var'_18_40) value("`mu'") format(%2.1f)
  
  /* 40-49 */
  qui sum `var' [aw=india_pop] if age >=40 & age < 50
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(india_`var'_40_50) value("`mu'") format(%2.1f)

  /* 50-60 */
  qui sum `var' [aw=india_pop] if age >=50 & age < 60
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(india_`var'_50_60) value("`mu'") format(%2.1f)

  /* 60-70 */
  qui sum `var' [aw=india_pop] if age >=60 & age < 70
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(india_`var'_60_70) value("`mu'") format(%2.1f)

  /* 70-80 */
  qui sum `var' [aw=india_pop] if age >= 70 & age < 80
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(india_`var'_70_80) value("`mu'") format(%2.1f)

  /* 80+ */
  qui sum `var' [aw=india_pop] if age >=80
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(india_`var'_80_) value("`mu'") format(%2.1f)

}

/* do the UK demographics */
use $tmp/uk_pop, clear
keep if age >= 18

/* get total population total */
qui sum uk_pop
local tot_pop = `r(sum)'

/* get each age bracket */
qui sum uk_pop if age >= 18 & age < 40
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_18_40) value("`pop_frac'") format(%2.1f)

qui sum uk_pop if age >= 40 & age < 50
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_40_50) value("`pop_frac'") format(%2.1f)

qui sum uk_pop if age >= 50 & age < 60
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_50_60) value("`pop_frac'") format(%2.1f)

qui sum uk_pop if age >= 60 & age < 70
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_60_70) value("`pop_frac'") format(%2.1f)

qui sum uk_pop if age >= 70 & age < 80
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_70_80) value("`pop_frac'") format(%2.1f)

qui sum uk_pop if age >= 80
local pop_frac = (`r(sum)' / `tot_pop') * 100
insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(uk_age_80) value("`pop_frac'") format(%2.1f)

/* Do the GBD comorbidities for both India and the UK */
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


/* Do age-specific prevalences of GBD variables */
foreach geo in india uk {

  use $health/gbd/gbd_nhs_conditions_`geo', clear

  /* drop age standardized and all age values */
  drop if age == -90
  drop if age ==  -99

  /* merge in population data */
  merge 1:1 age using $tmp/`geo'_pop, keep(match master)

  foreach var in gbd_chronic_heart_dz gbd_chronic_resp_dz gbd_kidney_dz gbd_liver_dz gbd_asthma_ocs gbd_cancer_non_haem_1 gbd_haem_malig_1  gbd_autoimmune_dz gbd_immuno_other_dz gbd_stroke_dementia gbd_neuro_other {

    /* 18 - 40 */
    qui sum `var' [aw=`geo'_pop] if age >= 18 & age < 40
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`geo'_`var'_18_40) value("`mu'") format(%2.1f)

    /* 40 - 50 */
    qui sum `var' [aw=`geo'_pop] if age >= 40 & age < 50
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`geo'_`var'_40_50) value("`mu'") format(%2.1f)

    /* 50 - 60 */
    qui sum `var' [aw=`geo'_pop] if age >= 50 & age < 60
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`geo'_`var'_50_60) value("`mu'") format(%2.1f)

    /* 60 - 70 */
    qui sum `var' [aw=`geo'_pop] if age >= 60 & age < 70
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`geo'_`var'_60_70) value("`mu'") format(%2.1f)

    /* 70 - 80 */
    qui sum `var' [aw=`geo'_pop] if age >= 70 & age < 80
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`geo'_`var'_70_80) value("`mu'") format(%2.1f)
  
    /* 80+ */
    qui sum `var' [aw=`geo'_pop] if age >= 80
    local mu = `r(mean)'*100
    insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`geo'_`var'_80_) value("`mu'") format(%2.1f)
  }
}


/* do the UK prevalence */
use $tmp/uk_prevalences, clear
drop if age > 99
merge 1:1 age using $tmp/uk_pop, keep(match master) nogen

foreach var in male uk_prev_diabetes_contr uk_prev_diabetes_uncontr uk_prev_chronic_resp_dz uk_prev_hypertension_both uk_prev_obese_3 uk_prev_obese_1_2 {
  qui sum `var' [aw=uk_pop]
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_sumstats.csv, key(`var') value("`mu'") format(%2.1f)
}

/* get all age-specific prevalences from uk data */
foreach var in male uk_prev_chronic_resp_dz uk_prev_diabetes_contr uk_prev_diabetes_uncontr uk_prev_hypertension_both uk_prev_obese_3 uk_prev_obese_1_2 {

  /* 18 - 40 */
  qui sum `var' [aw=uk_pop] if age >= 18 & age < 40
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`var'_18_40) value("`mu'") format(%2.1f)

  /* 40 - 50 */
  qui sum `var' [aw=uk_pop] if age >= 40 & age < 50
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`var'_40_50) value("`mu'") format(%2.1f)

  /* 50 - 60 */
  qui sum `var' [aw=uk_pop] if age >= 50 & age < 60
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`var'_50_60) value("`mu'") format(%2.1f)

  /* 60 - 70 */
  qui sum `var' [aw=uk_pop] if age >= 60 & age < 70
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`var'_60_70) value("`mu'") format(%2.1f)

  /* 70 - 80 */
  qui sum `var' [aw=uk_pop] if age >= 70 & age < 80
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`var'_70_80) value("`mu'") format(%2.1f)

  /* 80+ */
  qui sum `var' [aw=uk_pop] if age >= 80
  local mu = `r(mean)'*100
  insert_into_file using $ddl/covid/como/a/covid_como_agerisks.csv, key(`var'_80_) value("`mu'") format(%2.1f)

}

/* create the prevalence table 1 */
table_from_tpl, t($ddl/covid/como/a/covid_como_sumstats_tpl.tex) r($ddl/covid/como/a/covid_como_sumstats.csv) o($tmp/covid_como_sumstats.tex)

/* create the risk table 2 */
table_from_tpl, t($ddl/covid/como/a/covid_como_sumhr_tpl.tex) r($ddl/covid/como/a/covid_como_sumstats.csv) o($tmp/covid_como_sumhr.tex)

/* create the age-specific prevalence appendix table */
table_from_tpl, t($ddl/covid/como/a/covid_como_agerisks_tpl.tex) r($ddl/covid/como/a/covid_como_agerisks.csv) o($tmp/covid_como_agerisks.tex)

/* create the o/s vs. england  prevalence appendix table */
table_from_tpl, t($ddl/covid/como/a/covid_como_oscompare_tpl.tex) r($ddl/covid/como/a/covid_como_sumstats.csv) o($tmp/covid_como_oscompare.tex)

