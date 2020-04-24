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
/* in: $health/DLHS4, $keys/pc11_district_key.  out: $health/DLHS4 */
do $ccode/b/create_dlhs4_pc11_district_key

/* collapse raw DLHS4 data to district level */
/* in: $health/DLHS4, pc11_pca_district.  out: $health/hosp/dlhs4_hospitals_dist, $covidpub/dhls4_hospitals_dist
do $ccode/b/prep_dlhs4_district

/* prepare short village/town directory and PCA to save in public repo */
/* in: TD/VD.  out: $covidpub/pc11r_hosp, pc11r_hosp
do $ccode/b/prep_hosp_pca_vd

/* prepare EC microdata on hospitals */
/* in: raw economic census 2013.  out: $covidpub/ec13_hosp_microdata */
do $ccode/b/prep_ec_hosp_microdata

/* download latest district-level case data */
// need to fix conda setup to make this universal
// do $ccode/b/get_case_data
do $ccode/b/aggregate_case_data

/***********************************************/
/* PART 2 -- RUNS FROM DATA LINKED IN GIT REPO */
/***********************************************/


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

/* push data and metadata to production. metadata will be included in
data download links as well. */
shell source $ccode/b/push_data.sh
