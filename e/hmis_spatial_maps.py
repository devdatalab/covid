######################
# HMIS SPATIAL MAPS #
#####################

import os
import sys
import geopandas as gpd
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import pandas as pd
import time
import rasterio
import json
from rasterio.plot import show
from collections import Counter
from shapely.geometry import Point, LineString, box, Polygon
from IPython.core.display import display, HTML
from pathlib import Path
from shutil import copyfile
import string

# get the tmp and iec environment vars
TMP = Path(os.environ.get('TMP'))
IEC = Path(os.environ.get('IEC'))

# set some master parameters to make the font look good
mpl.rcParams['mathtext.fontset'] = 'custom'
mpl.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
mpl.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
mpl.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'
mpl.rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})

# this turns on latex, which makes font and number look really nice, but also 
# forces latex syntax which can cause problems (can be set to False)
mpl.rc('text', usetex=True)

# this sets the dots per inch- it's the resolution the figure will render at.
# make this larger for more precise rendering, though larger sizes will take longer
mpl.rcParams['figure.dpi'] = 100

# read in a standard dataframe
df = pd.read_stata(f"{os.environ['TMP']}/hmis_clean.dta")

#load district-level shapefile
geodist = gpd.read_file(f"{os.environ['IEC1']}/gis/pc11/pc11-district.shp")

#Convert dataframe to a geodataframe
geodist = gpd.GeoDataFrame(geodist)

#join HMIS with district spatial dataset
geodist = geodist.merge(df, left_on=["pc11_s_id", "pc11_d_id"], right_on=["pc11_state_id", "pc11_district_id"], how="left")

# 2020
geodist_2020 = geodist[geodist['year'] == 2020]
geodist_2020 = geodist_2020[geodist_2020['death_per_10000'] < 50] # drop outliers
geodist_2021 = geodist[geodist['year'] == 2021]
geodist_2021 = geodist_2021[geodist_2021['death_per_10000'] < 80] # drop outliers

#Add States' Outlines
geostate = gpd.read_file(f"{os.environ['IEC1']}/gis/pc11/pc11-state.shp")

# choose colormap
cmap = "Reds"

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data for Jan - May 2020
geodist_2020.plot(ax=axu, column="death_per_10000", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Adult Deaths per 10000 Population between January to May 2020")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Adult Deaths per 10000 Population (normalized 0-100)", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/hmis_deaths_2020.png"), bbox_inches="tight", dpi=400)

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data for Jan - May 2021
geodist_2021.plot(ax=axu, column="death_per_10000", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Adult Deaths per 10000 Population between January to May 2021")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Adult Deaths per 10000 Population (normalized 0-100)", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/hmis_deaths_2021.png"), bbox_inches="tight", dpi=400)

# Maternal deaths

geodist_2020 = geodist_2020[geodist_2020['mdeath_per_10000'] < 0.4] # drop outliers

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data for Jan - May 2021
geodist_2020.plot(ax=axu, column="mdeath_per_10000", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Maternal Deaths per 10000 Population between January to May 2020")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Maternal Deaths per 10000 Population (normalized 0-100)", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/hmis_maternal_deaths_2020.png"), bbox_inches="tight", dpi=400)

geodist_2021 = geodist_2021[geodist_2021['mdeath_per_10000'] < 0.4] # drop outliers

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data for Jan - May 2021
geodist_2021.plot(ax=axu, column="mdeath_per_10000", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Maternal Deaths per 10000 Population between January to May 2021")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Maternal Deaths per 10000 Population (normalized 0-100)", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/hmis_maternal_deaths_2021.png"), bbox_inches="tight", dpi=400)