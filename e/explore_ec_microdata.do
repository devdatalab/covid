use $tmp/ec13_hosp, clear

keep if nic == 861

sum emp_all, d
