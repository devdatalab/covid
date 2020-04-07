global out ~/iec/SAworking/hosp
mkdir $out

ls ~/iec/health/DLHS4_FacilitySurveyData/AHS_FACILITY
ls ~/iec/health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY

/* explore data */


/* hospitals (dh), community health centers (chc), primary health centers (phc), sub-health centers (shc) */

/* AHS districts */

/* district hospitals */
use ~/iec/health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_dh.dta , clear
/* variables of interest: */
/* qd2             double  %3.0f                 TOTAL NUMBER OF BEDS */
/* note: has beds broken out by type */

/* community health cetners */
use ~/iec/health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_chc.dta , clear
/* qc571           double  %3.0f                 Total Number of beds in CHC */

/* primary health center */
use ~/iec/health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_phc.dta , clear
/* qp429a          double  %2.0f                 Total number of bed sanction for PHC */
/* qp429b          double  %2.0f                 Total number of bed available in PHC */


/* sub health centers */
use ~/iec/health/DLHS4_FacilitySurveyData/AHS_FACILITY/AHS_shc.dta , clear
/* NO INPATIENT CARE */


/* NON AHS districts */

/* district hospitals */
use ~/iec/health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/DH_NONAHS.dta , clear
/* qd2             double  %3.0f                 TOTAL NUMBER OF BEDS */

/* community health centers */
use ~/iec/health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/CHC_NONAHS.dta , clear
/* qc571           double  %3.0f                 Total Number of beds in CHC */

/* primary health center */
use ~/iec/health/DLHS4_FacilitySurveyData/NON_AHS_FACILITY/PHC_NONAHS.dta , clear
/* qp429a          double  %2.0f                 Total number of bed sanction for PHC */
/* qp429b          double  %2.0f                 Total number of bed available in PHC */


/* scatter beds vs staff */
reg dlhs4_total_beds dlhs4_total_staff
scatter dlhs4_total_beds dlhs4_total_staff
graphout x

/* explore */
exit

forval i = 2/36 {
  tab state state_name if state == `i'
}



/* merge everything together at district level */

use $iec/health/hosp/dlhs4_hospitals_dist.dta, clear
merge 1:1 pc11_state_id pc11_district_id using $iec/health/hosp/ec_hospitals_dist.dta, gen(_m_ec13)
merge 1:1 pc11_state_id pc11_district_id using $iec/health/hosp/pc_hospitals_dist.dta, gen(_m_pc11)

/* key variables */
/* dlhs: dlhs4_total_beds, dlhs4_total_count, dlhs4_total_staff */
/* ec13: ec_emp_hosp_priv, ec_emp_hosp_gov */
/* pc11: pc_beds_urb_tot pc_beds_urb_allo*/

/* generate private share from EC */
gen ec_priv_hosp_share = ec_emp_hosp_priv / (ec_emp_hosp_priv + ec_emp_hosp_gov)
sum ec_priv_hosp_share,d
/* tons of variation, from 0 to 1, med .52, close to uniform */

/* generate total ec emp in hospitals */
gen ec_emp_hosp_tot = ec_emp_hosp_priv + ec_emp_hosp_gov

/* gen rural to urban doctor share */
gen pc_doc_u_share = pc_doctors_pos_u / (pc_doctors_pos_r + pc_doctors_pos_u)

/* scale up urban beds in pc by rural share */
gen pc_beds_tot = pc_beds_urb_tot / pc_doc_u_share
gen pc_beds_allo = pc_beds_urb_allo / pc_doc_u_share


/* everything scaled to per 1k */

/* dlhs4 */
foreach y in total_beds total_facilities total_staff {
  gen dlhs4_perk_`y' = dlhs4_`y' / pc11_pca_tot_p * 1000
}

/* pop census */
foreach y in beds_tot beds_allo {
  gen pc_perk_`y' = pc_`y' / pc11_pca_tot_p * 1000
}

/* economic census */
foreach y in emp_hosp_priv emp_hosp_gov emp_hosp_tot {
  gen ec_perk_`y' = ec_`y' / pc11_pca_tot_p * 1000
}

/* generate rankings */
foreach y in dlhs4_perk_total_beds dlhs4_perk_total_facilities dlhs4_perk_total_staff pc_perk_beds_tot pc_perk_beds_allo ec_perk_emp_hosp_priv ec_perk_emp_hosp_gov ec_perk_emp_hosp_tot {
  egen rank_`y' = rank(`y')
  gen bot_`y' = rank_`y' > 450 if !mi(rank_`y')
}

/* save */
save $tmp/hospitals_dist, replace


/* sum vars */
sum dlhs4_perk_total_beds dlhs4_perk_total_facilities dlhs4_perk_total_staff , d
sum pc_perk_beds_tot pc_perk_beds_allo  , d
sum ec_perk_emp_hosp_priv ec_perk_emp_hosp_gov ec_perk_emp_hosp_tot , d

/* compare beds vars */
corr dlhs4_perk_total_beds pc_perk_beds_tot
reg dlhs4_perk_total_beds pc_perk_beds_tot

/* compare rank vars */
corr rank_dlhs4_perk_total_beds rank_pc_perk_beds_tot
reg rank_dlhs4_perk_total_beds rank_pc_perk_beds_tot

/* compare bottom vars */
reg bot_dlhs4_perk_total_beds bot_pc_perk_beds_tot
tab bot_dlhs4_perk_total_beds bot_pc_perk_beds_tot
