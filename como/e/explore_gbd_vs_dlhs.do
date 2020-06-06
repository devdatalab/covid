use $tmp/india_models, clear

sort age
twoway ///
    (line diabetes_uncontr age) (scatter gbd_diabetes age)
graphout x
