
%% set odds ratios in bins and switch to logs since that is better for fitting
or_simple    = [.05 .27 1 2.61 7.61 26.27]';
or_full    = [.07 .31 1 2.09 4.77 12.64]';
ln_or_simple = log(or_simple);
ln_or_full = log(or_full);

%% set standard solver parameters
options = optimoptions(@fmincon,'MaxFunEvals',10000000,'Display','none','TolCon',0.0001,'TolFun',0.0001,'TolX',0.0001);

%% start with a linear function
x_start = [1 2 3 4];
[x, f_min, exit_flag, output] = fmincon(@mse_simple, x_start, [], [], [], [], [], [], [], options);

age = [18:100]';
y = x(1) .* age.^3 + x(2) .* age.^2 + x(3) .* age + x(4);

%% graph the fit
clf;
hold on
scatter(med_age, ln_or_simple);
plot(age,y)
xlabel("log odds ratio")
ylabel("age")
write_png('/scratch/pn/fit_simple')

%% %% generate predicted values
%% predicted_or_simple = fit_simple(age);
%% predicted_or_full = fit_full(age);
%% 
%% %% write these to a file
%% writematrix([age predicted_or_simple predicted_or_full],'/scratch/pn/uk_age_fits.csv')
%% 
%% %% prepend a header to the file
%% system('echo "age,ln_or_simple,ln_or_full" >~/iec/covid/covid/csv/uk_age_predicted_or.csv');
%% system('cat /scratch/pn/uk_age_fits.csv >>~/iec/covid/covid/csv/uk_age_predicted_or.csv');
%% fprintf("Writing uk_age_predicted_or.csv\n");
