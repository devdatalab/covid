/* =============================================================
 Date created : June 2020
 File purpose: Creating Distt Level Data from NFHS IV survey +
 HMIS dated 7th October 2016 + PM2.5 from SEDAC to be shared 
 with the DDL
============================================================= */

//Note: Change the director to match the path of your analysis folder
if c(username)=="nishthakochhar" {
	global directory "/Users/nishthakochhar/Dropbox/Healthcare_deserts"
	global location "/Users/nishthakochhar/Dropbox"
}
else {
global directory "D:/Dropbox/Healthcare_deserts"
}

//Note: Analysis folder has 3 sub-folders + Another folder where NFHS files are stored 
***********************
*Set Local directories*
gl data "${directory}/Analysis/Data"
gl output "${directory}/Analysis/Output"       //contains all the edited files 
gl temp "${directory}/Analysis/Temp"  //contains temp files - to be deleted
gl nfhsdata "${location}/Kosi/Data"       
***********************

********************************************************************************
********************************************************************************
*********************************Health facility********************************
********************************************************************************
********************************************************************************

//Note: Available from  https://data.gov.in/catalog/all-india-health-centres-directory
import delimited "$data/geocode_health_centre.csv", varnames(1) clear 

gen statename_ls = lower(statename)
replace statename_ls =subinstr( statename_ls ,"&","and",.)
replace statename_ls = "andaman and nicobar islands" if statename_ls == "a and n islands"
replace statename_ls = "andhra pradesh" if statename_ls == "andhra pradesh old"

//chc file
preserve 

keep if facilitytype == "chc"
export delimited using "$directory\Map\geocode_health_centre_chc.csv", replace

restore

//dis_h
preserve 

keep if facilitytype == "dis_h"
export delimited using "$directory\Map\geocode_health_centre_dish.csv", replace

restore

//phc
preserve 

keep if facilitytype == "phc"
export delimited using "$directory\Map\geocode_health_centre_phc.csv", replace

restore

//s_t_h
preserve 

keep if facilitytype == "s_t_h"
export delimited using "$directory\Map\geocode_health_centre_sth.csv", replace

restore

//sub_cen
preserve 

keep if facilitytype == "sub_cen"
export delimited using "$directory\Map\geocode_health_centre_sub.csv", replace

restore


********************************************************************************
/*Note: 
1. I exported these files into ArcGIS
2. With 2019 distt files as the base file, I joined each of these files and obtained
a count for the number of facilities of each type
3. Then I exported them to excel. I will bring them back to stata and merge them to 
create a distt level dataset on the number of health facilities as the distt names in 2018. 
*/

clear

foreach stub in phc sth dish sub chc {
import excel $data/Distt_health_fac/distt_`stub'.xls, sheet(distt_`stub') firstrow clear
rename Count_ count_`stub' 

clonevar districtcode_lgd = Dist_LGD 
clonevar statecode_lgd = State_LGD 
destring dtcode11, gen(dtcode11_td)
replace districtcode_lgd = dtcode11_td if inlist(dtname, "Mirpur", "Muzaffarabad")
drop dtcode11_td

save $temp/`stub'_distt.dta, replace
}

merge 1:1 statecode_lgd districtcode_lgd  using $temp/sub_distt.dta, keepus(count_sub)
rename _m merge1

merge 1:1 statecode_lgd districtcode_lgd  using $temp/dish_distt.dta, keepus(count_dish)
rename _m merge2

merge 1:1 statecode_lgd districtcode_lgd  using $temp/sth_distt.dta, keepus(count_sth)
rename _m merge3

merge 1:1 statecode_lgd districtcode_lgd  using $temp/phc_distt.dta, keepus(count_phc)
rename _m merge4

tempfile 2016_health_fac
save `2016_health_fac.dta'

********************************************************************************
//Population

clear
//Note: This file is available from https://sedac.ciesin.columbia.edu/theme/population
import excel "$data/gpw_original.xls", sheet("gpw_original") firstrow
duplicates drop NAME1 NAME2 NAME3, force

//Note: Crosswalk available on request
merge 1:1 NAME1 NAME2 NAME3 using "$output/crosswalk.dta"  
drop if _m != 3
drop _m

bys NAME1 NAME2: egen tot_pop_td = total(B_2010_E) //total population by 2011 distts

gen tot_pop_11 = tot_pop_td*con_factor
drop tot_pop_td 
duplicates drop stname dtname, force //keeping distt level dataset

//Note: Growth rate taken from US Census Bureau's estimates (https://www.census.gov/data-tools/demo/idb/informationGateway.php)
gen pop_tot_2016 = tot_pop_11*(1 + 0.029)^6  

tempfile 2016_pop
save `2016_pop.dta'

clear
use `2016_health_fac.dta'

merge 1:1 stname dtname using `2016_pop.dta', keepus( pop_tot_2016) 
drop _m

foreach stub in phc chc sub dish sth {
	display "`stub'"
	gen pr_`stub' = (count_`stub'/pop_tot_2016)*10000 //number of public medical fac per 10000 people
	replace pr_`stub' = . if inlist(dtname, "Mirpur", "Muzaffarabad")
	format pr_`stub' %12.2f
}

save "$output/health_fac_pop.dta", replace

********************************************************************************
//Health + pollution: to match 2011 boundaries

/*Note: 
1. I exported files from lines 34 to 63 files into ArcGIS
2. With 2011  census distt files as the base file, I joined each of these files and obtained
a count for the number of facilities of each type
3. Then I exported them to excel. I will bring them back to stata and merge them to 
create a distt level dataset on the number of health facilities as the distt names in 2018. 
*/

clear

foreach stub in phc sth dish sub chc {
import excel $data/Distt_health_fac/distt_2011_`stub'.xls, sheet(distt_2011_`stub') firstrow clear
rename Count_ count_2011_`stub' 

drop if FID == 135 // data not available in JnK

clonevar sdistri = censuscode 

save $temp/`stub'_distt.dta, replace
}

merge 1:1 sdistri  using $temp/sub_distt.dta, keepus(count_2011_sub)
rename _m merge1

merge 1:1 sdistri  using $temp/dish_distt.dta, keepus(count_2011_dish)
rename _m merge2

merge 1:1 sdistri  using $temp/sth_distt.dta, keepus(count_2011_sth)
rename _m merge3

merge 1:1 sdistri  using $temp/phc_distt.dta, keepus(count_2011_phc)
rename _m merge4

//Making district_code_census
tostring sdistri, gen(district_code_census)
replace district_code_census = "0" + "0" + district_code_census if sdistri < 10
replace district_code_census = "0" + district_code_census if sdistri >= 10 & sdistri < 100

//Merging in 2011 population numbers
//Note: File available on request; created from census 2011 data
merge 1:1 district_code_census using "$output/censusdistrict_pop.dta", keepus(tot_pop_census dist_name_census_census state_name_census) force 
drop _m

/*	
not matched	0
matched	640	(_merge==3)
*/	

gen pop_tot_2016 = tot_pop_census*(1 + 0.0108)^6

foreach stub in phc chc sub dish sth {
	display "`stub'"
	gen pr_2011_`stub' = (count_2011_`stub'/pop_tot_2016)*10000 //number of public medical fac per 10000 people
	*replace pr_`stub' = . if inlist(dtname, "Mirpur", "Muzaffarabad")
	format pr_2011_`stub' %12.2f
}

save "$output/health_fac_pop_2011.dta", replace

********************************************************************************
********************************************************************************
************************************NFHS****************************************
********************************************************************************
********************************************************************************

//Women's Data 
//Note: This dataset is available for download from https://dhsprogram.com/
use  "$data/NFHS/IAIR74FL.dta", clear

//clusterid
tostring v001, gen(clusterid)

//Alcohol
gen ever_alc = s716
clonevar alc_freq = s717

//Smoking
clonevar cig = v463a
clonevar pipe = v463b
clonevar cigar = v463e
clonevar bidi = s707
clonevar hookah = s710c
clonevar khaini = s710e
clonevar chewing_tobacco = v463c
clonevar snuff = v463d
clonevar gutkha = v463f
clonevar paan = v463g

//BP

clonevar bp_ms=sb17 //taken BP before
clonevar sbp1 = sb16s //1st systolic reading
clonevar sbp2 = sb23s //2nd systolic reading
clonevar sbp3 = sb27s //3rd systolic reading
clonevar dbp1 = sb16d //1st diastolic reading 
clonevar dbp2 = sb23d //2nd diastolic reading
clonevar dbp3 =sb27d //3rd diastolic reading

egen sbp_nmeasures = rownonmiss(sbp1 sbp2 sbp3)
egen dbp_nmeasures = rownonmiss(dbp1 dbp2 dbp3)

clonevar told_hi_bp = sb18
clonevar bp_med = sb19

//Diabetes
clonevar hbg12 = s723a
clonevar ex_dia_med_ind = s723ab

clonevar fast_variable_eat = sb51
clonevar fast_variable_drink = sb52
clonevar time_glucose_hr = sb69h
clonevar time_glucose_min = sb69m
gen fbg = sb70*0.0555 //also includes not fasted, to convert into mmol/l
clonevar ex_glucose_ind = sb70
clonevar pregnant = v213
clonevar ht = v438
clonevar wt = v437
clonevar ex_hb_ind = v453 //Hb
clonevar ex_hb_adj_ind = v456 //Adjusted Hb
clonevar ex_anemia_ind = v457 //Anemia
clonevar ex_bpprior_eaten_ind = sb12a //eaten 30 mins prior to bp
clonevar ex_bpprior_caffeine_ind = sb12b //caffeine 30 mins prior to bp 
clonevar ex_bpprior_smoked_ind = sb12c //smoked 30 minutes prior to bp
clonevar ex_bpprior_othertobacco_ind = sb12d //other tobacco 30 mins prior to bp

//Creating HHID
gen zero = "0"
egen cid = concat(zero clusterid)

tostring v002 , gen(hid1)
egen hid = concat(zero hid1) if v002 < 10
replace hid = hid1 if v002 > 9

egen hhid = concat(cid hid)

//Urban
gen urban = (v025 == 1)
//Visitor
gen visitor = (v135 == 2)

gen country = "India" 
gen year = "2015-2016" 
gen svy = "DHS"
gen psu = v021
clonevar resident_visitor = v135
clonevar consent=sconsent
clonevar ex_state_ind=v024
clonevar c_id=v001
clonevar stratum = v023
clonevar p_id=caseid
gen p_wt = v005/1000000 
gen sex = 1

//DOB
tostring v009, gen(month_st)
replace month_st = zero + month_st if v009 < 10
tostring v010, gen(year_st)
gen dob = month_st + "/" + year_st

clonevar age = v012
clonevar age_5yr= v013
clonevar edyears = v133
clonevar educat_lcl = v149
clonevar marital = v501
clonevar working=v714
clonevar total_hh=v136
clonevar wealth_quintile = v190
clonevar wealth_quintile_r=s190r
clonevar wealth_quintile_urb=s190u

//mergeid
tostring v001, gen(v001_st)
tostring v002, gen(v002_st)
tostring v003, gen(v003_st)
gen mergeid = v001_st + "_" + v002_st + "_" + v003_st

//d_id
tostring v024, gen(v024_st)
tostring sdistri, gen(sdistri_st)
gen d_id = v024_st + "_" + sdistri_st

//Eligibility
gen ineligible = consent == 0
drop if ineligible == 1

//Keeping relevant variables
keep country year svy psu stratum d_id ex_state_ind c_id hhid p_id p_wt sdistri ///
sex dob age age_5yr edyears educat_lcl marital working total_hh wealth_quintile ///
wealth_quintile_r wealth_quintile_urb ever_alc alc_freq bp_ms sbp1 sbp2 sbp3 fast_variable_eat ///
fast_variable_drink time_glucose_hr time_glucose_min cig pipe hookah pipe cigar fbg bidi chewing_tobacco snuff gutkha paan khaini ///
dbp1 dbp2 dbp3 sbp_nmeasures dbp_nmeasures ex_dia_med_ind hbg12 sb51 sb52 pregnant told_hi_bp bp_med /// 
ht wt ex_hb_ind ex_hb_adj_ind ex_anemia_ind mergeid urban visitor ineligible ex_hb_ind ///
ex_hb_adj_ind ex_anemia_ind ex_bpprior_eaten_ind ex_bpprior_caffeine_ind ex_bpprior_smoked_ind ///
ex_bpprior_othertobacco_ind ex_glucose_ind v106 v155 s191r s191u v463a v463b v463e s707 s710c sb18 sb19 resident_visitor consent

drop if mergeid == "._._."

//Keeping eligible obs
drop if pregnant == 1
drop if visitor == 1
drop if ineligible == 1

//Cleaning more data
replace edyears = . if edyears == 97
replace time_glucose_hr = . if time_glucose_hr >=96
replace time_glucose_min = . if time_glucose_hr >=96
replace fbg = . if fbg >= 995
replace ht = . if ht >= 9995
replace wt = . if wt >= 9995
replace sbp1 = . if sbp1>240 | sbp1 < 70
replace sbp2 = . if sbp2>240 | sbp2 < 70
replace sbp3 = . if sbp3>240 | sbp3 < 70
replace dbp1 = . if dbp1>240 | dbp1 < 70
replace dbp2 = . if dbp2>240 | dbp2 < 70
replace dbp3 = . if dbp3>240 | dbp3 < 70

***** correct diabetes variables ***** 

//glucose
replace ex_glucose_ind = . if ex_glucose_ind > 499
replace ex_glucose_ind = ex_glucose_ind*1.11 

***** Create hypertension variables *****
gen sbp_av = .
replace sbp_av = (sbp1 + sbp2 + sbp3)/3 if sbp1 != . & sbp2 != . & sbp3 != .
replace sbp_av = (sbp2 + sbp3)/2 if sbp1 == . & sbp2 != . & sbp3 != .
replace sbp_av = (sbp1 + sbp3)/2 if sbp1 != . & sbp2 == . & sbp3 != .
replace sbp_av = (sbp1 + sbp2)/2 if sbp1 != . & sbp2 != . & sbp3 == .
replace sbp_av = (sbp1)/1 if sbp1 != . & sbp2 == . & sbp3 == .
replace sbp_av = (sbp2)/1 if sbp1 == . & sbp2 != . & sbp3 == .
replace sbp_av = (sbp3)/1 if sbp1 == . & sbp2 == . & sbp3 != .

gen dbp_av = .
replace dbp_av = (dbp1 + dbp2 + dbp3)/3 if dbp1 != . & dbp2 != . & dbp3 != .
replace dbp_av = (dbp2 + dbp3)/2 if dbp1 == . & dbp2 != . & dbp3 != .
replace dbp_av = (dbp1 + dbp3)/2 if dbp1 != . & dbp2 == . & dbp3 != .
replace dbp_av = (dbp1 + dbp2)/2 if dbp1 != . & dbp2 != . & dbp3 == .
replace dbp_av = (dbp1)/1 if dbp1 != . & dbp2 == . & dbp3 == .
replace dbp_av = (dbp2)/1 if dbp1 == . & dbp2 != . & dbp3 == .
replace dbp_av = (dbp3)/1 if dbp1 == . & dbp2 == . & dbp3 != .

//Knew hypertension
gen htn_know = .
replace htn_know = sb18 if sb18 != . 

//Takes hypertension treatment
gen htn_treatment = .
replace htn_treatment = sb19 if sb19 != . 

*****Create new bmi and clean BMI
gen bmi = (wt*0.1)/(ht*0.001)^2
replace bmi = . if bmi < 10 | bmi > 80
gen bmicat = . 
replace bmicat = 1 if bmi < 18.5
replace bmicat = 2 if bmi >= 18.5 & bmi < 25 
replace bmicat = 3 if bmi >= 25 & bmi < 30
replace bmicat = 4 if bmi >= 30 

*****Create currently smoking variable *****

gen csmoke = .
replace csmoke = 1 if cig == 1 | pipe == 1 | hookah == 1 | cigar == 1 | bidi == 1 | chewing_tobacco == 1 | snuff == 1 | gutkha == 1 | paan == 1 | khaini == 1
replace csmoke = 0 if csmoke == .
replace csmoke = . if cig == . & pipe == 1 & hookah == 1 & cigar == 1 & bidi == 1 | chewing_tobacco == 1 | snuff == 1 | gutkha == 1 | paan == 1 | khaini == 1 

//change decimals
replace ht = ht*0.1
replace wt = wt*0.1

********************************************************************************
*1. diabetes ######################

*correct fast definition

gen fast = (fast_variable_drink == 1 | fast_variable_eat == 1)
replace fast = . if fast_variable_drink > 95 & fast_variable_eat > 48

*High blood sugar 
//Narrow definition
gen ex_diab_narrow_ind = (fast==1 & ex_glucose_ind >=126 | fast==0 & ex_glucose_ind >=200)
replace ex_diab_narrow_ind = . if ex_glucose_ind == . & fast == .

//Broader definition including self report
gen ex_diab_broad_ind = (ex_diab_narrow_ind == 1 | hbg12 == 1)
replace ex_diab_broad_ind = . if ex_diab_narrow_ind == . & hbg12 == .

*2. hypertension ######################

*high blood pressure definition

gen ex_htn_narrow_ind = (sbp_av >= 140 | dbp_av >=90)
replace ex_htn_narrow_ind = . if sbp_av == . & dbp_av == .
replace ex_htn_narrow_ind = . if dbp_av > sbp_av

*broader definition including self report
gen ex_htn_broad_ind = (htn_treatment==1 | htn_know==1 | ex_htn_narrow_ind==1)
replace ex_htn_broad_ind = . if (htn_treatment==1 & htn_know==1 & ex_htn_narrow_ind==1)

* 3. bmi ######################
//Create bmi group

gen bmi_grp = . 
replace bmi_grp = 1 if bmi < 18.5
replace bmi_grp = 2 if bmi >= 18.5 & bmi < 23 
replace bmi_grp = 3 if bmi >= 23 & bmi < 25
replace bmi_grp = 4 if bmi >= 25 & bmi <= 30
replace bmi_grp = 5 if bmi > 30 

//Obese
gen bmigrt27_5 = (bmi>=27.5)
replace bmigrt27_5 = . if bmi == . 

*4. currently smoking ######################
*currently smoking:defined as smoking cigarettes pipes,cigars hookah,bidis according to new created variable csmoke_new

//csmoke

/*
Variables we need from here:

1. Diabetes
1.1 ex_diab_narrow_ind
1.2 ex_diab_broad_ind

2. Hypertension
2.1 ex_htn_narrow_ind
2.2 ex_htn_broad_ind

3. Obesity
3.1 bmi_grp

4. Smoking
4.1 csmoke

*/

save "$temp/final_dataset_NFHS_to_share.dta", replace

***
use "$temp/final_dataset_NFHS_to_share.dta", clear

***
//Women

preserve
collapse (mean) ex_diab_narrow_ind ex_diab_broad_ind ex_htn_narrow_ind ex_htn_broad_ind bmigrt27_5 csmoke total_hh if sex == 1 [iw=p_wt], by(sdistri) 

gen district_code_census = sdistri

//Note: Crosswalk available on request
merge 1:m district_code_census using "$output/crosswalk.dta", keepus(con_factor stname dtname) 
drop _m

foreach var of varlist ex_diab_narrow_ind ex_diab_broad_ind ex_htn_narrow_ind ex_htn_broad_ind bmigrt27_5 csmoke total_hh {
rename `var' `var'_fem
replace `var' = con_factor*`var'
}
duplicates drop stname dtname, force //keeping distt level dataset

tempfile final_distt_NFHS_women
save `final_distt_NFHS_women.dta'

restore
********************************************************************************
use "$output/health_fac_pop.dta", clear

merge 1:1 stname dtname using `final_distt_NFHS_women.dta'
rename _m merge_fac_nfhs_fem
drop if merge_fac_nfhs_fem == 2

***
preserve

clear
import excel "$data/Zonal_pollution_distt.xls", sheet("Zonal_pollution_distt") firstrow
save "$temp/pollution.dta", replace
 
restore
***

merge 1:1 OBJECTID using "$temp/pollution.dta"
tab _m
rename _m merge_pollution

********************************************************************************

preserve
//Household Data
//Note: This dataset is available for download from https://dhsprogram.com/
use "$data/IAHR74FL.DTA", clear

//clusterid
//clusterid
tostring hv001, gen(clusterid)

merge m:1 clusterid using "$temp/nfhs_distt.dta"
drop _merge

**
gen sdistri = shdistri

gen urban_loc = ( URBAN_RURA == "U" )

gen water_dwelling = (hv201 == 1 | hv201 == 2 | hv235 == 1)
label var water_dwelling "Has water in dwelling"

gen water_fetch_women = ( hv236 == 1 | hv236 == 3 )
replace water_fetch = . if hv236 == .

gen hand_wash_water = (hv230b == 1)
gen hand_wash_soap = (hv232 == 1)

gen richest = (hv270 == 5)
gen richer = (hv270 == 4)
gen middle = (hv270 == 3)
gen poorer = (hv270 == 2)
gen poorest = (hv270 == 1)
 
//No toilet within the HH
gen no_toilet = (hv205 == 31)
//Firewood
gen firewood = (hv226 == 8)
//Number of rooms
gen num_rooms = hv216
//Room per member
gen mem_per_room = hv009/hv216
 
collapse (mean) urban water_dwelling water_fetch_women hand_wash_water hand_wash_soap richest richer middle poorer poorest no_toilet firewood num_rooms mem_per_room [iw=hv005], by(sdistri) 
gen district_code_census = sdistri

merge 1:m district_code_census using "$output/crosswalk.dta", keepus(con_factor stname dtname)
drop _m

foreach var of varlist urban water_dwelling water_fetch_women hand_wash_water hand_wash_soap richest richer middle poorer poorest {
	replace `var' = con_factor*`var'
}
duplicates drop stname dtname, force

tempfile nfhs_hh
save `nfhs_hh.dta'

***

//Aadhar
//Note: This dataset is available for download from https://dhsprogram.com/
use "$data/IAPR74FL.DTA", clear

gen sdistri = shdistri

gen aadhar = (sh21a == 1)
replace aadhar = . if sh21a == 8

gen age65p = (hv105 >= 65)
bys hhid: egen num_65p = total(age65p)
gen dum_65p = (num_65p > 0)

collapse (mean) aadhar dum_65p [iw=hv005], by(sdistri)
gen district_code_census = sdistri

merge 1:m district_code_census using "$output/crosswalk.dta", keepus(con_factor stname dtname)
drop _m

replace aadhar = con_factor*aadhar
replace dum_65p = con_factor*dum_65p
duplicates drop stname dtname, force 

tempfile nfhs_aadhar
save `nfhs_aadhar.dta'

***

restore

merge 1:1 stname dtname using `nfhs_hh.dta', keepus(water_dwelling water_fetch_women hand_wash_water hand_wash_soap richest richer middle poorer poorest urban_loc no_toilet firewood num_rooms mem_per_room)
rename _m merge_water
drop if merge_water == 2

merge 1:1 stname dtname using `nfhs_aadhar.dta', keepus(aadhar dum_65p)
rename _m merge_aadhar
drop if merge_aadhar == 2

replace dtname = "Almora" if Dist_LGD == 45 & State_LGD == 5
save "$output/To_share/distt_2016_final.dta", replace

********************************************************************************
//LGD
//To share with dev data lab

**PM2.5**

use "$output/To_share/distt_2016_final.dta", clear

replace districtcode_lgd = 544 if dtname == "Chengalpattu" & statecode_lgd == 33
replace districtcode_lgd = 731 if dtname == "Ranipet" & statecode_lgd == 33
replace districtcode_lgd = 733 if dtname == "Tenkasi" & statecode_lgd == 33
replace districtcode_lgd = 732 if dtname == "Tirupathur" & statecode_lgd == 33

drop if inlist(dtname, "Mirpur", "Muzaffarabad")

//In February 2020, a new distt, which was the 734th distt in India carved out in Chhattisgarh. 
//We don't have it in out data as the shapefiles reflect the latest boundaries as on 31st December, 2019. 

rename districtcode_lgd lgd_district_id
rename statecode_lgd lgd_state_id
rename dtname lgd_district_name
rename stname lgd_state_name
label var lgd_district_id "District code LGD as on 31st Dec 2019"
label var lgd_state_id "State code LGD as on 31st Dec 2019"
label var lgd_state_name "State name"
label var lgd_district_name "District name"
rename MEAN mean_pollution
label var mean_pollution "PM2.5 mean in 2016" 

global geography "lgd_district_id lgd_state_id lgd_district_name lgd_state_name"
global pollution "mean_pollution"

keep $geography $pollution 
drop if lgd_state_name == "ASSAM"

order $geography $pollution

save "$output/To_share/ddl_pollution_sedac_lgd.dta", replace

**Health Infrastructure**

use "$output/To_share/distt_2016_final.dta", clear

replace districtcode_lgd = 544 if dtname == "Chengalpattu" & statecode_lgd == 33
replace districtcode_lgd = 731 if dtname == "Ranipet" & statecode_lgd == 33
replace districtcode_lgd = 733 if dtname == "Tenkasi" & statecode_lgd == 33
replace districtcode_lgd = 732 if dtname == "Tirupathur" & statecode_lgd == 33

drop if inlist(dtname, "Mirpur", "Muzaffarabad")

//In February 2020, a new distt, which was the 734th distt in India carved out in Chhattisgarh. 
//We don't have it in out data as the shapefiles reflect the latest boundaries as on 31st December, 2019. 

rename districtcode_lgd lgd_district_id
rename statecode_lgd lgd_state_id
rename dtname lgd_district_name
rename stname lgd_state_name
label var lgd_district_id "District code LGD as on 31st Dec 2019"
label var lgd_state_id "State code LGD as on 31st Dec 2019"
label var lgd_state_name "State name"
label var lgd_district_name "District name"
label var count_chc "Number of CHCs in 2016"
label var count_sub "Number of Sub-centers in 2016"
label var count_dish "Number of District Hospitals in 2016"
label var count_sth "Number of Sub-district/Taluk Hospitals in 2016"
label var count_phc "Number of PHCs in 2016"
label var pr_phc "No of PHCs per 10,000 population in 2016"
label var pr_chc "No of CHCs per 10,000 population in 2016"
label var pr_sub "No of sub-centres per 10,000 population in 2016"
label var pr_dish "No of district hospitals per 10,000 population in 2016"
label var pr_sth "No of sub-district/taluk hospitals per 10,000 population in 2016"

global geography "lgd_district_id lgd_state_id lgd_district_name lgd_state_name"
global health_infra "count_sub count_dish count_sth count_phc count_chc pr_phc pr_chc pr_sub pr_dish pr_sth"

keep $geography $health_infra 
drop if lgd_state_name == "ASSAM"

order $geography $health_infra

save "$output/To_share/ddl_health_infra_lgd.dta", replace

**NFHS**

use "$output/To_share/distt_2016_final.dta", clear

replace districtcode_lgd = 544 if dtname == "Chengalpattu" & statecode_lgd == 33
replace districtcode_lgd = 731 if dtname == "Ranipet" & statecode_lgd == 33
replace districtcode_lgd = 733 if dtname == "Tenkasi" & statecode_lgd == 33
replace districtcode_lgd = 732 if dtname == "Tirupathur" & statecode_lgd == 33

drop if inlist(dtname, "Mirpur", "Muzaffarabad")

//In February 2020, a new distt, which was the 734th distt in India carved out in Chhattisgarh. 
//We don't have it in out data as the shapefiles reflect the latest boundaries as on 31st December, 2019. 

rename districtcode_lgd lgd_district_id
rename statecode_lgd lgd_state_id
rename dtname lgd_district_name
rename stname lgd_state_name
label var lgd_district_id "District code LGD as on 31st Dec 2019"
label var lgd_state_id "State code LGD as on 31st Dec 2019"
label var lgd_state_name "State name"
label var lgd_district_name "District name"
label var richest "Richest 20% in 2016"
label var poorest "Poorest 20% in 2016"
label var aadhar "% individuals covered by Aadhar in 2016"
label var water_dwelling "% housedholds with water access within dwelling in 2016" 
label var water_fetch_women "% households where women fetch water from outside in 2016"
label var hand_wash_water "% households with hand washing arrangement in 2016"
label var hand_wash_soap "% households handwashing with soap in 2016"
label var no_toilet "% households who practiced open defecation in 2016"
label var firewood "% households who used firewood for fuel in 2016"
label var num_rooms "Average number of rooms in 2016"
label var mem_per_room "Average number of members per room"
label var dum_65p "% households with a 65+ member"
label var ex_diab_broad_ind_fem "% with Diabetes in 2016, Female"
label var ex_htn_broad_ind_fem "% with Hypertension in 2016, Female"
label var bmigrt27_5_fem "% Obese in 2016, Female"
label var csmoke_fem "% consumed tobacco in 2016, Female"

foreach var of varlist richest poorest aadhar water_dwelling water_fetch_women hand_wash_water hand_wash_soap ///
no_toilet firewood dum_65p ex_diab_broad_ind_fem ex_htn_broad_ind_fem bmigrt27_5_fem csmoke_fem {

	replace `var' = `var'*100
	format `var' %12.2f

}

global geography "lgd_district_id lgd_state_id lgd_district_name lgd_state_name"
global economic "richest poorest"
global aadhaar "aadhar"
global water_access "water_dwelling water_fetch_women hand_wash_water hand_wash_soap no_toilet firewood num_rooms mem_per_room dum_65p"
global risk_factor "ex_diab_broad_ind_fem ex_htn_broad_ind_fem bmigrt27_5_fem csmoke_fem"

keep $geography $economic $aadhar $water_access $risk_factor 
drop if lgd_state_name == "ASSAM"

order $geography $economic $aadhar $water_access $risk_factor

save "$output/To_share/ddl_nfhs_lgd.dta", replace

******************************************************************************** 
******************************************************************************** 
****************************************2011************************************
********************************************************************************
********************************************************************************

***
use "$temp/final_dataset_NFHS.dta", clear

***
//Women

preserve
collapse (mean) ex_diab_narrow_ind ex_diab_broad_ind ex_htn_narrow_ind ex_htn_broad_ind bmigrt27_5 ///
csmoke total_hh if sex == 1 [iw=p_wt], by(sdistri) 

foreach var of varlist ex_diab_narrow_ind ex_diab_broad_ind ex_htn_narrow_ind ex_htn_broad_ind bmigrt27_5 ///
csmoke {
rename `var' `var'_fem 
}

tempfile final_distt_NFHS_women_census
save `final_distt_NFHS_women_census.dta'

restore

********************************************************************************
use "$output/health_fac_pop_2011.dta", clear

merge 1:1 sdistri using `final_distt_NFHS_women_census.dta'
rename _m merge_fac_nfhs_fem
drop if merge_fac_nfhs_fem == 2

***
preserve

import excel "$data/Zonal_pollution_distt_2011.xls", sheet("Zonal_pollution_distt_2011") firstrow clear
drop if FID == 135
save "$temp/pollution_2011.dta", replace
 
restore
***

merge 1:1 FID using "$temp/pollution_2011.dta"
tab _m
rename _m merge_pollution

********************************************************************************

preserve
//Household Data
use "$nfhsdata/IAHR74FL.DTA", clear

//clusterid
//clusterid
tostring hv001, gen(clusterid)

merge m:1 clusterid using "$temp/nfhs_distt.dta"
drop _merge

**
gen sdistri = shdistri

gen urban_loc = ( URBAN_RURA == "U" )

gen water_dwelling = (hv201 == 1 | hv201 == 2 | hv235 == 1)
label var water_dwelling "Has water in dwelling"

gen water_fetch_women = ( hv236 == 1 | hv236 == 3 )
replace water_fetch = . if hv236 == .

gen hand_wash_water = (hv230b == 1)
gen hand_wash_soap = (hv232 == 1)

gen richest = (hv270 == 5)
gen richer = (hv270 == 4)
gen middle = (hv270 == 3)
gen poorer = (hv270 == 2)
gen poorest = (hv270 == 1)
 
//No toilet within the HH
gen no_toilet = (hv205 == 31)
//Firewood
gen firewood = (hv226 == 8)
//Number of rooms
gen num_rooms = hv216
//Room per member
gen mem_per_room = hv009/hv216
 
collapse (mean) urban water_dwelling water_fetch_women hand_wash_water hand_wash_soap richest richer middle poorer poorest no_toilet firewood num_rooms mem_per_room [iw=hv005], by(sdistri) 

tempfile nfhs_hh
save `nfhs_hh.dta'

***

//Aadhar

use "$nfhsdata/IAPR74FL.DTA", clear

gen sdistri = shdistri

gen aadhar = (sh21a == 1)
replace aadhar = . if sh21a == 8

gen age65p = (hv105 >= 65)
bys hhid: egen num_65p = total(age65p)
gen dum_65p = (num_65p > 0)

collapse (mean) aadhar dum_65p [iw=hv005], by(sdistri)

tempfile nfhs_aadhar
save `nfhs_aadhar.dta'

***

restore

merge 1:1 sdistri using `nfhs_hh.dta', keepus(water_dwelling water_fetch_women hand_wash_water hand_wash_soap richest richer middle poorer poorest urban_loc no_toilet firewood num_rooms mem_per_room)
rename _m merge_water
drop if merge_water == 2

merge 1:1 sdistri using `nfhs_aadhar.dta', keepus(aadhar dum_65p)
rename _m merge_aadhar

save "$output/To_share/distt_2011_final.dta", replace

********************************************************************************
//2011 Census
//To share with dev data lab

**PM2.5**

use "$output/To_share/distt_2011_final.dta", clear
rename district_code_census pc11_district_id
rename dist_name_census_census pc11_district_name
rename ST_NM pc11_state_name
rename ST_CEN_CD pc11_state_id

label var pc11_district_id "Unique District ID Census 2011"
label var pc11_district_name "District name in census 2011"
label var pc11_state_id "State ID in census 2011"
label var pc11_state_name "State name in census 2011"
label var state_name_census "State name as on December 2019"
rename MEAN mean_pollution
label var mean_pollution "PM2.5 mean in 2016" 

global geography "pc11_district_id pc11_district_name pc11_state_id pc11_state_name"
global pollution "mean_pollution"

keep $geography $pollution 

order $geography $pollution

save "$output/To_share/ddl_pollution_sedac_2011.dta", replace

**Health Infrastructure**

use "$output/To_share/distt_2011_final.dta", clear
rename district_code_census pc11_district_id
rename dist_name_census_census pc11_district_name
rename ST_NM pc11_state_name
rename ST_CEN_CD pc11_state_id

label var pc11_district_id "Unique District ID Census 2011"
label var pc11_district_name "District name in census 2011"
label var pc11_state_id "State ID in census 2011"
label var pc11_state_name "State name in census 2011"
label var state_name_census "State name as on December 2019"
label var count_2011_chc "Number of CHCs in 2016"
label var count_2011_sub "Number of Sub-centers in 2016"
label var count_2011_dish "Number of District Hospitals in 2016"
label var count_2011_sth "Number of Sub-district/Taluk Hospitals in 2016"
label var count_2011_phc "Number of PHCs in 2016"
label var pr_2011_phc "No of PHCs per 10,000 population in 2016"
label var pr_2011_chc "No of CHCs per 10,000 population in 2016"
label var pr_2011_sub "No of sub-centres per 10,000 population in 2016"
label var pr_2011_dish "No of district hospitals per 10,000 population in 2016"
label var pr_2011_sth "No of sub-district/taluk hospitals per 10,000 population in 2016"

global geography "pc11_district_id pc11_district_name pc11_state_id pc11_state_name"
global health_infra "count_2011_sub count_2011_dish count_2011_sth count_2011_phc count_2011_chc pr_2011_phc pr_2011_chc pr_2011_sub pr_2011_dish pr_2011_sth"

keep $geography $health_infra 

order $geography $health_infra

save "$output/To_share/ddl_health_infra_2011.dta", replace

**NFHS**

use "$output/To_share/distt_2011_final.dta", clear
rename district_code_census pc11_district_id
rename dist_name_census_census pc11_district_name
rename ST_NM pc11_state_name
rename ST_CEN_CD pc11_state_id

label var pc11_district_id "Unique District ID Census 2011"
label var pc11_district_name "District name in census 2011"
label var pc11_state_id "State ID in census 2011"
label var pc11_state_name "State name in census 2011"
label var state_name_census "State name as on December 2019"
label var richest "Richest 20% in 2016"
label var poorest "Poorest 20% in 2016"
label var aadhar "% individuals covered by Aadhar in 2016"
label var water_dwelling "% housedholds with water access within dwelling in 2016" 
label var water_fetch_women "% households where women fetch water from outside in 2016"
label var hand_wash_water "% households with hand washing arrangement in 2016"
label var hand_wash_soap "% households handwashing with soap in 2016"
label var no_toilet "% households who practiced open defecation in 2016"
label var firewood "% households who used firewood for fuel in 2016"
label var num_rooms "Average number of rooms in 2016"
label var mem_per_room "Average number of members per room"
label var dum_65p "% households with a 65+ member"
label var ex_diab_broad_ind_fem "% with Diabetes in 2016, Female"
label var ex_htn_broad_ind_fem "% with Hypertension in 2016, Female"
label var bmigrt27_5_fem "% Obese in 2016, Female"
label var csmoke_fem "% consumed tobacco in 2016, Female"


foreach var of varlist richest poorest aadhar water_dwelling water_fetch_women hand_wash_water hand_wash_soap ///
no_toilet firewood dum_65p ex_diab_broad_ind_fem ex_htn_broad_ind_fem bmigrt27_5_fem csmoke_fem {

	replace `var' = `var'*100
	format `var' %12.2f

}

global geography "pc11_district_id pc11_district_name pc11_state_id pc11_state_name"
global economic "richest poorest"
global aadhaar "aadhar"
global water_access "water_dwelling water_fetch_women hand_wash_water hand_wash_soap no_toilet firewood num_rooms mem_per_room dum_65p"
global risk_factor "ex_diab_broad_ind_fem ex_htn_broad_ind_fem bmigrt27_5_fem csmoke_fem"

keep $geography $economic $aadhar $water_access $risk_factor 

order $geography $economic $aadhar $water_access $risk_factor

save "$output/To_share/ddl_nfhs_2011.dta", replace

********************************************************************************
********************************************************************************
********************************************************************************


/* (DDL) create CSVs */
foreach file in ddl_health_infra ddl_nfhs ddl_pollution_sedac {
  use $covidpub/nfhs/`file'_lgd, clear
  export delimited using $covidpub/nfhs/csv/`file'_lgd.csv, replace
  use $covidpub/nfhs/pc11/`file'_2011, clear
  export delimited using $covidpub/nfhs/csv/`file'_2011.csv, replace
}
  
