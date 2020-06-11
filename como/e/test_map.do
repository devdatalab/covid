use ~/iec/output/pn/test, clear

/* test by making kerala (32) / rajasthan (8) into outliers */
replace rf_conditions = 5 if pc11_state_name == "kerala"
replace rf_conditions = -1 if pc11_state_name == "rajasthan"

/* heatmap conditions by state */
shp2dta using $iec1/gis/pc11/pc11-state, database($tmp/state_db) coordinates($tmp/state_coord) replace genid(pc11_state_id) 

cap destring pc11_state_id, replace
spmap rf_conditions using $tmp/state_coord, id(pc11_state_id)
graphout map
