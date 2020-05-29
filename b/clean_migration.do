/* Clean district migration in/outflow data */


/* read in raw CSV data (source: Clement Imbert */
import delimited using $covidpub/migration/raw/district_migration_pc11.csv, clear varn(1)

/* reformat census identifiers to string */
ren statecodecensus2011 pc11_state_id
tostring pc11_state_id, format(%02.0f) replace
ren districtcodecensus2011 pc11_district_id
tostring pc11_district_id, format(%03.0f) replace

/* save to pc11 */
order _all, alphabetic
order pc11_state_id pc11_district_id, first
compress
save $covidpub/migration/pc11/district_migration_pc11, replace
export delimited using $covidpub/migration/csv/district_migration_pc11.csv, replace

/* create LGD version */
convert_ids, from_ids(pc11_state_id pc11_district_id) to_ids(lgd_state_id lgd_district_id) key($keys/lgd_pc11_district_key_weights.dta) weight_var(pc11_lgd_wt_pop) metadata_urls("https://docs.google.com/spreadsheets/d/e/2PACX-1vTu79uiVKSFv8c1oZvx7WARrWXSfbwfLakiukoezDaH0spMM_MQalkm5fr4bnkBQVNRs2aiU7x41oi3/pub?gid=0&single=true&output=csv") labels
save $covidpub/migration/district_migration, replace
export delimited using $covidpub/migration/csv/district_migration.csv, replace
