/* assemble statewise district-level Rt estimates manually from CSVs */
/* TODO FIXME: get rid of absolute paths and use globals */

/* pull globals */
process_yaml_config ~/ddl/covid/forecasting/config/config.yaml

/* function to append state and district files */
cap prog drop append_covid_estimates
prog def append_covid_estimates
  syntax anything
  local geo "`anything'"

  /* get all state or dist-level files */
  global imports $cdata/all_rt_estimates
  local files : dir "$imports" files "*`geo'*.csv"
  
  /* loop over files to save as .dta and append. slow logic but concise */
  clear
  save $tmp/covid_appender, emptyok replace
  foreach file in `files' {
    insheet using $imports/`file', names clear
    local state_abbrev = substr("`file'", 1, 2)
    drop v1
    append using $tmp/covid_appender
    save $tmp/covid_appender, replace
  }
end

/*************/
/* Districts */
/*************/

/* append raw data */
append_covid_estimates district

/* stringify ids */
gen tmp = string(lgd_state_id,"%02.0f")
drop lgd_state_id
ren tmp lgd_state_id 
gen tmp  = string(lgd_district_id,"%03.0f")
drop lgd_district_id
ren tmp lgd_district_id 

/* HACK - get rid of duplicates on date */
count
local pre_drop `r(N)'
ddrop lgd_state_id lgd_district_id dates
count
local post_drop `r(N)'
di "`post_drop' / `pre_drop'"
assert `post_drop' / `pre_drop' > 0.998

/* assert there are no duplicate entries for any district at any date */
distinct lgd_state_id lgd_district_id dates, joint
assert `r(ndistinct)' == `r(N)'

/* final output for dist data - save to tmp as we'll be merging back districts we want to keep */
drop state district
order lgd* dates, first
drop t_*
save $tmp/pred_data_all_dists, replace

/* new data file with single entry of latest date for each district -
used for choropleth */

/* get most recent date for imputation */
gen sdate = date(dates, "YMD")
gsort -sdate

/* keep most recent observed rt_pred for each district */
keep if !mi(rt_pred)
gsort lgd_district_id lgd_state_id dates
bysort lgd_district_id lgd_state_id : gen order = _n
by lgd_district_id lgd_state_id: gen latest = _n == _N
keep if latest

/* DROP IF OVER A MONTH OUT OF DATE */

/* create a var for the lag between today and the most recent date */
gen lag = sdate - daily("`c(current_date)'", "DMY")

/* drop if over 30 days out of date */
drop if lag < -30

/* create 100xed Rt for scaling (MB only allows interpolated fills with integer stops...) */
gen rt_pred_100x = 100 * rt_pred

/* merge back to district data */
preserve
keep lgd_district_id lgd_state_id 
merge 1:m lgd_district_id lgd_state_id using $tmp/pred_data_all_dists, keep(match) nogen

/* DTA and CSV versions */
save $cdata/pred_data_district, replace
outsheet using $cdata/pred_data_district.csv, comma replace
restore

/* keep only bare minimum of variables */
ren lgd_district_id lgd_d_id
keep lgd_d_id rt_pred_100x

/* save for adding to tileset */
save $cdata/pred_data_rt_choropleth, replace


/**********/
/* States */
/**********/

/* append raw data */
append_covid_estimates state

/* stringify ids */
gen tmp = string(lgd_state_id,"%02.0f")
drop lgd_state_id
ren tmp lgd_state_id 

/* same basic assertion */
distinct lgd_state_id dates, joint
assert `r(ndistinct)' == `r(N)'

/* minimal cleanup here */
drop state
order lgd* dates, first

/* final output for state data */
drop t_*
save $cdata/pred_data_state, replace

/* CSV version */
outsheet using $cdata/pred_data_state.csv, comma replace
