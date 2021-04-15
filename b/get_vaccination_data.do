/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do
qui do $ddl/tools/do/tools.do

/* retrieve the vaccination data from the covid19india API */
pyfunc retrieve_covid19india_vaccination("http://api.covid19india.org/csv/latest/cowin_vaccine_data_districtwise.csv", "$tmp"), i(from retrieve_case_data import retrieve_covid19india_vaccination) f("$ddl/covid/b")

/* read in the data */
import delimited using $tmp/covid19india_vaccination_data.csv, clear

/* reshape */
drop unnamed*

foreach var of var v7 - v876 {

  local label : variable label `var'
  local label: subinstr local label "/" ""
  local label: subinstr local label "/" ""
  local label: subinstr local label "." "_"
  ren `var' v_`label'

}


foreach var in v_16012021   v_17012021 	v_18012021	v_19012021	v_20012021	v_21012021 	v_22012021	v_23012021	v_24012021	v_25012021	v_26012021	v_27012021	v_28012021	v_29012021	v_30012021	v_31012021	v_01022021	v_02022021	v_03022021	v_04022021	v_05022021	v_06022021	v_07022021	v_08022021	v_09022021	v_10022021	v_11022021	v_12022021	v_13022021	v_14022021	v_15022021	v_16022021	v_17022021	v_18022021	v_19022021	v_20022021	v_21022021	v_22022021	v_23022021	v_24022021	v_25022021	v_26022021	v_27022021	v_28022021	v_01032021	v_02032021	v_03032021	v_04032021	v_05032021	v_06032021	v_07032021	v_08032021	v_09032021	v_10032021	v_11032021	v_12032021	v_13032021	v_14032021	v_15032021	v_16032021	v_17032021	v_18032021	v_19032021	v_20032021	v_21032021	v_22032021	v_23032021	v_24032021	v_25032021	v_26032021	v_27032021	v_28032021	v_29032021	v_30032021	v_31032021	v_01042021	v_02042021	v_03042021	v_04042021	v_05042021	v_06042021	v_07042021	v_08042021	v_09042021	v_10042021	v_11042021	v_12042021 {
  ren `var' `var'_0
}

drop in 1

duplicates tag state_code district_key, gen(tag)
keep if tag == 0
drop tag

forval i = 0/9 {
  ren v*`i' v`i'*
}

ren v*_ v*
ren v*2021 v*

reshape long v0_ v1_ v2_ v3_ v4_ v5_ v6_ v7_ v8_ v9_, i(state_code district_key) j(date) string

replace date = date + "=" + "2021"
replace date = subinstr(date, "=", "", .)

la var v0_  "total individuals registered"
la var v1_ "total sessions conducted"
la var v2_ "total sites"
la var v3_ "first dose admin"
la var v4_ "second dose admin"
la var v5_ "male vac"
la var v6_ "female vc"
la var v7_ "trans vac"
la var v8_ "total covaxin"
la var v9_ "total covishied"

save $tmp/vaccines_clean, replace

/****************/
/* match to LGD */
/****************/
use $tmp/vaccines_clean, clear

/* drop extra variables */
drop district_key state_code

/* create lgd_state variable to merge */
gen lgd_state_name = lower(state)

/* fix dadra and nager haveli and daman and diu */
replace lgd_state_name = "dadra and nagar haveli" if district == "Dadra and Nagar Haveli"
replace lgd_state_name = "daman and diu" if (district == "Daman") | (district == "Diu")

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match master) nogen

/* now create an lgd_district variable to merge */
gen lgd_district_name = lower(district)

/* fix misspellings and name changes */
synonym_fix lgd_district_name, synfile($ddl/covid/b/str/cov19india_vaccine_district_fixes.txt) replace

/* save */
save $tmp/temp, replace

/* run masala merge */
keep lgd_state_name lgd_district_name
duplicates drop
masala_merge lgd_state_name using $keys/lgd_district_key, s1(lgd_district_name) minbigram(0.2) minscore(0.6) outfile($tmp/vaccine_lgd_district)

/* keep master matches */
keep if match_source < 7

/* drop unneeded variables */
keep lgd_state_name lgd_district_name_using lgd_district_name_master

/* merge data back in */
ren lgd_district_name_master lgd_district_name
merge 1:m lgd_state_name lgd_district_name using $tmp/temp
drop _merge

/* now replace the district name with the lgd key name */
drop lgd_district_name
ren lgd_district_name_using lgd_district_name

/* ensure that it is it square */
egen dgroup = group(lgd_state_name lgd_district_name)
fillin date dgroup
drop dgroup _fillin

/* clean final variables */
forvalues i=0/9 {

  /* convert to numerical  */
  destring v`i'_, replace

  /* get the new name from the label */
  local newname: var lab v`i'
  local newname = subinstr("`newname'", " ", "_", .)

  /* rename the variable */
  ren v`i'_ `newname'
}

/* fix spelling */
ren female_vc female_vac

/* rename variables */
ren total_covishied total_covishield

/* collapse to state-district-date: this sums over a couple duplicated lgd districts, 
districts that have been created since the lgd */
collapse (sum) total_* *_dose_* *_vac (first) state cowinkey district, by(lgd_state_id lgd_state_name lgd_district_name date)

/* format */
order lgd*id lgd*

/* fix labels */
la var date "Date"
la var state "state name from COWIN dashboard"
la var cowinkey "district key from COWIN dashboard"
la var district "district name from COWIN dashboard"
la var total_individuals_registered "Total individuals registered"
la var total_sessions_conducted "Total sessions conducted"
la var first_dose_admin "First doses administered"
la var second_dose_admin "Second doses administered"
la var male_vac "Number of males vaccinated"
la var female_vac "Number of females vaccinated"
la var trans_vac "Number of trans individuals vaccinated"
la var total_covaxin "Total Covaxin doses administered"
la var total_covishield "Total Covishield doses administered"

/* save data */
save $covidpub/covid/covid_vaccination, replace

