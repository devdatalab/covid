/******************************************************/
/* Compare England and India Prevalence of Biomarkers */
/******************************************************/
use $tmp/prev_compare, clear

foreach v of varlist i_* u_* {
  replace `v' = `v' * 100
}

/* diabetes comparison */
twoway ///
    (line i_diabetes_uncontr age, lwidth(thick) lcolor(gs2) lpattern(solid)) ///
    (line i_diabetes_contr   age, lwidth(thick) lcolor(gs2) lpattern(-))     ///
    (line u_diabetes_uncontr age, lwidth(thick) lcolor(orange) lpattern(solid)) ///
    (line u_diabetes_contr   age, lwidth(thick) lcolor(orange) lpattern(-)) ///
    , name(diabetes, replace) xtitle("Age", size(large)) ytitle("Prevalence (%)", size(large)) xlabel(, labsize(medium)) ylabel(, labsize(medium)) ///
    legend(size(large) rows(2) symxsize(5) bm(tiny) ///
    lab(1 "Uncontrolled (India)") ///
    lab(2 "Controlled (India)") ///
    lab(3 "Uncontrolled (England)") ///
    lab(4 "Controlled (England)"))
graphout diabetes, pdf

/* hypertension comparison */
twoway ///
    (line i_hypertension_uncontr age, lwidth(thick) lcolor(gs2) lpattern(solid)) ///
    (line i_hypertension_contr   age, lwidth(thick) lcolor(gs2) lpattern(-))     ///
    (line u_hypertension_uncontr age, lwidth(thick) lcolor(orange) lpattern(solid)) ///
    (line u_hypertension_contr   age, lwidth(thick) lcolor(orange) lpattern(-))     ///
    , name(hypertension, replace) xtitle("Age", size(large)) ytitle("Prevalence (%)", size(large)) xlabel(, labsize(medium)) ylabel(, labsize(medium)) ///
    legend(size(large) rows(2) symxsize(5) bm(tiny) ///
    lab(1 "Uncontrolled (India)") ///
    lab(2 "Controlled (India)") ///
    lab(3 "Uncontrolled (England)") ///
    lab(4 "Controlled (England)"))
graphout hypertension, pdf

/* obesity comparison */
twoway ///
    (line i_obese age, lwidth(thick) lcolor(gs2) lpattern(solid)) ///
    (line u_obese age, lwidth(thick) lcolor(orange) lpattern(solid)) ///
    , name(obese, replace) xtitle("Age", size(large)) ytitle("Prevalence (%)", size(large)) xlabel(, labsize(medium)) ylabel(, labsize(medium)) ///
    legend(size(large) rows(1) symxsize(5) bm(tiny) ///
    lab(1 "India") ///
    lab(2 "England"))
graphout obese, pdf

graph combine diabetes hypertension obese, rows(2)
graphout biomarker_uk_india

/***********************************************/
/* plot combined risk of all health conditions */
/***********************************************/

/* open analysis file */
use $tmp/como_analysis, clear

/* plot comparison of PRR(age,all health conditions) in india vs. UK matched */
sort age
twoway ///
    (line prr_h_india_full_cts age, lwidth(medthick) lcolor(black)) ///
    (line prr_h_uk_nhs_matched_full_cts age, lwidth(medthick) lcolor(orange)), ///
    ytitle("Population Relative Risk of COVID-19 Mortality", size(medsmall)) xtitle("Age", size(medsmall)) ///
    legend(lab(1 "India") lab(2 "England") ring(0) pos(5) cols(1) size(small) symxsize(5) bm(tiny) region(lcolor(black))) ///
    name(prr_health, replace)  ylabel(1(.5)3) 
graphout prr_health, pdf

/********************/
/* Coefficient Plot */
/********************/
/* isolate risk vars for plot */
import delimited $ddl/covid/como/a/covid_como_sumstats.csv, clear
keep if strpos(v1, "ratio") != 0
drop if strpos(v1, "sign") != 0
ren v1 variable
ren v2 coef
save $tmp/coefs_to_plot, replace
shell python $ccode/como/a/make_coef_plot.py
// cp ~/public_html/png/coefplot.png $out/, replace

/*******************************/
/* plot distribution of deaths */
/*******************************/

/* open the full data */
use $tmp/mort_density_full, clear

foreach v of varlist *deaths {
  replace `v' = `v' * 100
}

/* graph with hybrid india population * england health conditions */
twoway ///
    (line india_full_deaths age if age <= 89, lcolor(black) lpattern(solid) lwidth(medthick))       ///
    (line uk_full_deaths    age if age <= 89, lcolor(orange) lwidth(medthick) lpattern(solid))     ///
    (line ipop_ehealth_deaths age if age <= 89, lcolor("33 173 191") lwidth(medium) lpattern(dash))     ///
    , ytitle("Share of Deaths at each Age (%)", size(medsmall)) xtitle(Age, size(medsmall))  ///
    legend(lab(1 "India") ///
    lab(2 "England") lab(3 "India demographics, England age-specific health") ///
    ring(0) pos(11) cols(1) region(lcolor(black)) size(small) symxsize(5) bm(tiny)) ///
    xscale(range(18 90)) xlabel(20 40 60 80) ylabel(0 1 2 3 4) 
graphout mort_density_full, pdf
