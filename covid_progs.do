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

