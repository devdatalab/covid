function mse_simple = mse_simple(x);

  %% the odds we're trying to match
  or_simple    = [.05 .27 1 2.61 7.61 26.27]';
  ln_or_simple = log(or_simple);
  
  %% create the x axis for age from 18-90
  age = [18:.1:90]';

  %% predict odds at each age using cubic function x
  y = x(1) .* age.^3 + x(2) .* age.^2 + x(3) .* age + x(4);

  %% calculate difference between bin means and target odds ratios
  m1 = abs(mean(y(age >= 18 & age < 40)) - ln_or_simple(1));
  m2 = abs(mean(y(age >= 40 & age < 50)) - ln_or_simple(2));
  m3 = abs(mean(y(age >= 50 & age < 60)) - ln_or_simple(3));
  m4 = abs(mean(y(age >= 60 & age < 70)) - ln_or_simple(4));
  m5 = abs(mean(y(age >= 70 & age < 80)) - ln_or_simple(5));
  m6 = abs(mean(y(age >= 80 & age < 90)) - ln_or_simple(6));
  
  %% calculate MSE between means and target log odds ratios, with uniform weighting
  %% first bin gets scaled 2.2 since it is 18-40, while other bins are all width 10
  mse_simple = m1 * 2.2 + m2 + m3 + m4 + m5 + m6;

  %% penalize max changes in slope
  abs((y(3:721) - y(2:720)) - (y(2:720) - y(1:719)))
  f2 = max(abs((y(3:721) - y(2:720)) - (y(2:720) - y(1:719))))
  mse_simple = mse_simple;
  
  %% fprintf("%5.2f,%5.2f,%5.2f,%5.2f\n", x(1), x(2), x(3), x(4))
  
