/* assemble statewise district-level Rt estimates manually from CSVs */
/* TODO FIXME: get rid of absolute paths and use globals */

/* pull globals */
process_yaml_config ~/ddl/covid/forecasting/config/config.yaml

/* get all district-level files */
global imports $cdata/all_rt_estimates
local files : dir "$imports" files "*district*.csv"

/* loop over files to save as .dta and append. slow logic but concise */
clear
save $tmp/covid_appender, emptyok replace
foreach file in `files' {
  insheet using $imports/`file', names clear
  local state_abbrev = substr("`file'", 1, 2)
  gen statename = "`state_abbrev'"
  drop v1
  append using $tmp/covid_appender
  save $tmp/covid_appender, replace
}

/* get most recent date for imputation */
gen sdate = date(dates, "YMD")
gsort -sdate
local recent = date[1]
local recent_sdate = sdate[1]

/* HACK: impute most recent date when missing as == latest observation of rt_pred */
gsort lgd_district_id lgd_state_id dates
bysort lgd_district_id lgd_state_id : gen order = _n
by lgd_district_id lgd_state_id: gen last = _n == _N
expand 2 if last, gen(expanded)
replace dates = "`recent'" if expanded == 1

/* drop unnecessarily filled in obs, as well as duplicates in the raw data */
duplicates drop lgd_district_id lgd_state_id rt_pred dates, force

/* clean up */
drop sdate order last expanded

/* create 100xed Rt for scaling (MB only allows interpolated fills with integer stops...) */
gen rt_pred_100x = 100 * rt_pred

/* stringify ids */
gen tmp = string(lgd_state_id,"%02.0f")
drop lgd_state_id
ren tmp lgd_state_id 
gen tmp  = string(lgd_district_id,"%03.0f")
drop lgd_district_id
ren tmp lgd_district_id 

/* final output for predictions data */
save $cdata/pred_data, replace

/* we need to push the `recent' string to the web app. save to a JS object for push to AWS */
cap rm $cdata/pred_metadata.js
append_to_file using $cdata/pred_metadata.js , s(`"predMeta='[{"most_recent":"`recent'"}]'"')
