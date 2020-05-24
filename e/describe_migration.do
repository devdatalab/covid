/* Matching migration data to covid data */

/* use covid dataset */
use $covidpub/covid/covid_infected_deaths.dta, clear

/* merge migration data */
merge m:1 lgd_district_id using $covidpub/migration/district_migration.dta

/* drop _merge */
drop _merge

/* merge population data */
merge m:1 lgd_district_id using $covidpub/demography/lgd_pc11_district_capacity.dta

/* drop missing values */
drop if mi(lgd_state_id)
drop if mi(lgd_district_id)

/* generate migration district data (share in national total*total national migrants) */
gen outltmigration = outltmigrationshare*outltmigrantstotal

/* gen per capita variables */
gen total_cases_pc = total_cases/pc11_pca_tot_p
gen outltmigration_pc = outltmigration/pc11_pca_tot_p

/* gen log variables */
foreach var in total_cases outltmigration pc11_pca_tot_p outltmigration_pc total_cases_pc {
 gen log_`var' = ln(`var')
}

/* keep latest covid data */
keep if date==22056

/* sava dataset */
save $covidpub/migration/covid_migration.dta, replace

/* regression log variables */
reg log_total_cases log_outltmigration log_pc11_pca_tot_p

/* regression per capita variables */
reg log_total_cases_pc log_outltmigration_pc
