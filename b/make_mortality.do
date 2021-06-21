/* This makefile runs all the data construction steps for district-level mortality data */

/* globals that need to be set:
$tmp -- a temporary folder
$ccode -- this root folder for this repo
$covidpub -- processed data used as inputs for COVID variable construction
*/

/**************************/
/* PART I: Clean raw data */
/**************************/

/* West Bengal (district level data only available for Kolkata (KMDC)) */
do $ddl/covid/b/clean_kmdc_mort

/* Karnataka (district level data only available for Bangalore (BBMP)) */
do $ddl/covid/b/clean_bbmp_mort

/* Telangana (district level data only available for Hyderabad (GHMC)) */
do $ddl/covid/b/clean_ghmc_mort

/* Tamil Nadu (district level data only available for Chennai */
do $ddl/covid/b/clean_chennai_mort

/* Madhya Pradesh */
do $ddl/covid/b/clean_mp_mort

/* Assam */
do $ddl/covid/b/clean_assam_mort

/* Bihar */
do $ddl/covid/b/clean_bihar_mort

/* Andhra Pradesh */
do $ddl/covid/b/clean_ap_mort

/**********************************/
/* PART II: Append processed data */
/**********************************/

clear

/* append all processed data in PART I */
foreach i in mort_ap mort_assam mort_bbmp mort_bihar mort_chennai mort_ghmc mort_kolkata mort_mp {

  append using $tmp/`i'.dta, force

}
