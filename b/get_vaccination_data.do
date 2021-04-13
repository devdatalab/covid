http://api.covid19india.org/csv/latest/cowin_vaccine_data_districtwise.csv

/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do
qui do $ddl/tools/do/tools.do

/* retrieve the vaccination data from the covid19india API */
pyfunc retrieve_covid19india_vaccination("http://api.covid19india.org/csv/latest/cowin_vaccine_data_districtwise.csv", "$tmp"), i(from retrieve_case_data import retrieve_covid19india_vaccination) f("$ddl/covid/b")

/* read in the data */
import delimited using $tmp/covid19india_vaccination_data.csv, clear




