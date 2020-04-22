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


/*****************************/
/* PART 4 -- DDL SERVER ONLY */
/*****************************/

/* push data to production */
shell source $ccode/b/push_data.sh

/* push metadata to production */
shell source $ccode/b/push_metadata.sh
