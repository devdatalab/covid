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



use $iec/health/hosp/hospitals_dist, clear

/* sum vars */
sum dlhs4_perk_total_beds dlhs4_perk_total_facilities dlhs4_perk_total_staff , d
sum pc_perk_beds_tot pc_perk_beds_allo pc_perk_beds_urb_tot pc_perk_beds_urb_allo , d
sum ec_perk_emp_hosp_priv ec_perk_emp_hosp_gov ec_perk_emp_hosp_tot , d

/* compare beds vars */
corr dlhs4_perk_total_beds pc_perk_beds_tot
corr dlhs4_perk_total_beds pc_perk_beds_urb_tot
reg dlhs4_perk_total_beds pc_perk_beds_tot
reg dlhs4_perk_total_beds pc_perk_beds_urb_tot

/* compare rank vars */
corr rank_dlhs4_perk_total_beds rank_pc_perk_beds_tot
reg rank_dlhs4_perk_total_beds rank_pc_perk_beds_tot

scatter rank_dlhs4_perk_total_beds rank_pc_perk_beds_tot
graphout ranks

/* compare bottom vars */
corr bot_dlhs4_perk_total_beds bot_pc_perk_beds_tot
reg bot_dlhs4_perk_total_beds bot_pc_perk_beds_tot
tab bot_dlhs4_perk_total_beds bot_pc_perk_beds_tot

/* pc vs dlhs bed count */
gen pc_dlhs_beds_ratio = pc_beds_tot / dlhs4_total_beds
gen pc_dlhs_priv_share = (pc_beds_tot - dlhs4_total_beds) / pc_beds_tot
sum pc_dlhs_beds_ratio ec_priv_hosp_share, d
corr pc_dlhs_beds_ratio ec_priv_hosp_share

/* is pc capturing private hospitals? */
tabstat ec_priv_hosp_share pc_dlhs_priv_share [aw=pc11_pca_tot_p], by(pc11_state_name ) 
corr ec_priv_hosp_share pc_dlhs_priv_share [aw=pc11_pca_tot_p]
/* doesn't look like it, since ec_priv_share seems more correlated */


