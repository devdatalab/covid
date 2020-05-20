/* this do file defines programs used by various do files in the covid repo */


/***********************************************************************/
/* Program lgd_state_clean : Use to prep state variable for lgd match */
/***********************************************************************/

cap prog drop lgd_state_clean
prog def lgd_state_clean
  {
    /* varname is the state identifier to be matched, e.g. `state` for covid case data */
    syntax varname (min=1)

    /* format variables */
    gen lgd_state_name = lower(trim(`0'))
    replace lgd_state_name = "" if real(lgd_state_name) ~= .
    replace lgd_state_name = substr(lgd_state_name, 1, strpos(lgd_state_name, "(") - 1) if regexm(lgd_state_name, "\(")
    
    /* format state and clean names for merge */
    replace lgd_state_name = subinstr(lgd_state_name, "&", "and", .)
    replace lgd_state_name = trim(lgd_state_name)

    /* these idiosyncratic fixes have not resulted in collisions yet;
    if they do in the future, put them in dataset-specific `if`
    blocks. */
    replace lgd_state_name = "andaman and nicobar islands" if `0' == "A & N Islands"
    replace lgd_state_name = "jammu and kashmir" if inlist(lgd_state_name, "jammu", "kashmir")
    replace lgd_state_name = "dadra and nagar haveli" if lgd_state_name == "d and n haveli"
    replace lgd_state_name = "andaman and nicobar islands" if lgd_state_name == "a"
    drop if inlist(lgd_state_name, "code", "state/u.t.")
    replace lgd_state_name = "andaman and nicobar islands" if lgd_state_name == "andaman and nicobar"
    replace lgd_state_name = "maharashtra" if lgd_state_name == "maharastra"
    replace lgd_state_name = "chhattisgarh" if lgd_state_name == "chattisgarh"
    replace lgd_state_name = "odisha" if lgd_state_name == "orissa"
    
    /* fill down state identifier when missing */
    replace lgd_state_name = lgd_state_name[_n-1] if mi(lgd_state_name)
  }
end
/* *********** END program lgd_state_clean ***************************************** */


/********************************************************************************/
/* Program lgd_state_match : Use to match state keys to lgd_pc11_state_key */
/********************************************************************************/

cap prog drop lgd_state_match
prog def lgd_state_match
  {
    syntax varname (min=1)

    /* extract lgd state names and ids */
    merge m:1 lgd_state_name using $keys/lgd_state_key, gen(state_merge) 

    /* list states that didn't merge from key  */
    disp_nice "Unmatched master"
    list `0' if state_merge == 1
    disp_nice "Unmatched using"
    list lgd_state_name if state_merge == 2

    /* keep merged obs */
    keep if state_merge == 3
    drop state_merge
    drop `0'
  }
end    
/* *********** END program lgd_state_match ***************************************** */


/********************************************************************************/
/* Program lgd_dist_clean : Use to prep district variable for lgd match */
/********************************************************************************/

cap prog drop lgd_dist_clean
prog def lgd_dist_clean
  {
    syntax varname (min=1)

    /* assert lowercase name strings from input variable */
    gen lgd_district_name = lower(`0')  

    /* run universal string corrections that don't collide across datasets */
    replace lgd_district_name = subinstr(lgd_district_name, "paschim", "west", .)
    replace lgd_district_name = subinstr(lgd_district_name, "purba", "east", .)
    replace lgd_district_name = subinstr(lgd_district_name, "paschimi", "west", .)
    replace lgd_district_name = subinstr(lgd_district_name, "purbi", "east", .)

    /* these districts are in ladakh in using data, but may not be in master data */
    replace lgd_state_name = "ladakh" if inlist(lgd_district_name, "leh ladakh", "kargil", "leh", "ladakh")

    /* these districts are in telangana in using data but may not be in master data  */
    replace lgd_state_name = "telangana" if inlist(lgd_district_name, "mahbubnagar", "nalgonda", "khammam", "nizamabad", "hyderabad")
    replace lgd_state_name = "telangana" if inlist(lgd_district_name, "warangal", "karimnagar", "medak", "rangareddi", "adilabad")

    /* replace master to lower case */
    replace `0' = lower(trim(`0'))

    /* run synonym fixes in name cleaning  */
    synonym_fix lgd_district_name, synfile(~/ddl/covid/b/str/lgd_district_fixes.txt) replace group(lgd_state_name)
    
    /* idiosyncratic NSS changes */
    if "`0'" == "nss_district_name" {

      /* expand jaintia hills into two obs */
      expand 2 if lgd_district_name == "jaintia hills", gen(dups)                                 
      replace lgd_district_name = "east jaintia hills" if dups == 1                               
      replace lgd_district_name = "west jaintia hills" if lgd_district_name == "jaintia hills"    
      drop dups                                                                                  
      /***********************************************************************************************/

    }
    
    /* idiosyncratic covid case data changes */
    if "`0'" == "district" {

      /* dropping a district called "Lower" in Arunachal  */
      drop if `0' == "lower"
      
      /*expand jaintia hills into two obs*/
      expand 2 if lgd_district_name == "jaintia hills", gen(dups)
      replace lgd_district_name = "east jaintia hills" if dups == 1
      replace lgd_district_name = "west jaintia hills" if lgd_district_name == "jaintia hills"   
      drop dups

      /*expand warangal into two obs*/
      expand 2 if lgd_district_name == "warangal", gen(dups)                             
      replace lgd_district_name = "warangal rural" if dups == 1                          
      replace lgd_district_name = "warangal urban" if lgd_district_name == "warangal"    
      drop dups                                                                          
    }
    
    /* match name spellings to the lgd:pc11 district key to ensure an accurate merge */
    fix_spelling lgd_district_name, src($keys/lgd_pc11_district_key.dta) group(lgd_state_name) replace

    /* display and drop duplicates */
    duplicates list lgd_state_name lgd_district_name
    bys lgd_state_name lgd_district_name : keep if _n == 1
  }
end
/* *********** END program lgd_dist_clean ***************************************** */


/********************************************************************************/
/* Program lgd_dist_match : Use to merge district key to lgd_pc11_district_key */
/********************************************************************************/

cap prog drop lgd_dist_match
prog def lgd_dist_match
  {
    syntax varname (min=1)
    
    /* merge with lgd pc11 district key */
    merge 1:1 lgd_state_name lgd_district_name using $keys/lgd_district_key, gen(`0'_lgd_merge) update

    /* generate merge tracker */
    gen lgd_dist_match = "simple merge" if `0'_lgd_merge == 3
    
    /* save matched and unmatched obs separately */
    savesome using $tmp/master_matched_r1 if `0'_lgd_merge == 3, replace
    savesome using $tmp/master_unmatched_r1 if `0'_lgd_merge == 1, replace
    savesome using $tmp/lgd_unmatched_r1 if `0'_lgd_merge == 2, replace

    /* prep for masala merge for unmatched master observations not merged to the key */
    use $tmp/master_unmatched_r1, clear

    /* drop extra vars */
    cap drop *_merge
    cap drop lgd_state_id lgd_state_version lgd_state_name_local lgd_state_status 
    cap drop lgd_district_id lgd_district_version lgd_district_name_local 

    /* generate ids */
    gen idm = lgd_state_name + "=" + lgd_district_name
    
    /* save corrected _merge == 1 observations */
    save $tmp/master_fmm, replace

    /* open _merge == 2 observations (unmatched from using) */
    use $tmp/lgd_unmatched_r1, clear

    /* generate ids */
    gen idu = lgd_state_name + "=" + lgd_district_name

    /* drop extra vars */
    cap drop *_merge
    keep lgd_* idu
    
    /* save */
    save $tmp/lgd_fmm, replace

    /* prep using data for masala merge */
    use $tmp/master_fmm, clear
    
    /* merge */
    masala_merge lgd_state_name using $tmp/lgd_fmm, s1(lgd_district_name) idmaster(idm) idusing(idu) minbigram(0.2) minscore(0.6) outfile($tmp/`0'_lgd)
    drop lgd_district_name_master
    ren lgd_district_name_using lgd_district_name

    /* check merged status */
    disp_nice "Merge status after masala merge"
    tab match_source
    
    /* update merge tracker */
    replace lgd_dist_match = "masala merge" if match_source < 6
    
    /* save matched separately */
    savesome using $tmp/master_matched_r2 if match_source < 6, replace

    /* append matched obs */
    use $tmp/master_matched_r1, clear
    append using $tmp/master_matched_r2

    /* clean up dataset */
    drop masala* match_source idm idu *_merge
    drop *_version *_local *_match *_status 
    keep *_name *_id 
    order lgd_state_id lgd_district_id, first 
    order *id

    /* all lgd ids should be strings */
    tostring lgd_state_id, format("%02.0f") replace
    tostring lgd_district_id, format("%03.0f") replace
  }
end    
/* *********** END program lgd_dist_match ***************************************** */



/****************************************************************************************************/
/* Program covidsave: Convert easily back and forth between LGD and PC11 identifiers, and write out */
/****************************************************************************************************/

cap prog drop covidsave
prog def covidsave
  {
    /* NOTE: this program requires globals for each var e.g. $`varname'_aggmethod */
    syntax, Native(string) [VARiables(varlist) Level(string) OUTfile(string) Globals_from_csv(string) METAdata_urls(string)]

    /* set default level to district if option is missing (can't set this in the syntax line in Stata) */
    if mi("`level'") local level "district"
    
    /* pull down metadata csv and extract globals, if specified */
    if !mi("`metadata_urls'") {
      foreach url in `metadata_urls' {
        shell wget --no-check-certificate --output-document=$tmp/metadata_scrape.csv '`metadata_urls''
        covidsave_globals_from_csv $tmp/metadata_scrape.csv
      }
    }
    
    /* load globals, if specified */
    if !mi("`globals_from_csv'") covidsave_globals_from_csv `globals_from_csv'
    
    /* set identifiers for FROM and TO */
    if "`native'" == "pc11" {
      local from_ids pc11_state_id pc11_district_id
      local to_ids lgd_state_id lgd_district_id
      local not_native lgd
    }
    if "`native'" == "lgd" {
      local from_ids lgd_state_id lgd_district_id
      local to_ids pc11_state_id pc11_district_id
      local not_native pc11
    }
    
    /* set varlist if not specified */
    if mi("`variables'") {
      unab variables : _all
    }

    /* remove identifiers from varlist */
    local variables : list variables - from_ids

    /* assert globals exist for all vars other than ID */
    disp_nice "Globals in the form of \$[varname]_aggmethod must be set for all collapse (non-id) vars"
    foreach var in `variables' {
      if mi("${`var'_aggmethod}") {
        disp "`var' will be ignored and dropped from this transformation" _n
        local variables : list variables - var
      }
      else disp _n "`var' aggregation type set to: ${`var'_aggmethod}"
    }

    /* save mean values for each variable into locals for validation */
    foreach var in `variables' {
      qui sum `var'
      local `var'_oldmean = `r(mean)'
    }
    
    /* merge in area and population weights */
    isid `from_ids'
    qui merge 1:m `from_ids' using $keys/lgd_pc11_district_key_weights

    /* make sure merge is decent */
    qui count
    local tot_ct `r(N)'
    qui count if _merge == 3
    if `r(N)' / `tot_ct' < 0.9 disp "WARNING: merge rate to pc11:LGD key is less than 90%"
    qui keep if _merge == 3
    drop _merge
    
    /* initialize a collapse string for instances where pc11 dists are aggregated to LGD (or vice versa) */
    local collapse_string
    
    /* conduct the weighting for all variables, using externally-defined globals. loop over calculated vars */
    foreach var in `variables' {
    
      /* aggregation type can be [min, max, mean, count, sum]; sum and
      count are easily area-weighted (same in each direction, split
      and merge) */
      if inlist(lower("${`var'_aggmethod}"), "count", "sum") {

        /* if so, we need to apply weights. weight variable for instances where pc11 dists are split to multiple LGDs */
        qui replace `var' = `var' * pc11_lgd_wt_pop

        /* execute the weights for instances where pc11 dists are merged */
        qui replace `var' = `var' * lgd_pc11_wt_pop

        /* add to collapse string */
        local clean_method = lower("${`var'_aggmethod}")
        local collapse_string `collapse_string' (`clean_method') `var'
      }
      /* means are a bit different. we can population-weight merges, but not splits */
      else if inlist(lower("${`var'_aggmethod}"), "mean") {
        
        /* weight merges only (not splits), and add to collapse call string */
        qui replace `var' = `var' * `native'_`not_native'_wt_pop
        local clean_method = lower("${`var'_aggmethod}")
        local collapse_string `collapse_string' (`clean_method') `var'
      }
      else {
        /* we can't infer how to weight mean, max, min values
        (means/shares may not have a pop denominator), so we assume
        split dists have the same values as their parents.  */
        local collapse_string `collapse_string' (first) `var'
      }    
    }    

    /* collapse to LGD (or pc11) */
    collapse_save_labels
    collapse `collapse_string', by(`to_ids')
    collapse_apply_labels
            
    /* check old and new values */
    foreach var in `variables' {    
      qui sum `var'
      local newmean = `r(mean)'
      if !inrange(`newmean', ``var'_oldmean' * .8, ``var'_oldmean' * 1.2) disp "WARNING: `var' has changed more than 20% from original value (``var'_oldmean' -> `newmean')"
    }
    
    /* add dataset note */
    note: Data programmatically transformed from '`from_ids'' to '`to_ids''

    /* save outfile if specified */
    if !mi("`outfile'") {
      qui compress
      save `outfile', replace
    }
  }
end
/* *********** END program covidsave ***************************************** */



/***************************************************************************************************/
/* Program covidsave_globals_from_csv: pull variable collapse type globals necessary for covidsave */
/***************************************************************************************************/

/* could rework this to use frames to avoid preserve/restore, but
dont' want stata16 dependency */
cap prog drop covidsave_globals_from_csv
prog def covidsave_globals_from_csv
  {
    /* infile is the only argument */
    syntax anything

    /* preserve data in memory */
    preserve
    
    /* print infile requirements */
    disp _n "NOTE: this program requires a .csv file with variable name and aggregationMethod variables" _n
    
    /* rename arg for clarity */
    local infile `anything'
    
    /* read in the file */
    disp "Reading variable definitions from `infile'" _n
    import delimited using `infile', clear

    /* target variable name and aggregation method for adding to globals */
    keep variablename aggregationmethod
    forval i = 1/`=_N' {
      local var = variablename[`i']
      local aggmethod = aggregationmethod[`i']
      if !mi("`aggmethod'") global `var'_aggmethod `aggmethod'
      disp "global set: \$`var'_aggmethod = `aggmethod'"
    }
    restore
  }
end
/* *********** END program covidsave_globals_from_csv ***************************************** */

