/* process DDL covid data for merging with dist-level predictions */
/* FIXME TODO: paths - use globals */
use ~/iec/covid/hospitals/pc11/pc_hospitals_dist_pc11.dta , clear

/* keep vars to include in the tileset */
keep pc11_*id pc_clinics pc_num_hospitals

/* write out for merging */
save ~/iec/covid/forecasting/ddl_data, replace
