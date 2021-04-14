import geopandas as gpd
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import time
import rasterio
from rasterio.plot import show
from collections import Counter
from shapely.geometry import Point, LineString, box, Polygon
from IPython.core.display import display, HTML
from pathlib import Path
from shutil import copyfile

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

# load dataset we want to map
vacc = pd.read_stata(os.path.join(TMP, "vacc_eligible.dta"))

#rename variables to match with shape file
vacc = vacc.rename(columns={'pc11_state_id': 'pc11_s_id', 'pc11_district_id': 'pc11_d_id'})

#load district-level shapefile
geodist = gpd.read_file(f"{os.environ['IEC1']}/gis/pc11/pc11-district.shp")

#Convert dataframe to a geodataframe
geodist = gpd.GeoDataFrame(geodist)

#join dataset with district spatial dataset
geodist = geodist.merge(vacc, left_on = ['pc11_s_id', 'pc11_d_id'], 
                        right_on = ['pc11_s_id', 'pc11_d_id'], how = "left")

#Add States' Outlines
geostate = gpd.read_file(f"{os.environ['IEC1']}/gis/pc11/pc11-state.shp")

# choose colormap
cmap = "viridis_r"

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data
geodist.plot(ax=axu, column="vacc_eligible", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Total vaccinations divided by 45$+$ population")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Total vaccinations/45 $+$ population", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/vacc.png"), bbox_inches="tight", dpi=150)

# choose colormap
cmap = "Reds"

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data
geodist.plot(ax=axu, column="tot_vacc", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Total vaccinations")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Total vaccinations (normalized 0-100)", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/vacc_all.png"), bbox_inches="tight", dpi=150)


# choose colormap
cmap = "PRGn"

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data
geodist.plot(ax=axu, column="vacc_hc", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 2.4)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Total vaccinations divided by number of health-care centres")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=100))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Total vaccinations$/$No. health-care centres", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.expanduser("~/public_html/png/vacc_hc.png"), bbox_inches="tight", dpi=150)


