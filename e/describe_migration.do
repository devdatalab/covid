/* Matching migration data to covid data */

/* use covid dataset */
use $covidpub/covid/covid_infected_deaths.dta, clear

/* merge migration data */
merge m:1 lgd_district_id using $covidpub/migration/district_migration.dta

/* drop _merge */
drop _merge

/* merge population data */
merge m:1 lgd_district_id using $covidpub/demography/dem_district.dta

/* drop missing values */
drop if mi(lgd_state_id)
drop if mi(lgd_district_id)

/* generate migration district data (share in national total*total national migrants) */
gen outltmigration = outltmigrationshare * outltmigrantstotal

/* gen per capita variables */
gen total_cases_pc = total_cases / pc11_pca_tot_p
gen outltmigration_pc = outltmigration / pc11_pca_tot_p

/* gen log variables */
foreach var in total_cases outltmigration pc11_pca_tot_p outltmigration_pc total_cases_pc {
  gen log_`var' = ln(`var')
}

/* keep latest covid data */
keep if date == 22082

/* save dataset */
save $tmp/covid_migration.dta, replace

/* binscatter log cases vs. log outmigratns */
binscatter log_total_cases log_outltmigration 
graphout cases_outmigrants

/* repeat, controlling for population */
binscatter log_total_cases log_outltmigration, control(log_pc11_pca_tot_p) xlabel(7.5(.5)10.5) ylabel(2.5(.5)4.5)
graphout cases_outmigrants_popcontrol

/* per capita variables */
binscatter log_total_cases_pc log_outltmigration_pc, control(log_pc11_pca_tot_p)
graphout cases_outmigrants_pc

/* repeat, restricting to bihar and UP */
gen sample = inlist(lgd_state_name, "bihar", "uttar pradesh")
binscatter log_total_cases log_outltmigration if sample == 1
graphout cases_outmigrants_subsample
binscatter log_total_cases log_outltmigration if sample == 1, control(log_pc11_pca_tot_p) xlabel(7.5(.5)10.5) ylabel(2.5(.5)4.5) xtitle("Log number typical outmigrants") ytitle("Log cases (5/22)")
graphout cases_outmigrants_popcontrol_subsample
binscatter log_total_cases_pc log_outltmigration_pc if sample == 1, control(log_pc11_pca_tot_p)
graphout cases_outmigrants_pc_subsample

reg log_total_cases log_pc11_pca_tot_p if sample == 1
predict case_hat, resid
reg log_outltmigration log_pc11_pca_tot_p if sample == 1
predict outmigrants_hat, resid

twoway (scatter case_hat outmigrants_hat if sample == 1, xtitle("Log residual number typical outmigrants") ytitle("Log residual cases (5/22)")) ///
(lfit case_hat outmigrants_hat if sample & inrange(outmigrants_hat, -2, 2))
graphout scatter

/* regression versions */
reg log_total_cases log_outltmigration 
reg log_total_cases log_outltmigration log_pc11_pca_tot_p
reg log_total_cases log_outltmigration if sample == 1
reg log_total_cases log_outltmigration log_pc11_pca_tot_p if sample == 1
