/* merge DLHS, PC, EC together at district level */
use $covidpub/dlhs4_hospitals_dist.dta, clear
merge 1:1 pc11_state_id pc11_district_id using $covidpub/ec_hospitals_dist.dta, gen(_m_ec13)
merge 1:1 pc11_state_id pc11_district_id using $covidpub/pc_hospitals_dist.dta, gen(_m_pc11)

/* drop if missing pc11 ids */
drop if mi(pc11_state_id) | mi(pc11_district_id)

/* reconcile variable names (though really should do this in the build files above) */
ren dlhs4* dlhs*

/* key variables */
/* dlhs: dlhs4_total_beds, dlhs4_total_count, dlhs4_total_staff */
/* ec13: ec_emp_hosp_priv, ec_emp_hosp_gov */
/* pc11: pc_hosp_beds_u pc_clinic_beds_u */

/* generate private share from EC */
gen ec_priv_hosp_share = ec_emp_hosp_priv / (ec_emp_hosp_priv + ec_emp_hosp_gov)
sum ec_priv_hosp_share,d
/* tons of variation, from 0 to 1, med .52, close to uniform */

/* generate total ec emp in hospitals */
gen ec_emp_hosp_tot = ec_emp_hosp_priv + ec_emp_hosp_gov

/* gen urban to rural doctor share */
gen pc_doc_u_share = pc_docs_pos_u / (pc_docs_pos_r + pc_docs_pos_u)

/* gen urban to rural doctor in hospital share */
gen pc_hosp_doc_u_share = pc_docs_hosp_u / (pc_docs_hosp_r + pc_docs_hosp_u)

/* scale up urban beds in pop census using rural share of doctors */

/* use overall doc share for clinic beds */
gen pc_clinic_beds = pc_clinic_beds_u / pc_doc_u_share

/* use hospital doc share for hospital beds */
gen pc_hosp_beds = pc_hosp_beds_u / pc_hosp_doc_u_share

/* Scale everything to number per 1000 */

/* dlhs4 */
foreach y in total_beds total_facilities total_staff {
  gen dlhs_perk_`y' = dlhs_`y' / pc11_pca_tot_p * 1000
}

/* pop census */
foreach y in clinic_beds hosp_beds docs docs_hosp {
  gen pc_perk_`y' = pc_`y' / pc11_pca_tot_p * 1000
}

/* economic census */
foreach y in emp_hosp_priv emp_hosp_gov emp_hosp_tot {
  gen ec_perk_`y' = ec_`y' / pc11_pca_tot_p * 1000
}

/* rename DLHS and PC public vars to be clear they are gov hospitals only */
ren dlhs*total* dlhs*gov*
ren pc*hosp* pc*gov_hosp*
ren pc*clinic* pc*gov_clinic*
ren pc*pmed* pc*gov_pmed*
ren pc_docs_pos_r pc_gov_docs_r
ren pc_docs_pos_u pc_gov_docs_u
ren pc_docs pc_gov_docs
ren pc_perk_docs pc_perk_gov_docs

/* scale up variables of interest by ec priv share */
gen dlhs_perk_pubpriv_beds = dlhs_perk_gov_beds / (1 - ec_priv_hosp_share)
gen pc_perk_pubpriv_clinic_beds = pc_perk_gov_clinic_beds / (1 - ec_priv_hosp_share)
gen pc_perk_pubpriv_hosp_beds = pc_perk_gov_hosp_beds / (1 - ec_priv_hosp_share)

/* generate rankings */
foreach y in dlhs_perk_pubpriv_beds pc_perk_pubpriv_hosp_beds {
  egen rank_`y' = rank(`y')
}

/* get names */
merge 1:1 pc11_state_id pc11_district_id using $keys/pc11_district_key, keepusing(pc11_state_name pc11_district_name)
drop if _merge == 2
drop _merge

/* save district-level hospital dataset with 3 hospital sources: DLHS, PC, EC*/
save $iec/health/hosp/hospitals_dist, replace
