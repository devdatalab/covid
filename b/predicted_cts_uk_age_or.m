
med_age = [29 45 55 65 75 85]';
or_simple    = [.05 .27 1 2.61 7.61 26.27]';
or_full    = [.07 .31 1 2.09 4.77 12.64]';

ln_or_simple = log(or_simple);
ln_or_full = log(or_full);

age = [18:100]';

%% use a polynomial interpolation since spline fails on the endpoints
fit_simple = fit(med_age, ln_or_simple, 'poly3')
fit_full = fit(med_age, ln_or_full, 'poly3')

%% graph the fits
clf;
hold on
scatter(med_age, ln_or_full);
plot(fit_full, age, zeros(83, 1))
xlabel("log odds ratio")
ylabel("age")
write_png('/scratch/pn/fit_full')

clf;
hold on
scatter(med_age, ln_or_simple);
plot(fit_simple, age, zeros(83, 1))
xlabel("log odds ratio")
ylabel("age")
write_png('/scratch/pn/fit_simple')

%% generate predicted values
predicted_or_simple = fit_simple(age);
predicted_or_full = fit_full(age);

%% write these to a file
writematrix([age predicted_or_simple predicted_or_full],'/scratch/pn/uk_age_fits.csv')

%% prepend a header to the file
system('echo "age,ln_or_simple,ln_or_full" >~/iec/covid/covid/csv/uk_age_predicted_or.csv');
system('cat /scratch/pn/uk_age_fits.csv >>~/iec/covid/covid/csv/uk_age_predicted_or.csv');
fprintf("Writing uk_age_predicted_or.csv\n");
