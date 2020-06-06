import delimited using $health/gbd/ihme-gbd.csv, clear

/* confirm we got the data we want */
assert measure == "Prevalence"
assert sex == "Both"
assert metric == "Percent"
assert year == 2017
drop measure sex metric year

/* set the start and end age for this prevalence */
gen agestart = real(substr(age, 1, 2))
gen ageend = real(substr(age, 7, 2))
replace agestart = -99 if age == "All Ages"
replace ageend = -99 if age == "All Ages"
drop age

/* rename variable names for consistency with our other stuff */
ren val prevalence
ren location country
ren cause condition
replace condition = lower(condition)

/* expand to ages 20-89 */
expand 5 if agestart != -99
bys country agestart condition: egen age = seq()
replace age = age + agestart - 1
drop agestart ageend

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

/* collapse all prevalences in condition group sums, leaving old conditions behind */
collapse (sum) prevalence upper lower, by(age cgroup country)

/* convert data into wide format on conditions */
reshape wide prevalence upper lower, i(country age) j(cgroup) string
ren prevalence* *
ren upper* *_upper
ren lower* *_lower

/* now adjust groups where there was double counting */
foreach v in "" _upper _lower {
  replace cancer_non_haem_1`v' = cancer_non_haem_1`v' - haem_malig_1`v'
  replace chronic_heart_dz`v' = chronic_heart_dz`v' - stroke`v'
  replace neuro_other`v' = neuro_other`v' - headaches`v' - dementia`v'
  winsorize neuro_other`v' 0 1, replace
  gen stroke_dementia`v' = stroke`v' + dementia`v'
}
drop headache* stroke stroke_upper stroke_lower dementia*

/* prefix everything with gbd */
ren * gbd_*
ren (gbd_country gbd_age) (country age)

savesome if country == "United Kingdom" using $health/gbd/gbd_nhs_conditions_uk, replace
savesome if country == "India" using $health/gbd/gbd_nhs_conditions_india, replace



exit
exit
exit

OLD VERSION OF GBD WHERE WE DIDN'T REALIZE WE COULDN'T ADD THESE THINGS TOGETHER

global xls_list asthma cancer_hematological diabetes neuro_motor neuro_strokedementia spleen
global csv_list autoimmune_rheumatoidpsoriasis cancer_other heart immunosuppressive kidney liver respiratory_other

/* loop over all excel sheets */
qui foreach f in $xls_list $csv_list {

  noi disp_nice "`f'"
  
  /* check if it's an excel or csv file */
  cap confirm file $health/gbd/`f'.xlsx

  /* open if an excel file */
  if !_rc {
    import excel using $health/gbd/`f'.xlsx, clear firstrow
  }
  /* otherwise open if a CSV */
  else {
    import delimited using $health/gbd/`f'.csv, clear
  }    
  
  /* make vars lowercase */
  rename *, lower
  
  /* confirm we have the fields we want */
  drop if mi(measure_name)
  assert measure_name == "Prevalence"
  assert sex_name == "Both"
  assert metric_name == "Percent"
  assert year == 2017
  
  /* set the country name */
  ren location_name country
  
  /* set the start and end age for this prevalence */
  gen agestart = real(substr(age_name, 1, 2))
  gen ageend = real(substr(age_name, 7, 2))
  
  /* set the health condition */
  ren cause_name condition
  
  /* set the prevalence variable */
  ren val prevalence
  
  /* keep the parts we are using */
  keep country agestart ageend condition prevalence
  
  /* expand to ages 20-89 */
  expand 5
  bys country agestart condition: egen age = seq()
  replace age = age + agestart - 1
  
  /* drop age bin variables */
  drop agestart ageend

  /* collapse all variables in this dataset to a single condition that matches our other data */
  collapse (sum) prevalence, by(country age)
  di "`f'"
  noi sum prevalence
  
  /* save prevalence for this condition separately for UK and India */
  savesome if country == "India" using $tmp/gbd_`f'_india, replace
  savesome if country == "United Kingdom" using $tmp/gbd_`f'_uk, replace
}
