/******************************/
/* Clean Assam mortality data */
/******************************/

/* set globals for year */
global year "2018 2019 2020"

/* process raw data for each year */
foreach j in $year {

  /* import raw data */
  import excel "$covidpub/mortality/raw/assam/`j'.xlsx", sheet("D-4") cellrange(A5:P364) firstrow clear
  drop if C == ""

  /* fill missing values */
  foreach i in A B {
    replace `i' = `i'[_n-1] if mi(`i')
  }

  /* drop redundant vars */
  drop if C == "T"
  drop if A == 27
  drop P

  /* rename vars */
  ren A id
  ren B district
  ren C sex
  ren D death_january
  ren E death_february
  ren F death_march
  ren G death_april
  ren H death_may
  ren I death_june
  ren J death_july
  ren K death_august
  ren L death_september
  ren M death_october
  ren N death_november 
  ren O death_december

  /* reshape from wide to long */
  reshape long death_, i(district sex) j(month) string

  /* drop id var and generate vars for state and year */
  drop id
  gen state = "Assam"
  gen year = "`j'"

  /* rename and order variables */
  ren death_ deaths
  order state district month year death sex

  save "$tmp/assam_`j'" , replace 

}

clear 

/* append all month-year data */
foreach j in $year {

  append using $tmp/assam_`j'

}

collapse (sum) deaths, by(state district month year)

la var state "State"
la var district "District"
la var month "Month"
la var year "Year"
la var deaths "Total Death"

/* save clean dataset unique on district-month-year */
save $tmp/mort_assam.dta, replace
