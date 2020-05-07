/* this do file defines programs used by various do files in the covid repo */


/***********************************************************************/
/* Program lgd_state_clean : Use to prep state variable for lgd match */
/***********************************************************************/

cap prog drop lgd_state_clean
prog def lgd_state_clean

{
  syntax varname (min=1)

   /* format variables */
   gen lgd_state_name = lower(trim(`0'))
   replace lgd_state_name = "" if real(lgd_state_name) ~= .
   replace lgd_state_name = substr(lgd_state_name, 1, strpos(lgd_state_name, "(") - 1) if regexm(lgd_state_name, "\(")
    
   /* format state and clean names for merge */
   replace lgd_state_name = "andaman and nicobar islands" if `0' == "A & N Islands"
   replace lgd_state_name = subinstr(lgd_state_name, "&", "and", .)
   replace lgd_state_name = "jammu and kashmir" if inlist(lgd_state_name, "jammu", "kashmir")
   replace lgd_state_name = "dadra and nagar haveli" if lgd_state_name == "d and n haveli"
   replace lgd_state_name = "andaman and nicobar islands" if lgd_state_name == "a"
   drop if inlist(lgd_state_name, "code", "state/u.t.")

  }

end

/*****************************************************************************/
/*                   END program lgd_state_clean                             */
/*****************************************************************************/


/********************************************************************************/
/* Program lgd_state_match : Use to match state keys to lgd_pc11_state_key */
/********************************************************************************/

cap prog drop lgd_state_match
prog def lgd_state_match

{
   syntax varname (min=1)

   /* extract lgd state names and ids */
   merge m:1 lgd_state_name using $keys/lgd_pc11_state_key, gen(state_merge) 

  }

end    

/*****************************************************************************/
/*                   END program lgd_state_match                             */
/*****************************************************************************/



/********************************************************************************/
/* Program lgd_dist_clean : Use to prep district variable for lgd match */
/********************************************************************************/

cap prog drop lgd_dist_clean

prog def lgd_dist_clean

{
   syntax varname (min=1)

   /*format variables */
   gen lgd_district_name = lower(`0')  

   /*format district names for merge */
   replace lgd_district_name = subinstr(lgd_district_name, "paschim", "west", .)
   replace lgd_district_name = subinstr(lgd_district_name, "purba", "east", .)
   replace lgd_district_name = subinstr(lgd_district_name, "paschimi", "west", .)
   replace lgd_district_name = subinstr(lgd_district_name, "purbi", "east", .)

   /*these districts are in ladakh in using data, but may not be in master data */
   replace lgd_state_name = "ladakh" if inlist(lgd_district_name, "leh ladakh", "kargil", "leh")
 
   if "`0'" == "hmis_district" {
      
   /* these obs masala merge incorrectly */
   replace lgd_district_name = "ayodhya" if `0' == "Faizabad"
   replace lgd_district_name = "purbi champaran" if `0' == "East Champaran"

   }

   if "`0'" == "nss_district_name" {
   
   /* these obs masala merge incorrectly */
   replace lgd_district_name = "ayodhya" if `0' == "faizabad"

   }
    
   /*fix lgd district name spellings */
   fix_spelling lgd_district_name, src($keys/lgd_pc11_district_key.dta) group(lgd_state_name) replace


  /*display and drop duplicates */
   duplicates list lgd_state_name lgd_district_name
   bys lgd_state_name lgd_district_name : keep if _n == 1

  }

end


/*****************************************************************************/
/*                   END program lgd_dist_clean                             */
/*****************************************************************************/

/********************************************************************************/
/* Program lgd_dist_match : Use to merge district key to lgd_pc11_district_key */
/********************************************************************************/

cap prog drop lgd_dist_match

prog def lgd_dist_match

{
   syntax varname (min=1)
    
   /* merge with lgd pc11 district key */
   merge 1:1 lgd_state_name lgd_district_name using $keys/lgd_pc11_district_key, gen(`0'_lgd_merge) update

   /* generate merge tracker */
   gen lgd_dist_match = "simple merge" if `0'_lgd_merge == 3
    
   /* save matched and unmatched obs separately */
   savesome using $tmp/master_matched_r1 if `0'_lgd_merge == 3, replace
   savesome using $tmp/master_unmatched_r1 if `0'_lgd_merge == 1, replace
   savesome using $tmp/lgd_unmatched_r1 if `0'_lgd_merge == 2, replace

   /* prep for masala merge */
   use $tmp/master_unmatched_r1, clear

   /* generate ids */
   gen idm = lgd_state_name + "=" + lgd_district_name

   /* drop extra vars */
   cap drop *_merge
   cap drop lgd_state_id lgd_state_version lgd_state_name_local lgd_state_status 
   cap drop lgd_district_id lgd_district_version lgd_district_name_local pc11* pc01*

   
   if "`0'" == "hmis_district" {

   /* manual merges after checking unmatched output */
   replace lgd_district_name = "y s r" if `0' == "Cuddapah"
   replace lgd_district_name = "nuh" if `0' == "Mewat"
   replace lgd_district_name = "kalaburagi" if `0' == "Gulbarga"
   replace lgd_district_name = "east nimar" if `0' == "Khandwa"
   replace lgd_district_name = "amethi" if `0' == "C S M Nagar"
   replace lgd_district_name = "amroha" if `0' == "Jyotiba Phule Nagar"

   }

   if "`0'" == "nss_district_name" {

   /* manual merges after checking unmatched output */   
   replace lgd_district_name = "nuh" if `0' == "mewat"
   replace lgd_district_name = "kalaburagi" if `0' == "gulbarga"
   replace lgd_district_name = "amroha" if `0' == "jyotiba phule nagar"
   replace lgd_district_name = "leh ladakh" if `0' == "leh"
   replace lgd_district_name = "hathras" if `0' == "mahamaya nagar" 
   replace lgd_district_name = "s.a.s nagar" if `0' == "sahibzada ajit singh"


   /*expand jaintia hills into two obs*/
   expand_n 1 if lgd_district_name == "jaintia hills", gen(dups)
   replace lgd_district_name = "east jaintia hills" if dups == 1
   replace lgd_district_name = "west jaintia hills" if lgd_district_name == "jaintia hills"   
   drop dups
   }

   /* save */
   save $tmp/master_fmm, replace

   use $tmp/lgd_unmatched_r1, clear

   /* generate ids */
   gen idu = lgd_state_name + "=" + lgd_district_name

   /* drop extra vars */
   cap drop *_merge
   keep lgd_* pc* idu
    
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
   label variable lgd_dist_match "Merge level"
  }

end    

/*****************************************************************************/
/*                   END program lgd_dist_match                             */
/*****************************************************************************/


