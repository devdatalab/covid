import geopandas as gpd
import contextily as ctx
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import getpass
import os
​
​
# select the population you want to work with and store full variable name in var
var = "dummy"
​
df = pd.read_excel("nrega.xlsx")

# convert the dataframe to a geodataframe
df = gpd.GeoDataFrame(pd.read_excel("nrega.xlsx"), geometry=gpd.points_from_xy(df["longitude"], df["latitude"]),crs={'init' :'epsg:4326'})
​
# convert the crs of the dataframe
df = df.to_crs(epsg=3857)
​
# sort values by longitude
df = df.sort_values(by="longitude")
​
# identify minimum and maxiumum values of variable of interest                           
vmin = df[var].min()
vmax = df[var].max()
​
# set up a figure                              
f, ax = plt.subplots(1, figsize=[10,15])
​
# choose colormap
cmap = "viridis_r"
                              
# plot figure                            
df.plot(column=var, ax=ax, vmin=vmin, vmax=vmax, cmap=cmap, alpha=0.85)
​
# add basemap
ctx.add_basemap(ax, source=ctx.providers.Stamen.TonerLite, zoom=6)
​
# set axis parameters - these are manually set to be the window over all of India                             
ax.set_xlim([7510000, 10000000])
ax.set_ylim([1250000, 3750000])
ax.axes.xaxis.set_visible(False)
ax.axes.yaxis.set_visible(False)
                              
# set plot title
ax.set_title(f"% reporting NREGA unavailability", fontsize=18, pad=8)
​
# add colorbar
cax = f.add_axes([0.93, .25, 0.025, 0.5])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=vmin, vmax=vmax))
​
# fake up the array of the scalar mappable. 
sm._A = []
cb = f.colorbar(sm, cax=cax)
                              
# label the colorbar
cb.set_label(label='Share', fontsize=16, rotation=270, labelpad=30)
cb.ax.tick_params(labelsize=14)

plt.savefig("nrega.png", bbox_inches="tight", dpi=300)


# save the figure                              
username = getpass.getuser()
plt.savefig(os.path.join("/scratch", username, "f{var}.png"), bbox_inches="tight", dpi=300)


plt.savefig("/scratch/adibmk/labor_lost_work.png", bbox_inches="tight", dpi=300)


plt.savefig(f"{var}.png", bbox_inches="tight", dpi=300)

plt.close("all")
 
