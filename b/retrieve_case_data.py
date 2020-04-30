
from bs4 import BeautifulSoup
import json
import pandas as pd
import os
import urllib.request
import requests
from collections import Counter

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


def read_hmis_csv(year, filepath):
    """
    read in hmis data stored in xml/xls format
    and convert to csv
    """
    # get full filepath
    fp = os.path.join(filepath, "nrhm_hmis", "itemwise_monthly", "district", year)

    # get all files in this folder
    filelist = os.listdir(fp)

    # only keep xls files
    filelist = [x for x in filelist if x.endswith(".xls")]
    
    #Loop over all the state .xls file
    for i in filelist:

        #Skip.xls files not for the state
        if i in ( "All_India.xls", "M O Defence.xls", "M O Railways.xls")  :
            continue

        # read in the data
        df = pd.read_html(os.path.join(fp, i))[0]

        # transpose the dataframe
        df = df.T.reset_index()

        # extract just the variable names and descriptions as their own dataframe
        df_vars = df.loc[1:2].T

        # drop extra rows with no data
        df_vars = df_vars.drop(["level_0", "level_1", 0]).reset_index(drop=True)

        # rename the columns
        df_vars.columns = ["variable", "description"]

        # drop extra rows with no data
        df = df.drop([2, 3]).reset_index(drop=True)

        # identify all the districts
        districts = list(Counter(df.loc[0]).keys())
        districts = [x for x in districts if "Unnamed" not in x]
        districts = [x for x in districts if "District" not in x]

        # create empty dataframe to hold all final data
        df_all = pd.DataFrame()

        # cycle through the districts
        for dist in districts:

            # identify all the columns with data for this district, along with identiyfing columns
            cols = ["level_0", "level_1"] + list(df.columns[(df.loc[0]==dist).values])

            # extract the data
            temp = df[cols].copy()

            # set the columns to be the variable names
            temp.columns = temp.loc[1]

            # set the district to be a column
            temp["district"] = dist

            # drop unneeded rows and columns with no data
            temp = temp.drop([0,1]).reset_index(drop=True)

            # append this district to the final dataframe
            df_all = df_all.append(temp)

        # replace meaningless names with true names
        df_all = df_all.rename(columns={"Unnamed: 1_level_0": "month", "Unnamed: 1_level_1": "category"})

        # set the index
        df_all = df_all.set_index(["district", "month", "category"])

        # save the data to a csv
        df_all.to_csv(os.path.join(fp, f"{i.split('.')[0]}.csv"))

    # save the variable definitions out to a csv
    df_vars.to_csv(os.path.join(fp, "hmis_variable_definitions.csv"), index=False)
