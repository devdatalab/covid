/* processes excel files from NRHM HMIS and saves as stata files and csv's */
/* data source: https://nrhm-mis.nic.in/hmisreports/frmstandard_reports.aspx */

/* make directories */
cap mkdir $health/nrhm_hmis
cap mkdir $health/nrhm_hmis/raw/
cap mkdir $health/nrhm_hmis/raw/itemwise_comparison/
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/district
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/subdistrict

/*********/
/* Unzip */
/*********/

/* itemwise monthly */
!unzip -u $health/nrhm_hmis/raw/itemwise_monthly/district/*.zip -d $health/nrhm_hmis/raw/itemwise_monthly/district/
!unzip -u $health/nrhm_hmis/raw/itemwise_monthly/subdistrict/*.zip -d $health/nrhm_hmis/raw/itemwise_monthly/subdistrict/

/****************/
/* Process Data */
/****************/

/********************/
/* Itemwise Monthly */
/********************/

xmluse "$health/nrhm_hmis/raw/itemwise_monthly/district/2019-2020/Goa.xls", doctype(excel) clear

