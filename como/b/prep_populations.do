/********************************************/
/* convert the UK age distribution to Stata */
/********************************************/

/* open the raw csv file */
import delimited using $covidpub/covid/csv/uk_demography.csv, clear

/* split the age into a start and end */
gen agestart = real(substr(age, 1, strpos(age, "-") - 1))
gen ageend   = real(substr(age, strpos(age, "-") + 1, .))

/* create 5 rows for each age to have granular age */
expand 5
ren age age_str
bys age_str: egen age = seq()
replace age = age + agestart - 1

/* cut population by 5 since we multiplied each bin by 5 */
replace uk_pop = uk_pop / 5

/* keep the ages and vars that we want */
drop agestart ageend age_str
keep if inrange(age, 16, 90)

order age
save $tmp/uk_pop, replace

/****************************************/
/* create age-granular india population */
/****************************************/

/* open district data with 5-year age bins */
use $covidpub/demography/pc11/age_bins_district_t_pc11.dta, clear

/* collapse to national level */
gen x = 1
collapse (sum) age_*_t, by(x)

/* reshape to long on ages */
ren *_t *
ren age_* india_pop*
reshape long india_pop, j(age) i(x)
format india_pop %10.0f
drop x

/* expand to have one row per age */
expand 5
ren age agebin
bys agebin: egen age = seq()
replace age = age + agebin - 1
replace india_pop = india_pop / 5

drop agebin
keep if inrange(age, 16, 90)
order age
save $tmp/india_pop, replace
