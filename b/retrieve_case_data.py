from bs4 import BeautifulSoup
import json
import pandas as pd
import os
import urllib.request
import requests

def retrieve_covid19india_case_data(url, output_fp):
    """
    url = specific url to api provided by covid19india (ex. "https://api.covid19india.org/raw_data.json")
    output_fp = the filepath the final csv data is stored to, should be your scratch folder
    """
    # retrieve the json with all data
    with urllib.request.urlopen(url) as _url:

        # load the json
        data = json.loads(_url.read().decode())

        # get name of data sheet 
        key = list(data.keys())[0]
        
        # convert the raw data to a dataframe
        df =  pd.DataFrame.from_records(data[key])

    # write the dataframe out as a csv
    df.to_csv(os.path.join(output_fp, f"covid_{key}.csv"))


def retrieve_state_case_data(output_fp):
    """
    Get official state level case data
    """
    url = "https://www.mohfw.gov.in/"
    page = requests.get(url)
    soup = BeautifulSoup(page.content, 'html.parser')
    table = soup.find_all("table", {"class": "table table-striped"})[0]
    df = pd.read_html(table.prettify())[0]

    df.to_csv(os.path.join(output_fp, "covid_state_case_data.csv"))
