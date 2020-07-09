/* The graphs in the r1 op-ed were generated */
/* uding code in the graphs section of this do file */

/***** TABLE OF CONTENTS *****/
/* Setup */
/* Graphs */

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

/* generate percentage change in earnings */
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
gen pc_con_change = (con_wk/con_feb_wk) - 1 if con_wk < r(p95) & !mi(con_wk) & !mi(con_feb_wk)

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

/* remove random outlier coming from one observation */
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

/**********/
/* Graphs */
/**********/

use $tmp/idi_survey_clean, clear

/* Graph 1 */
/* generate indicator for all who were employed pre-lockdown */
gen emp = lab_march_occu > 0 & !mi(lab_march_occu)

/* tab current employment status for all who were employed */
tab lab_curr_occu if emp == 1
/* note: graph 1 was made on excel using above output */

/* Graph 2 */
tab rel_nrega_unavail_prop
tab rel_nrega_unavail_prop geo_state, col nofreq

/* Graph 3 */
sum rel_amt_received_mean, d

/* generate weekly earnings loss */
gen loss = lab_curr_earn - lab_march_earn if !mi(lab_curr_earn) & !mi(lab_march_earn)

/* generate monthly earning loss */
gen month_loss = loss*4

/* relief is already at monthly level */
/* graph 3 in oped reports median values */
sum rel_amt_received_mean month_loss, d

/* Graph 4 */
binscatter rel_amt_received_mean tdist_500 [aw = weight_hh], ci(model)
graphout rel_distance

/* Graph 5 */
graph hbar (mean) agr_selldiff_none - agr_selldiff_police [aw = weight_hh], ascategory yvar(relabel(1 "No difficulty" 2 "Labor shortage" 3 "Transport Unavail" 4 "Markets closed" 5 "No demand" 6 "Travel distance too long" 7 " Police harrassment")) ylabel(0 (0.1) 0.6) bar(1, color(emerald))
graphout selldiff

/* Not a graph but agriculture input changes result reported in oped */

/* median is 0 in both cases */
sum pc_ag_input_change, d
sum pc_ag_land_change, d

/* Graph 6 is the bokeh plot Ali produced */

/* op-ed also reported 29% decline in perishable crop price */
bys agr_crop_cat_prop: sum pc_agr_prc_change_holi


