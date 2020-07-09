

/********************************************************************************************/
/* Append HMIS data across years, after matching variables from early years and later years */
/********************************************************************************************/

/* We have broadly two regimes of variable naming: an early regime from 2208/09 to 2016/17
and the present regime from 2017/18 to 2020/21. Variables in early regime are prefixed by "ev_" and
variables from the present regime are prefixed with a "v_". We first append all the variables for this early regime and then rename it to be consistent with the present regime by matching
on variable descriptions with the new regime of data.*/

/* Create an empty temp file to append early years' data */

clear
save $tmp/hmis_early_years, replace emptyok

/* Define a local for early regime's years */
local early_years "2008-2009 2009-2010 2010-2011 2011-2012 2012-2013 2013-2014 2014-2015 2015-2016 2016-2017"

/* Append Data for years 2008-2017 */
foreach year in `early_years'{
  use $tmp/hmis/hmis_dist_clean_`year', clear

  /* We use ev_ to denote variable that come from early regime of data (ev_ = early variables) */
  ren v_* ev_*
  
  qui append using $tmp/hmis_early_years
  save $tmp/hmis_early_years, replace
}

/**********************************************/
/* Rename Variables to merge with later_years */
/**********************************************/

/* Matchit, reclink and fix_spelling were used initially but they were ineffective in matching
large strings of descriptions, with changing aggregations. So this matching was done manually */

/* Ante Natal Care(ANC) Services */
ren ev_1_1_TOTAL v_1_1_TOTAL
ren ev_1_1_1_TOTAL v_1_1_1_TOTAL
ren ev_1_4_1_TOTAL v_1_2_1_TOTAL
ren ev_1_4_2_TOTAL v_1_2_2_TOTAL

/* Merge 3 ANC checkups wth 4 or more ANC Checkups */
ren ev_1_3_TOTAL v_1_2_7_TOTAL

/* IFA Tablets given to Pregnant Women(100 and 180) Number different but we still add it. */
ren ev_1_5_TOTAL v_1_2_4_TOTAL

/* Pregnancy Complications */
ren ev_1_6_1_TOTAL v_1_3_1_TOTAL
ren ev_1_6_2_TOTAL v_1_3_2_TOTAL
ren ev_1_7_1_TOTAL v_1_4_2_TOTAL
ren ev_1_7_2_TOTAL v_1_4_3_TOTAL

/* Deliveries */
ren ev_2_1_1_a_TOTAL v_2_1_1_a_TOTAL
ren ev_2_1_1_b_TOTAL v_2_1_1_b_TOTAL

/* The present regime of Data has just the one variable on institutional delivery,but the early regime
has two different variables on public and private institutional delivery, so we add the two into a
new variable*/
gen v_2_2_TOTAL = ev_2_2_TOTAL + ev_2_3_TOTAL

/* C-Sections */
gen v_3_1_TOTAL = ev_3_1_5_TOTAL + ev_3_2_TOTAL

/*  Newborn Details*/
ren ev_4_1_1_a_TOTAL v_4_1_1_a_TOTAL
ren ev_4_1_1_b_TOTAL v_4_1_1_b_TOTAL
ren ev_4_1_2_TOTAL v_4_1_3_TOTAL
ren ev_4_1_3_TOTAL v_4_2_TOTAL
ren ev_4_2_1_TOTAL v_4_4_1_TOTAL
ren ev_4_2_2_TOTAL v_4_4_2_TOTAL
ren ev_4_3_TOTAL v_4_4_3_TOTAL

/* Complicated Pregnancies */
gen v_5_1_TOTAL = ev_5_1_5_TOTAL + ev_5_2_TOTAL
ren ev_5_3_4_TOTAL v_5_2_TOTAL

/* Post Natal Care */
ren ev_6_1_TOTAL v_6_1_TOTAL
ren ev_6_2_TOTAL v_6_2_TOTAL

//Medical Termination of Pregnancy Data not aggregatable for >12 and <12 weeks

/* RTI/STI */
ren ev_8_1_a_TOTAL v_7_2_1_TOTAL
ren ev_8_1_b_TOTAL v_7_2_2_TOTAL

/* Family Planning Variables */

/* Vasectomies and Sterilisations */
/* Add vasectomies and sterilisations at public and private institutions */
gen v_8_1_1_TOTAL = ev_9_1_1_e_TOTAL + ev_9_1_2_TOTAL
gen v_8_2_1_TOTAL = ev_9_2_1_e_TOTAL + ev_9_2_2_TOTAL  
gen v_8_2_2_TOTAL = ev_9_3_1_e_TOTAL + ev_9_3_2_TOTAL  
gen v_8_2_3_TOTAL = ev_9_4_1_e_TOTAL + ev_9_4_2_TOTAL

/* IUCD */
//ignoring IUCD insertions because conusing aggregation on post-partum etc.
ren ev_9_06_TOTAL v_8_6_TOTAL

/* Contraceptive Distribution */
ren ev_9_07_TOTAL v_8_12_TOTAL
ren ev_9_08_TOTAL v_8_13_TOTAL
ren ev_9_09_TOTAL v_8_14_TOTAL
ren ev_9_10_TOTAL v_8_15_TOTAL

/* Pregnancy Kits Used*/
ren ev_1_8_TOTAL v_8_16_TOTAL

/* Sterilisation Complications */
ren ev_9_11_1_a_TOTAL v_8_17_1_TOTAL
ren ev_9_11_1_b_TOTAL v_8_17_2_TOTAL
ren ev_9_11_2_a_TOTAL v_8_17_3_TOTAL
ren ev_9_11_2_b_TOTAL v_8_17_4_TOTAL
ren ev_9_11_3_a_TOTAL v_8_17_5_TOTAL
ren ev_9_11_3_b_TOTAL v_8_17_6_TOTAL


/* Child Immunisation */

/* BCG */
ren ev_10_1_01_TOTAL v_9_1_2_TOTAL

/* DPT */
ren ev_10_1_02_TOTAL v_9_1_3_TOTAL
ren ev_10_1_03_TOTAL v_9_1_4_TOTAL
ren ev_10_1_04_TOTAL v_9_1_5_TOTAL
ren ev_10_2_1_TOTAL v_9_4_3_TOTAL
ren ev_10_3_2_TOTAL v_9_5_2_TOTAL

/* Pentavalent */
ren ev_10_1_04A_TOTAL v_9_1_6_TOTAL
ren ev_10_1_04B_TOTAL v_9_1_7_TOTAL
ren ev_10_1_04C_TOTAL v_9_1_8_TOTAL

/* OPV/Polio */
ren ev_10_1_05_TOTAL v_9_1_9_TOTAL
ren ev_10_1_06_TOTAL v_9_1_10_TOTAL
ren ev_10_1_07_TOTAL v_9_1_11_TOTAL
ren ev_10_1_08_TOTAL v_9_1_12_TOTAL
ren ev_10_2_2_TOTAL v_9_4_4_TOTAL

/* Hepatitis B */
ren ev_10_1_09A_TOTAL v_9_1_13_TOTAL
ren ev_10_1_09_TOTAL v_9_1_14_TOTAL
ren ev_10_1_10_TOTAL v_9_1_15_TOTAL
ren ev_10_1_11_TOTAL v_9_1_16_TOTAL

/*  Measles*/
ren ev_10_1_12_TOTAL v_9_2_2_TOTAL
ren ev_10_1_12B_TOTAL v_9_4_2_TOTAL

/* Measles Mumps Rubella */
ren ev_10_2_3_TOTAL v_9_4_5_TOTAL

/* Tetanus/TT  */
ren ev_10_3_3_TOTAL v_9_5_3_TOTAL
ren ev_10_3_4_TOTAL v_9_5_4_TOTAL

/* Japanese Encephalitis */
ren ev_10_1A_TOTAL v_9_3_3_TOTAL
ren ev_10_5_1_TOTAL v_9_4_6_TOTAL

/* Adverse Event Following Immunisations */
ren ev_10_3_5_a_TOTAL v_9_6_1_TOTAL
ren ev_10_3_5_b_TOTAL v_9_6_2_TOTAL
ren ev_10_3_5_c_TOTAL v_9_6_3_TOTAL

/* Immunisation Sessions */
ren ev_10_4_1_TOTAL v_9_7_1_TOTAL
ren ev_10_4_2_TOTAL v_9_7_2_TOTAL
ren ev_10_4_3_TOTAL v_9_7_3_TOTAL

/* Vitamin A */
ren ev_11_1_1_TOTAL v_9_8_1_TOTAL
ren ev_11_1_2_TOTAL v_9_8_2_TOTAL
ren ev_11_1_3_TOTAL v_9_8_3_TOTAL

/* Childhood Diseases */
ren ev_12_1_TOTAL v_10_4_TOTAL
ren ev_12_2_TOTAL v_10_5_TOTAL
ren ev_12_3_TOTAL v_10_6_TOTAL
ren ev_12_6_TOTAL v_10_9_TOTAL
ren ev_12_8_TOTAL v_10_10_TOTAL
ren ev_12_9_TOTAL v_10_13_TOTAL

/********************/
/* Patient Services */
/********************/

/* Number of Village Health and Nutrition Days */
ren ev_14_03_TOTAL v_14_16_TOTAL 

/* Rogi Kalyan Samiti (Sick Welfare Society) Meetings */
ren ev_14_05_TOTAL v_14_15_TOTAL

/* Inpatients Children*/
ren ev_14_10_1_a_1 v_14_3_1_a_TOTAL
ren ev_14_10_1_b_1 v_14_3_2_a_TOTAL

/* Inpatients Adults*/
ren ev_14_10_1_a_2 v_14_3_1_b_TOTAL
ren ev_14_10_1_b_2 v_14_3_2_b_TOTAL

/* Inpatient Death */
ren ev_14_10_2_a_TOTAL v_14_9_1_TOTAL
ren ev_14_10_2_b_TOTAL v_14_9_2_TOTAL

/* Operations */
ren ev_14_13_1_TOTAL v_14_8_1_TOTAL
ren ev_14_13_1A_TOTAL v_14_8_2_TOTAL
ren ev_14_13_2_TOTAL v_14_8_4_TOTAL
ren ev_14_14_b_TOTAL v_14_1_8_TOTAL
// adolescent couselling available as an aggregate left as is. 

/* Laboratory Testing */

/* Haemoglobin Tests */
ren ev_15_1_a_TOTAL v_15_2_1_TOTAL
ren ev_15_1_1_a_TOTAL v_15_2_2_TOTAL

/* HIV Tests */
ren ev_15_1_2_a_1 v_15_3_1_a_TOTAL
ren ev_15_1_2_a_2 v_15_3_1_b_TOTAL
ren ev_15_1_2_b_1 v_15_3_2_a_TOTAL
ren ev_15_1_2_b_2 v_15_3_2_b_TOTAL
ren ev_15_1_2_c_1 v_15_3_3_a_TOTAL
ren ev_15_1_2_c_2 v_15_3_3_b_TOTAL

/* Widal Tests */
ren ev_15_2_Number_tested v_15_4_1_TOTAL

/* Syphilis/VDRL Tests */
ren ev_15_3_a_Number_tested v_15_3_4_a_TOTAL
ren ev_15_3_b_Number_tested v_15_3_4_c_TOTAL
ren ev_15_3_c_Number_tested v_1_6_2_a_TOTAL

/* Malaria Tests */
/* We Assume microscopy tests == blood smear test */
ren ev_15_4_1_TOTAL v_11_1_1_a_TOTAL
ren ev_15_4_2_TOTAL v_11_1_1_b_TOTAL
ren ev_15_4_3_TOTAL v_11_1_1_c_TOTAL

/* Vaccinations */

/* DPT  */
ren ev_16_1_1_1 v_17_1_1
ren ev_16_1_1_2 v_17_1_2
ren ev_16_1_1_3 v_17_1_3
ren ev_16_1_1_4 v_17_1_4
ren ev_16_1_1_5 v_17_1_5

/* Penatvalent  */
ren ev_16_1_1A_1 v_17_2_1
ren ev_16_1_1A_2 v_17_2_2
ren ev_16_1_1A_3 v_17_2_3
ren ev_16_1_1A_4 v_17_2_4
ren ev_16_1_1A_5 v_17_2_5

/* OPV  */
ren ev_16_1_2_1 v_17_3_1
ren ev_16_1_2_2 v_17_3_2
ren ev_16_1_2_3 v_17_3_3
ren ev_16_1_2_4 v_17_3_4
ren ev_16_1_2_5 v_17_3_5

/* TT  */
ren ev_16_1_3_1 v_17_4_1
ren ev_16_1_3_2 v_17_4_2
ren ev_16_1_3_3 v_17_4_3
ren ev_16_1_3_4 v_17_4_4
ren ev_16_1_3_5 v_17_4_5

/* DT  */
ren ev_16_1_4_1 v_17_5_1
ren ev_16_1_4_2 v_17_5_2
ren ev_16_1_4_3 v_17_5_3
ren ev_16_1_4_4 v_17_5_4
ren ev_16_1_4_5 v_17_5_5

/* BCG  */
ren ev_16_1_5_1 v_17_6_1
ren ev_16_1_5_2 v_17_6_2
ren ev_16_1_5_3 v_17_6_3
ren ev_16_1_5_4 v_17_6_4
ren ev_16_1_5_5 v_17_6_5

/* Measles */
ren ev_16_1_6_1 v_17_7_1
ren ev_16_1_6_2 v_17_7_2
ren ev_16_1_6_3 v_17_7_3
ren ev_16_1_6_4 v_17_7_4
ren ev_16_1_6_5 v_17_7_5

/* JE */
ren ev_16_1_7_1 v_17_8_1
ren ev_16_1_7_2 v_17_8_2
ren ev_16_1_7_3 v_17_8_3
ren ev_16_1_7_4 v_17_8_4
ren ev_16_1_7_5 v_17_8_5

/* Hep B */
ren ev_16_1_8_1 v_17_9_1
ren ev_16_1_8_2 v_17_9_2
ren ev_16_1_8_3 v_17_9_3
ren ev_16_1_8_4 v_17_9_4
ren ev_16_1_8_5 v_17_9_5

/* Family Planning Inventory Data */

/* IUD 380A */
ren ev_16_2_1_1 v_18_1_1
ren ev_16_2_1_2 v_18_1_2
ren ev_16_2_1_3 v_18_1_3
ren ev_16_2_1_4 v_18_1_4
ren ev_16_2_1_5 v_18_1_5

/* Condoms */
ren ev_16_2_2_1 v_18_3_1
ren ev_16_2_2_2 v_18_3_2
ren ev_16_2_2_3 v_18_3_3
ren ev_16_2_2_4 v_18_3_4
ren ev_16_2_2_5 v_18_3_5

/* Oral Contraceptive */
ren ev_16_2_3_1 v_18_4_1
ren ev_16_2_3_2 v_18_4_2
ren ev_16_2_3_3 v_18_4_3
ren ev_16_2_3_4 v_18_4_4
ren ev_16_2_3_5 v_18_4_5

/* Emergency Contraceptive */
ren ev_16_2_4_1 v_18_5_1
ren ev_16_2_4_2 v_18_5_2
ren ev_16_2_4_3 v_18_5_3
ren ev_16_2_4_4 v_18_5_4
ren ev_16_2_4_5 v_18_5_5

/* Tubal Rings */
ren ev_16_2_5_1 v_18_8_1
ren ev_16_2_5_2 v_18_8_2
ren ev_16_2_5_3 v_18_8_3
ren ev_16_2_5_4 v_18_8_4
ren ev_16_2_5_5 v_18_8_5

/* Miscellaneous Inventory */

/* Gloves */
ren ev_16_3_02_1 v_19_1_1
ren ev_16_3_02_2 v_19_1_2
ren ev_16_3_02_3 v_19_1_3
ren ev_16_3_02_4 v_19_1_4
ren ev_16_3_02_5 v_19_1_5

/* MVA Syringes */
ren ev_16_3_03_1 v_19_2_1
ren ev_16_3_03_2 v_19_2_2
ren ev_16_3_03_3 v_19_2_3
ren ev_16_3_03_4 v_19_2_4
ren ev_16_3_03_5 v_19_2_5

/* Fluconazole Tablets */
ren ev_16_3_04_1 v_19_3_1
ren ev_16_3_04_2 v_19_3_2
ren ev_16_3_04_3 v_19_3_3
ren ev_16_3_04_4 v_19_3_4
ren ev_16_3_04_5 v_19_3_5

/* Blood Transfusion Sets */
ren ev_16_3_05_1 v_19_4_1
ren ev_16_3_05_2 v_19_4_2
ren ev_16_3_05_3 v_19_4_3
ren ev_16_3_05_4 v_19_4_4
ren ev_16_3_05_5 v_19_4_5

/* Gluteraldehyde 2%  */
ren ev_16_3_06_1 v_19_5_1
ren ev_16_3_06_2 v_19_5_2
ren ev_16_3_06_3 v_19_5_3
ren ev_16_3_06_4 v_19_5_4
ren ev_16_3_06_5 v_19_5_5

/* IFA Tablets */
ren ev_16_3_07_1 v_19_6_1
ren ev_16_3_07_2 v_19_6_2
ren ev_16_3_07_3 v_19_6_3
ren ev_16_3_07_4 v_19_6_4
ren ev_16_3_07_5 v_19_6_5

/* IFA Syrup */
ren ev_16_3_08_1 v_19_9_1
ren ev_16_3_08_2 v_19_9_2
ren ev_16_3_08_3 v_19_9_3
ren ev_16_3_08_4 v_19_9_4
ren ev_16_3_08_5 v_19_9_5

/* Pediatric Antibiotics */
ren ev_16_3_09_1 v_19_10_1
ren ev_16_3_09_2 v_19_10_2
ren ev_16_3_09_3 v_19_10_3
ren ev_16_3_09_4 v_19_10_4
ren ev_16_3_09_5 v_19_10_5

/* Vitaman A Solution Merged with Vitamin A Syrup**  */
ren ev_16_3_10_1 v_19_11_1
ren ev_16_3_10_2 v_19_11_2
ren ev_16_3_10_3 v_19_11_3
ren ev_16_3_10_4 v_19_11_4
ren ev_16_3_10_5 v_19_11_5

/* ORS(New WHO) */
ren ev_16_3_11_1 v_19_12_1
ren ev_16_3_11_2 v_19_12_2
ren ev_16_3_11_3 v_19_12_3
ren ev_16_3_11_4 v_19_12_4
ren ev_16_3_11_5 v_19_12_5

/* Syringes*/

/* 0.1ml */
ren ev_16_4_1_1 v_20_1_1
ren ev_16_4_1_2 v_20_1_2
ren ev_16_4_1_3 v_20_1_3
ren ev_16_4_1_4 v_20_1_4
ren ev_16_4_1_5 v_20_1_5

/* 0.5ml */
ren ev_16_4_2_1 v_20_2_1
ren ev_16_4_2_2 v_20_2_2
ren ev_16_4_2_3 v_20_2_3
ren ev_16_4_2_4 v_20_2_4
ren ev_16_4_2_5 v_20_2_5

/* 5ml Disposable */
ren ev_16_4_3_1 v_20_3_1
ren ev_16_4_3_2 v_20_3_2
ren ev_16_4_3_3 v_20_3_3
ren ev_16_4_3_4 v_20_3_4
ren ev_16_4_3_5 v_20_3_5

/* Deaths */

/* Infant deaths first 24 hours */
ren ev_17_1_TOTAL v_16_1_TOTAL

/* Infant deaths upto 4 weeks due to sepsis */
ren ev_17_2_1_3 v_16_2_1_TOTAL

/* Infant deaths upto 4 weeks due to asphyxia */
ren ev_17_2_2_3 v_16_2_2_TOTAL

/* Infant deaths upto 4 weeks due to other reasons */
gen v_16_2_3_TOTAL = ev_17_2_3_3 + ev_17_2_4_3

/* Infant deaths in 1st year due to Pneumonia */
ren ev_17_3_1_1 v_16_3_1_TOTAL

/* Infant deaths in 1st year due to Diarrhoea */
ren ev_17_3_2_1 v_16_3_2_TOTAL

/* Infant deaths in 1st year due to Fever */
ren ev_17_3_3_1 v_16_3_3_TOTAL

/* Infant deaths in 1st year due to Measles */
ren ev_17_3_4_1 v_16_3_4_TOTAL

/* Infant deaths in 1st year due to Other causes */
ren ev_17_3_5_1 v_16_3_5_TOTAL

/* Infant deaths (1-5 years) due to Pneumonia */
ren ev_17_3_1_2 v_16_4_1_TOTAL

/* Infant deaths (1-5 years) due to Diarrhoea */
ren ev_17_3_2_2 v_16_4_2_TOTAL

/* Infant deaths (1-5 years) due to Fever */
ren ev_17_3_3_2 v_16_4_3_TOTAL

/* Infant deaths (1-5 years) due to Measles */
ren ev_17_3_4_2 v_16_4_4_TOTAL

/* Infant deaths (1-5 years) due to Other causes */
ren ev_17_3_5_2 v_16_4_5_TOTAL

/* Adult/Adoloscent Deaths due to Diarrhoea */
ren ev_17_4_1_4 v_16_7_1_TOTAL

/* Adult/Adoloscent Deaths due to Tuberculosis */
ren ev_17_4_2_4 v_16_7_2_TOTAL

/* Adult/Adoloscent Deaths due to Respiratory disease(not TB) */
ren ev_17_4_3_4 v_16_7_3_TOTAL

/* Adult/Adoloscent Deaths due to Malaria */
//ren ev_17_4_1_4 is split by species in 2017-2020 data, so this is skipped.

/* Adult/Adoloscent Deaths due to Fever */
ren ev_17_4_5_4 v_16_7_4_TOTAL

/* Adult/Adoloscent Deaths due to HIV/AIDS */
ren ev_17_4_6_4 v_16_7_5_TOTAL

/* Adult/Adoloscent Deaths due to Heart Disease/Hypertension */
ren ev_17_4_7_4 v_16_7_6_TOTAL

/* Adult/Adoloscent Deaths due to Neurological Disease  */
ren ev_17_4_8_4 v_16_7_8_TOTAL

/* Adult/Adoloscent Deaths due to Trauma/Accident/Burn */
ren ev_17_4_10_4 v_16_7_9_TOTAL

/* Adult/Adoloscent Deaths due to Suicide */
ren ev_17_4_11_4 v_16_7_10_TOTAL

/* Adult/Adoloscent Deaths due to Animal Bites */
ren ev_17_4_12_4 v_16_7_11_TOTAL

/* Adult/Adoloscent Deaths due to Acute Disease */
ren ev_17_4_13_a_4 v_16_7_12_TOTAL

/* Adult/Adoloscent Deaths due to Chronic Disease */
ren ev_17_4_13_b_4 v_16_7_13_TOTAL

/* Adult/Adoloscent Deaths due to unknown causes */
ren ev_17_4_13_c_4 v_16_7_14_TOTAL

/* Maternal Deaths Due to Bleeding */
ren ev_17_4_9_d_4 v_16_5_1_TOTAL

/* Maternal Deaths Due to High Fever */
ren ev_17_4_9_e_4 v_16_5_2_TOTAL

/* Maternal Deaths Due to Abortion */
ren ev_17_4_9_a_4 v_16_5_3_TOTAL

/* Maternal Deaths Due to Obstructed/Prolonged labour */
ren ev_17_4_9_b_4 v_16_5_4_TOTAL

/* Maternal Deaths Due to Hypertension/fits */
ren ev_17_4_9_c_4 v_16_5_5_TOTAL

/* Maternal Deaths Due to Unknown Causes */
ren ev_17_4_9_f_4 v_16_5_6_TOTAL

/* Save data */
save $tmp/hmis_early_years, replace

/* Create an empty temp file to append later years' data */
clear
save $tmp/hmis_later_years, replace emptyok

/* Append Data for years 2017-2021 */
local later_years "2017-2018 2018-2019 2019-2020 2020-2021"

foreach year in `later_years'{
  use $tmp/hmis/hmis_dist_clean_`year', clear
  append using $tmp/hmis_later_years
  save $tmp/hmis_later_years, replace
}

/* Add Early Years' Data to this */
// 290 variables matched, 188 unmatched from 2008/09-2016/17.
append using $tmp/hmis_early_years

/* We also rename select variables*/

/* Child Immunisations  */
rename v_9_1_2_TOTAL	hm_vac_bcg
rename v_9_1_13_TOTAL	hm_vac_hepb
rename v_9_1_9_TOTAL hm_vac_opv0
rename v_9_7_2_TOTAL hm_vac_sessions

/* Hospital Attendance Numbers */
rename v_14_3_1_b_TOTAL	hm_inpatient_adult_m 
rename v_14_3_2_b_TOTAL	hm_inpatient_adult_f
rename v_14_3_1_a_TOTAL	hm_inpatient_kids_m
rename v_14_3_2_a_TOTAL	hm_inpatient_kids_f
rename v_14_4_4_TOTAL	hm_inpatient_respiratory
rename v_14_1_1_TOTAL	hm_outpatient_diabetes
rename v_14_1_2_TOTAL	hm_outpatient_hypertension
rename v_14_1_9_TOTAL	hm_outpatient_cancer
rename v_14_5_TOTAL	hm_emergency_total
rename v_14_6_1_TOTAL	hm_emergency_trauma
rename v_14_6_5_TOTAL	hm_emergency_heart_attack
rename v_14_8_1_TOTAL	hm_operation_major
rename v_14_8_4_TOTAL	hm_operation_minor

/* Testing */
rename v_15_1_TOTAL	hm_tests_total 
rename v_15_3_1_a_TOTAL	 hm_tests_hiv_m
rename v_15_3_2_a_TOTAL	hm_tests_hiv_f
rename v_15_3_3_a_TOTAL hm_tests_hiv_f_anc  

/* Maternal Health */
rename v_1_1_TOTAL hm_anc_registered
rename v_2_2_TOTAL hm_delivery_institutional
rename v_2_1_1_a_TOTAL hm_delivery_anm	
rename v_2_1_1_b_TOTAL  hm_delivery_no_anm
rename v_4_1_1_b_TOTAL hm_birth_f	
rename v_4_1_1_a_TOTAL hm_birth_m
rename v_2_1_3_TOTAL hm_care_home
rename v_2_2_2_TOTAL hm_care_institution	

/* PPE */
rename v_19_1_1 hm_gloves_balance
rename v_19_1_2	hm_gloves_received 
rename v_19_1_3	hm_gloves_unusable
rename v_19_1_4	hm_gloves_distributed
rename v_19_1_5	hm_gloves_total

/* Deaths Data */

/* Deaths due to sterilisation */
ren v_8_17_5_TOTAL hm_death_sterilise_m
ren v_8_17_6_TOTAL hm_death_sterilise_f

/* Deaths at a hospital */
ren v_9_6_2_TOTAL hm_death_aefi
ren v_14_7_TOTAL hm_death_emergency
ren v_14_9_1_TOTAL hm_death_inpat_m
ren v_14_9_2_TOTAL hm_death_inpat_f

/* Infant and Child Deaths */
ren v_14_13_TOTAL hm_death_infant_sncu
ren v_16_1_TOTAL hm_death_infant_24h
ren v_16_2_1_TOTAL hm_death_infant_4w_sepsis
ren v_16_2_2_TOTAL hm_death_infant_4w_asphyxia
ren v_16_2_3_TOTAL hm_death_infant_4w_other
ren v_16_3_1_TOTAL hm_death_infant_1y_pneumonia
ren v_16_3_2_TOTAL hm_death_infant_1y_diarrhoea
ren v_16_3_3_TOTAL hm_death_infant_1y_fever
ren v_16_3_4_TOTAL hm_death_infant_1y_measles
ren v_16_3_5_TOTAL hm_death_infant_1y_others
ren v_16_4_1_TOTAL hm_death_infant_5y_pneumonia
ren v_16_4_2_TOTAL hm_death_infant_5y_diarrhoea
ren v_16_4_3_TOTAL hm_death_infant_5y_fever
ren v_16_4_4_TOTAL hm_death_infant_5y_measles
ren v_16_4_5_TOTAL hm_death_infant_5y_others

/* Maternal Deaths */
ren v_16_5_1_TOTAL hm_death_maternal_bleeding
ren v_16_5_2_TOTAL hm_death_maternal_fever
ren v_16_5_3_TOTAL hm_death_maternal_abortion
ren v_16_5_4_TOTAL hm_death_maternal_labor
ren v_16_5_5_TOTAL hm_death_maternal_fits
ren v_16_5_6_TOTAL hm_death_maternal_other

/* Adult Death */
ren v_16_7_1_TOTAL hm_death_adult_diarrhoea
ren v_16_7_2_TOTAL hm_death_adult_tuberculosis
ren v_16_7_3_TOTAL hm_death_adult_respiratory
ren v_16_7_4_TOTAL hm_death_adult_fever
ren v_16_7_5_TOTAL hm_death_adult_hiv
ren v_16_7_6_TOTAL hm_death_adult_hypertension
ren v_16_7_7_TOTAL hm_death_adult_cancer
ren v_16_7_8_TOTAL hm_death_adult_stroke
ren v_16_7_9_TOTAL hm_death_adult_accident_burns
ren v_16_7_10_TOTAL hm_death_adult_suicide
ren v_16_7_11_TOTAL hm_death_adult_animalbite
ren v_16_7_12_TOTAL hm_death_adult_acute_disease
ren v_16_7_13_TOTAL hm_death_adult_chronic_disease
ren v_16_7_14_TOTAL hm_death_adult_unknown

/* Deaths Viruses */
ren v_16_8_1_TOTAL hm_death_viral_malaria_pvivax
ren v_16_8_2_TOTAL hm_death_viral_malaria_pfalci
ren v_16_8_3_TOTAL hm_death_viral_kalaazar
ren v_16_8_4_TOTAL hm_death_viral_dengue
ren v_16_8_5_TOTAL hm_death_viral_aes
ren v_16_8_6_TOTAL hm_death_viral_je

/* rename and label hospitals with their full names */
label var sc "Number of Sub Center Reporting Reporting"
label var phc "Number of Primary Health Center Reporting"
label var chc "Number of Community Health Center Reporting"
label var sdh "Number of Sub District Hospital Reporting"
label var dh  "Number of District Hospital Reporting"
label var total "Total Number of Hospitals Reporting"

rename sc hm_hosp_sc
rename phc hm_hosp_phc
rename chc hm_hosp_chc
rename sdh hm_hosp_sdh
rename dh hm_hosp_dh
rename total hm_hosp_total

/* Label identifiers */
label var state "Name of the State"
label var district "Name of the district"
label var year "Calendar Year"
label var month "Month"
label var category "Total/Rural/Urban/Private/Public"
label var year_financial "Financial Year for whcih the data is reported"

/* Get identifiers and renmaed variables to the front */
order hm_*, alphabetic
order state district year month category year_financial 

/* Rename other variables to some extent */
ren ev_* hm_ev_*
ren v_* hm_v_*

/* Save Data */
compress
save $health/hmis/hmis_dist_clean.dta, replace

/* save to covid repo */
save $covidpub/hmis/hmis_dist_clean.dta, replace
export delimited $covidpub/hmis/csv/hmis_dist_clean.csv, replace
