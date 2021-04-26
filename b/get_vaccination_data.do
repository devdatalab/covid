/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do
qui do $ddl/tools/do/tools.do

/* retrieve the vaccination data from the covid19india API */
pyfunc retrieve_covid19india_vaccination("http://api.covid19india.org/csv/latest/cowin_vaccine_data_districtwise.csv", "$tmp"), i(from retrieve_case_data import retrieve_covid19india_vaccination) f("$ddl/covid/b")

/* read in the data */
import delimited using $tmp/covid19india_vaccination_data.csv, clear

/* get all the v* variables */
qui ds v*
local allvars `r(varlist)'

/* cylce through each variables */
foreach var in `allvars' {

  /* save the date that is in the label */
  local label : variable label `var'

  /* split on the period to get the date split from the variable number */
  tokenize `label', p(".")

  /* save the date */
  local date = subinstr("`1'", "/", "", .)

  /* if no argument was split off, the number was missing and it should be 0 */
  if "`3'" == "" local num = 0
  
  /* otherwise, save the split of argument as the variable number */
  else local num = `3'

  /* rename the variable */
  ren `var' v_`date'_`num'

}

/* drop the first row which contains variable names */
drop in 1

/* convert all variables to numbers */
qui destring v*, replace

/* rename variables to prep for reshape */
forval i = 0/9 {
  ren v*`i' v`i'*
}

/* drop the underscore and yeaer */
ren v*_ v*
ren v*2021 v*

/* get all the new variable names */
qui ds v*
local allvars `r(varlist)'

/* collapse over repeated districts- these have towns reported separately in the cowin dashboard
and we want to collapse them back to a single district value */
collapse (sum) `allvars', by(state_code state district_key district)

/* rehsape long so data is unique on state-district-year */
reshape long v0_ v1_ v2_ v3_ v4_ v5_ v6_ v7_ v8_ v9_, i(state_code state district_key district) j(date) string

/* clean up the date */
replace date = date + "=" + "2021"
replace date = subinstr(date, "=", "", .)

/* label variables */
la var v0_ "Total Individuals Registered"	
la var v1_ "Total Sessions Conducted"	
la var v2_ "Total Sites" 	
la var v3_ "First Dose Administered"	
la var v4_ "Second Dose Administered"	
la var v5_ "Male(Individuals Vaccinated)"	
la var v6_ "Female(Individuals Vaccinated)"	
la var v7_ "Transgender(Individuals Vaccinated)"	
la var v8_ "Total Covaxin Administered"	
la var v9_ "Total CoviShield Administered"

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

/* check that all districts were matched to LGD */
qui count if match_source == 6
local unmatched_districts = `r(N)'
if `unmatched_districts' > 0 {
  disp_nice "`unmatched_districts' districts from the vaccination data are unmatched. These districts must be matched to LGD before proceeding."
  exit 9
}

/* keep master matches */
keep if match_source < 7

/* drop unneeded variables */
keep lgd_state_name lgd_district_name_using lgd_district_name_master lgd_district_id

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

/* clean final variable names */
ren v0_ total_individuals_registered
ren v1_ total_sessions_conducted
ren v2_ total_sites
ren v3_ first_dose_admin
ren v4_ second_dose_admin
ren v5_ male_vac
ren v6_ female_vac
ren v7_ trans_vac
ren v8_ total_covaxin
ren v9_ total_covishield

/* collapse to state-district-date: this sums over a couple duplicated lgd districts, 
districts that have been created since the lgd */
collapse (sum) total_* *_dose_* *_vac (first) state district, by(lgd_state_id lgd_state_name lgd_district_name lgd_district_id date)

/* fix labels */
la var date "Date"
la var state "state name from COWIN dashboard"
la var district "district name from COWIN dashboard"
la var total_individuals_registered "Total individuals registered"
la var total_sessions_conducted "Total sessions conducted"
la var total_sites "Total sites where vaccine is administered"
la var first_dose_admin "First doses administered"
la var second_dose_admin "Second doses administered"
la var male_vac "Number of males vaccinated"
la var female_vac "Number of females vaccinated"
la var trans_vac "Number of trans individuals vaccinated"
la var total_covaxin "Total Covaxin doses administered"
la var total_covishield "Total Covishield doses administered"

/* work with the date variable */
tostring date, replace
gen day = substr(date, 1, 2)
gen month = substr(date, 3, 2)
gen year = "2021"

/* create date object for sorting */
destring day month year, replace
gen date_fmt = mdy(month, day, year)
format date_fmt %td

/* sort */
sort lgd_state_id lgd_district_id date_fmt

/* order */
order lgd_state_id lgd_state_name lgd_district_id lgd_district_name date_fmt

/* drop extra variables */
drop month day year date

/* rename date_fmt */
ren date_fmt date

/*************************/
/* Flag bad daily counts */
/*************************/
/*  print the value from Mahe district in Puducherry as an example to see what bad values we are flagging:
list lgd_state_name lgd_district_name date total_covishield if lgd_district_name == "mahe"

note that we are not replacing total values, just flagging days that we suspect were data entry errors.  */

/* do for total covishield and covaxin values */
foreach var in covishield covaxin {
  qui {
    disp_nice "Checking total_`var'"

    /* FIRST check for values that are anomalously large compared to the days before and after them.
       these are data entry errors we want to flag and replace in our subsequent logic checking first differences.
       see 14apr2021 in Mahe district for an exmple of the values we are flagging
    */
    bys lgd_state_id lgd_district_id: gen `var'_previous = (total_`var' - total_`var'[_n-1]) / total_`var'[_n-1]
    bys lgd_state_id lgd_district_id: gen `var'_next = (total_`var' - total_`var'[_n+1]) / total_`var'[_n+1]

    /* if a value is more than 100% of the value before AND after it, we want to flag it */
    gen bad_flg_`var' = 1 if `var'_previous > 1 & `var'_next > 1 & !mi(`var'_previous) & !mi(`var'_next)

    /* create a temporary variable to manipulate the data */
    gen temp = total_`var'

    /* replace temp with the previous day's value if it's one of these flagged values */
    replace temp = temp[_n-1] if bad_flg_`var' == 1

    /* SECOND: calculate first differences to flag days that have values lower than the day before
     see 13apr2021 in Mahe district for an exmple of the values we are flagging */
    
    /* make a counter */
    local counter = 1

    /* while this counter is not 0, we have strange daily totals reported */
    while `counter' != 0 {
    
      /* calculate the first differences */
      cap drop daily_temp
      bys lgd_state_id lgd_district_id: gen daily_temp = temp - temp[_n-1]
      replace daily_temp = temp if daily_temp == .

      /* add all bad obs to the flagged variable */
      replace bad_flg_`var' = 1 if daily_temp < 0

      /* identify the flagged observations that haven't been resolbed*/
      cap drop bad_flg_still
      gen bad_flg_still = 1 if daily_temp < 0

      /* replace bad obs with the previous day */
      replace temp = temp[_n-1] if bad_flg_still == 1
  
      /* count how many bad flags there are */
      count if bad_flg_still == 1
      local counter = `r(N)'

      /* if the counter is 0, it's done- display the number of flagged observations */
      if `counter' == 0 {
        count if bad_flg_`var' == 1
        noi disp_nice "`var' done. `r(N)' observations flagged in bad_flg_`var'."
      }
    }
    
  /* drop the temporary variables */
  drop temp bad_flg_still daily_temp `var'_next `var'_previous
  }
}

/* label flags */
lab var bad_flg_covishield "Likely data entry error in covishield total for this day in this district"
lab var bad_flg_covaxin "Likely data entry error in covaxin total for this day in this distrct"

/* save data */
save $covidpub/covid/covid_vaccination, replace
export delimited using $covidpub/covid/csv/covid_vaccination.csv, replace
