/* This makefile runs all the data construction steps in the repo */

/* globals that need to be set:
$tmp -- a temporary folder
$ccode -- this root folder for this repo
$hosp -- output folder for hospital data
*/

/*****************************/
/* PART 1 -- DDL SERVER ONLY */
/*****************************/

/* match DLHS4 to PC11 districts */
do $ccode/b/merge_dlhs4_pc11_district

/* collapse raw DLHS4 data to district level */
do $ccode/b/generate_dlhs4_district

/* prepare short village/town directory and PCA to save in public repo */
do $ccode/b/prep_hosp_pca_vd

/* prepare EC microdata on hospitals */
do $ccode/b/prep_ec_hosp_microdata


/****************************************/
/* PART 2 -- RUNS FROM DATA IN GIT REPO */
/****************************************/

/* download latest district-level case data */
// need to fix conda setup to make this universal
// do $ccode/b/get_case_data

/* prepare PC11 hospital/clinic data */
do $ccode/b/prep_pc_hosp.do

/* prepare economic census (2013) hospital data */
do $ccode/b/prep_ec_hosp.do

/* create predicted mortality based on age distribution */
do $ccode/b/gen_district_age_bins.do

/* prepare SECC district-level poverty data [unfinished] */
// do $ccode/b/prep_secc.do

/* subdistrict-level urbanization */
// gen_urbanization_subdist -- subdistrict PCA urbanization


/***************************************/
/* PART 3 ANALYTICAL RESULTS/ESTIMATES */
/***************************************/

/* combine PC and DLHS hospital capacity */
do $ccode/a/estimate_hosp_capacity

/* combine hospital capacity with estimated district mortality rates */
do $ccode/a/export_hosp_cfr

/* export some additional stats that were asked for */
do $ccode/a/impute_additional_fields

/*****************************/
/* PART 4 -- DDL SERVER ONLY */
/*****************************/

/* push data to production */


/* push metadata to production */




- DLHS documentation as well as PC
- integrate rclone and dropbox into the build
- write readme describe metastructure of the code
- covid deaths and cases (state and district); dist-level hospital
  data; district age distributions and CFR predictions
