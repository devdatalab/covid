/* generates clean district key out of pdf-to-csv conversion of Appendix-I */

/* define lgd matching program */
qui do $ddl/covid/covid_progs.do

/* load data */
insheet using $nss/nss-75-health/Appendix-I.csv, clear

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
/* arunachal pradesh and mizoram missing in nss key */

/* generate nss state id from the lgd state id variable*/
gen nss_state_id = real(lgd_state_id)


/* district match to lgd key */
lgd_dist_match nss_district_name

/* re-order vars */
order nss_state_id nss_district_id, first
order nss_district_name, before(lgd_district_name)

/* the final key has 649 obs */
/* original key had 648 obs */
/* jaintia hills was expanded into 2 obs bc lgd data has e & w. jaintia hills */

/* pull population weights to handle jaintia hills split - these can
be drawn from pc11:LGD key, which has the same split */
preserve
use $keys/lgd_pc11_district_key_weights.dta, clear

/* make sure the key hasn't changed */
count if regexm(lower(pc11_district_name), "jaintia")
assert `r(N)' == 2

/* pull weights into locals */
sum pc11_lgd_wt_pop if regexm(lower(lgd_district_name), "east jaintia hills")
local east = `r(mean)'
sum pc11_lgd_wt_pop if regexm(lower(lgd_district_name), "west jaintia hills")
local west = `r(mean)'

/* back to the NSS key. weight is just 1 for all others */
restore
gen nss_lgd_wt_pop = 1

/* replace for split */
replace nss_lgd_wt_pop = `west' if regexm(lower(lgd_district_name), "west jaintia hills")
replace nss_lgd_wt_pop = `east' if regexm(lower(lgd_district_name), "east jaintia hills")

/* save */
save $nss/nss-75-health/nss75_lgd_district_key, replace
save $covidpub/nss/nss75_lgd_district_key, replace
