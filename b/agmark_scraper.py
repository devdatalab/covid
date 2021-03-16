# DDL NOTE: THIS IS NOT YET INTEGRATED INTO THE BUILD
# this script was given to us by Matt Lowe's RA over email.

# this script scrapes agmarknet.com for commodity quantity and price data at the mandi-day-item-level and writes it to a .csv
from datetime import datetime
import pandas as pd
import time
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
code_time_0 = time.time()
print('Start time:', datetime.now().time(), code_time_0, "\n")

## specify the month(s) and the name of the output file:
## be sure to change the output file name each time the sript is run, otherwise it will write over the same file
month_list = ['May']
output_file_name = "Agmark_2020_May.csv"

# creating an empty dataframe to store results
df_m = pd.DataFrame()

# initiating the browser
## specify path to chromedriver.exe. Download at https://chromedriver.chromium.org
browser = webdriver.Chrome(executable_path=r'path to chromedriver.exe')
try:
    wait = WebDriverWait(browser, 60)
    browser.get("http://www.agmarknet.gov.in/PriceAndArrivals/CommodityWiseDailyReport.aspx")
except TimeoutException:
    print('Webpage did not load')

for year in range(2020, 2021):
    # selecting the year
    browser.find_element_by_xpath('//*[@id="cphBody_drpDwnYear"]').send_keys(year)
    time.sleep(10)
    for month in month_list:
        # selecting the month
        browser.find_element_by_xpath('//*[@id="cphBody_drpDwnMonth"]').send_keys(month)
        time.sleep(15)

        # calendar matrix, range=(3-9, 1-8)
        ## specify the row (for week), and column (for day) based on the calendar at http://www.agmarknet.gov.in/PriceAndArrivals/CommodityWiseDailyReport.aspx
        for row in range(3, 9):
            for column in range(1, 8):
                try:
                    # selecting the date (a cell in the given calendar)
                    browser.find_element_by_xpath('//*[@id="cphBody_Calendar1"]/tbody/tr[%d]/td[%d]/a' % (row, column)).send_keys(Keys.ENTER)
                    print(year, month, browser.find_element_by_xpath('//*[@id="cphBody_Calendar1"]/tbody/tr[%d]/td[%d]/a' % (row, column)).text)
                    time.sleep(15)

                    # submitting the first page and opening in a new tab
                    browser.find_element_by_xpath('//*[@id="cphBody_Submit_list"]').send_keys(Keys.CONTROL + Keys.ENTER)
                    browser.switch_to.window(browser.window_handles[1])

                    # selecting the commodities
                    WebDriverWait(browser, 60).until(EC.element_to_be_clickable((By.ID, 'cphBody_btnSubmit')))
                    browser.maximize_window()
                    n = 140
                    browser.execute_script("window.scrollTo(0, %d);" % n)
                    time.sleep(1)
                    checkbox_list = browser.find_elements_by_css_selector('[type="checkbox"]')
                    for checkbox in checkbox_list:
                        checkbox.click()
                        time.sleep(0.2)
                        browser.execute_script("window.scrollTo(0, %d);" % n)
                        n += 10
                    browser.execute_script("window.scrollTo(0, 140);")
                    for checkbox in checkbox_list:
                        if not checkbox.is_selected():
                            WebDriverWait(browser, 20).until(EC.element_to_be_clickable((By.CSS_SELECTOR, '[type="checkbox"]')))
                            checkbox.click()
                            browser.execute_script("window.scrollTo(0, %d);" % n)
                            n += 10

                    # submitting the second page (query)
                    time.sleep(5)
                    browser.find_element_by_xpath('//*[@id="cphBody_btnSubmit"]').click()

                    # reading into dataframe
                    WebDriverWait(browser, 60).until(EC.visibility_of_element_located((By.XPATH, '//*[@id="owner"]/div/div[1]/img')))
                    df = pd.read_html(browser.page_source, skiprows=None)[3]

                    # adding date to the dataframe
                    today = browser.find_element_by_xpath('//*[@id="cphBody_lblTitle"]/font').text
                    date = [today] * len(df)
                    df['Date'] = date
                    
                    # filling the blank centre names
                    df['Market Center'] = df['Market Center'].fillna(method='ffill')

                    # appending to database
                    ## specify path to output folder
                    df.to_csv(r'path to output folder\%s' % output_file_name, mode='a', header=False)
                    time.sleep(10)

                    # closing the tab and switching back to the calendar tab
                    browser.close()
                    browser.switch_to.window(browser.window_handles[0])

                except NoSuchElementException:
                    print("not found: calendar(%d, %d)" % (row, column))

browser.quit()
code_time_1 = time.time()
print('\nEnd time:', datetime.now().time(), code_time_1)
print('Total script time: %d minutes ' % (float((code_time_1 - code_time_0)/60)))
