/* AGMARK MANDI PRICE DATA */
/* source: Matt Lowe (UBC) */

/* Generating a seedfile for appending */
clear
save $tmp/agmark/agmark_new.dta, replace emptyok

/* Loop over all the csv files. Change the loop in a way to loop over all the files */
forval i = 1/13 {
	import delimited $covidpub/agmark/raw/Agmark_`i'.csv, encoding(ISO-8859-1) clear
	
	*Rename all variables
	drop v1
	ren (v2 v3 v4 v5 v6 v7 v8 v9 v10 v11) ///
	(mandi qty unit source spec minprice maxprice modeprice priceunit date1)

	destring modeprice, force replace
	gen item=maxprice if modeprice==.

	replace item="" if mandi=="Andhra Pradesh"| ///
	mandi=="Arunachal Pradesh"| ///
	mandi=="Assam"| ///
	mandi=="Chattisgarh"| ///
	mandi=="Bihar" | ///
	mandi=="Gujarat"| ///
	mandi=="Haryana"| ///
	mandi=="Jharkhand"| ///
	mandi=="Karnataka"| ///
	mandi=="Kerala"| ///
	mandi=="Madhya Pradesh"| ///
	mandi=="Maharashtra"| ///
	mandi=="Manipur"| ///
	mandi=="Meghalaya"| ///
	mandi=="NCT of Delhi"| ///
	mandi=="Nagaland"| ///
	mandi=="Odisha"| ///
	mandi=="Pondicherry"| ///
	mandi=="Punjab"| ///
	mandi=="Rajasthan"| ///
	mandi=="Tamil Nadu"| ///
	mandi=="Telangana"| ///
	mandi=="Tripura"| ///
	mandi=="Uttar Pradesh"| ///
	mandi=="Uttrakhand"| ///
	mandi=="West Bengal" | ///
	mandi=="Goa" | ///
	mandi=="Chandigarh" | ///
	mandi=="Mizoram" | ///
	mandi=="Andaman and Nicobar"| ///
	mandi=="Himachal Pradesh" | ///
	mandi =="Jammu and Kashmir" 

	replace item = item[_n-1] if missing(item)

	gen state=mandi if mandi=="Andhra Pradesh"| ///
	mandi=="Arunachal Pradesh"| ///
	mandi=="Assam"| ///
	mandi=="Chattisgarh"| ///
	mandi=="Bihar" | ///
	mandi=="Gujarat"| ///
	mandi=="Haryana"| ///
	mandi=="Jharkhand"| ///
	mandi=="Karnataka"| ///
	mandi=="Kerala"| ///
	mandi=="Madhya Pradesh"| ///
	mandi=="Maharashtra"| ///
	mandi=="Manipur"| ///
	mandi=="Meghalaya"| ///
	mandi=="NCT of Delhi"| ///
	mandi=="Nagaland"| ///
	mandi=="Odisha"| ///
	mandi=="Pondicherry"| ///
	mandi=="Punjab"| ///
	mandi=="Rajasthan"| ///
	mandi=="Tamil Nadu"| ///
	mandi=="Telangana"| ///
	mandi=="Tripura"| ///
	mandi=="Uttar Pradesh"| ///
	mandi=="Uttrakhand"| ///
	mandi=="West Bengal"| ///
	mandi=="Mizoram" | ///
	mandi=="Goa" | ///
	mandi=="Chandigarh" | ///
	mandi=="Andaman and Nicobar" | ///
	mandi=="Himachal Pradesh" | ///
	mandi == "Jammu and Kashmir" 

	replace state = state[_n-1] if missing(state)

	gen group=mandi if ///
	mandi=="Beverages"| ///
	mandi=="Dry Fruits"| ///
	mandi=="Flowers"| ///
	mandi=="Drug and Narcotics"| ///
	mandi=="Fibre Crops"| ///
	mandi=="Forest Products"| ///
	mandi=="Fruits"| ///
	mandi=="Live Stock,Poultry,Fisheries"| ///
	mandi=="Oil Seeds"| ///
	mandi=="Oils and Fats"| ///
	mandi=="Pulses"| ///
	mandi=="Spices"| ///
	mandi=="Vegetables"| ///
	mandi=="Cereals"| ///
	mandi=="Other"

	replace group = group[_n-1] if missing(group)

	drop if modeprice==.

	gen date=date(date1, "DMY")
	format date %td
	drop date1
	
 append using $tmp/agmark/agmark_new.dta
 save $tmp/agmark/agmark_new.dta, replace
}

*Cleaning up the data
drop if date == .
drop if mandi == state
replace state = lower(state)
replace mandi = lower(mandi)

*Merging in the LSG district codes. We have mapped all Mandis in Agmark database.
*Download and add the market lsg coded file to the path before proceeding
merge m:1 state mandi using $covidpub/agmark/raw/marketcoded, keepusing(district lgd_state_id lgd_district_id)
keep if _merge == 3
drop _merge

label var qty "Arrival Quantity"
label var unit "Unit of Measurement (Qty)"
label var source "Source of Arrival"
label var spec "Specification of Commodity"
label var minprice "Minimum Traded Price (Rupees)"
label var maxprice "Maximum Traded Price (Rupees)"
label var modeprice "Mode of Traded Price (Rupees)"
label var priceunit "Unit of Price expression"
label var item "Name of the item"
label var group "Broad item category"
label var date "Date of reporting"
label var mandi "Name of Mandi"
label var state "State as recorded in Agmark"
label var district "District as recorded in Agmark"

/* For Creating aggregators/ Prototype for only 2020 uncomment the following block
keep if date>td(31dec2019)
*/

*Generate aggregative quantity for items (expressed in Tonnes alone)
destring qty, force replace
bysort date lgd_district_id: egen qty_dist=sum(qty) if unit=="Tonnes"
bysort date lgd_state_id: egen qty_state=sum(qty) if unit=="Tonnes"
bysort date group: egen qty_group=sum(qty) if unit=="Tonnes"

* Generate aggregate Price (All-India, Item Level)
bysort date item: egen price_avg=mean(modeprice)
label var qty_dist "Aggregate Quantity in a District per day (Only those expressed in Tonnes)"
label var qty_state "Aggregate Quantity in a State per day (Only those expressed in Tonnes)"
label var qty_group "Aggregate Quantity for a product group per day (Only those expressed in Tonnes)"
label var price_avg "Average All India Price for the Item in a day "

/* reduce filesize as much as possible */
replace minprice = "" if minprice == "NR"
destring minprice, force replace
replace maxprice = "" if maxprice == "NR"
destring maxprice, force replace 
foreach v in state mandi district item unit source spec priceunit group {
  ren `v' old`v'
  encode old`v', gen(`v')
  drop old`v'
}

/* drop duplicates present in the raw data which do not provide additional information */
duplicates drop date state mandi district item, force

/* write out master dataset */
order date state mandi district item unit priceunit source spec group, first
compress
save $covidpub/agmark/agmark_clean.dta, replace

* If you are generating only 2020 data comment above line and uncomment following line,
*save $covidpub/agmark/agmark_2020lsgcoded.dta, replace 

