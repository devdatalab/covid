/******************************/
/* Clean Bihar mortality data */
/******************************/

/* load covid programs */
qui do $ddl/covid/covid_progs.do

/* set globals for year and month */
global year "2018 2019 2020 2021"
global month "01 02 03 04 05 06 07 08 09 10 11 12"

foreach j in $year {

  /* conditional global for 2021 since data if only available till May */
  if `j' == 2021 {
    global month = "01 02 03 04 05"
  }

  foreach i in $month {

    /* import raw data */
    import excel "$covidpub/mortality/raw/bihar/`j'_`i'.xlsx", sheet("Monitoring Report") cellrange(A4:P45) clear

    /* basic cleaning - keep relevant vars and rename */
    keep A B E F G
    drop if B == ""

    ren A id 
    ren B district 
    ren E death_male
    ren F death_female
    ren G death_trans

    /* generate vars for state, month, year */
    gen state = "Bihar"
    gen month = `i'
    gen year = `j'

    save $tmp/bihar_`i'_`j', replace

  }
}

clear 

/* reset global for month */
global month "01 02 03 04 05 06 07 08 09 10 11 12"

/* append all month-year data */
foreach j in $year {

  if `j' == 2021 {
    global month = "01 02 03 04 05"
  }

  foreach i in $month {

    append using $tmp/bihar_`i'_`j'.dta

  }
}

/* convert months from float to string for consistency */
str_month, float(month) string(str_month)

/* sum total deaths */
egen deaths = rowtotal(death_*)

/* drop gender-wise deaths and id var and order vars */
drop death_* id
order state district deaths month year
