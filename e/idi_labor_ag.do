global idi $iec/covid/idi_survey

/* use most recent data */
use $idi/round1/wb1_cleaned_dataset_2020-06-02, clear

/*********/
/* Setup */
/*********/

/* declare survey data */
svyset psu [pw=weight_hh], strata(strata_id) singleunit(scaled)

/* merge to shrug data */
merge m:1 shrid using $idi/survey_shrid_data, keep(match master) nogen
/* 70 obs with missing shrid didn't match */
/* 2 obs with shrid 11-10-244076 didn't match, not present in shrug data */

/* pc11 ids in the dataset are nonsensical drop them */
drop pc11*id 

/* merge using shrid to shrug-pc11 key to extract pc11 state and district ids*/
merge m:1 shrid using $shrug/keys/shrug_pc11_district_key, keep(match master) nogen 

/* note: pc11 ids are missing for the 70 obs in idi survey data with no shrid */
/* pc11 district ids are missing for additional 43 obs (bc shrug-pc11 key has missing pc11_district_ids) */
/* generate march earnings */

sum lab_march_wage, d
gen lab_march_earn = lab_march_wage * lab_march_freq if !mi(lab_march_wage) & !mi(lab_march_freq) & lab_march_wage < r(p95)

/* generate current earnings */
sum lab_curr_wage, d
gen lab_curr_earn = lab_curr_wage * lab_curr_freq if !mi(lab_curr_wage) & !mi(lab_curr_freq) & lab_curr_wage < r(p95)

/* gen percentage change in earnings */
gen pc_lab_earn_change = (lab_curr_earn/lab_march_earn) - 1 if !mi(lab_curr_earn) & !mi(lab_march_earn)

/* indicator for whether hh has at least one migrant */
gen mig = 1 if mig_size > 0 & !mi(mig_size)
replace mig = 0 if mig_size == 0 

/* migrants ratio */
gen mig_ratio = mig_size/demo_hh_size

/* generate consumption change */
sum con_feb, d
gen con_feb_wk = con_feb/4 if con_feb < r(p95)

sum con_wk, d
gen pc_con_change = (con_wk/con_feb_wk) - 1 if con_wk < r(p95)

/* gen labour workdays change */
gen pc_lab_work_change = (lab_curr_freq/lab_march_freq) - 1 if !mi(lab_curr_freq) & !mi(lab_march_freq)

/* generate indicator variable for share of workers whose workdays dropped to 0 */
gen lab_lost_work = 1 if lab_curr_freq == 0 & lab_march_freq > 0 & !mi(lab_march_freq)
replace lab_lost_work = 0 if lab_lost_work == .  & !mi(lab_march_freq) & !mi(lab_curr_freq)

/* generate labour wage change */
sum lab_curr_wage, d
local ccap = r(p95)

sum lab_march_wage, d
local mcap = r(p95)

gen pc_lab_wage_change = (lab_curr_wage/lab_march_wage) - 1 if lab_curr_earn > 0 & lab_march_earn > 0 & lab_march_wage < `mcap' & lab_curr_wage < `ccap'

/* random outlier coming from one observation */
replace pc_lab_wage_change = . if pc_lab_wage_change == 49

/* generate migration pre and post lockdown daily wage */
foreach i of var mig_avg_wage mig_daily_wage{

  if "`i'" == "mig_avg_wage" local unit mig_wage_unit
  if "`i'" == "mig_daily_wage" local unit mig_daily_wage_unit

/* unit - daily wage */
  gen s_`i' = `i' if `unit' == 3

/* convert weekly wage to daily wage */
  replace s_`i' = `i'/6 if `unit' == 1

/* convert monthly to daily wage */
  replace s_`i' = `i'/26 if `unit' == 2
}

/* generate migration wage change */
sum s_mig_daily_wage, d
local mccap = r(p95)

sum s_mig_avg_wage, d
local mmcap = r(p95)

gen pc_mig_wage_change = (s_mig_daily_wage/s_mig_avg_wage) - 1 if lab_curr_earn > 0 & lab_march_earn > 0 & s_mig_avg_wage < `mmcap' & s_mig_daily_wage < `mccap'

/* generate ag inputs change */
gen pc_ag_input_change = (agr_next_ssn_inputs/agr_monsoon_inputs) - 1  if !mi(agr_next_ssn_inputs) & !mi(agr_monsoon_inputs)
replace pc_ag_input_change = . if pc_ag_input_change >= 1

/* generate ag borrowing change */
gen pc_agr_borrow_change = (agr_next_ssn_borrow/agr_monsoon_borrow) - 1 if !mi(agr_next_ssn_borrow) & !mi(agr_monsoon_borrow)
replace pc_agr_borrow_change = . if pc_agr_borrow_change >= 1

/* generate ag price change - since holi */
gen pc_agr_prc_change_holi = (agr_prc_curr_kg/agr_prc_holi_kg) - 1 if !mi(agr_prc_curr_kg) & !mi(agr_prc_holi_kg)

/* generate ag price change - since last year */
gen pc_agr_prc_change_yr = (agr_prc_curr_kg/agr_prc_prev_yr_kg) - 1 if !mi(agr_prc_curr_kg) & !mi(agr_prc_prev_yr_kg) 

/* for land change, using ID insight's constructed variable bc */
/* the units vary by state and I'm not sure of the conversions! */
gen pc_ag_land_change = agr_land_change_mean if agr_land_change_mean <= 1

/* converting to 100 scale */
gen pc_borrow = pc_agr_borrow_change * 100
gen pc_input = pc_ag_input_change * 100
gen pc_earn = pc_lab_earn_change * 100
gen pc_work = pc_lab_work_change * 100

/* label variables */
la var lab_march_earn "Pre-lockdown weekly earning"
la var lab_curr_earn "Post-lockdown weekly earning"
la var lab_lost_work "Workdays fell to zero"
label define gt 0 "No transfer" 1 "Received a govt transfer"
label values rel_govt_transfer_fa_prop gt
label define m 0 "No migrants in hh" 1 "At least one migrant in hh"
label values mig m

/* nrega */
label define n 0 "NREGA available" 1 "NREGA unavailable"
label values rel_nrega_unavail_prop n
la var rel_nrega_unavail_prop "NREGA availability"

/* non-agricultural households cannot be self-employed in ag, dropping them */
drop if lab_curr_occu == 1 & demo_ag_hh == 0
drop if lab_march_occu == 1 & demo_ag_hh == 0

/* not doing much with health - drop those vars */
drop hea*

/* save as tempfile */
save $tmp/idi_survey_clean, replace

/************/
/* Analysis */
/************/

cd $tmp
use $tmp/idi_survey_clean, clear

/* 1. Total earnings and days worked loss */
graph bar (mean) pc_earn pc_work, yvar(relabel(1 "% change in earnings" 2 "% change in workdays")) bar(1, color(emerald*0.8)) bar(2, color(maroon)) ascategory ylabel(-100 (20) 0)
graphout earn_work

label define ll 1 "Workdays fell to zero" 0 ">0 workdays post lockdown"
label values lab_lost_work ll

/* labour lost */
tab lab_lost_work, gen(l)
set scheme s1color
graph pie l1 l2, plabel(_all percent) legend(label(1 "Retained some work") label(2 "Lost all work")) pie(1, color(emerald)) pie(2, color(emerald*0.4) explode)
graphout laborlost

/* 2. Variation in earnings change by categories */

/* by pre-lockdown occupation category */
cibar pc_lab_earn_change [aw = weight_hh] if lab_march_occu != 0, over(lab_march_occu) barcolor(black teal emerald dknavy) graphopts(ytitle("% earnings/revenue change") ylabel(-1 (.2) 0))
graphout earn_worker

/* losses by caste */
cibar pc_work if demo_caste > 0 & demo_caste < 99 [aw = weight_hh], over(demo_caste) barcolor(black dknavy emerald dkgreen) graphopts(ytitle("% workdays change", margin(medium)) ylabel(-100 (20) 0))
graphout work_caste

/* collapse at subdistrict level */
preserve

collapse_save_labels
collapse (mean) ec13* pc_work lab_lost_work [aw = weight_hh], by(geo_state geo_dist geo_block)
collapse_apply_labels

/* graph emp availability and pc_work */
binscatter lab_lost_work ec13* if ec13_nonfarm_emp_per_capita < .34, ytitle("Share reporting total work loss", margin(medium)) xtitle("Non-farm jobs per capita", margin(medium)) yline(0) ci(model) 
graphout work_emp

restore

/* workdays change and nrega */
cibar lab_lost_work [aw = weight_hh], over(rel_nrega_unavail_prop) barcolor(black dknavy) graphopts(ytitle("Share reporting unemployment") ylabel(0 (.2) 1, grid) )
graphout n_lw

cibar pc_work [aw = weight_hh], over(rel_nrega_unavail_prop) barcolor(black dknavy) graphopts(ytitle("% change in workdays") ylabel(-100 (20) 0, grid) )
graphout n_lw

/* price by crop category */
gen pc_crop_holi = pc_agr_prc_change_holi*100
cibar pc_crop_holi [aw = weight_hh] if pc_agr_prc_change_holi < 1, over(agr_crop_cat_prop) barcolor(black dknavy dkgreen) graphopts(ytitle("Price changes since holi, by crop category")ylabel(-100 (20) 0, grid))
graphout prc_crop_holi

/* price since last year by crop category */
gen pc_crop_yr = pc_agr_prc_change_yr*100
cibar pc_crop_yr [aw = weight_hh] if pc_agr_prc_change_yr < 1, over(agr_crop_cat_prop) barcolor(black dknavy dkgreen) graphopts(ytitle("Price changes since last year, by crop category")ylabel(-100 (20) 0, grid))
graphout prc_crop_yr

/* reasons for sales not starting */
graph hbar (mean) agr_nosell_notready - agr_nosell_machine [aw = weight_hh], ascategory yvar(relabel(1 "Crops not ready" 2 "Saving for seeds/home" 3 "Crops destroyed" 4 "No demand" 5 "Closed markets" 6 "Prices low" 7 "Lockdown" 8 "Labor shortage" 9 "Transport Unavail" 10 "Machine Unavail")) ylabel(0 (0.1) 0.6) bar(1, color(dknavy))
graphout nosell_reason

/* selling difficulties for ongoing sales + sales completed within last two weeks  */
graph hbar (mean) agr_selldiff_none - agr_selldiff_police [aw = weight_hh], ascategory yvar(relabel(1 "No difficulty" 2 "Labor shortage" 3 "Transport Unavail" 4 "Markets closed" 5 "No demand" 6 "Travel distance too long" 7 " Police harrassment")) ylabel(0 (0.1) 0.6) bar(1, color(emerald))
graphout selldiff_reason

graph hbar (mean) pc_input pc_borrow, yvar(relabel(1 "% change in input exp." 2 "% change in borrowing" )) bar(1, color(emerald)) bar(2, color(emerald)) ascategory ylabel(-13 (2) 0, grid)
graphout ag

/* 4. collapse dataset at district level */
collapse_save_labels
collapse (mean) *lost* rel*amt *nrega* pc_* ag*land*mean tdist* pc11_pca* ec13* land* mig_total_ratio *wagechange*[aw = weight_hh], by(pc11_state_id pc11_district_id)
collapse_apply_labels

/* save district level dataset */
save $tmp/idi_survey_clean_district, replace

/* haven't included this in op-ed as the result is intuitive but weak! */
twoway lfitci pc_input pc_earn if pc_earn <= 100, yline(0) ylabel(-30 (10) 40, grid) xlabel(-100 (20) 100, grid)
graphout trial
