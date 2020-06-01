global idi $iec/covid/idi_survey


use $iec/covid/idi_survey/round1/wb1_cleaned_dataset_2020-05-10, clear

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

/* occupation of non-agri households */
fre lab_march_occu if demo_ag_hh == 0

/* very large hhs */
sum demo_hh_size, d
replace flag = 1 if demo_hh_size >= r(p99) & !mi(demo_hh_size)
replace flag = 1 if demo_hh_size == 0

/* migrants and hh members */
replace flag = 1 if mig_size >= demo_hh_size & demo_hh_size != 0

/* no. of migrants returned/not home cannot exceed no. of migrants in hh */
count if mig_return_size > mig_size & !mi(mig_return_size)
count if mig_no_return_size > mig_size & !mi(mig_no_return_size)

/* prices/availability of atta, rice, onions*/
foreach i in atta rice onions {
disp_nice "`i'"
  compare con_wk_`i' con_curr_`i'
}

foreach i in atta rice onion {
tab con_`i'_unavail_prop
}

/* check how occupation has changed pre/post lockdown */
fre lab_march_occu
fre lab_curr_occu

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

/* consumption change */

/* consumption decline and share of workforce in agricultural jobs */
binscatter con_weekchange_mean pc11_pca_agr_work_share [aw = weight_hh]
graphout con_ag_share

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

/* Relief */

/* Relief and ag share */
binscatter rel_amt_received_mean pc11_pca_agr_work_share [aw = weight_hh], absorb(geo_state)
graphout relief_ag

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

/* onion price and roads */
binscatter con_attachange_mean tdist_100 [aw = weight_hh], absorb(geo_state) by(rural_road)
graphout price_atta_dist_road

/* Inputs and prices */
binscatter agr_prc_change_yr_mean agr_inputs_change_abs_mean [aw = weight_hh], absorb(geo_state)
graphout inputs_price

/* Migration */

/* consumption and migrant size of households */
binscatter con_weekchange_mean mig_size [aw = weight_hh]
graphout migsize_con

/* Wage change */

/* wage change and labor surplus */
binscatter lab_wagechange_mean land_acres_per_capita [aw = weight_hh] if land_acres_per_capita < 3.5, absorb(geo_state)
graphout labsurplus

/* zero income for the past week */
catplot lab_zeroinc_prop [aw = weight_hh], over(geo_state) perc(geo_state) ytitle(" " ) 
graphout zero_inc
