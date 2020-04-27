/* This makefile runs all the data construction steps in the repo */

/* globals that need to be set:
$tmp -- a temporary folder
$ccode -- this root folder for this repo
$hosp -- output folder for hospital data
*/

global fast 1

/*****************************/
/* PART 1 -- DDL SERVER ONLY */
/*****************************/

/* match DLHS4 to PC11 districts */
/* in: $health/DLHS4, $keys/pc11_district_key.  out: $health/DLHS4 */
do $ccode/b/create_dlhs4_pc11_district_key

/* collapse raw DLHS4 data to district level */
/* in: $health/DLHS4, pc11_pca_district.  out: $health/hosp/dlhs4_hospitals_dist, $covidpub/dhls4_hospitals_dist */
do $ccode/b/prep_dlhs4_district

/* prepare short village/town directory and PCA to save in public repo */
/* in: TD/VD.  out: $covidpub/pc11r_hosp, pc11r_hosp */
do $ccode/b/prep_hosp_pca_vd

/* prepare EC microdata on hospitals */
/* in: raw economic census 2013.  out: $covidpub/ec_hosp_microdata */
do $ccode/b/prep_ec_hosp_microdata

/* build age distribution by district/subdistrict, using SECC + PC */
if "$fast" != "1" {
  do $ccode/b/gen_age_distribution
}

/* download latest district-level case data */
// need to fix conda setup to make this universal
// do $ccode/b/get_case_data

/***********************************************/
/* PART 2 -- RUNS FROM DATA LINKED IN GIT REPO */
/***********************************************/

/* aggregate case data into a district file with confirmed + deaths */
do $ccode/b/aggregate_case_data

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

/* predict district and subdistrict mortality distribution based on age distribution */
/* out: estimates/(sub)district_age_dist_cfr */
do $ccode/a/predict_age_cfr

/* combine PC and DLHS hospital capacity */
do $ccode/a/estimate_hosp_capacity

/* export some additional stats that were asked for into a combined file */
do $ccode/a/impute_additional_fields


/*****************************/
/* PART 4 -- DDL SERVER ONLY */
/*****************************/

/* push data and metadata to production. metadata will be included in
data download links as well. */
// shell source $ccode/b/push_data.sh
