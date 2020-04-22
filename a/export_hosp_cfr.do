/* open hospital bed capacity */
use $covidpub/hospitals_dist_export.dta, clear

/* merge with age distribution and infection fatality rate file */
merge 1:1 pc11_state_id pc11_district_id using $covidpub/district_age_dist_cfr, nogen

save $covidpub/out/district_ages_cfr_hospitals, replace
export delimited using $covidpub/out/district_ages_cfr_hospitals.csv, replace

