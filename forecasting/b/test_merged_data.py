# general imports - use spatial env in configs/
import geopandas as gpd
import pandas as pd
from pathlib import Path
import shutil

# import our configs - depends on 'process_yaml_config' utility in ddl/tools/py/tools.py
import sys, os
sys.path.insert(0, os.path.expanduser("~/ddl/tools/py"))
from tools import process_yaml_config
config = process_yaml_config('~/ddl/covid/forecasting/config/config.yaml')

# shorten path globals
CCODE = Path(os.path.expanduser(config['globals']['ccode']))
CDATA = Path(os.path.expanduser(config['globals']['cdata']))

# read temp directory from env variable
TMP = Path(os.environ['TMP'])


###############
# Merge tests #
###############

# combine DDL covid data and UChicago predictions
pred_data = pd.read_stata(CDATA / 'pred_data.dta')
ddl_data = pd.read_stata(CDATA / 'ddl_data.dta')
merged_data = pred_data.merge(ddl_data, how='inner', on=['lgd_district_id', 'lgd_state_id'])

# check merge rate
if (len(merged_data) / len(pred_data)) < 0.98:
    raise ValueError('merge rate from DDL data to covid predictions on LGD state / dist must be greater than 98%')


#####################
# Identifiers tests #
#####################

# read in the merged data saved by Stata script
merged_data = pd.read_stata(CDATA / 'merged_data.dta')

# assert we're unique on LGD state/dist and time
if not merged_data.set_index(['lgd_d_id','lgd_s_id', 'date']).index.is_unique:
    raise ValueError('LGD state and district do not uniquely identify observations across dates')

# assert no missings in identifiers
idnames = ['lgd_d_id', 'lgd_s_id']
for idname in idnames:
    if not merged_data[idname].isna().sum() == 0:
        raise ValueError(f'Identifier {idname} has missings')

###################
# Variables tests #
###################

# look for missings
varnames = ['rt_pred', 'total_cases', 'new_cases_ts']
for varname in varnames:
    if not merged_data[varname].isna().sum() == 0:
        raise ValueError(f'Variable {varname} has missings')


##############
# Dates test #
##############

# convert to pd datetime format for sorting
merged_data['date'] = pd.to_datetime(merged_data['date'])

# get latest date observed for RT within each district into an array
latest_df = merged_data.loc[merged_data.groupby(['lgd_d_id','lgd_s_id']).date.idxmax()]

# assert we only have a single latest date across all dists
if not len(latest_df['date'].unique()) == 1:
    raise ValueError(f'Different districts have different latest Rt observation dates in merged DTA file')

# pull latest date into a string
latest_date = latest_df.iloc[0]['date'].strftime('%Y-%m-%d')

# read in the JSON object in a JS file that contains this "most recent date" metadata to compare to the date in the tabular data
with open(CDATA / 'pred_metadata.js') as f:
    lines = f.readlines()
json_date = lines[0].split('most_recent":"',1)[1][:10]

# check that the latest tabular date matches
if not latest_date == json_date:
    raise ValueError(f'Different latest dates in tabular file and JSON metadata')


#################
# GeoJSON tests #
#################

# read in geojson output that gets transformed to vector tileset
# hack around gpd.read_file having STRANGE conda-related error when reading from ~/iec/ filesystem?!
geojson = gpd.read_file(CDATA / 'district.geojson')

# check merged state ids are the same
geojson['lgd_s_id_x'].equals(geojson['lgd_s_id_y'])

# check that the geojson file also has the same latest date
geojson['date'] = pd.to_datetime(geojson['date'])
json_latest = geojson.loc[geojson.groupby(['lgd_d_id','lgd_s_id_x']).date.idxmax()]
if not len(json_latest['date'].unique()) == 1:
    raise ValueError(f'Different districts have different latest Rt observation dates in geojson file')

# check that the latest date agrees with JS metadata
latest_date = json_latest.iloc[0]['date'].strftime('%Y-%m-%d')
if not latest_date == json_date:
    raise ValueError(f'Different latest dates in geojson file and JSON metadata')

# EXIT
print('TESTS PASSED')



