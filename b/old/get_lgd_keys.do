/* use downloaded Local Government Data codes to formalize PC-LGD keys

data downloaded 14 April 2020 from: https://lgdirectory.gov.in/
from the "data download" page, selecting the CSV option
*/

/**********/
/* States */
/**********/
import delimited $iec/lgd/raw/allStateofIndia2020_04_14_23_16_43_253.csv, charset("utf-8") delimit(";") clear
ren census2001code pc01_state_id
ren census2011code pc11_state_id

/* convert id to 2-digit string */
tostring pc01_state_id, format("%02.0f") replace
tostring pc11_state_id, format("%02.0f") replace

/* save */
save $iec/keys/lgd/lgd_pc_state_key, replace

/*************/
/* Districts */
/*************/
import delimited $iec/lgd/raw/allDistrictofIndia2020_04_14_23_23_07_748.csv, charset("utf-8") delimit(";") clear
ren census2001code pc01_district_id
ren census2011code pc11_district_id

/* convert id to 2- or 3-digit string */
tostring pc01_district_id, format("%02.0f") replace
tostring pc11_district_id, format("%03.0f") replace

/* merge in the state id's */
merge m:1 statecode using $iec/keys/lgd/lgd_pc_state_key, keepusing(pc01_state_id pc11_state_id)
drop _merge

/* save */
save $iec/keys/lgd/lgd_pc_district_key, replace

/****************/
/* Subdistricts */
/****************/
import delimited $iec/lgd/raw/allSubDistrictofIndia2020_04_14_23_23_17_755.csv, charset("utf-8") delimit(";") clear
ren census2001code pc01_subdistrict_id
ren census2011code pc11_subdistrict_id

/* convert id to 4- or 5-digit string */
tostring pc01_subdistrict_id, format("%04.0f") replace
tostring pc11_subdistrict_id, format("%05.0f") replace

/* merge in the state and district id's */
merge m:1 statecode districtcode using $iec/keys/lgd/lgd_pc_district_key, keepusing(pc01_state_id pc11_state_id pc01_district_id pc11_district_id) keep(match master)
drop _merge

/* save */
save $iec/keys/lgd/lgd_pc_subdistrict_key, replace

/************/
/* Villages */
/************/
import delimited $iec/lgd/raw/allVillagesofIndia2020_04_14_23_23_29_843.csv, charset("utf-8") delimit(";") clear
ren census2001code pc01_village_id
ren census2011code pc11_village_id

/* merge in the state, district, and subdistrict id's */
merge m:1 statecode districtcode subdistrictcode using $iec/keys/lgd/lgd_pc_subdistrict_key, keepusing(pc01_state_id pc11_state_id pc01_district_id pc11_district_id pc01_subdistrict_id pc11_subdistrict_id) keep(match master)
drop _merge

/* convert id to 8- or 6-digit string */
tostring pc01_village_id, format("%08.0f") replace
tostring pc11_village_id, format("%06.0f") replace

/* save */
save $iec/keys/lgd/lgd_pc_village_key, replace
