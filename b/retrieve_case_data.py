
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

    # make date a python object
    df["date"] = df["dateannounced"].apply(lambda x: datetime.datetime.strptime(x, "%d/%m/%Y"))
    df = df.sort_values(["date", "detectedstate", "detecteddistrict"]).reset_index(drop=True)

    # write the dataframe out as a csv
    df.to_csv(os.path.join(output_fp, "covid19india_old_cases.csv"))

    
def retrieve_covid19india_deaths_data(url, output_fp):
    """
    url = specific url to api provided by covid19india (ex. "https://api.covid19india.org/deaths_recoveries.json")
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

    # make date a python object
    df["date"] = df["date"].apply(lambda x: datetime.datetime.strptime(x, "%d/%m/%Y"))
    df = df.sort_values(["date", "state", "district"]).reset_index(drop=True)

    # write the dataframe out as a csv
    df.to_csv(os.path.join(output_fp, "covid19india_old_deaths.csv"))


def retrieve_covid19india_district_data(url, output_fp):
    """
    """
    # create empty dataframe to hold all results
    df = pd.DataFrame()
    
    with urllib.request.urlopen(url) as _url:
    
        # load the json
        data = json.loads(_url.read().decode())['districtsDaily']

    # get state list
    state_list = list(data.keys())

    # cycle through each state
    for state in state_list:

        # get district list for this state
        district_list = list(data[state].keys())

        # cycle through districts
        for dist in district_list:

            # extract district dataframe
            df_dist = pd.DataFrame.from_records(data[state][dist])

            # set the state and district of this dataframe
            df_dist["state"] = state
            df_dist["district"] = dist

            # parse dates
            df_dist["date_obj"] = df_dist["date"].apply(lambda x: datetime.datetime.strptime(x, "%Y-%m-%d"))
            df_dist = df_dist.sort_values("date_obj").reset_index(drop=True)

            # count new cases
            # df_dist["cases"] = df_dist["confirmed"].diff()
            # df_dist.loc[0, "cases"] = df_dist.loc[0, "confirmed"].copy()           

            # count new deaths
            # df_dist["death"] = df_dist["deceased"].diff()
            # df_dist.loc[0, "death"] = df_dist.loc[0, "deceased"].copy()
            
            # add this data to the master dataframe
            if df.empty:
                df = df_dist.copy()
            else:
                df = df.append(df_dist, sort=False)

    df.to_csv(os.path.join(output_fp, "covid19india_district_data.csv"))


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

            #Print success message
            print(f"Saved without errors in State {i.split('.')[0]} and year {year}")
        except:
            print(f"Error in State File {i}")
            print(f"Error in Year {year}")
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
    
    
    


def read_hmis_subdistrict_csv(year, filepath):
    """
    read in hmis data stored in xml/xls format
    and convert to csv
    """
    # get full filepath to state directory
    # (this is where we'll save the data)
    fp_state = os.path.join(filepath, "hmis", "itemwise_monthly", "subdistrict", year, "A.Monthwise")

    # get all sub directories in this folder
    filelist_state = os.listdir(fp_state)

    #Loop Over all States
    for i in filelist_state:
        try:
            #get full filepath to district folders
            fp_dist = os.path.join(filepath, "hmis", "itemwise_monthly", "subdistrict", year, "A.Monthwise",
        	                       i)

            #get all subdirectories list in this folder
            filelist_dist = os.listdir(fp_dist)

    	    # create an empty dataframe to hold all the districts and subdistrict data
            df_all = pd.DataFrame()
    
            # create dataframe to store all variable definitions at the state level
            df_vars_all = pd.DataFrame()

            #Loop over all the districts directories in the state
            for j in filelist_dist:
                
                #get filepath to month of district reporting
                fp_month = os.path.join(filepath, "hmis", "itemwise_monthly", "subdistrict", year, "A.Monthwise",
                                        i, j)

                #get all subdirectories in monthly district reporting data
                filelist_month =  os.listdir(fp_month)

                #Only keep xls files
                filelist_month = [x for x in filelist_month if x.endswith(".xls")]
            
                #Loop Over all Distrct-month xls files
                for k in filelist_month:
    
                    #read in xls file
                    temp = pd.read_html(os.path.join(fp_month,k))[0]

                    # transpose the dataframe
                    temp = temp.T.reset_index()
    
                    # drop the unnecessary subdistrict column and variable category row
                    temp = temp.drop(["level_0"], axis = 1)

                    # combine variable name columns
                    temp.loc[1] = temp.loc[1] + "." + temp.loc[3].astype(str)

                    # initialise a dataframe to hold all variable and descriptions
                    df_vars = pd.DataFrame()
                    
                    # extract the variable names and descriptions as their own dataframe
                    df_vars = temp.loc[1:2].T
                    
                    # drop extra rows with no data
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
    
    
                    # drop extra rows with no data
                    df_vars = df_vars.drop(index_col_map[year]).reset_index(drop=True)
    
                    # rename the columns
                    df_vars.columns = ["variable", "description"]
    
                    # add month, district and subdistrict identifiers to df_var data
                    # add in month
                    df_vars["month"] =  f"{k.split('_')[1].split('.')[0]}"
    
                    # add in district
                    df_vars["district"] = f"{j}"

                    # drop extra rows with variable description and redundant name information
                    temp = temp.drop([0,2, 3]).reset_index(drop=True)

                    # Rename columns using the first row
                    temp = temp.set_axis(list(Counter(temp.loc[0]).keys()), axis = 1)

                    # Drop now redundant first row
                    temp = temp.drop(0)

                    # rename subdistrict and category columns
                    temp = temp.rename(columns = {"Unnamed: 1_level_1.Unnamed: 3_level_1": "subdistrict",
                                                  "Unnamed: 1_level_2.Unnamed: 3_level_2":"category"})
                
    
                    # filter district names out
                    dist_name = f"_{j}"
                    temp = temp.query('subdistrict != @dist_name ')
    
                    # add in month
                    temp = temp.assign(month =  f"{k.split('_')[1].split('.')[0]}")
    
                    # add in district
                    temp = temp.assign(district = f"{j}")

    
                    # save data to dataframe
                    df_all = df_all.append(temp)

                    # save data definitions to dataframe
                    df_vars_all = df_vars_all.append(df_vars)
    
            # save state-wise data
            df_all.to_csv(os.path.join(fp_state, f"{i}.csv"))

            # drop duplicates. For every district with n subdistricts, variables are repeated n times.
            df_vars_all = df_vars_all.drop_duplicates()
            
            # save state-wise data definitions
            df_vars_all.to_csv(os.path.join(fp_state, f"{i}_hmis_variable_definitions.csv"))

            # print success message
            print(f"Saved {i} data for {year}")
        except:
            #Print Error message
            print(f"Error in year {year} and file {i}")
       
