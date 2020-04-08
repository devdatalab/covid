import urllib.request
import json
import pandas as pd
import os

def retrieve_case_data(output_fp):
    """
    output_fp = the filepath the final csv data is stored to, should be your scratch folder
    """
    # retrieve the json with all data
    with urllib.request.urlopen("https://api.covid19india.org/raw_data.json") as url:

        # load the json
        data = json.loads(url.read().decode())

        # convert the raw data to a dataframe
        df =  pd.DataFrame.from_records(data['raw_data'])

    # write the dataframe out as a csv
    df.to_csv(os.path.join(output_fp, "covid_case_data.csv"))
