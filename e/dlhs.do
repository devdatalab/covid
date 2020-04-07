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



