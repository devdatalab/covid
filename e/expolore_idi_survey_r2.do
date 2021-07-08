global idi ~/iec/covid/idi_survey

/* import data */
use $idi/wb_r1_r2_wide_08_14, clear

/* drop if negative weights */
drop if weight_hh_r2 < 0

/* relabel demo_ag_hh var for easy interpretation on graphs */
label define a 0 "Non-ag household" 1 "Ag household"
label values demo_ag_hh_r2 a

/* create earnings variables */
gen lab_mar_earn = lab_march_wage_r1 * lab_march_freq_r1
gen lab_curr_earn_r1 = lab_curr_wage_r1 * lab_curr_freq_r1
gen lab_curr_earn_r2 = lab_curr_wage_r2 * lab_curr_freq_mean_r2
gen lab_lckdwn_earn_r2 = lab_lckdwn_wage_r2 * lab_lckdwn_freq_mean_r2

/* top code earnings variables */
forval i = 1/2 {
  foreach x of var *earn*r*`i' {
   sum `x' [aw = weight_hh_r`i'], d
   replace `x' = . if `x' > r(p95)
  }
}

/* earnings change between lckdwn and r2 */
gen earn_change_r2 = (lab_curr_earn_r2 - lab_lckdwn_earn_r2) / lab_lckdwn_earn_r2
gen earn_change_r1 = (lab_lckdwn_earn_r2 - lab_mar_earn) / lab_mar_earn

/* calculate freq change for r1 */
gen lab_freq_change_r1 = (lab_curr_freq_r1 - lab_march_freq_r1)/lab_march_freq_r1

/* activate line below for doing analysis for same sample */
replace earn_change_r2 = . if r1_r2 != 1
replace lab_freq_change_r2 = . if r1_r2 != 1

/* label earnings change */
la var earn_change_r2 "% change in earnings since lockdown"
la var earn_change_r1 "% change in earnings march-lockdown"

/* gen indicator variable for whether an individual faced difficulty in fert purchase */
gen fert_diff = agr_fert_diffs_none_prop_r2

label define df 1 "Faced no difficulty" 0 "Faced dificulty"
label values fert_diff ft

/* set scheme */
set scheme pn
stop
/**********/
/* Labour */
/**********/

/* 1. changes across time */

/* save relevant values as locals for time series graph */
forval i = 1/2{
  
 sum earn_change_r`i' if inlist(lab_curr_occu_r`i', 1, 2, 3, 4, 5, 99) [aw = weight_hh_r`i']
 local earn_change_r`i' `r(mean)'

 sum lab_freq_change_r`i' if inlist(lab_curr_occu_r`i', 1, 2, 3, 4, 5, 99) [aw = weight_hh_r`i'] 
 local lab_freq_change_r`i' `r(mean)'
}

/* save unemp shares */
tab lab_march_occu_r1 [aw = weight_hh_r1]
local unemp_1 0.1695

tab lab_curr_occu_r1 [aw = weight_hh_r1]
local unemp_2 0.6826

tab lab_curr_occu_r2 [aw = weight_hh_r2]
local unemp_3 0.41

preserve

clear

insobs 3

gen time = ""
gen unemp = .
gen earn = .
gen freq = .

/* unemployement shares */
forval i = 1/3{
  replace unemp = `unemp_`i'' in `i'
  }

/* earnings w.r.t march */
foreach x of var earn freq{
 replace `x' = 1 in 1
}

forval i = 1/2{
  local z = `i' + 1
  replace earn = `earn_change_r`i'' in `z'
  replace freq = `lab_freq_change_r`i'' in `z'
}

foreach x of var earn freq{
  replace `x' = `x'[2] + `x'[3] in 3
}

/* format time variable */
replace time = "March, 2020" in 1
replace time = "May, 2020" in 2
replace time = "July, 2020" in 3

gen date = date(time, "MY")
format date %td

/* label variables for graph */
la var earn "Weekly earnings"
la var freq "Weekly work frequency"

/* graph unemployment share across the three months */
tsset date
tsline unemp, recast(connected) , tlabel(, format(%tdmy)) ttitle("Month", margin(medium)) ytitle("Unemployed share") ylabel(0 (0.2) 0.8) name(unemp, replace)
graphout unemployment

/* graph earning change across the three months */
tsline earn freq, recast(connected) , tlabel(, format(%tdmy)) ttitle("Month", margin(medium)) ytitle("Weekly earnings/Work frequency (% points)") name(earn, replace) ylabel(-0.6 (0.1) 0.9) ///
    ttext(1 01mar2020  "2100 Rs" -.1 01may2020 "900 Rs" .4 01jul2020 "1200 Rs", size(small) placement(north) box bcolor(dimgray)) note("Note: Median earnings have been reported for each period.")
graphout lab_changes

restore
 
/* 2. Who is still getting work */
cibar lab_freq_change_r2 if inlist(lab_curr_occu_r2, 1, 2, 3, 4, 5) [aw = weight_hh_r2], over(lab_curr_occu_r2) graphopts(ytitle("% change in weekly workdays since lockdown"))
graphout recovery

cibar earn_change_r2 if inlist(lab_curr_occu_r2, 1, 2, 3, 4, 5) [aw = weight_hh_r2], over(lab_curr_occu_r2) graphopts(ytitle("% change in weekly workdays since lockdown"))
graphout trial

/***************/
/* Agriculture */
/***************/

/* 1. inputs */
graph bar agr_fert_cost_mean_r2 agr_borrow_mean_r2 [aw = weight_hh_r2], ytitle("% change since last season") legend(label(1 "Fertilizer expenditure") label(2 "Borrowing") label(3 "Borrowing") label(4 "Borrowing - KCC")) ylabel(-0.25 (0.05) 0.1) bargap(40) yline(0)
graphout ag_inputs

/* 2. fertilizers */
twoway lfitci agr_fert_cost_mean_r2 agr_borrow_mean_r2 [aw = weight_hh_r2], ytitle("% change in fertilizer expenditure") xtitle("% change in borrowing") yline(0)
graphout borrow_fert

/* regression - internal */
la var agr_borrow_mean_r2 "% change borrow"
la var fert_diff "reported diff. in purchasing fert"
la var agr_land_change_mean_r2 "% change in planned land for cultiv"
la var agr_fert_price_all_inc_prop_r2 "report inc. in all fert prices"
la var agr_fert_price_some_inc_prop_r2 "report inc. in some fert prices"

reg agr_fert_cost_mean_r2 agr_borrow_mean_r2 fert_diff agr*fert*price*inc* [aw = weight_hh_r2], robust
estimates store fert

coefplot fert, drop(_cons) xline(0) xtitle("% change in fert exp")
graphout reg

/* 3. planned land for cultivation, by state */
ciplot agr_land_change_mean_r2 [aw = weight_hh_r2], by(state) xtitle("State") ytitle("% change in land planned for kharif cultivation")
graphout state_land

/* 4. relief diff between ag/non-ag households */
ciplot rel_amt_received_mean_r2 [aw = weight_hh_r2], by(demo_ag_hh_r2) xtitle(" ") name(relief_amt, replace)
graphout relief_amt








