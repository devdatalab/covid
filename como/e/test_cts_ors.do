import delimited uk_age_predicted_or.csv, clear

/* see how well the bin means line up */
replace or_simple = exp(or_simple)
replace or_full = exp(or_full)

sum or* if inrange(age, 18, 39)
sum or* if inrange(age, 40, 49)
sum or* if inrange(age, 50, 59)
sum or* if inrange(age, 60, 69)
sum or* if inrange(age, 70, 79)
sum or* if inrange(age, 80, 85)
