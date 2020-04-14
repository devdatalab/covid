/* This makefile runs all the data construction steps in the repo */

/* globals that need to be set:
$tmp -- a temporary folder
$ccode -- this root folder for this repo
$hosp -- output folder for hospital data
*/

/* collapse raw DLHS4 data to district level */
do $ccode/b/generate_dlhs4_district

/* match DLHS4 to PC11 districts */
do $ccode/b/matching_dlhs4_pc11_district.do

/* download latest district-level case data */
// do $ccode/b/get_case_data

/* prepare PC11 hospital/clinic data */
do $ccode/b/prep_pc_hosp.do

/* prepare economic census (2013) hospital data */
do $ccode/b/prep_ec_hosp.do

/* prepare SECC district-level poverty data */
do $ccode/b/prep_secc.do


