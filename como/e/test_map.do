use ~/iec/output/pn/test, clear

/* test by making kerala (32) / rajasthan (8) into outliers */
replace rf_conditions = 5 if pc11_state_name == "kerala"
replace rf_conditions = -1 if pc11_state_name == "rajasthan"

ren pc11_state_id pc11_s_id

/* save the temp dataset for merging the values to the geodataset */
save $tmp/test.dta, replace

/* convert the shapefile into a geodatabase */
shp2dta using $iec1/gis/pc11/pc11-state, database($tmp/state_db) coordinates($tmp/state_coord) genid(geo_id)  replace 

/* use the created database, it is the one that the map can be created from */
use $tmp/state_db, clear 

/* merge wiith the  */
	merge 1:1 pc11_s_id  using $tmp/test.dta 		

	cap destring pc11_s_id, replace

/* test blank map by state */
spmap using $tmp/state_coord, id(geo_id)
graphout blank_map

/* heatmap conditions by state */
spmap rf_conditions using $tmp/state_coord, id(geo_id)
graphout heatmap
