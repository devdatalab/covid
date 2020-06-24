/* open hazard ratio interpolations */
import delimited using $covidpub/covid/csv/uk_age_predicted_hr.csv, clear
ren ln_hr_age_sex ln_hr_simple

/* merge to actual data used in OpenSAFELY */
merge 1:1 age using $tmp/hr_full_dis, nogen keepusing(hr_age)
ren hr_age hr_full_age

merge 1:1 age using $tmp/hr_simp_dis, nogen keepusing(hr_age)
ren hr_age hr_simple_age

/* expand opensafely data to decimal ages */
expand 10
bys age: egen s = seq()
replace age = age - (s - 1) / 10
replace ln_hr_simple = . if age != round(age)
replace ln_hr_full = . if age != round(age)

foreach v in simple full {
  gen ln_hr_`v'_age_dis = ln(hr_`v'_age)
}

keep if inrange(age, 18, 89)

sort age
twoway ///
    (line ln_hr_full         age, lwidth(medthick) lpattern(solid) lcolor(black)) ///
    (line ln_hr_full_age_dis age, lwidth(medthick) lpattern(-) lcolor(gs8)) ///
    , xscale(range(15 90)) xlabel(20(10)90) xtitle(Age) ytitle("Log Hazard Ratio") ///
    legend(region(lcolor(black)) rows(2) ring(0) pos(5) lab(1 "Interpolated Age Hazard Ratio") lab(2 "Discrete Age Hazard Ratio") size(small) symxsize(5) bm(tiny)) 

graphout age_interpolation_full, pdf

twoway ///
    (line ln_hr_simple         age, lwidth(medthick) lpattern(-) lcolor(gs8)) ///
    (line ln_hr_simple_age_dis age, lwidth(medthick) lpattern(solid) lcolor(black)) ///
    , xscale(range(15 90)) xlabel(20(10)90) xtitle(Age) ytitle("Log Hazard Ratio") ///
    legend(region(lcolor(black)) rows(2) ring(0) pos(5) lab(1 "Discrete Age Hazard Ratio") lab(2 "Interpolated Hazard Ratio") size(small) symxsize(5) bm(tiny)) 

graphout age_interpolation_simple, pdf


