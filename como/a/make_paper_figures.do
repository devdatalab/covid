/******************************************************/
/* Compare England and India Prevalence of Biomarkers */
/******************************************************/
use $tmp/prev_compare, clear

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
    lab(3 "Uncontrolled Diabetes (Englamd)") ///
    lab(4 "Controlled Diabetes (England)"))
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
    lab(3 "Uncontrolled Hypertension (England)") ///
    lab(4 "Controlled Hypertension (England)"))
graphout hypertension

/* obesity comparison */
twoway ///
    (line i_obese age, lwidth(medthick) lcolor(gs2) lpattern(solid)) ///
    (line u_obese age, lwidth(medthick) lcolor(orange) lpattern(solid)) ///
    , name(obese, replace) xtitle("Age") ytitle("Prevalence") ///
    legend(size(vsmall) rows(2) ///
    lab(1 "Obese (India)") ///
    lab(2 "Obese (England)"))
graphout obese

graph combine diabetes hypertension obese, rows(2)
graphout biomarker_uk_india

/*****************************************/
/* compare health condition risk factors */
/*****************************************/

/* open analysis file */
use $tmp/como_analysis, clear
sort age

/* compare India and UK health condition risk factors */
// scp prr_h_india_full_cts prr_h_uk_os_full_cts prr_h_uk_nhs_matched_full_cts prr_h_uk_nhs_full_cts, ///
//     ytitle("Aggregate Contribution to Mortality from Risk Factors") ///
//     legend(lab(1 "India") lab(2 "UK OpenSafely Coefs") lab(3 "UK full matched") lab(4 "UK full full")) name(prr_health_all)

/* india vs. uk matched */

twoway ///
    (line prr_h_india_full_cts age, lwidth(medthick) lcolor(black)) ///
    (line prr_h_uk_nhs_matched_full_cts age, lwidth(medthick) lcolor(orange)), ///
    ytitle("Aggregate Contribution to Mortality from Risk Factors") xtitle("Age") ///
    legend(lab(1 "India") lab(2 "England") ring(0) pos(5) cols(1) size(small) symxsize(5) bm(tiny) region(lcolor(black))) ///
    name(prr_health, replace)  ylabel(1(.5)4) 
graphout prr_health

/* NY hazard ratios */
twoway ///
    (line prr_h_india_ny age, lwidth(medthick) lcolor(black)) ///
    (line prr_h_uk_nhs_matched_ny age, lwidth(medthick) lcolor(gs8) lpattern(-)), ///
    title("NY State Hazard Ratios") ytitle("Risk Factor from Population Health Conditions") xtitle("Age") ///
    legend(lab(1 "India") lab(2 "England") ring(0) pos(5) cols(1) region(lcolor(black))) ///
    name(prr_health_ny, replace)  ylabel(1(.5)4)
graphout prr_health_ny

/* NY-Cummings HRs */
twoway ///
    (line prr_h_india_nycu age, lwidth(medthick) lcolor(black)) ///
    (line prr_h_uk_nhs_matched_nycu age, lwidth(medthick) lcolor(gs8) lpattern(-)), ///
    title("NY (Cummings) Hazard Ratios") ytitle("Risk Factor from Population Health Conditions") xtitle("Age") ///
    legend(lab(1 "India") lab(2 "England") ring(0) pos(5) cols(1) region(lcolor(black))) ///
    name(prr_health_nycu, replace)  ylabel(1(.5)6)
graphout prr_health_nycu

// graph combine prr_health prr_health_ny prr_health_nycu, cols(3) ycommon
// graphout prr_combined


// /*************************************/
// /* compare age * health risk factors */
// /*************************************/
// /* compare three UK models: OS fixed age, full-prevalences, simp */
// sc prr_all_uk_os_simp_cts prr_all_uk_os_full_cts prr_all_uk_nhs_matched_full_cts prr_all_uk_nhs_full_cts, ///
//     legend(lab(1 "Simp") lab(2 "Full O.S. coefs") lab(3 "Full (matched conditions)") lab(4 "Full (all conditions)")) name(prr_uk_compare) yscale(log)
// 
// /* full vs. full, India vs. UK */
// sc prr_all_india_full_cts prr_all_uk_nhs_matched_full_cts, ///
//     name(prr_all_full) yscale(log) legend(lab(1 "India") lab(2 "UK"))
// 
// /* simp vs. simp, India vs. UK */
// sc prr_all_india_simp_cts prr_all_uk_nhs_simp_cts, ///
//     name(prr_all_simp) yscale(log) legend(lab(1 "India") lab(2 "UK"))


/*********************/
/* Mortality Density */
/*********************/
/* open the simple data */
use $tmp/mort_density_simp, clear

// /* plot uk vs. india death density, simp */
// sort age
// label var age "Age"
// twoway ///
//     (line uk_simp_deaths    age, lcolor(orange) lwidth(medium) lpattern(.-))     ///
//     (line india_simp_deaths age, lcolor(gs8) lpattern(-) lwidth(medthick))       ///
//     , ytitle("Distribution of Deaths" "Normalized population: 100,000") xtitle(Age)  ///
//     legend(lab(1 "England (simp)") ///
//     lab(2 "India (simp)"))
// graphout mort_density_simp

/* open the full data */
use $tmp/mort_density_full, clear

/* same graph, full model */
twoway ///
    (line india_full_deaths age if age <= 89, lcolor(black) lpattern(solid) lwidth(thick))       ///
    (line uk_full_deaths    age if age <= 89, lcolor(orange) lwidth(thick) lpattern(solid))     ///
    (line in_deaths_old     age if age <= 89, lcolor(black) lwidth(medium) lpattern(-))     ///
    (line en_deaths         age if age <= 89, lcolor(orange) lwidth(medium) lpattern(-))     ///
    , ytitle("Density Function of Deaths (%)") xtitle(Age)  ///
    legend(lab(1 "India (model)") ///
    lab(2 "England (model)") lab(3 "India (reported)") lab(4 "England (reported)") ///
    ring(0) pos(11) cols(2) region(lcolor(black)) size(small) symxsize(5) bm(tiny)) ///
    xscale(range(18 90)) xlabel(20 40 60 80) ylabel(.01 .02 .03 .04 .044) 
graphout mort_density_full

// /* all 4 lines */
// twoway ///
//     (line uk_simp_deaths    age, lcolor(orange) lwidth(medium) lpattern(-))        ///
//     (line india_simp_deaths age, lcolor(gs8) lpattern(-) lwidth(medthick))         ///
//     (line uk_full_deaths      age, lcolor(orange) lwidth(medium) lpattern(solid))    ///
//     (line india_full_deaths   age, lcolor(gs8) lpattern(solid) lwidth(medthick))     ///
//     , ytitle("Distribution of Deaths" "Normalized population: 100,000") xtitle(Age)  ///
//     legend(lab(1 "England (simp)") lab(2 "India (simp)") ///
//     lab(3 "England (full)") lab(4 "India (full)"))
// graphout mort_density_all

/* graph ny and nycu results  */
twoway ///
    (line uk_ny_deaths    age if age <= 89, lcolor(gs8) lwidth(medium) lpattern(-))     ///
    (line india_ny_deaths age if age <= 89, lcolor(black) lpattern(solid) lwidth(medthick))       ///
    (line mh_deaths         age if age <= 89, lcolor(orange) lwidth(medium) lpattern(.-))     ///
    (line en_deaths         age if age <= 89, lcolor(gs14) lwidth(medium) lpattern(.-))     ///
    , ytitle("Density Function of Deaths (%)") xtitle(Age)  ///
    title("NY State Age-specific ORs") legend(lab(1 "England (model)") ///
    lab(2 "India (model)") lab(3 "Maharasthra (reported)") lab(4 "England (reported)") ///
    ring(0) pos(11) cols(1) region(lcolor(black))) ///
    xscale(range(18 90)) xlabel(20 40 60 80) ylabel(.01 .02 .03 .04 .044)
graphout mort_density_ny
twoway ///
    (line uk_nycu_deaths    age if age <= 89, lcolor(gs8) lwidth(medium) lpattern(-))     ///
    (line india_nycu_deaths age if age <= 89, lcolor(black) lpattern(solid) lwidth(medthick))       ///
    (line mh_deaths         age if age <= 89, lcolor(orange) lwidth(medium) lpattern(.-))     ///
    (line en_deaths         age if age <= 89, lcolor(gs14) lwidth(medium) lpattern(.-))     ///
    , ytitle("Density Function of Deaths (%)") xtitle(Age)  ///
    title("NY (Cummings) HRs") legend(lab(1 "England (model)") ///
    lab(2 "India (model)") lab(3 "Maharasthra (reported)") lab(4 "England (reported)") ///
    ring(0) pos(11) cols(1) region(lcolor(black))) ///
    xscale(range(18 90)) xlabel(20 40 60 80) ylabel(.01 .02 .03 .04 .044)
graphout mort_density_nycu

// graph combine density density_ny density_nycu, rows(1)
// graphout mort_combined

/********************/
/* Coefficient Plot */
/********************/
/* isolate risk vars for plot */
import delimited $ddl/covid/como/a/covid_como_sumstats.csv, clear
keep if strpos(v1, "ratio") != 0
drop if strpos(v1, "sign") != 0
drop if v1 == "health_ratio"
ren v1 variable
ren v2 coef
save $tmp/coefs_to_plot, replace
shell python $ccode/como/a/make_coef_plot.py
