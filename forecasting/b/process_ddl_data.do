/* process DDL covid data for merging with dist-level predictions */

/* FIXME TODO: paths - use globals */
/* pull globals */
process_yaml_config ~/ddl/covid/forecasting/config/config.yaml

/* read from covidi repo output */
use ~/iec/covid/hospitals/pc_hospitals_dist.dta , clear

/* keep vars to include in the tileset */
keep lgd_*id pc_clinics pc_num_hospitals

/* write out for merging */
save $cdata/ddl_data, replace
