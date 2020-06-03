/* open thte dataset */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities_full, clear

/* initiate file for biomarker vs. self-reported definitions */
!rm -f $tmp/biomarkers_compare_diabetes.csv
!rm -f $tmp/biomarkers_compare_hypertension.csv

/*************************/
/* create samples labels */
/*************************/

/* 1. the cab sample is all data that reports biomarkers */
gen cab_sample = 1 if !mi(bp_high) & !mi(diabetes) & !mi(bmi)

/* 2. the cab + hh samples is all data that reports BOTH biomarkers and HH module (self-reported data) */
gen cab_hh_sample = 1 if !mi(bp_high) & !mi(diabetes) & !mi(bmi) & sample != 1

/* 3. the hh only samples */
gen hh_sample = 1 if !mi(diagnosed_for)


/************/
/* Diabetes */
/************/

/* save the cab-only sample */
count if !mi(cab_sample)
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("cab_N") value(`r(N)') format(%9.0f)

/* save the cab-hh sample */
count if !mi(cab_hh_sample)
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("cab_hh_N") value(`r(N)') format(%9.0f)

/* save the hh-only sample */
count if !mi(hh_sample)
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("hh_N") value(`r(N)') format(%9.0f)

/* save the full sample */
count
insert_into_file using $tmp/biomarkers_compare_diabetes.csv,key("full_N") value(`r(N)') format(%12.0f)

/* 1. Biomarkers only in FULL cab sample */
tabstat diabetes [aw=wt] if !mi(cab_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of diabetes as measured by biomarkers in FULL cab sample */
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("biomarker_cab") value(`a') format(%5.4f)


/* 2. Biomarkers only in cab + hh sample */
tabstat diabetes [aw=wt] if !mi(cab_hh_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of diabetes as measured by biomarkers in cab + hh matched sample */
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("biomarker_cab_hh") value(`a') format(%5.4f)


/* 3. Self-reported diabetes in hh sample */
tabstat diabetes_selfreport [aw=wt] if !mi(hh_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of self-reported diabetes in the hh sample */
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("selfreported_hh") value(`a') format(%5.4f)


/* 4. Biomarkers + self-reported in full sample */
tabstat diabetes_combined [aw=wt], save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of biomarker + self-reported diabetes in full sample */
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("biomarker_selfreported_full") value(`a') format(%5.4f)


/* 5. Biomarkers + self-reported in matched cab + hh sample */
tabstat diabetes_combined [aw=wt] if !mi(cab_hh_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of biomarker + self-reported diabetes in cab + hh sample */
insert_into_file using $tmp/biomarkers_compare_diabetes.csv, key("biomarker_selfreported_cab_hh") value(`a') format(%5.4f)


/****************/
/* Hypertension */
/****************/
/* save the cab-only sample */
count if !mi(cab_sample)
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("cab_N") value(`r(N)') format(%9.0f)

/* save the cab-hh sample */
count if !mi(cab_hh_sample)
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("cab_hh_N") value(`r(N)') format(%9.0f)

/* save the hh-only sample */
count if !mi(hh_sample)
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("hh_N") value(`r(N)') format(%12.0f)

/* save the full sample */
count
insert_into_file using $tmp/biomarkers_compare_hypertension.csv,key("full_N") value(`r(N)') format(%9.0f)

/* 1. Biomarkers only in FULL cab sample */
tabstat bp_high_stage2 [aw=wt] if !mi(cab_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of compare as measured by biomarkers in FULL cab sample */
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("biomarker_cab") value(`a') format(%5.4f)

/* 2. Biomarkers only in cab + hh sample */
tabstat bp_high_stage2 [aw=wt] if !mi(cab_hh_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of hypertension as measured by biomarkers in cab + hh matched sample */
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("biomarker_cab_hh") value(`a') format(%5.4f)


/* 3. Self-reported hypertension in hh sample */
tabstat bp_hypertension [aw=wt] if !mi(hh_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of self-reported hypertension in the hh sample */
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("selfreported_hh") value(`a') format(%5.4f)


/* 4. Biomarkers + self-reported in full sample */
gen bp_high_temp = bp_high
replace bp_high_temp = 0 if mi(bp_high_temp)
tabstat bp_high_temp [aw=wt], save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of biomarker + self-reported hypertension in full sample */
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("biomarker_selfreported_full") value(`a') format(%5.4f)


/* 5. Biomarkers + self-reported in matched cab + hh sample */
tabstat bp_high [aw=wt] if !mi(cab_hh_sample), save
mat prev = r(StatTotal)
local a =  prev[1,1]
/* save the prevalence of biomarker + self-reported hypertension in cab + hh sample */
insert_into_file using $tmp/biomarkers_compare_hypertension.csv, key("biomarker_selfreported_cab_hh") value(`a') format(%5.4f)


/* COMBINE */

/* import hypertension values */
import delimited using $tmp/biomarkers_compare_hypertension.csv, clear
ren v2 y1
save $tmp/hypertension_table, replace

/* import diabetes values */
import delimited using $tmp/biomarkers_compare_diabetes.csv, clear 
ren v2 y2

/* merge in hypertension values */
merge 1:1 v1 using $tmp/hypertension_table, nogen

/* reshape */
reshape long y, i(v1) j(comorbidity)
reshape wide y, i(comorbidity) j(v1) string
renpfix y

/* rename id to be the proper comorbidite */
tostring comorbidity, replace
replace comorbidity = "diabetes" if comorbidity == "2"
replace comorbidity = "hypertension" if comorbidity == "1"

/* save as csv */
export delimited $tmp/hypertension_diabetes.csv, replace

