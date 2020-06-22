
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

/************/
/* analysis */
/************/

/* calculate summary statistics and prevalences */
// do $ccode/como/a/sumstats.do

/* Figure 1: plot UK / India prevalence of comorbid conditions */
do $ccode/como/a/compare_uk_india_prevalence.do

/* run analysis for paper */
do $ccode/como/a/calc_outcomes_generic.do

/* Figure 3: coefficient plot */
shell python $ccode/como/a/make_coef_plot.py

/* create tables */
do $ccode/como/b/make_paper_tables.do


/************/
/* appendix */
/************/

/* app figure: hr interpolations */
do $ccode/como/a/app_age_hr_interpolation.do

/* app table: NHS/GBD prevalences vs OpenSAFELY */
do $ccode/como/a/app_table_nhs_vs_os.do

/* app table: risk factor prevalences by age bin for all places */
do $ccode/como/a/app_table_age_bin_prev.do

