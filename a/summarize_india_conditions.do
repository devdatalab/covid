use $tmp/tmp_hr_data, clear

sum risk_ratio [aw=wt] if hr == "hr_age_sex", d
sum risk_ratio [aw=wt] if hr == "hr_fully_adj", d

/* put risk ratio on log scale */
gen ln_risk_ratio = ln(risk_ratio)

/* collapse to age*model for result comparison */
winsorize age 18 95, replace
collapse (mean) ln_risk_ratio [aw=wt], by(hr age)

/* line graph of risk profiles by age using the two kinds of adjustments */
sort age
twoway ///
    (line ln_risk_ratio age if hr == "hr_age_sex",  ylabel(-6(2)6) lwidth(medthick)) ///
    (line ln_risk_ratio age if hr == "hr_fully_adj", ylabel(-6(2)6) lwidth(medthick)) ///
    , legend(lab(1 "Age-Sex Adjusted") lab(2 "Fully adjusted")) 

graphout death_risk
