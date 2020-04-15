/* generate pc11 subdistrict-level urbanization dataset */

/* figure out why there are duplicates!!!!!!!!!! */

/* total */
use $pc11/pc11_pca_subdistrict_clean.dta, clear
duplicates tag pc11_state_id pc11_district_id pc11_subdistrict_id, gen(dups)
tab dups
list *id *name dups pc11_pca_tot_p if dups > 0
tab pc11_subdistrict_id if pc11_state_id == "07" & pc11_district_id == "096"
/* one of the 00450 should be 00448 */

/* rural */
use $pc11/pc11r_pca_subdistrict_clean.dta, clear
duplicates tag pc11_state_id pc11_district_id pc11_subdistrict_id, gen(dups)
tab dups
list *id *name dups pc11_pca_tot_p if dups > 0
tab pc11_subdistrict_id if pc11_state_id == "07" & pc11_district_id == "096"


/* save unique subdistrict files, fixing bad id's, with proper prefixes */
foreach i in pc11 pc11r pc11u {
  use $pc11/`i'_pca_subdistrict_clean.dta, clear
  replace pc11_subdistrict_id = "00448" if pc11_district_id == "096" & pc11_pca_subdistrict_name == "Patel Nagar"
  replace pc11_subdistrict_id = "00449" if pc11_district_id == "096" & pc11_pca_subdistrict_name == "Rajouri Garden"
  ren pc11_pca* `i'_pca*
  drop `i'_pca_tru
  save $tmp/`i'_pca_subd_uniq, replace
}

/*merge together */
use $tmp/pc11_pca_subd_uniq, clear
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id using $tmp/pc11r_pca_subd_uniq, gen(_m_pc11r)
merge 1:1 pc11_state_id pc11_district_id pc11_subdistrict_id using $tmp/pc11u_pca_subd_uniq, gen(_m_pc11u)
drop _m*

/* generate urbanization variable */
gen pc11_urb_share = pc11u_pca_tot_p / pc11_pca_tot_p
label var pc11_urb_share "Urbanization share of subdistrict"

/* save */
save $tmp/pc11_pca_subd, replace 

/* zip  */
cd $tmp
!zip pc11_pca_subd.zip pc11_pca_subd.dta
