/* open clean DLHS / AHS */
use $tmp/combined, clear

/* rename simple model to simple for less confusion */
ren *age_sex* *simple*

/* create naive age-sex risk factor (cts) */
gen rf_simple = hr_simple_age_cts * hr_simple_male

/* create age-sex component of biomarker risk factor */
gen rf_full_agesex = hr_full_age_cts * hr_full_male

/* add biomarkers */
gen rf_full_biomarkers = rf_full_agesex
foreach condition in $hr_biomarker_vars {
  replace rf_full_biomarkers = rf_full_biomarkers * hr_full_`condition'
}

/* collapse to the state-age level */
collapse (mean) rf_* $hr_biomarker_vars $hr_selfreport_vars [aw=wt], by(age pc11_state_id pc11_state_name)

/* bring in GBD average age-specific conditions by state */
merge 1:1 age pc11_state_id using $health/gbd/gbd_india_states, keep(match) nogen

/* bring back hazard ratios which were lost in the collapse */
gen v1 = 0
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_full, nogen

/* add GBD risk factors, starting from biomarker model */
save $tmp/foo, replace

use $tmp/foo, clear
gen rf_full_all = rf_full_biomarkers
foreach condition in $hr_gbd_vars {
  replace rf_full_all = rf_full_all * ((`condition'_hr_full * `condition') + (1 - `condition'))
}
  
/* get state-level total population */
merge m:1 pc11_state_id using $pc11/pc11_pca_state_clean, keepusing(pc11_pca_tot_p) keep(master match) nogen

/* get state-level age-specific population */
//// need to build this

/* assume a mortality rate of 1% for risk factor 1 and calculate deaths */
// global mortrate 0.01
// foreach v in simple full_biomarkers full_all {
//   gen deaths_`v' = rf_`v' * state_age_pop * $mortrate
// }

save $tmp/sofar, replace


exit

/* summarize risk factors at age 50 */
use $tmp/sofar, clear

/* generate conditions only */
gen rf_conditions = rf_full_biomarkers / rf_full_agesex

/* generate each state's rank on each risk factor */
keep if inrange(age, 40, 65)
collapse (mean) rf*, by(pc11_state_id pc11_state_name)

list pc11_state_name rf*

foreach v in simple full_biomarkers conditions full_all {
  egen rank_`v' = rank(rf_`v'), field
}

/* #1 is the most at risk */
sort rank_full_all
list pc11_state_name rank_simple rf_simple rank_full_all rf_full_all 

/* heatmap conditions by state */
shp2dta using ~/iec/gis/pc11/pc11-state, database($tmp/state_db) coordinates($tmp/state_coord) replace genid(pc11_state_id) 

cap destring pc11_state_id, replace
spmap rf_conditions using $tmp/state_coord, id(pc11_state_id)
graphout x

exit

/* ida's code */

shp2dta using "~/iec1/gis/pc11/pc11_state.shp", database("state_db") coordinates("state_coord") genid(pc11_state_id) replace
use state_db, clear
	*** 	Red-Green map, automatically identified quantiles of the var of interest		***			
grmap rf_condition  using  state_coord, id(pc11_state_id) ///
	legenda(on) clmethod(quantile) fcolor(RdYlGn) ocolor(white ..) osize(vvthin ..)  ///
	title("Figure title here", size(*0.8)) 	subtitle("(Subtitle here) ", size(*0.6)) ///
	legtitle("Legend title here")   legcount  ///
	legend(size(medium)) legend(pos(6) row(7) ring(1) size(*.75) forcesize /* symx(*.75) symy(*.75) */ )  
		/* ocolor() sets the color of the polygon border
		   Legend suboptions:
				pos() and ring() override the default location of the legend
					(ring > 0 will place it outside the plot region) 
				row() identifies the max number of rows in the legend   								*/
	graph export Maps\Map_1.png, as(png) replace
		* same options as for normal graph export
			***		Shades of blue Map, manually set category ranges	***	
grmap rf_condition  using state_coord, id(pc11_state_id) ///
	legenda(on) clmethod(custom) clbreaks(0 10000 25000 50000 5000000)  fcolor(Blues) ocolor(black ..) osize(vvthin ..)  ///
	title("Figure title here", size(*0.8)) 	subtitle("(Subtitle here) ", size(*0.6)) ///
	legtitle("Legend title here")   legcount  ///
	legend(size(medium)) legend(pos(6) row(7) ring(1) size(*.75) forcesize /* symx(*.75) symy(*.75) */ )  
	graph export Maps\Map_2.png, as(png) replace
