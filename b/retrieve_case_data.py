from bs4 import BeautifulSoup
import datetime
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


def retrieve_covindia_case_data(url, output_fp):
    """
    url = specific url to api provided by covindia (ex. "https://v1.api.covindia.com/covindia-raw-data")
    output_fp = the filepath the final csv data is stored to, should be your scratch folder
    """
    # retrieve the json with all data
    with urllib.request.urlopen(url) as _url:

        # load the json
        data = json.loads(_url.read().decode())

    # convert the raw data to a dataframe
    df =  pd.DataFrame.from_records(data).T

    # convert date to datetime
    df["date_obj"] = df["date"].apply(lambda x: datetime.datetime.strptime(x, "%d/%m/%Y"))

    # sort on date, state, and district
    df = df.sort_values(["date_obj", "state", "district"])

    # set index
    df = df.set_index(["date", "state", "district"])

    # extract filename from the url
    fn = url.split("/")[-1]
        
    # write the dataframe out as a csv
    df.to_csv(os.path.join(output_fp, f"{fn}.csv"))

def retrieve_covindia_state_district_list(output_fp):
    """
    get the json of states and district used by covindia
    """
    url = "https://covindia-api-docs.readthedocs.io/en/latest/resources/covindia-resources-list.json"

    # retrieve the json file
    r = requests.get(url)

    # read in the data
    data = r.json()

    # create empty dataframe to hold all states and districts
    df = pd.DataFrame(columns=["state", "district"])

    # cycle through dictionary 
    for k, v in data.items():

        # create a dataframe for this state
        temp = pd.DataFrame(data[k], columns=["district"])
        temp['state'] = k

        # append this state to the complete dataframe
        df = df.append(temp, sort=False)

    # order the columns
    df = df[["state", "district"]]

    # write out the dataframe
    df.to_csv(os.path.join(output_fp, "covindia_state_district_list.csv"), index=False)
    
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
    fp = os.path.join(filepath, "hmis", "itemwise_monthly", "district", year)

    # get all files in this folder
    filelist = os.listdir(fp)

    # only keep xls files
    filelist = [x for x in filelist if x.endswith(".xls")]
    
    #Loop over all the state .xls file
    #Add try and except to handle empty excel files for 2020-2021
    for i in filelist:
        try:
            #Skip.xls files not for the state
            if i in ( "All_India.xls", "M O Defence.xls", "M O Railways.xls")  :
                continue
    
            # read in the data
            df = pd.read_html(os.path.join(fp, i))[0]
    
            # transpose the dataframe
            df = df.T.reset_index()
    
            # drop empty column
            df = df.drop(0, axis=1)
    
            # split the column with variable name and definition information into separate name, definition columns
            new_rows = df.loc[3].T.str.split(".", expand=True)
    
            # combine variable name columns
            df.loc[1] = df.loc[1] + "." + new_rows[0].astype(str)
    
            # combine variabel definition columns
            df.loc[2] = df.loc[2] + "-" + new_rows[1].replace({None: ""}).astype(str)
    
            # extract just the variable names and descriptions as their own dataframe
            df_vars = df.loc[1:2].T
    
            # drop extra rows with no data
            index_col_map = {
                "2020-2021": ["level_0","level_1"],
                "2019-2020": ["level_0", "level_1"],
                "2018-2019": ["level_0", "level_1"],
                "2017-2018": ["level_0", "level_1"],
                "2016-2017": ["index"],
                "2015-2016": ["index"],
                "2014-2015": ["index"],
                "2013-2014": ["index"],
                "2012-2013": ["index"],
                "2011-2012": ["index"],
                "2010-2011": ["index"],
                "2009-2010": ["index"],
                "2008-2009": ["index"]
            }
        
            # drop extra rows with no data
            df_vars = df_vars.drop(index_col_map[year]).reset_index(drop=True)
            
            # rename the columns
            df_vars.columns = ["variable", "description"]
            
            # drop extra rows with variable description and redundant name information
            df = df.drop([2, 3]).reset_index(drop=True)
    
            # identify all the districts
            districts = list(Counter(df.loc[0]).keys())
            districts = [x for x in districts if "Unnamed" not in x]
            districts = [x for x in districts if "District" not in x]
            districts = [x for x in districts if "Unnamed: 0" not in x]
            
            # create empty dataframe to hold all final data
            df_all = pd.DataFrame()
    
            # cycle through the districts
            for dist in districts:
    
                # identify all the columns with data for this district, along with identiyfing columns
                cols = index_col_map[year] + list(df.columns[(df.loc[0]==dist).values])
    
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
            df_all = df_all.rename(columns={"Unnamed: 1_level_0.Unnamed: 3_level_0": "month",
                                            "Unnamed: 1_level_1.Unnamed: 3_level_1": "category",
                                            "Unnamed: 1.Unnamed: 3": "month"})
    
    
            #set dictionary for index
            index_set_map = {
                "2020-2021": ["district", "month", "category"],
                "2019-2020": ["district", "month", "category"],
                "2018-2019": ["district", "month", "category"],
                "2017-2018": ["district", "month", "category"],
                "2016-2017": ["district", "month"],
                "2015-2016": ["district", "month"],
                "2014-2015": ["district", "month"],
                "2013-2014": ["district", "month"],
                "2012-2013": ["district", "month"],
                "2011-2012": ["district", "month"],
                "2010-2011": ["district", "month"],
                "2009-2010": ["district", "month"],
                "2008-2009": ["district", "month"]
            }
            
            # set the index
            df_all = df_all.set_index(index_set_map[year])
    
            # save the data to a csv
            df_all.to_csv(os.path.join(fp, f"{i.split('.')[0]}.csv"))
        except:
            print(f"Error in State File {i}")
    # drop the duplicates variables, for each state file with X districts the variables are repeated X times
    df_vars = df_vars.drop_duplicates()
    
    # save the variable definitions out to a csv
    df_vars.to_csv(os.path.join(fp, "hmis_variable_definitions.csv"), index=False)


def read_hmis_csv_hospitals(year, filepath):
    """
    read in hmis data stored in xml/xls format
    and convert to csv
    """
    # get full filepath
    fp = os.path.join(filepath, "hmis", "data_reporting_status", year)
    
    # get all files in this folder
    filelist = os.listdir(fp)
    
    # only keep xls files
    filelist = [x for x in filelist if x.endswith(".xls")]
    
    #Loop over all the state .xls file
    df_cols = pd.DataFrame()
    for i in filelist:
    
        #Skip.xls files not for the state
        if i in ("_All_India_DataUploadStatus.xls")  :
            continue
    
        # read in the data
        df = pd.read_html(os.path.join(fp, i))[0]
    
        # transpose the dataframe
        df = df.T.reset_index()
    
        # drop empty column
        df = df.drop(0, axis=1)
    
        # Identify all the districts
        districts = list(Counter(df.loc[0]).keys())
    
        # remove non-district names from district list
        districts = [x for x in districts if 'Unnamed: 0_level_1' not in x]
        districts = [x for x in districts if 'Unnamed: 0_level_2' not in x]
    
        # Remove the state name in the district list of the state
        districts = [x for x in districts if f"{i.upper().split('.')[0]}" not in x]
    
        # create empty dataframe to hold all final data
        df_all = pd.DataFrame()
    
        # make a dictionaryto take care of different years
        index_col_map = {
                    "2020-2021": ["level_1","level_2"],
                    "2019-2020": ["level_1", "level_2"],
                    "2018-2019": ["level_1", "level_2"],
                    "2017-2018": ["level_1", "level_2"],
                    "2016-2017": ["level_1"],
                    "2015-2016": ["level_1"],
                    "2014-2015": ["level_1"],
                    "2013-2014": ["level_1"],
                    "2012-2013": ["level_1"],
                    "2011-2012": ["level_1"],
                    "2010-2011": ["level_1"],
                    "2009-2010": ["level_1"],
                    "2008-2009": ["level_1"]
            }
        
        # cycle through the districts
        for dist in districts:
    
            # identify all the columns with data for this district, along with identiyfing columns
            cols = index_col_map[year] + list(df.columns[(df.loc[0]==dist).values])
    
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
        df_all = df_all.rename(columns={"Unnamed: 1_level_1": "month",
                                        "Unnamed: 1_level_2": "category",
        })
    
        #drop unnecessary column
        df_all = df_all.drop(labels = ['Unnamed: 1_level_0', 'Reporting at District Level'], axis =1, errors = 'ignore')
    
        #drop total/active facilities to clean 'month variable'  
        df_all = df_all.loc[~df_all['month'].isin(['Total Facility', 'Active Facilities'])]
    
        #drop non-districts from district variable.
        df_all = df_all.loc[~df_all['district'].isin(['Unnamed: 0_level_0', 'WARANGAL U'])]
    
        # set the dictionary for the index
        index_set_map = {
                    "2020-2021": ["district", "month", "category"],
                    "2019-2020": ["district", "month", "category"],
                    "2018-2019": ["district", "month", "category"],
                    "2017-2018": ["district", "month", "category"],
                    "2016-2017": ["district", "month"],
                    "2015-2016": ["district", "month"],
                    "2014-2015": ["district", "month"],
                    "2013-2014": ["district", "month"],
                    "2012-2013": ["district", "month"],
                    "2011-2012": ["district", "month"],
                    "2010-2011": ["district", "month"],
                    "2009-2010": ["district", "month"],
                    "2008-2009": ["district", "month"]
                }
        # set index based on year    
        df_all = df_all.set_index(index_set_map[year])
    
        # save the data to a csv
        df_all.to_csv(os.path.join(fp, f"{i.split('.')[0]}.csv"))
    
    
    


