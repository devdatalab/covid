/***************************************/
/* Clean Madhya Pradesh mortality data */
/***************************************/

/* set globals for month and year */
global month "january february march april may june july august september october november december"

global year "2018 2019 2020 2021"

/* process raw data from January 2018 to May 2021 */
foreach j in $year {
  
/* conditional global for 2021 since data is available upto May */
  if `j' == 2021 {
    global month = "january february march april may"
  }

  foreach i in $month {

/* import raw data */
    import excel "$covidpub/mortality/raw/madhya_pradesh/`j'/`i'`j'.xlsx", sheet("Monitoring Report") firstrow clear

/* rename vars and drop redundant obs */
    ren SlNo id
    ren District district
    ren C deaths

    drop in 1/2
    drop if id == ""

/* generate variables for month and year */
    gen month = "`i'"
    gen year = "`j'"
    gen state = "Madhya Pradesh"

    destring * , replace
    order id state district
    
/* save temp file for month-year */
    save $tmp/`i'`j' , replace

  }
}

clear

/* reset global */
global month "january february march april may june july august september october november december"

/* append all month-year data */
foreach j in $year {

  if `j' == 2021 {
    global month = "january february march april may"
  }

  foreach i in $month {

    append using $tmp/`i'`j'

  }
}

/* save clean dataset unique on district-month-year */
save $tmp/mort_mp.dta
