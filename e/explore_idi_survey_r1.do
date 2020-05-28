use $iec/covid/idi_survey/round1/wb1_cleaned_dataset_2020-05-10, clear

/* declare survey data */
svyset psu [pw=weight_hh], strata(strata_id) singleunit(scaled)

/* install commands used frequently in do file */
ssc install fre

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


/************/
/* Analysis */
/************/
