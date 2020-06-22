global idi $iec/covid/idi_survey

/* use most recent data */
use $idi/round1/wb1_cleaned_dataset_2020-06-02, clear

/* declare survey data */
svyset psu [pw=weight_hh], strata(strata_id) singleunit(scaled)

/* install commands used frequently in do file */
ssc install fre
ssc install ietoolkit

/* merge to shrug data */
merge m:1 shrid using $idi/survey_shrid_data, keep(match master) nogen
/* 70 obs with missing shrid didn't match */
/* 2 obs with shrid 11-10-244076 didn't match, not present in shrug data */

/* gen no weight condition for robustness check of results */
gen no_weight = 1

/* generate earnings */
gen lab_march_earn = lab_march_wage * lab_march_freq
gen lab_curr_earn = lab_curr_wage * lab_curr_freq
gen lost_earn = lab_curr_earn - lab_march_earn
gen lab_earn_change = lost_earn/lab_march_earn

/* migrants ratio */
gen mig_ratio = mig_total_ratio/demo_hh_size

/* label variables */
la var lab_march_earn "Pre-lockdown weekly earning"
la var lab_curr_earn "Post-lockdown weekly earning"
la var lab_earn_change "% change in weekly earnings"
label define gt 0 "No transfer" 1 "Received a govt transfer"
label values rel_govt_transfer_fa_prop gt

/* nrega */
label define n 0 "NREGA available" 1 "NREGA unavailable"
label values rel_nrega_unavail_prop n
la var rel_nrega_unavail_prop "NREGA availability"

/* distribution */
hist lab_wagechange_mean if lab_wagechange_mean < 1 & lab_curr_wage != 0, saving(l_w) xtitle("Labor wage % change") bin(10) ylabel(0(.5)4,grid) xlabel(-1(.2)1) normal
hist mig_wage_change_mean if mig_daily_wage != 0, saving(m_w) xtitle ("Migrant wage % change") bin(10) ylabel(0(.5)4,grid) xlabel(-1(.2)1) normal

graph combine "l_w" "m_w"
graphout lmwchng

/* replace as missing category - self employed in agriculture as these are non agri households */
foreach x of var *occu {
  replace `x' = . if `x' == 1
}


/* replace labor and migrant income and earnings as percentage changes */
foreach x of var lab_workdayschange_mean lab_earn_change mig_wage_change_mean{
  gen `x'_og = `x'
  replace `x' = `x' * 100
  }

/* converat agr price and input change into % changes */
foreach x of var agr_prc_change_yr_mean agr_inputs_change_abs_mean {
  gen `x'_og = `x'
  replace `x' = `x' * 100
  }
  
/* the following analysis is being done with and without weights - so in a loop */
forval i = 0/2{

  /* declare various weight conditions */
  if `i' == 0 local wt [aw = no_weight]
  if `i' == 1 local wt [aw = weight_hh]
  if `i' == 2 local wt [aw = no_weight]

  /* declare conditon for just keeping obs to Rajasthan, Jharkhand */
  if `i' == 2 {
    preserve

    keep if inlist(geo_state, 8, 20)
  }
  
  /* days worked per week pre and post lockdown */
  binscatter lab_curr_freq lab_march_freq `wt' if lab_curr_occu != 0, ytitle("Post-lockdown workdays") xtitle("Pre-lockdown workdays") ylabel(0 (1) 7) xlabel(0 (1) 7)
  graphout pre_post_wd_`i'

  /* days worked per week pre and post by occupation  */
  binscatter lab_curr_freq lab_march_freq `wt' if lab_curr_occu != 0, ytitle("Post-lockdown workdays") xtitle("Pre-lockdown workdays")  by(lab_march_occu) ylabel(0 (1) 7) xlabel(0 (1) 7)
  graphout pre_post_wd_cat_`i'

  /* earnings per week pre and post lockdown */
  binscatter lab_curr_earn lab_march_earn `wt' if lab_curr_occu != 0 & lab_curr_earn < 10000 & lab_march_earn < 10000, ytitle("Postlockdown earnings") xtitle("Prelockdown earnings") ylabel(0 (2000) 10000) xlabel(0 (2000) 10000)
  graphout pre_post_e_`i'

  /* earnings per week pre and post by occupation */
  binscatter lab_curr_earn lab_march_earn `wt' if lab_curr_occu != 0 & lab_curr_earn < 10000 & lab_march_earn < 10000, ytitle("Postlockdown earnings") xtitle("Prelockdown earnings")  by(lab_march_occu) ylabel(0 (2000) 10000) xlabel(0 (5000) 10000)
  graphout pre_post_cat_e_`i'

  /* shrid variables */
  foreach x of var pc11_pca_agr_work_share tdist* landless_share ec13_nonfarm_emp_per_capita {
    local lab: variable label `x'
    binscatter lab_earn_change `x' `wt', ytitle("% Change in weekly earnings") xtitle("`lab'", margin(medium))
    graphout le_`x'_`i'
    binscatter lab_workdayschange_mean `x' `wt', ytitle("% Change in days worked per week") xtitle("`lab'", margin(medium))
    graphout lw_`x'_`i'
  }

  /* land per working person */
  binscatter lab_earn_change land_acres_per_capita `wt' if land_acres_per_capita < 5, ytitle("% Change in weekly earnings") xtitle("Land acres available per working person")
  graphout le_lac_`i'

  /* note: the binscatter below won't run for sub-sample restricted to Raj/JK, Ns get too low */
  binscatter lab_workdayschange_mean land_acres_per_capita `wt' if land_acres_per_capita < 5, ytitle("% Change in days worked per week") xtitle("Land acres available per working person")
  graphout lw_lac_`i'

  /* relief and pre and post covid earnings */
  binscatter rel_amt_received_mean lab_curr_earn `wt' if lab_curr_occu != 0 & lab_curr_earn < 10000, ytitle("Relief amount received") xtitle("Post-lockdown earnings") xlabel(0 (2000) 10000)
  graphout rel_curr_earn_`i'

  binscatter rel_amt_received_mean lab_march_earn `wt' if lab_curr_occu != 0 & lab_march_earn < 10000, ytitle("Relief amount received") xtitle("Pre-lockdown earnings") xlabel(0 (2000) 10000)
  graphout rel_mar_earn_`i'

  if `i' == 2 {
    restore
  }
}

/* distribution of total days worked */
foreach i in march curr {

  /* total days worked by sample */
  egen total_`i'_wd = sum(lab_`i'_freq)

  /* total days worked by each worker type */
  bys lab_curr_occu: egen `i'_wf = sum(lab_`i'_freq)

  /* share of days worked by worker type */
  gen `i'_wd_share = `i'_wf/total_`i'_wd
}

/* how are total workdays in economy pre/post lockdown distributed by worker type */
graph hbar march_wd_share [aw = weight_hh], over(lab_march_occu) saving(wd_1) ytitle("Pre-lockdown workdays") ylabel(0 (0.2) 0.8)
graph hbar curr_wd_share [aw = weight_hh], over(lab_curr_occu) saving(wd_2) ytitle("Post-lockdown workdays") ylabel(0 (0.2) 0.8)

graph combine "wd_1" "wd_2"
graphout workdays

/* relief, earnings and workdays change by labor  */
foreach x in rel_amt_received_mean lab_workdayschange lab_earn_change{
  cibar `x', over(lab_march_occu) barcolor(black maroon olive sienna sand) graphopts(xtitle("pre-lockdown occupation") name(`x', replace))
  }

graph combine lab_workdayschange lab_earn_change rel_amt_received_mean, xcommon
graphout relief_loss

/* relief and earnings by distance */
foreach i in lab_workdayschange rel_amt_received_mean{
  local lab: variable label `i'
  binscatter `i' tdist_100 [aw = weight_hh], ytitle("`lab'") xtitle("Min dist.(km) to nearest place with pop>100k", margin(medium))saving(`i'_tdi100) 
}

graph combine "lab_workdayschange_tdi100" "rel_amt_received_mean_tdi100"
graphout rel_earn_distance

/* Relief and distance to nearest town */
binscatter rel_amt_received_mean tdist_100 [aw = weight_hh], xtitle("Min dist. (km) to nearest place with population > 100k (including self") ytitle("Mean relief amount received")
graphout rel_distance

/* nrega */
graph hbar rel_nrega_unavail_prop, over(geo_state) ytitle("% of hh reporting unavailability of NREGA")
graphout nrega_stat

cibar lab_workdayschange_mean [aw = weight_hh], over(rel_nrega_unavail_prop) barcolor(black sand) 
graphout n_lw

/* relief per week, lost earnings per week */
graph bar lost_earn rel_amt_received, ylabel(-5000 (1000) 5000) legend(lab(1 "Lost earnings per week") lab(2 "Relief amount received across past 4 weeks"))
graphout relief_loss_earn

/* relief and spending on ag */
cibar agr_inputs_change_abs_mean [aw = weight_hh], over(rel_govt_transfer_fa_prop) barcolor(black sand) graphopts(ytitle("change in spending on agriculture inputs") name(rel_ag, replace))
cibar agr_inputs_change_abs_mean [aw = weight_hh], over(rel_nrega_unavail_prop) barcolor(black sand) graphopts(ytitle("change in spending on agriculture inputs") name(nreg_ag, replace))

graph combine rel_ag nreg_ag
graphout relief_ag_use

/* mig and ag outputs */
forval i = 0/2{

  /* declare various weight conditions */
  if `i' == 0 local wt [aw = no_weight]
  if `i' == 1 local wt [aw = weight_hh]
  if `i' == 2 local wt [aw = no_weight]

  /* declare conditon for just keeping obs to Rajasthan, Jharkhand */
  if `i' == 2 {
    preserve

    keep if inlist(geo_state, 8, 20)
  }

/* characteristics of households with higher proportion of migrants */  
foreach x of var pc11_pca_agr_work_share tdist_100 landless_share ec13_nonfarm_emp_per_capita {
  local lab: variable label `x'

  binscatter mig_ratio `x' `wt', ytitle("Migrant: HH size ratio") xtitle("`lab'", margin(medium))
  graphout mr_`x'_`i'

  }

/* Inputs and prices */
  binscatter agr_prc_change_yr_mean agr_inputs_change_abs_mean `wt', ytitle("% change in price of crops") xtitle("% change in expenditure on inputs", margin(medium))
  graphout inputs_price_`i'

/* prices and distance to towns */
  binscatter agr_prc_change_yr_mean tdist_100 `wt', ytitle("% change in price of crops") xtitle("Min. distance to nearest place with population > 100k (inc. self)", margin(medium))
  graphout price_dist_`i'

/* above plot by crop category */
  binscatter agr_prc_change_yr_mean tdist_100 `wt', by(agr_crop_cat_prop)  ytitle("% change in price of crops") xtitle("Min. distance to nearest place with population > 100k (inc. self)", margin(medium))
  graphout price_crops_`i'

  if `i' == 2 {
    restore
  }
}

/* histogram for distance to nearest place */
sum tdist_100
hist tdist_100, xtitle("Distance to nearest town (Pop more than 100k)") bin(10) caption("Mean: 40.65 km")
graphout distance

