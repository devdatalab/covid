# take DTA data and joins with shapefiles for both shrid and dist
# outputs geojson, which will then be merged into a tileset using tippecanoe
# depends on py_spatial env (run from snakemake)


############
# Preamble #
############

import sys, os, importlib
import geopandas as gpd
import pandas as pd
import argparse

# import ddlpy utils
sys.path.insert(0, os.path.expanduser("~/ddl/tools/py"))
from ddlpy.geospatialtools.utils import import_vector_data

# initialize args
parser = argparse.ArgumentParser()
parser.add_argument("--intable", type=str)
parser.add_argument("--inshp", type=str)
parser.add_argument("--outfile", type=str)
args = parser.parse_args()

# define tabular import fn
def import_tabular_data(fp):
    """
    Reads in tabular data with file extension checks
    fp: filepath for datafile to be imported, must bs shp/csv/dta/excel
    """
    # expand data filepath
    fp = os.path.expanduser(fp)

    # assert that the data file exists
    if not os.path.isfile(fp):
        raise OSError("Input file not found")

    # ensure that the data file is a readable format
    fp_ext = os.path.splitext(fp)[1]
    if fp_ext not in [".csv", ".dta", ".xls", ".xlsx"]:
        raise ValueError("Data must be .dta, .csv, .xlsx/.xls format")

    # read in csv
    if fp_ext == ".csv":
        target_df = pd.read_csv(fp)

    # read in excel
    if fp_ext in [".xls", "xlsx"]:
        target_df = pd.read_excel(fp)

    # read in dta
    if fp_ext == ".dta":
        target_df = pd.read_stata(fp)

    return target_df

# function to merge tabular data with a shapefile / gdf object
def table_geodataframe_join(poly_in, join_id, fp_table, fp_out=""):

    # expand filepaths
    fp_table = os.path.expanduser(fp_table)
    fp_out = os.path.expanduser(fp_out)

    # assert that the filepaths exist
    if not os.path.isfile(fp_table):
        raise OSError("Tabular data file not found")

    # read in the tabular data
    tab_data = import_tabular_data(fp_table)

    # execute the merge
    #    joined = poly_in.merge(tab_data, on=join_id, how='left')
    # inner join removes district polygons wihtout data rather than keeping empty geometries
    joined = poly_in.merge(tab_data, on=join_id, how='inner')

    # convert any categorical columns to string (breaks to_file gpd method)
    for column in joined.select_dtypes(include='category').columns: joined[column] = joined[column].astype('string') 

    # write to geojson in desired location
    joined.to_file(fp_out, driver="GeoJSON")

    
#################
# District data #
#################

# read in district shapefile simplified on mapshaper.org
dist_poly = import_vector_data(f'{args.inshp}')

# run the join
print("initiating district-level join")
table_geodataframe_join(poly_in=dist_poly, join_id='lgd_d_id', fp_table=f'{args.intable}', fp_out=os.path.expanduser(f'{args.outfile}'))

