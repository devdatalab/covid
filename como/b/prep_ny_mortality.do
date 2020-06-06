import delimited using $covidpub/covid/csv/nystate_or.csv, varnames(1) clear

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

/* prefix with ny to avoid name collision */
rename * ny_or_*
ren ny_or_age age

/* clean and save */
order age
save $tmp/nystate_or, replace
