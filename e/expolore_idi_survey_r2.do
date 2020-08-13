global idi ~/iec/covid/idi_survey/round2

/* import data */
use $idi/wb2_cleaned_2020_08_07, clear

/* relabel demo_ag_hh var for easy interpretation on graphs */
label define a 0 "Non-ag household" 1 "Ag household"
label values demo_ag_hh_r2 a

/* create earnings variables */
foreach t in lckdwn curr{
  gen lab_`t'_earn_r2 = lab_`t'_wage_r2 * lab_`t'_freq_mean_r2
}

/* earnings change between lckdwn and r2 */
gen earn_change_r2 = (lab_curr_earn_r2 - lab_lckdwn_earn_r2) / lab_lckdwn_earn_r2

/* top code earnings change */
sum earn_change_r2, d
replace earn_change_r2 = . if earn_change_r2 > r(p95)

/* label earnings change */
la var earn_change_r2 "% change in earnings since lockdown"

/* gen indicator variable for whether an individual faced difficulty in fert purchase */
gen fert_diff = agr_fert_diffs_none_prop_r2

label define df 1 "Faced no difficulty" 0 "Faced dificulty"
label values fert_diff ft

/* 2 obs in r2 have negative weights - drop them */
drop if weight_hh_r2 < 0

/* set scheme */
set scheme pn

/**********/
/* Labour */
/**********/

/* 1. What are those who were unemployed in the previous round doing now? */
tab lab_curr_occu_r2 if lab_curr_occu_r1 == 0
tab demo_ag_hh_r2 if lab_curr_occu_r1 == 0

/* clone current occupation variable */
gen r2_occ = lab_curr_occu_r2
replace r2_occ = 6 if lab_curr_occu_r1 == 0 & demo_ag_hh_r2 == 1
replace r2_occ = . if r2_occ < 0

/* label values */
label define r2 0 "Unemployed" 1 "Self-employed non-ag" 2 "Salaried pvt" 3 "Salaried govt" 4 "Daily wage ag" 5 "Daily wage non-ag" 6 "Working on own farm" 99 "Other"
label values r2_occ r2

/* plot */
la var r2_occ " "
catplot r2_occ if lab_curr_occu_r1 == 0, title("Current occupation of sample unemployed during lockdown", margin(medium))
graphout lab_then_now

/* 2. Labour market status since lockdown remains bleak  */
graph bar lab_freq_change_r2 lab_wagechange_mean_r2 earn_change_r2 if inlist(lab_curr_occu_r2, 1, 2, 3, 4, 5) [aw = weight_hh_r2], ytitle("% change since lockdown", margin(small)) bargap(20) legend(label(1 "Weekly workdays change") label(2 "Daily wage change") label(3 "Weekly earnings change"))
graphout lab_status

/* 3. Who is still getting work */
cibar lab_freq_change_r2 if inlist(lab_curr_occu_r2, 1, 2, 3, 4, 5) [aw = weight_hh_r2], over(lab_curr_occu_r2) graphopts(ytitle("% change in weekly workdays since lockdown"))
graphout recovery

/***************/
/* Agriculture */
/***************/

/* 1. general state of agriculture */
graph bar agr_land_change_mean_r2 agr_fert_cost_mean_r2 agr_borrow_mean_r2 agr_borrow_kcc_mean_r2 [aw = weight_hh_r2], ytitle("% change since last season") legend(label(1 "Planned land for kharif cultivation") label(2 "Fertilizer spending") label(3 "Borrowing") label(4 "Borrowing - KCC")) ylabel(-0.25 (0.05) 0.1)
graphout ag_stat

/* 2. fertilizers */
graph bar fert_diff agr_fert_price_all_inc_prop_r2 [aw = weight_hh_r2], bar(1, color(green)) bar(2, color(red)) bargap(30) legend(label( 1 "Faced no difficulty in fertilizer purchase") label(2 "Reported a price increase of fertilizers")) ytitle("Percentage", margin(small)) ylabel(0 (0.1) 0.6, grid)
graphout fert

/* 3. planned land for cultivation, by state */
ciplot agr_land_change_mean_r2 [aw = weight_hh_r2], by(state) xtitle("State") ytitle("% change in land planned for kharif cultivation")
graphout state_land

/* 4. graphs to show ag households are doing well */
cibar con_limit_wk_reduce_prop_r2 [aw = weight_hh_r2], over(demo_ag_hh_r2) graphopts(ytitle("Reduced proportion size of meals in the last week") ylabel(0 (0.02) 0.2) name(food_1, replace))
cibar con_limit_wk_out_prop_r2 [aw = weight_hh_r2], over(demo_ag_hh_r2) graphopts(ytitle("Ran out of food in the last week") ylabel(0 (0.02) 0.2) name(food_2, replace))
graph combine food_1 food_2, ycommon
graphout ag_better

/* 5. relief diff between ag/non-ag households */
ciplot rel_amt_received_mean_r2 [aw = weight_hh_r2], by(demo_ag_hh_r2) xtitle(" ") name(relief_amt, replace)
graphout relief_amt








