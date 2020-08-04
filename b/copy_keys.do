/* copy keys for release in the covid data repository, with any
necessary processing. */

/* copy EC:PC keys */
shell cp $keys/pc11_district_key.dta $covidpub/keys/
shell cp $keys/pc11_ec13_district_key.dta $covidpub/keys/
shell cp $keys/pc11r_ec13r_key.dta $covidpub/keys/
shell cp $keys/pc11u_ec13u_key.dta $covidpub/keys/

/* copy LGD keys */
shell cp $keys/lgd_district_key.dta $covidpub/keys/
shell cp $keys/lgd_pc11_town_key.dta $covidpub/keys/
shell cp $keys/lgd_town_key.dta $covidpub/keys/
shell cp $keys/lgd_village_key.dta $covidpub/keys/

/* excise unnecessary fields from LGD PC11 village key */
use $keys/lgd_pc11_village_key.dta, clear
keep pc11_state_id pc11_district_id pc11_subdistrict_id pc11_village_id lgd_state_id lgd_district_id lgd_subdistrict_id lgd_village_id lgd_pc11_match
encode lgd_pc11_match, gen(tmp)
drop lgd_pc11_match
ren tmp lgd_pc11_match
compress
save $covidpub/keys/lgd_pc11_village_key.dta, replace
