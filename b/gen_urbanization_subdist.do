/* generate pc11 subdistrict-level urbanization dataset */

/* merge total/urban/rural data together */
use $pc11/pc11r_pca_subdistrict_clean.dta, clear
ren pc11_pca* pc11r_pca*
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id using $pc11/pc11u_pca_subdistrict_clean, gen(_m_pc11u)
ren pc11_pca* pc11u_pca*
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id using $pc11/pc11_pca_subdistrict_clean, gen(_m_pc11r)
drop _m*

/* generate urbanization variable */
gen pc11_urb_share = pc11u_pca_tot_p / pc11_pca_tot_p
label var pc11_urb_share "Urbanization share of subdistrict"

/* save */
save $tmp/pc11_pca_subd, replace 

/* zip  */
cd $tmp
!zip pc11_pca_subd.zip pc11_pca_subd.dta
