import delimited using "$iec/health/DLHS4_FacilitySurveyData/dlhs4_dist_key.csv", clear

/* drop missing data */
drop if mi(state_name)
drop pc11_district_id

ren ïstate state
tostring state, format("%02.0f") gen(pc11_state_id)

/* general name cleaning */
gen pc11_district_name = lower(district_name)
replace pc11_district_name = subinstr(pc11_district_name, "&", "", .)
replace pc11_district_name = subinstr(pc11_district_name, ")", "", .)
replace pc11_district_name = subinstr(pc11_district_name, "(", "", .)
replace pc11_district_name = subinstr(pc11_district_name, "-", "", .)
replace pc11_district_name = itrim(trim(pc11_district_name))

/* manual replacements */
/* Andaman Nicobar Islands */
replace pc11_district_name = "nicobars" if district_name == "Nicobar"
replace pc11_district_name = "south andaman" if district_name == "South Andamana"

/* Andhra Pradesh */
replace pc11_district_name = "anantapur" if district_name == "Anantpur"
replace pc11_district_name = "chittoor" if district_name == "Chitoor"
replace pc11_district_name = "visakhapatnam" if district_name == "Vishakapatnam"
replace pc11_district_name = "ysr kadapa" if district_name == "Y.S.R."

/* Arunachal Pradesh */
replace pc11_district_name = "kurung kumey" if district_name == "Kurung Kamey"
replace pc11_district_name = "papum pare" if district_name == "Papumpare"

/* Assam */
replace pc11_district_name = "morigaon" if district_name == "Marigaon"
replace pc11_district_name = "dima hasao" if district_name == "North Cachar Hills"
replace pc11_district_name = "sivasagar" if district_name == "Sibsagar"

/* Chhattisgarh */
replace pc11_district_name = "kabeerdham" if district_name == "Kawardha "
replace pc11_district_name = "bastar" if district_name == "Kanker "
replace pc11_district_name = "dakshin bastar dantewada" if district_name == "Dantewada"

/* Haryana */
replace pc11_district_name = "panipat" if district_name == "Panipath"
replace pc11_district_name = "sonipat" if district_name == "Sonipath"

/* Jharkhand */
replace pc11_district_name = "pakur" if district_name == "Pakaur "

/* Karnataka */
replace pc11_district_name = "davanagere" if district_name == "Davangere"
replace pc11_district_name = "chikkaballapura" if district_name == "Chikkaballarpura"

/* Kerala */
replace pc11_district_name = "malappuram" if district_name == "Mallappuram"
replace pc11_district_name = "wayanad" if district_name == "Wayanand"

/* MP */
replace pc11_district_name = "datia" if district_name == "Datai"

/* Maharashtra */
replace pc11_district_name = "amravati" if district_name == "Amrawati"

/* Meghalaya */
replace pc11_district_name = "ribhoi" if district_name == "Ri Bhoi"

/* Nagaland */
replace pc11_district_name = "peren" if district_name == "Paren"

/* Odisha */
replace pc11_district_name = "subarnapur" if district_name == "Sonapur"

/* Puducherry */
replace pc11_district_name = "puducherry" if district_name == "Pondicherry"
replace pc11_district_name = "yanam" if district_name == "Yaman"

/* Punjab */
replace pc11_district_name = "sahibzada ajit singh nagar" if district_name == "SAS Nagar"
replace pc11_district_name = "bathinda" if district_name == "Bhathinda"
replace pc11_district_name = "tarn taran" if district_name == "Taran Taran"

/* Rajasthan */
replace pc11_district_name = "jalor" if district_name == "Jalore"
replace pc11_district_name = "hanumangarh" if district_name == "Hamumagarh"

/* Sikkim */
replace pc11_district_name = "west district" if district_name == "West"
replace pc11_district_name = "south district" if district_name == "South"
replace pc11_district_name = "east district" if district_name == " East"
replace pc11_district_name = "north district" if district_name == "North"

/* Tamil Nadu */
replace pc11_district_name = "the nilgiris" if district_name == "Nilgiris"

/* Telangana */
replace pc11_state_id = "28" if district_name == "Nizamabad"
replace pc11_state_id = "28" if district_name == "Mahbubnagar"
replace pc11_state_id = "28" if district_name == "Warngal"
replace pc11_state_id = "28" if district_name == "Medak"
replace pc11_state_id = "28" if district_name == "Adilabad"
replace pc11_state_id = "28" if district_name == "Rangareddy"
replace pc11_state_id = "28" if district_name == "Nalgonda"
replace pc11_state_id = "28" if district_name == "Karimnagar"
replace pc11_state_id = "28" if district_name == "Hyderabad"
replace pc11_state_id = "28" if district_name == "Khammam"

replace pc11_district_name = "warangal" if district_name == "Warngal"

/* UP */
replace pc11_district_name = "bara banki" if district_name == "Barabanki"
replace pc11_district_name = "aligarh" if district_name == "Hathras"
replace pc11_district_name = "bulandshahr" if district_name == "Bulandshahar"

/* West Bengal */
replace pc11_district_name = "purba medinipur" if district_name == "Purba Mednipur"
replace pc11_district_name = "north twenty four parganas" if district_name == "North 24 Parganas"
replace pc11_district_name = "south twenty four parganas" if district_name == "South 24 Parganas"

/* aligarh is duplicated */
// drop if district_name == "Hathras"
// drop if district_name == "Kanker "

merge m:1 pc11_state_id pc11_district_name using $iec/keys/pc11_district_key

drop if _merge != 3
drop _merge

save $iec/health/DLHS4_FacilitySurveyData/dlhs4_district_key.dta, replace
