
med_age = [29 45 55 65 75 85]';
hr_age_sex    = [.05 .27 1 2.61 7.61 26.27]';
hr_full    = [.07 .31 1 2.09 4.77 12.64]';

ln_hr_age_sex = log(hr_age_sex);
ln_hr_full = log(hr_full);

age = [18:100]';

%% use a polynomial interpolation since spline fails on the endpoints
fit_age_sex = fit(med_age, ln_hr_age_sex, 'poly3')
fit_full = fit(med_age, ln_hr_full, 'poly3')

%% graph the fits
clf;
hold on
scatter(med_age, ln_hr_full);
plot(fit_full, age, zeros(83, 1))
xlabel("log odds ratio")
ylabel("age")
b = gca; legend(b,'off');
write_png('/scratch/pn/fit_full')

clf;
hold on
scatter(med_age, ln_hr_age_sex);
plot(fit_age_sex, age, zeros(83, 1))
xlabel("log odds ratio")
ylabel("age")
write_png('/scratch/pn/fit_age_sex')

%% generate predicted values
predicted_hr_age_sex = fit_age_sex(age);
predicted_hr_full = fit_full(age);

%% topcode predicted values at age 90 value since we don't have certainty over the
%% age distribution here or whether HRs keep rising
predicted_hr_age_sex(age > 90) = predicted_hr_age_sex(age == 90);
predicted_hr_full(age > 90) = predicted_hr_full(age == 90);

%% write these to a file
writematrix([age predicted_hr_age_sex predicted_hr_full],'/scratch/pn/uk_age_fits.csv')

%% prepend a header to the file
system('echo "age,ln_hr_age_sex,ln_hr_full" >~/iec/covid/covid/csv/uk_age_predicted_hr.csv');
system('cat /scratch/pn/uk_age_fits.csv >>~/iec/covid/covid/csv/uk_age_predicted_hr.csv');
fprintf("Writing uk_age_predicted_hr.csv\n");
