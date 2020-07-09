/********************************/
/* prepare O/R from NY epi data */
/********************************/
import delimited using $comocsv/nystate_or.csv, varnames(1) clear

/* bottom-code everything at 1. it's not plausible that these conditions are protective */
foreach v of varlist * {
  if "`v'" == "age" continue

  winsorize `v' 1 100, replace
}

/* make the data granular on age */
gen start_age = real(substr(age, 1, 2))
drop age

expand 10
bys start_age: egen increment = seq()
gen age = start_age + increment - 1

/* clean up unused vars */
drop increment start_age

/* expand to cover 18-19 */
expand 3 if age == 20
bys age: egen s = seq()
replace age = age + 1 - s
drop s

/* expand to cover 80-99 */
expand 21 if age == 79
bys age: egen s = seq()
replace age = age - 1 + s
drop s

/* prefix with ny to avoid name collision */
rename * hr_*
ren hr_age age

/* assume this new york measure is mostly controlled, though we don't know */
ren hr_diabetes_uncontr hr_diabetes_contr

/* clean and save */
order age
save $tmp/nystate_hr, replace


/**************************************/
/* prepare O/Rs from NY Cummings data */
/**************************************/
import delimited using $comocsv/ny_cummings.csv, varnames(1) clear
ren * hr_*

expand 82
gen age = _n + 17

save $tmp/nycu_hr, replace
