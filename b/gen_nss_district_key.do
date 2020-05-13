/* generates clean district key out of pdf-to-csv conversion of Appendix-I */

/* define lgd matching program */
qui do $ddl/covid/covid_progs.do

/* load data */
insheet using ~/iec1/nss/nss-75-health/Appendix-I.csv, clear

/* drop unnecessary vars */
drop v1 v3 v6 v11 v10

/* gen state and district name vars */
gen nss_state_name = v9
gen nss_district_name = v7
gen nss_district_id = v8

/* drop bad obs */
drop if real(nss_district_id) == . | real(nss_district_id) < 0

/* format nss id variables */
destring nss_district_id, replace

/* state and district name cleaning */
lgd_state_clean nss_state_name
lgd_dist_clean nss_district_name

/* state match to lgd key */
lgd_state_match nss_state_name

/* generate nss state id from the lgd state id variable*/
gen nss_state_id = lgd_state_id

/* district match to lgd key */
lgd_dist_match nss_district_name

/* re-order vars */
order nss_state_id nss_district_id, first

/* the final key has 649 obs */
/* original key had 648 obs */
/* jaintia hills was expanded into 2 obs */

/* save */
save $iec1/nss/nss-75-health/nss75_lgd_district_key, replace
