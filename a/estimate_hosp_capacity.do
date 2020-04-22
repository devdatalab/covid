/* merge DLHS, PC, EC together at district level */
use $iec/health/hosp/dlhs4_hospitals_dist.dta, clear
merge 1:1 pc11_state_id pc11_district_id using $iec/health/hosp/ec_hospitals_dist.dta, gen(_m_ec13)
merge 1:1 pc11_state_id pc11_district_id using $covidpub/pc_hospitals_dist.dta, gen(_m_pc11)

/* drop if missing pc11 ids */
drop if mi(pc11_state_id) | mi(pc11_district_id)

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

/* gen urban to rural doctor share */
gen pc_doc_u_share = pc_doctors_pos_u / (pc_doctors_pos_r + pc_doctors_pos_u)

/* gen urban to rural doctor in hospital share */
gen pc_hosp_doc_u_share = pc_doctors_pos_u / (pc_doctors_pos_r + pc_doctors_pos_u)

/* scale up urban beds in pc by rural share */
gen pc_beds_tot = pc_beds_urb_tot / pc_doc_u_share
gen pc_beds_allo = pc_beds_urb_allo / pc_doc_u_share

/* everything scaled to per 1k */

/* dlhs4 */
foreach y in total_beds total_facilities total_staff {
  gen dlhs4_perk_`y' = dlhs4_`y' / pc11_pca_tot_p * 1000
}

/* pop census */
foreach y in beds_tot beds_allo  {
  gen pc_perk_`y' = pc_`y' / pc11_pca_tot_p * 1000
}

/* economic census */
foreach y in emp_hosp_priv emp_hosp_gov emp_hosp_tot {
  gen ec_perk_`y' = ec_`y' / pc11_pca_tot_p * 1000
}

/* scale up variables of interest by ec priv share */
gen dlhs4_perk_pubpriv_beds = dlhs4_perk_total_beds / (1 - ec_priv_hosp_share)
gen pc_perk_beds_pubpriv = pc_perk_beds_tot / (1 - ec_priv_hosp_share)

/* generate rankings */
foreach y in dlhs4_perk_total_beds dlhs4_perk_total_facilities dlhs4_perk_total_staff pc_perk_beds_tot pc_perk_beds_allo pc_perk_beds_urb_tot pc_perk_beds_urb_allo ec_perk_emp_hosp_priv ec_perk_emp_hosp_gov ec_perk_emp_hosp_tot dlhs4_perk_pubpriv_beds pc_perk_beds_pubpriv {
  egen rank_`y' = rank(`y')
  gen bot_`y' = rank_`y' > 450 if !mi(rank_`y')
}

/* get names */
merge 1:1 pc11_state_id pc11_district_id using $keys/pc11_district_key, keepusing(pc11_state_name pc11_district_name)
drop if _merge == 2
drop _merge

/* save */
save $iec/health/hosp/hospitals_dist, replace


/* output hospital capacity dataset */
/* vars: beds_pc beds_dlhs priv_share_ec total_beds (pc and dlhs) capacity_ranks population */
use $iec/health/hosp/hospitals_dist, clear
keep pc11_state_name pc11_state_id pc11_district_name pc11_district_id dlhs4_perk_total_beds pc_perk_beds_tot ec_priv_hosp_share dlhs4_perk_pubpriv_beds rank_dlhs4_perk_pubpriv_beds pc_perk_beds_pubpriv rank_pc_perk_beds_pubpriv pc11_pca_tot_p
order pc11_state_name pc11_state_id pc11_district_name pc11_district_id dlhs4_perk_total_beds pc_perk_beds_tot ec_priv_hosp_share dlhs4_perk_pubpriv_beds rank_dlhs4_perk_pubpriv_beds pc_perk_beds_pubpriv rank_pc_perk_beds_pubpriv pc11_pca_tot_p
ren pc11_pca_tot_p pc11_population
ren *total_beds *beds_tot
ren *pubpriv_beds *beds_pubpriv
save $iec/health/hosp/hospitals_dist_export, replace
export excel using $iec/health/hosp/hospitals_dist_export, replace firstrow(variables)
