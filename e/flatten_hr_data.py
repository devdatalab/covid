import os
import pandas as pd

def flatten_hr_data(hr_var, fn_in, fn_out):
    """
    flatten the hazard ratio data from the NHS study to 
    be a 1D array with the names of the variables and the 
    selected hazard ratio variable.
    """
    # read in the HR data
    df = pd.read_stata(fn_in)

    # select just the variables we need
    df = df[["variable", hr_var]].T

    # set new column names to combine hr and variable names
    new_cols = [f"{x}_{hr_var}" for x in df.loc["variable"]]
    df.columns = new_cols
    
    # drop the variable column
    df = df.drop(["variable"])

    # set the index value to 0
    df.index = [0]

    # write out the file
    df.to_csv(fn_out)
    

    

