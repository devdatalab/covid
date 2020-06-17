/*************************/
/* prep india male share */
/*************************/
import excel $covidpub/demography/pc11/pc11_agesex.xls, firstrow clear

keep if place_name == "India"

keep age tot_p tot_m tot_f
assert tot_m + tot_f == tot_p

destring age, replace force
drop if mi(age)

/* take 5-year MA of population data series to pull out bumps */
gen x = 1
xtset x age
gen     p_smooth = (L2.tot_p + L1.tot_p + tot_p + F.tot_p + F2.tot_p) / 5 if !mi(L2.tot_p) & !mi(F2.tot_p)
replace p_smooth = (L1.tot_p + tot_p + F.tot_p + F2.tot_p) / 4 if mi(L2.tot_p) & !mi(F2.tot_p) & mi(p_smooth)
replace p_smooth = (L2.tot_p + L1.tot_p + tot_p + F.tot_p) / 4 if mi(F2.tot_p) & !mi(L2.tot_p) & mi(p_smooth)
replace p_smooth = tot_p if mi(p_smooth)

/* repeat for male population to get smoothed sex ratio */
gen     m_smooth = (L2.tot_m + L1.tot_m + tot_m + F.tot_m + F2.tot_m) / 5 if !mi(L2.tot_m) & !mi(F2.tot_m)
replace m_smooth = (L1.tot_m + tot_m + F.tot_m + F2.tot_m) / 4 if mi(L2.tot_m) & !mi(F2.tot_m) & mi(m_smooth)
replace m_smooth = (L2.tot_m + L1.tot_m + tot_m + F.tot_m) / 4 if mi(F2.tot_m) & !mi(L2.tot_m) & mi(m_smooth)
replace m_smooth = tot_m if mi(m_smooth)

/* calculate male share */
gen male = m_smooth / p_smooth

ren p_smooth india_pop

keep if inrange(age, 18, 100)
keep age male india_pop
save $tmp/india_pop, replace

/********************************/
/* UK population and male share */
/********************************/
import delimited using $covidpub/demography/csv/uk_gender_age.csv, clear
gen male_share = male / total
drop male female
ren male_share male
ren total uk_pop

/* distribute age 90 weight across remaining years, since age 90 is actually 90+ */
/* this is basically inconsequential since it is very few people and COPD is the
   only variable that is non-constant from 90-99. */
expand 10 if age == 90
replace uk_pop = uk_pop/10 if inrange(age, 90, 99)
replace age = _n - 1 if age == 90

save $tmp/uk_pop, replace

