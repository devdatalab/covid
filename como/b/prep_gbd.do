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
replace agestart = -90 if age == "Age-standardized"
replace ageend = -90 if age == "Age-standardized"
drop age

/* rename variable names for consistency with our other stuff */
ren val prevalence
ren location country
ren cause condition
replace condition = lower(condition)

/* expand to ages 20-84 */
expand 5 if !inlist(agestart, -99, -90)

/* copy 80-84 into 85-99 */
expand 4 if agestart == 80
bys country agestart condition: egen age = seq()
replace age = age + agestart - 1

/* adjust first category for the fact that is only length 4 (ages 1-4) */
drop if age == 5 & agestart == 1
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

/* label all-age and age-standardized */
label define gbdage -99 "All Ages" -90 "Age-standardized"
label values age gbdage

/* smooth each variable to make age continuous */
foreach v in $hr_gbd_vars diabetes {
  lpoly gbd_`v' age if age > 0 & country == "India", bw(4) gen(gbd_`v'_smooth_ind) at(age)
  lpoly gbd_`v' age if age > 0 & country == "United Kingdom", bw(4) gen(gbd_`v'_smooth_uk) at(age)

  /* assign smooth vars correctly since lpoly isn't smart enough */
  gen     gbd_`v'_smooth = gbd_`v'_smooth_ind if country == "India"
  replace gbd_`v'_smooth = gbd_`v'_smooth_uk  if country == "United Kingdom"
  drop gbd_`v'_smooth_ind gbd_`v'_smooth_uk
}

/* set smoothed vars as defaults */
save $tmp/prerename, replace
ren *_upper upper_*
ren *_lower lower_*
ren gbd_*_smooth tmp_*
ren gbd* gbd*_granular
order country age tmp*
ren tmp_* gbd_*
ren upper_* *_upper
ren lower_* *_lower

savesome if country == "United Kingdom" using $health/gbd/gbd_nhs_conditions_uk, replace
savesome if country == "India" using $health/gbd/gbd_nhs_conditions_india, replace
