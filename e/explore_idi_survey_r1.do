global idi $iec/covid/idi_survey

/* use most recent data */
use $idi/round1/wb1_cleaned_dataset_2020-06-02, clear

/* declare survey data */
svyset psu [pw=weight_hh], strata(strata_id) singleunit(scaled)

/* install commands used frequently in do file */
ssc install fre
ssc install ietoolkit

/*******************/
/* Validity checks */
/*******************/

gen flag = 0

/* 6 more than 80 year olds */
replace flag = 1 if demo_age >= 80 & !mi(demo_age)

/* Note: disproportionately backward caste */

/* migrants and hh members */
replace flag = 1 if mig_size >= demo_hh_size & demo_hh_size != 0

/* check if anything valuable is in the other option */
tab lab_march_occu_oth

/* outliers in wage */
sum *wage, d

/* valuable information in other option */
tab lab_nowork_oth
tab agr_crop_grown_oth

/* 144 obs where individual checked bank balance before march and */
/* mentioned receiving gov transfer in past four weeks - should I flag these? */
fre rel_check_balance if rel_transfer_rec == 1


/*************/
/* Exploring */
/*************/

/* migrants still stuck */
gen mig_stuck = mig_noreturn_ratio/mig_total_ratio
tab geo_state if mig_stuck != 0 & !mi(mig_stuck)

/* migrants ratio */
gen mig_ratio = mig_total_ratio/demo_hh_size

/* association between consumption and migration in agri/non agri hh */
binscatter mig_wage_change_mean con_weekchange_mean if demo_ag_hh == 0
graphout migwage_effect_non_agri

binscatter mig_wage_change_mean con_weekchange_mean if demo_ag_hh == 1
graphout migwage_effect_agri

/* characteristics of households reporting consumption decline */
gen condecline = con_weekchange_mean < 0 & !mi(con_weekchange_mean)
iebaltab demo_ag_hh mig_return_size mig_noreturn_ratio mig_most_inc mig_avg_wage mig_zeroinc_prop mig_wage_change_mean mig_size con_feb demo_hh_size lab_wagechange_mean lab_workdayschange_mean rel_transfer_rec, grpvar(condecline) save($tmp/balance.xlsx) replace

/* consumption associations */
binscatter con_weekchange_mean agr_prc_change_yr_mean
graphout inputchange

drop flag mig_stuck condecline


/*****************************/
/* Analysis using shrug data */
/*****************************/

/* merge to shrug data */
merge m:1 shrid using $idi/survey_shrid_data, keep(match master) nogen
/* 70 obs with missing shrid didn't match */
/* 2 obs with shrid 11-10-244076 didn't match, not present in shrug data */

/* label values prior to analysis */
label define road 0 "no road" 1 "has road"
label values rural_road road

/* consumption levels */
foreach x of var con_feb con_wk con_weekchange_mean {
  binscatter `x' pc11_pca_agr_work_share [aw = weight_hh]
  graphout `x'_ag
}

/* consumption decline and share of workforce in agri + roads */
binscatter con_weekchange_mean pc11_pca_agr_work_share [aw = weight_hh], by(rural_road)
graphout con_ag_share_road

/* consumption decline and landless share */
binscatter con_weekchange_mean landless_share [aw = weight_hh]
graphout con_landless

/* consumption decline and size of landholding */
binscatter con_weekchange_mean land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 3.5
graphout con_landsize

/* consumption and non farm jobs per capita */
binscatter con_weekchange_mean ec13_nonfarm_emp_per_capita [aw = weight_hh]
graphout con_nonfarmem_share

/* consumption and roads */
cibar con_weekchange_mean, over(rural_road) barcolor(teal black)
graphout con_roads

/* consumption and religion */
cibar con_weekchange_mean [aw = weight_hh], over(demo_religion) barcolor(teal black)
graphout con_rel

/* Relief */

/* Relief and ag share */
binscatter rel_amt_received_mean pc11_pca_agr_work_share [aw = weight_hh], absorb(geo_state)
graphout relief_ag

/* Relief and pre covid consumption */
binscatter rel_amt_received_mean con_feb [aw = weight_hh], absorb(geo_state) 
graphout relief_confeb

/* Relief and distance to city */
binscatter rel_amt_received_mean tdist_100 [aw = weight_hh], absorb(geo_state)
graphout relief_dist

/* Price of perishables */

/* onion price and distance */
binscatter con_onionschange_mean tdist_100 [aw = weight_hh], absorb(geo_state)
graphout price_onion_dist

/* atta price and distance */
binscatter con_attachange_mean tdist_100 [aw = weight_hh], absorb(geo_state)
graphout price_atta_dist

/* onion price and roads */
binscatter con_onionschange_mean tdist_100 [aw = weight_hh], absorb(geo_state) by(rural_road)
graphout price_onions_dist_road

/* atta price and roads */
binscatter con_attachange_mean tdist_100 [aw = weight_hh], absorb(geo_state) by(rural_road)
graphout price_atta_dist_road

/* Inputs and prices */
binscatter agr_prc_change_yr_mean agr_inputs_change_abs_mean [aw = weight_hh], absorb(geo_state)
graphout inputs_price

/* prices and distance to city */
binscatter agr_prc_change_yr_mean tdist_100 [aw = weight_hh], absorb(geo_state)
graphout price_dist

/* above plot by crop category */
binscatter agr_prc_change_yr_mean tdist_100 [aw = weight_hh], by(agr_crop_cat_prop) absorb(geo_state)
graphout price_crops

/* Migration */

/* consumption and migrant size of households */
binscatter con_weekchange_mean mig_ratio [aw = weight_hh]
graphout migsize_con

/* migration size and agriculture work share */
binscatter mig_ratio pc11_pca_agr_work_share [aw = weight_hh]
graphout migsize_ag

/* mig wage change */
binscatter mig_wage_change_mean land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 3.5, absorb(geo_state)
graphout mig_wage

/* Wage change */

/* wage change and labor surplus */
binscatter lab_wagechange_mean land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 3.5, absorb(geo_state)
graphout labsurplus

/* wage change and shrid vars */
binscatter lab_wagechange_mean ec13_nonfarm_emp_per_capita [aw = weight_hh], absorb(geo_state)
graphout labnonfarm

/* what determines consumption change */
svy: reg con_weekchange_mean pc11_pca_agr_work_share landless_share rel_amt_received_mean tdist_100 land_acres_per_capita demo_hh_size i.geo_state
coefplot
graphout reg


/*************************/
/* Analysis - 2020-06-03 */
/*************************/

cd $tmp

/* lab wage change and mig wage change */

/* distribution */
kdensity lab_wagechange_mean [aw = weight_hh], saving(lw) title("labor wage perc change") replace
kdensity mig_wage_change_mean [aw = weight_hh], saving(mw) title ("mig wage perc change") replace

graph combine "lw" "mw"
graphout lmwchng

/* means */
graph bar lab_wagechange_mean mig_wage_change_mean if lab_curr_wage!=0 & mig_daily_wage !=0 [aw = weight_hh]
graphout l_m_w_c

/* labour days worked */
kdensity lab_workdayschange_mean [aw = weight_hh] if lab_curr_wage !=0, title("% change in work freq. (days per week)")
graphout ldw

/* labour wage change by current occupation category */
cibar lab_wagechange_mean [aw = weight_hh], over(lab_curr_occu) barcolor(black teal blue green yellow maroon)
graphout lw_o

/* labour wage change by current occupation category */
cibar lab_workdayschange_mean [aw = weight_hh], over(lab_curr_occu) barcolor(black teal blue green yellow maroon)
graphout ld_o

/* labour wage change by caste, states, religion */
foreach x of var demo_caste demo_religion geo_state {
  cibar lab_wagechange_mean [aw = weight_hh], over(`x')
  graphout lw_`x'
  }

/* labour wage change and shrid variables */
foreach x of var pc11_pca_agr_work_share tdist* landless_share ec13_nonfarm_emp_per_capita {
  binscatter lab_wagechange_mean `x' [aw = weight_hh]
  graphout lw_`x'
}

binscatter lab_wagechange_mean land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 5, absorb(geo_state)
graphout lw_lac

/* became unemployed */
gen lost_job = lab_curr_occu == 0 & lab_march_occu != 0 & !mi(lab_march_occu)

/* total employed back in the day */
gen prev_emp = lab_march_occu != 0 & !mi(lab_march_occu)

/* village level analysis */
bys shrid: egen lost_job_subtotal = sum(lost_job)
bys shrid: egen total_prev_emp = sum(prev_emp)

/* generate labor force exit prop */
gen became_unemp_share = lost_job_subtotal/total_prev_emp

/* became unemployed vs shrid vars */
foreach x of var pc11_pca_agr_work_share tdist_100 landless_share ec13_nonfarm_emp_per_capita {
  binscatter became_unemp_share `x' [aw = weight_hh]
  graphout u_`x'
}

binscatter became_unemp_share land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 5, absorb(geo_state)
graphout u_lac

/* pre lockdown occupations for those unemployed today */
catplot lab_march_occu if lab_curr_occu == 0, perc
graphout pre_post

cibar lab_wagechange_mean if lab_march_occu != 0, over(lab_march_occu) barcolor(black maroon olive sienna sand) graphopts(xtitle("pre-lockdown occupation"))
graphout pre_wc

cibar lab_workdayschange_mean if lab_march_occu != 0, over(lab_march_occu) barcolor(black maroon olive sienna sand) graphopts(xtitle("pre-lockdown occupation"))
graphout pre_wd

/* characteristics of households with higher proportion of migrants */
foreach x of var pc11_pca_agr_work_share tdist_100 landless_share ec13_nonfarm_emp_per_capita {
  binscatter mig_ratio `x' [aw = weight_hh], absorb(geo_state)
  graphout mr_`x'
}

binscatter mig_ratio land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 5, absorb(geo_state)
graphout mr_lac

/* migrant wage change and consumption */
binscatter con_weekchange_mean mig_wage_change_mean [aw = weight_hh], absorb(geo_state)
graphout con_mw

/* mig wage change and ag status of hh */
cibar mig_wage_change_mean [aw = weight_hh], over(demo_ag_hh) barcolor(teal black)
graphout mw_ag

/* plot above by ag/non ag status of hh */
binscatter con_weekchange_mean mig_wage_change_mean [aw = weight_hh], absorb(geo_state) by(demo_ag_hh)
graphout con_mw_ah

/* Is relief going to poorest hh and areas */
foreach x of var pc11_pca_agr_work_share tdist* landless_share ec13_nonfarm_emp_per_capita {
  binscatter rel_amt_received_mean `x' [aw = weight_hh], absorb(geo_state)
  graphout rel_`x'
}

binscatter rel_amt_received_mean land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 5, absorb(geo_state)
graphout rel_lac

/* plot relief amount received by pre-lock down occupation */
cibar rel_amt_received_mean, over(lab_march_occu) barcolor(black maroon olive sienna sand) graphopts(xtitle("pre-lockdown occupation"))
graphout rel_pre_occ

label define gt 0 "No transfer" 1 "Received a govt transfer"
label values rel_govt_transfer_fa_prop gt

/* relief amount received and possible use? */
foreach x of var con_weekchange_mean agr_inputs_change_abs_mean agr_borrow_change_abs_mean {
  cibar `x' [aw = weight_hh], over(rel_govt_transfer_fa_prop) barcolor(black sand)
  graphout r_`x'
  }

/* nrega */
label define n 0 "NREGA available" 1 "NREGA unavailable"
label values rel_nrega_unavail_prop n
la var rel_nrega_unavail_prop "NREGA availability"

catplot rel_nrega_unavail_prop, over(geo_state) perc(geo_state) 
graphout nrega_stat

cibar lab_workdayschange_mean [aw = weight_hh], over(rel_nrega_unavail_prop) barcolor(black sand)
graphout n_lw

cibar mig_total_ratio [aw = weight_hh], over(rel_nrega_unavail_prop) barcolor(black sand)
graphout n_m



