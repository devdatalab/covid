use $iec/covid/idi_survey/wb3_clean, clear

drop if weight_hh_r3 < 0

global ag agr_loc_shift_prop_r3 agr_harvest_outlook_prop_r3 

/* collapse dataset to shrid level */
collapse (mean) $ag *change* hea_symp*prop_r3 rel_pds_any_prop_r3 rel*mean_r3 con_stillinsecure_prop* lab_occ*none_r3 (firstnm) state [pw = weight_hh_r3] , by(shrid)

/* merge to shrids */
merge 1:1 shrid using $iec/covid/idi_survey/survey_shrid_data.dta, keep(master match) nogen

/* add nightlights data */
merge 1:1 shrid using $shrug/data/shrug_nl_wide, keep(master match) nogen keepusing(*2013)

/* sc-st share */
merge 1:1 shrid using $shrug/data/shrug_pc11_pca, keepusing(*pca_tot_p *p_sc) keep(master match) nogen

/* poverty rate */
merge 1:1 shrid using $shrug/data/shrug_secc, keepusing(secc_pov_rate_rural) keep(master match) nogen

/* village directory chars */
merge 1:1 shrid using $shrug/data/shrug_pc11_vd, keepusing(pc11_vd_asha pc11_vd_ams *wkl_haat *vd_mrkt) keep(master match) nogen

/* keep only variables we need */
keep $ag *change* land* pc11_pca* ec13* tdist* rural* *light* secc* pc11_vd* hea_symp*prop_r3 rel_pds_any_prop_r3 rel*mean_r3 shrid state *insecure* *none*

/* generate sc population share */
gen sc_share = pc11_pca_p_sc/pc11_pca_tot_p

/************************/
/* Analysis begins here */
/************************/

set scheme pn

/* consumption recovery */
ren con_stillinsecure_prop* insecure*

twoway lfitci insecure_r3 secc_pov_rate_rural, ytitle("% HH still food insecure - Sept 2020", margin(medium)) xtitle("Poverty % in village - SECC") name(insecure2, replace) ///
    note("Note: The Y-axis shows % of HH in the village that became food insecure due to the pandemic and haven't recovered", size(vsmall))
graphout cons_pov

/* relief poverty rate */
/* MNREGA targeting */
/* take logs */
gen temp = rel_mnrega_wages_mean_r3 + 1
gen ln_mnrega = ln(temp)
replace temp = secc_pov_rate_rural + 1  
gen ln_pov = ln(temp)
drop temp

reg ln_mnrega ln_pov

/* Save coefficients for graph */
local   beta_pov  = round(_b[ln_pov],0.001)

test _b[ln_pov] = 0
local p_val = round(`r(p)', 0.001)

twoway lfitci ln_mnrega ln_pov, ytitle("Log (mean MNREGA wages received)") xtitle("Log (SECC village poverty rate)") clcolor(navy) acolor(ltblue%80) ///
    text( 5.4 5.5 "ln(MNREGA wage) on ln(poverty)" " "  "Regression coefficient: 0`beta_pov'***", orient(horizontal) size(vsmall) justification(center) fcolor(white) box margin(small))
graphout targeting

/* unemployment as of september 2020 */
twoway lfitci lab_occ_none_r3 tdist_100, ytitle("% HH unemployed - September 2020") xtitle("Distance to nearest town (Km)") name(unemp_1, replace) ylabel(0.25 (.05) .6) clcolor(navy) acolor(green)
twoway lfitci lab_occ_lckdwn_none_r3 tdist_100, ytitle("% HH unemployed - Lockdown") xtitle("Distance to nearest town (Km)") name(unemp_2, replace) ylabel(0.25 (.05) .6) clcolor(pink) acolor(red)

graph combine unemp_2 unemp_1, rows(1) 
graphout unemp_urb

/* agriculture infrastructure - roads, access to AMS, mandis */
ren agr_loc_shift_prop_r3 shift_loc

reg shift_loc rural_road
estimates store Road
reg shift_loc pc11_vd_mrkt
estimates store Mandi

la var pc11_vd_mrkt "Village has regular mandis"

coefplot Road Mandi, drop(_cons) xline(0) scheme(plottig) levels(90) legend(label(1 "Village has a road", 2 "Village has weekly mandis", 3 "Distance to nearest city")) xtitle("Outcome: Whether cultivator decided to shift selling location this year", size(small) margin(medium)) recast(bar)
graphout infra

/* Harvest outlook */
reg harvest_outlook landless_share

/* Save coefficients for graph */
local   beta_land  = round(_b[landless_share],0.001)

twoway lfitci harvest_outlook landless_share, ytitle("% of farmers with a +ve harvest outlook this year vs. last year") xtitle("Census: Share of landless working age population (18-65)") clcolor(sienna) acolor(sand%80) ///
    text( 0.6 0.7 "Harvest outlook on landless share" " "  "Regression coefficient: `beta_land'***", orient(horizontal) size(vsmall) justification(center) fcolor(white) box margin(small))
graphout ag_outlook

/* wage change versus poverty rate */
ren lab_wagechange_mean* wagechange*

