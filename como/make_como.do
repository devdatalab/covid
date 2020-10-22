
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
do $ccode/como/b/prep_india_comorbidities.do

/* create an age-level dataset with England condition prevalence */
do $ccode/como/b/prep_england_prevalence.do

/* create a clean set of files with relative risks */
do $ccode/como/b/prep_hrs.do

/* prep NY odds ratios of death */
do $ccode/como/b/prep_ny_mortality.do

/* prep india and UK sex ratios and populations */
do $ccode/como/b/prep_pop_sex.do

/* create age-level datasets for HR, prevalence, population, all with identical structures */
/* THIS CREATES THE MAIN ANALYSIS FILE */
do $ccode/como/b/prep_age_level_data.do

/* create prevalence standard errors for bootstraps */
do $ccode/como/b/prep_standard_errors.do

/* calculate population relative risks and death distributions for england / india */
do $ccode/como/a/calc_prrs.do

/************/
/* analysis */
/************/

/* prepare data for England / India prevalence comparison */
do $ccode/como/a/prep_eng_india_prev_compare.do

/* calculate summary statistics and prevalences */
// do $ccode/como/a/sumstats.do

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

/* sensitivity to joint conditions */
do $ccode/como/a/app_joint_condition.do
