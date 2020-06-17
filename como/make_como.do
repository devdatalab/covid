
/*********************/
/* data construction */
/*********************/

/* get continuous fit to UK age hazard ratios */
//shell matlab $ccode/como/b/fit_cts_uk_age_hr.m

/* combine DLHS and AHS */
do $ccode/como/b/prep_health_data.do

/* prepare global burden of disease data */
do $ccode/como/b/prep_gbd.do

/* calculate risk factors */
do $ccode/como/b/gen_comorbidity_predictions.do

/* create an age-level dataset with UK condition prevalence */
do $ccode/como/b/prep_uk_prevalence.do

/* repeat with external india aggregate data (e.g. GBD) */
// do $ccode/como/b/prep_india_sim_prevalence.do

/* prep NY odds ratios of death */
do $ccode/como/b/prep_ny_mortality.do

/* clean state-level GBD for India */
// do $ccode/como/b/clean_gbd_india.do

/* create state-level biomarker variables */
// do $ccode/como/b/collapse_biomarkers_to_state.do

/* prep india and UK sex ratios and populations */
do $ccode/como/b/prep_pop_sex.do

/************/
/* analysis */
/************/

/* calculate summary statistics and prevalences */
// do $ccode/como/a/sumstats.do

/* Figure 1: plot UK / India prevalence of comorbid conditions */
do $ccode/como/a/compare_uk_india_prevalence.do

/* create HR, prevalence, population files all with identical structures */
do $ccode/como/a/prep_outcomes_generic.do

/* run analysis for paper */
do $ccode/como/a/calc_outcomes_generic.do

// /* plot India risk factors under various assumptions*/
// do $ccode/como/a/analyze_age_mort_risk.do
// 
// /* run model in levels with population weighting to predict E(deaths) */
// do $ccode/como/a/analyze_mort_counts.do
// 
// /* examine risk factor distribution across states */
// 
// 
// /* plot relationship between risk and poverty */
// do $ccode/como/a/examine_risk_factors_poverty.do
// 

/************/
/* appendix */
/************/

/* risk factor prevalences by age bin for all places */
do $ccode/como/a/app_table_age_bin_prev.do

