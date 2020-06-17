/* merge India and UK age-specific health prevalences with country prefixes */
use $tmp/prev_india, clear
ren prev_* i_*

merge 1:1 age using $tmp/prev_uk_nhs_matched, nogen
ren prev_* u_*


/* combine all three classes of obesity */
gen u_obese = u_obese_1_2 + u_obese_3
gen i_obese = i_obese_1_2 + i_obese_3

/* label the variables we will graph */
label var u_diabetes_contr "Diabetes (Controlled, UK)"
label var u_diabetes_uncontr "Diabetes (Uncontrolled, UK)"
label var u_hypertension_contr "Hypertension (Controlled, UK)"
label var u_hypertension_uncontr "Hypertension (Uncontrolled, UK)"
label var u_obese "Obese (BMI >= 30, UK)"
label var i_diabetes_contr "Diabetes (Controlled, India)"
label var i_diabetes_uncontr "Diabetes (Uncontrolled, India)"
label var i_hypertension_contr "Hypertension (Controlled, India)"
label var i_hypertension_uncontr "Hypertension (Uncontrolled, India)"
label var i_obese "Obese (BMI >= 30, India)"

/* apply a smoother to the India microdata conditions */
sort age
tsset age
foreach v in i_diabetes_contr i_diabetes_uncontr i_hypertension_uncontr i_hypertension_contr i_obese {
  replace `v' = (L2.`v' + L1.`v' + `v' + F1.`v' + F2.`v') / 5 if !mi(L2.`v') & !mi(F2.`v')
  replace `v' = (L1.`v' + `v' + F1.`v') / 3 if (mi(L2.`v') | mi(F2.`v')) & !mi(L1.`v') & !mi(F1.`v')
}
sort age
keep if age < 90

drop *diabetes_no_measure *hypertension_both

/* diabetes comparison */
twoway ///
    (line i_diabetes_uncontr age, lwidth(medthick) lcolor(gs2) lpattern(solid)) ///
    (line i_diabetes_contr   age, lwidth(medthick) lcolor(gs2) lpattern(-))     ///
    (line u_diabetes_uncontr age, lwidth(medthick) lcolor(orange) lpattern(solid)) ///
    (line u_diabetes_contr   age, lwidth(medthick) lcolor(orange) lpattern(-))     ///
    , name(diabetes, replace) xtitle("Age") ytitle("Prevalence") ///
    legend(size(vsmall) rows(2) ///
    lab(1 "Uncontrolled Diabetes (India)") ///
    lab(2 "Controlled Diabetes (India)") ///
    lab(3 "Uncontrolled Diabetes (U.K.)") ///
    lab(4 "Controlled Diabetes (U.K.)"))
graphout diabetes

/* hypertension comparison */
twoway ///
    (line i_hypertension_uncontr age, lwidth(medthick) lcolor(gs2) lpattern(solid)) ///
    (line i_hypertension_contr   age, lwidth(medthick) lcolor(gs2) lpattern(-))     ///
    (line u_hypertension_uncontr age, lwidth(medthick) lcolor(orange) lpattern(solid)) ///
    (line u_hypertension_contr   age, lwidth(medthick) lcolor(orange) lpattern(-))     ///
    , name(hypertension, replace) xtitle("Age") ytitle("Prevalence") ///
    legend(size(vsmall) rows(2) ///
    lab(1 "Uncontrolled Hypertension (India)") ///
    lab(2 "Controlled Hypertension (India)") ///
    lab(3 "Uncontrolled Hypertension (U.K.)") ///
    lab(4 "Controlled Hypertension (U.K.)"))
graphout hypertension

/* obesity comparison */
twoway ///
    (line i_obese age, lwidth(medthick) lcolor(gs2) lpattern(solid)) ///
    (line u_obese age, lwidth(medthick) lcolor(orange) lpattern(solid)) ///
    , name(obese, replace) xtitle("Age") ytitle("Prevalence") ///
    legend(size(vsmall) rows(2) ///
    lab(1 "Obese (India)") ///
    lab(2 "Obese (U.K.)"))
graphout obese

graph combine diabetes hypertension obese, rows(2)
graphout biomarker_uk_india



