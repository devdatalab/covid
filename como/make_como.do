
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

/* create a clean set of files with relative risks */
do $ccode/como/b/prep_hrs.do

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

/* create HR, prevalence, population files all with identical structures */
do $ccode/como/b/prep_outcomes_generic.do

/* create prevalence standard errors for bootstraps */
do $ccode/como/b/prep_prev_standard_errors.do

/************/
/* analysis */
/************/

/* calculate summary statistics and prevalences */
// do $ccode/como/a/sumstats.do

/* compare England / India prevalence of comorbid conditions */
do $ccode/como/a/compare_uk_india_prevalence.do

/* run analysis for paper */
do $ccode/como/a/calc_outcomes_generic.do

/**********************/
/* figures and tables */
/**********************/

/* create tables for main text and appendix*/
do $ccode/como/a/make_paper_tables.do

/* create figures */
do $ccode/como/a/make_paper_figures.do


/************/
/* appendix */
/************/

/* app figure: hr interpolations */
do $ccode/como/a/app_age_hr_interpolation.do

/* run sensitivity tests for sampling error in HRs */
do $ccode/como/a/calc_hr_sensitivity.do

/* run sensitivity tests for sampling error in prevalences */
do $ccode/como/a/calc_prev_sensitivity.do


/* app table: NHS/GBD prevalences vs OpenSAFELY */
// do $ccode/como/a/app_table_nhs_vs_os.do

/* app table: risk factor prevalences by age bin for all places */
// do $ccode/como/a/app_table_age_bin_prev.do

