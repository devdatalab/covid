import os
import json
import pandas as pd
import geopandas as gpd
from shapely.geometry.polygon import Polygon
from shapely.geometry.multipolygon import MultiPolygon

import json
import matplotlib as mpl
import pylab as plt
import string
import numpy as np

from bokeh.io import output_file, show, output_notebook, export_png
from bokeh.layouts import row, column, layout
from bokeh.models import CustomJS, GeoJSONDataSource, LogColorMapper, ColorBar, HoverTool, LinearColorMapper, FixedTicker
from bokeh.plotting import figure, save, output_file
from bokeh.palettes import brewer
from bokeh.tile_providers import CARTODBPOSITRON, CARTODBPOSITRON_RETINA, STAMEN_TONER, get_provider
from bokeh.models.widgets import Select
from bokeh.embed import autoload_static
from bokeh.resources import CDN

import plotly.express as px

# ---------------- #
# Define Functions #
# ---------------- #
def read_in_data(fn, data_fp="~/iec/covid/estimates"):
    
    # add the complete home directory if indicated in the filepath
    if "~" in data_fp:
        home_dir = os.path.expanduser("~")
        data_fp = data_fp.replace("~", home_dir)

    # read in the data
    df = pd.read_stata(os.path.join(data_dp, fn))

    return df


def read_in_shapefile(fn, data_fp="~/iec1/gid/pc11")

    # add the complete home directory if indicated in the filepath
    if "~" in data_fp:
        home_dir = os.path.expanduser("~")
        data_fp = data_fp.replace("~", home_dir)

    # read in the shapefile
    gdf = gpd.read_file(os.path.join(data_fp, fn))

    # rename the columns to match the data
    gdf = gdf.rename(columns = {"pc11_s_id": "pc11_state_id",
                                "pc11_d_id": "pc11_district_id"
                                 }
                     )
    return gdf


def get_geodatasource(gdf):
    """
    Get getjsondatasource from geopandas object
    """
    json_data = json.dumps(json.loads(gdf.to_json()))
    return GeoJSONDataSource(geojson = json_data)


def create_figure(title="", ph=850, pw=850):
    """
    Create a basic bokeh figure template
    """
    # define tools
    tools = 'wheel_zoom, pan, reset'

    # define basemap
    tile_provider = get_provider(CARTODBPOSITRON_RETINA)

    # create figure
    p = figure(title = title,
               plot_height=ph ,
               plot_width=pw,
               x_axis_type="mercator",
               y_axis_type="mercator",
               toolbar_location='right',
               tools=tools
               )
    
    # add title and format axes
    p.add_tile(tile_provider)
    p.title.text_font_size = '16pt'
    p.xgrid.grid_line_color = None
    p.ygrid.grid_line_color = None

    return p


def create_color_mapper(mapper_type, c_min, c_max, cmap="YlGnBu", cmap_res=8, cmap_r=True):
    """
    create the colormapper
    mapper_type = "log" or "linear"
    """
    # define the color palette
    palette = brewer[cmap][cmap_res]
    
    # reverese the color palette if desired
    if cmap_r == True:
        palette = palette[::-1]
          
    #Instantiate LogColorMapper that maps numbers in a range, into a sequence of colors.
    # Create the specified color mapper
    if mapper_type == "log":
        color_mapper = LogColorMapper(palette=palette, low=c_min, high=c_max)
    elif mapper_type == "linear":
        color_mapper = LinearColorMapper(palette=palette, low=c_min, high=c_max)
    else:
        raise ValueError("mapper_type must be specified as either 'log' or 'linear'")

    # set the nan_color of the color mapper
    color_mapper.nan_color = "#f0f0f0"

    return color_mapper


def plot_patch_data(geosource, df, color_mapper, column,
                    tick_label_mapper={}, ticks=[],
                    title='', ph=850, pw=850, leg_title=""):

    # set ticker if specified
    if ticks != []:
        ticker = FixedTicker(ticks=ticks)
    else:
        ticker = FixedTicker()

    # create the colorbar
    color_bar = ColorBar(color_mapper=color_mapper,
                         ticker=ticker,
                         major_label_overrides=tick_label_mapper,
                         major_label_text_font_size="10pt",
                         label_standoff=8,
                         width=int(pw*0.9),
                         height=20,
                         location=(0,0),
                         orientation='horizontal',
                         title=leg_title)

    #Add patch renderer to figure
    patch = p.patches('xs','ys',
                      source=geosource,
                      fill_alpha=0.7,
                      line_width=0.5,
                      line_color='black',
                      hover_fill_alpha=1.0,
                      hover_line_width=2.0,
                      hover_line_color='white',
                      fill_color={'field': column, 'transform': color_mapper}
                      )
    
    
    return patch, color_bar


def create_hover_tool(hover_dict, hover_formats={}):
    """
    create the hover tool from a dictionary
    hover_dict: {label: column name}
        e.g. {"State", "pc11_state_name", "District": "pc11_district_name"}
    hover_formats: {column name: format}
        e.g. {"hospital_beds": "{1.11}"}
    """
    # create an empty tooltips list
    tooltips = []
    
    # cycle through dictionary and append items to the tooltips list
    for k, v in hover_dict.items():
        
        # if a format is specified for this column, add it to the column name
        if v in hover_formats:
            v = str.join(v + hover_dict[v])
     
        # create the tuple defining this label
        t = (k, f"@{v}")

        # append the tuple to the tooltips list
        tooltips.append(t)

        
# ---------------------- #
# District Hosptial Beds #
# ---------------------- #

# read in the data
df = read_in_data("hospitals_dist.dta")

# read in the pc11 district shapefile
gdf = read_in_shapefile("pc11-district-simplified.shp")

# merge the data and the geodataframe
data = gdf.merge(df, left_on=["pc11_state_id", "pc11_district_id"], right_on=["pc11_state_id", "pc11_district_id"])

# convert multipoloygon states into individual polygons
data = data.explode()

# capitalize the first letter of district and state names
data['pc11_state_name'] = [string.capwords(x) for x in data['pc11_state_name']]
data['pc11_district_name'] = [string.capwords(x) for x in data['pc11_district_name']]

# calculate state avergage values
state_avg = data.groupby(['pc11_state_id']).mean()[["dlhs_perk_pubpriv_beds"]]

# find indices of missing district data
missing_index = data.loc[data['dlhs_perk_pubpriv_beds'].isnull()].index

# fill in the missing districts with the state averages
data.loc[missing_index, "dlhs_perk_pubpriv_beds"] = state_avg.loc[data.loc[missing_index, "pc11_state_id"], "dlhs_perk_pubpriv_beds"].values

# convert to web mercator crs to match the basemap
data = data.to_crs(epsg=3857)

# definte the output file
output_file("hospital-beds.html", title="Number of Hospital Beds per 1000")

# create figure
p = create_figure( title="Number of Hospital Beds per 1000")

# get the geosource
geosource = get_geodatasource(data)

# create the color mapper
c_min = np.nanmin(data["dlhs_perk_pubpriv_beds"])
color_mapper = create_color_mapper("log", c_min, 9, cmap="YlGnBu", cmap_res=9)

# create the map
patch, color_bar = plot_patch_data(geosource, df, color_mapper, "dlhs_perk_pubpriv_beds",
                                   title="Hospital Beds", leg_title="Number of Hospital Beds per 1000 People")                                   


# create the hover tool
hover_tool = create_hover_tool({"State": "pc11_state_name",
                                "District": "pc11_district_name",
                                "Hospital Beds": "dlhs_perk_pubpriv_beds"},
                               hover_formats={"dlhs_perk_pubpriv_beds" : "{1.11}"})

# add the chloropleth to the figure
p.patch

# add the hover tool to the figure
p.tools.append(hover_tool)

# add the color bar to the figure
p.add_layout(color_bar, 'below')

# write out the code to embed the figure
js, tag = autoload_static(p, CDN, 'main/static/main/js/hospital-beds.js')

# write out the javascript file
with open('../assets/hospital-beds.js', 'w') as file:
    file.write(js)

# write out the html tag 
with open("../assets/hospital-beds.html", "w") as file:
    file.write(tag)

# save the html for easy viewing
save(p) 


# ----------------------- #
# District Mortality Rate #
# ----------------------- #

# read in the data
df = read_in_data("district_age_dist_cfr.dta")

# read in the pc11 district shapefile
gdf = read_in_shapefile("pc11-district-simplified.shp")

# merge the data and the geodataframe
data = gdf.merge(df, left_on=["pc11_state_id", "pc11_district_id"], right_on=["pc11_state_id", "pc11_district_id"])

# convert multipoloygon states into individual polygons
data = data.explode()

# capitalize the first letter of district and state names
data['pc11_state_name'] = [string.capwords(x) for x in data['pc11_state_name']]
data['pc11_district_name'] = [string.capwords(x) for x in data['pc11_district_name']]

# calculate state avergage values
state_avg = data.groupby(['pc11_state_id']).mean()[["district_estimated_cfr_t"]]

# find indices of missing district data
missing_index = data.loc[data['district_estimated_cfr_t'].isnull()].index

# fill in the missing districts with the state averages
data.loc[missing_index, "district_estimated_cfr_t"] = state_avg.loc[data.loc[missing_index, "pc11_state_id"], "district_estimated_cfr_t"].values

# convert to web mercator crs to match the basemap
data = data.to_crs(epsg=3857)

# definte the output file
output_file("mortality-pred.html", title="Mortality Prediction")

# create figure
p = create_figure( title="Mortality Prediction")

# get the geosource
geosource = get_geodatasource(data)

# create the color mapper
color_mapper = create_color_mapper("linear", 0, 2, cmap="RdYlBu", cmap_res=10)

# create the map
patch, color_bar = plot_patch_data(geosource, df, color_mapper, "district_estimated_cfr_t",
                                   title="Mortality Prediction", leg_title="Mortality Prediction")   

# create the hover tool
hover_tool = create_hover_tool({"State": "pc11_state_name",
                                "District": "pc11_district_name",
                                "Mortality Prediction": "district_estimated_cfr_t"},
                               hover_formats={"district_estimated_cfr_t" : "{1.11}"})

# add the chloropleth to the figure
p.patch

# add the hover tool to the figure
p.tools.append(hover_tool)

# add the color bar to the figure
p.add_layout(color_bar, 'below')

# write out the code to embed the figure
js, tag = autoload_static(p, CDN, 'main/static/main/js/mortality-pred.js')

# write out the javascript file
with open('../assets/mortality-pred.js', 'w') as file:
    file.write(js)

# write out the html tag 
with open("../assets/mortality-pred.html", "w") as file:
    file.write(tag)

# save the html for easy viewing
save(p) 
