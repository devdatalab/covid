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

/* repeat for male population to get smoothed sex ratio */
gen     m_smooth = (L2.tot_m + L1.tot_m + tot_m + F.tot_m + F2.tot_m) / 5 if !mi(L2.tot_m) & !mi(F2.tot_m)
replace m_smooth = (L1.tot_m + tot_m + F.tot_m + F2.tot_m) / 4 if mi(L2.tot_m) & !mi(F2.tot_m) & mi(m_smooth)
replace m_smooth = (L2.tot_m + L1.tot_m + tot_m + F.tot_m) / 4 if mi(F2.tot_m) & !mi(L2.tot_m) & mi(m_smooth)

/* calculate male share */
gen male = m_smooth / p_smooth

ren p_smooth india_pop

keep if inrange(age, 18, 100)
keep age male india_pop
save $tmp/india_pop, replace

/*****************/
/* UK male share */
/*****************/
import delimited using $covidpub/demography/csv/uk_gender_age.csv, clear
gen male_share = male / total
drop male female
ren male_share male
ren total uk_pop
save $tmp/uk_pop, replace
