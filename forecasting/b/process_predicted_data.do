/* assemble statewise district-level Rt estimates manually from CSVs */
/* TODO FIXME: get rid of absolute paths and use globals */

/* get all district-level files */
global imports ~/iec/covid/forecasting/all_rt_estimates
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

/* hack: gen state ID from abbrev */
gen pc11_state_id = ""
replace pc11_state_id = "28" if statename == "AP"
replace pc11_state_id = "12" if statename == "AR"
replace pc11_state_id = "18" if statename == "AS"
replace pc11_state_id = "10" if statename == "BR"
replace pc11_state_id = "22" if statename == "CT"
replace pc11_state_id = "30" if statename == "GA"
replace pc11_state_id = "24" if statename == "GJ"
replace pc11_state_id = "02" if statename == "HP"
replace pc11_state_id = "06" if statename == "HR"
replace pc11_state_id = "20" if statename == "JH"
replace pc11_state_id = "29" if statename == "KA"
replace pc11_state_id = "32" if statename == "KL"
// ladakh - assign J+K
replace pc11_state_id = "01" if statename == "LA"
//
replace pc11_state_id = "31" if statename == "LD"
replace pc11_state_id = "27" if statename == "MH"
replace pc11_state_id = "17" if statename == "ML"
replace pc11_state_id = "14" if statename == "MN"
replace pc11_state_id = "23" if statename == "MP"
replace pc11_state_id = "15" if statename == "MZ"
replace pc11_state_id = "13" if statename == "NL"
replace pc11_state_id = "21" if statename == "OR"
replace pc11_state_id = "03" if statename == "PB"
replace pc11_state_id = "34" if statename == "PY"
replace pc11_state_id = "08" if statename == "RJ"
replace pc11_state_id = "11" if statename == "SK"
// telangana - assign to AP
replace pc11_state_id = "28" if statename == "TG" 
//
replace pc11_state_id = "33" if statename == "TN"
replace pc11_state_id = "16" if statename == "TR"
replace pc11_state_id = "09" if statename == "UP"
replace pc11_state_id = "05" if statename == "UT"
replace pc11_state_id = "19" if statename == "WB"

/* get most recent date for imputation */
gen sdate = date(dates, "YMD")
gsort -sdate
local recent = date[1]

/* fill in most recent date for districts missing observations (hack: makes choropleth easier) */
fillin district pc11_state_id  dates
egen latest_date = max(sdate), by(district pc11_state_id)
gen rt_tmp = rt_pred if latest_date == sdate
egen latest_rt = max(rt_tmp), by(district pc11_state_id)
replace rt_pred = latest_rt if dates == "`recent'"
drop if _fillin == 1 & mi(rt_pred)
drop latest_rt rt_tmp latest_date _fillin sdate

/* create 100xed Rt for scaling (MB only allows interpolated fills with integer stops...) */
gen rt_pred_100x = 100 * rt_pred

/* final output for predictions data */
save ~/iec/covid/forecasting/pred_data, replace

/* we need to push the `recent' string to the web app. save to a JS object for push to AWS */
cap rm ~/iec/covid/forecasting/pred_metadata.js
append_to_file using ~/iec/covid/forecasting/pred_metadata.js , s(`"predMeta='[{"most_recent":"`recent'"}]'"')
