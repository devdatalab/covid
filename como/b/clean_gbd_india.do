/* make a list of all india CSV files */
shell find $health/gbd/gbd-india-states -type f -name "*.csv" >$tmp/filelist.txt

/* create a path for temp file components */
cap mkdir $tmp/gbd

/* open the list */
cap file close fh
file open fh using $tmp/filelist.txt, read
file read fh line

/* set a file counter for appending */
local c 1
while r(eof) == 0 {
  di "`line'"

  /* save the file in stata format. we don't need to do anything
  else since all the distinguish fields are in the csv already. */
  import delimited using "`line'", clear
  gen file = "`line'"
  save $tmp/gbd/gbd`c', replace

  /* advance the file counter */
  local c = `c' + 1
  file read fh line
}
file close fh

/* append all the stata files */
clear
local c = `c' - 1
forval i = 1/`c' {
  append using $tmp/gbd/gbd`i'
}

drop if strpos(location, "Global Burden of Disease Study 2017")
drop if strpos(location, "Available from http")
drop if strpos(location, "For terms and conditions")

/* drop vars that are identical everywhere */
assert measure == "Prevalent cases per 100,000"
assert sex == "Both"
assert year == 2017
drop lower* upper* measure sex

/* sort causes according to our cause definitions */
ren cause condition
replace condition = lower(condition)

/* drop hemoglobinopathies which clearly don't correspond to the NHS immunosuppressive category */
drop if inlist(condition, "hemoglobinopathies and hemolytic anemias")

/* drop liver disease NASH which is a predictive category not a severe illness */
drop if inlist(condition, "cirrhosis due to nash")

/* create aggregate condition groups that correspond to the hazard ratios we have in the NHS study */
gen     cgroup = "immuno_other_dz" if inlist(condition, "hiv/aids")
replace cgroup = "chronic_heart_dz" if inlist(condition, "cardiovascular diseases")
replace cgroup = "kidney_dz" if inlist(condition, "chronic kidney disease")
replace cgroup = "chronic_resp_dz" if inlist(condition, "chronic obstructive pulmonary disease")
replace cgroup = "liver_dz" if inlist(condition, "cirrhosis and other chronic liver diseases due to alcohol use", "cirrhosis and other chronic liver diseases due to hepatitis b", "cirrhosis and other chronic liver diseases due to hepatitis c", "cirrhosis and other chronic liver diseases due to other causes")
replace cgroup = "diabetes" if inlist(condition, "diabetes mellitus")
replace cgroup = "headaches" if inlist(condition, "headache disorders")
replace cgroup = "haem_malig_1" if inlist(condition, "hodgkin lymphoma", "leukemia", "multiple myeloma", "non-hodgkin lymphoma")
replace cgroup = "cancer_non_haem_1" if inlist(condition, "neoplasms")
replace cgroup = "neuro_other" if inlist(condition, "neurological disorders")
replace cgroup = "autoimmune_dz" if inlist(condition, "psoriasis", "rheumatoid arthritis")
replace cgroup = "stroke" if inlist(condition, "stroke")
replace cgroup = "dementia" if inlist(condition, "alzheimer's disease and other dementias")
replace cgroup = "asthma_ocs" if inlist(condition, "asthma")

drop condition

/* collapse all prevalences in condition group sums, leaving old conditions behind */
collapse (sum) value, by(age cgroup location)

/* expand ages into continuous data */
gen agestart = real(substr(age, 1, 2))
gen ageend = real(substr(age, 4, 2))
replace ageend = 90 if agestart == 70
expand 67
ren age agebin
bys location cgroup agebin: egen age = seq()
replace age = age + 17
gen prevalence = value if inrange(age, agestart, ageend)
drop if mi(prevalence)

sort location cgroup age
capdrop agebin agestart ageend value

/* convert to wide format on conditions */
reshape wide prevalence, i(location age) j(cgroup) string
ren prevalence* *

/* now adjust groups where there was double counting */
replace cancer_non_haem_1 = cancer_non_haem_1 - haem_malig_1
replace chronic_heart_dz = chronic_heart_dz - stroke
replace neuro_other = neuro_other - headaches - dementia
winsorize neuro_other 0 1, replace
gen stroke_dementia = stroke + dementia

/* drop conditions no longer used */
drop headache* stroke dementia*

/* get proper state identifiers */
ren location pc11_state_name
replace pc11_state_name = lower(pc11_state_name)
replace pc11_state_name = "jammu kashmir" if pc11_state_name == "jammu and kashmir"
drop if pc11_state_name == "telangana"
replace pc11_state_name = "nct of delhi" if pc11_state_name == "delhi"
drop if inlist(pc11_state_name, "union territories other than delhi")
merge m:1  pc11_state_name using $keys/pc11_state_key, keep(master match) nogen assert(match)
get_state_ids, y(11)
drop pc01*

/* convert everything from X/100,000 to % prevalence */
foreach v in $hr_gbd_vars diabetes {
  replace `v' = `v' / 100000
}

/* save clean state-level GBD */
order pc11_state_id pc11_state_name
save $health/gbd/gbd_india_states, replace

