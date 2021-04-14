import os
import pandas as pd
import getpass
import datetime
import matplotlib.pyplot as plt

# vaccination dataframe
vdf = pd.read_stata(os.path.expanduser("~/iec/covid/covid/covid_vaccination.dta"))

# case data
cdf = pd.read_stata(os.path.expanduser("~/iec/covid/covid/covid_infected_deaths.dta"))

# population data
pdf = pd.read_stata(f"/scratch/{getpass.getuser()}/lgd_pca_district_pop.dta")

# get dates as string
cdf['string_date'] = cdf['date'].apply(lambda x: x.strftime("%d%m%Y"))
vdf = vdf.rename(columns={"date": "string_date"})

# merge case data and vaccination data
df = cdf.merge(vdf, on=["lgd_state_name", "lgd_state_id", "lgd_district_name", "string_date"], how="outer")

# merge in population data
df = df.merge(pdf, on=["lgd_state_name", "lgd_state_id", "lgd_district_name", "lgd_district_id"], how="left")

# get date as datetime object
df['date'] = df['string_date'].apply(lambda x: datetime.datetime.strptime(x, "%d%m%Y"))
df = df.sort_values(["lgd_state_name", "lgd_district_name", "date"])

# keep only dates with vaccination data, after Jan 16 2021, before April 13
df = df.loc[(df['date'] >= datetime.datetime.strptime("16012021", "%d%m%Y")) &
            (df['date'] < datetime.datetime.strptime("13042021", "%d%m%Y"))].copy()
df['total_vaccinated'] = df['total_covaxin'] + df['total_covishied']

# calculate per capita vaccination rates
df['vac_rate'] = df['total_vaccinated'] / df['lgd_pca_tot_p']


# ---- #
# plot #
# ---- #
f, ax = plt.subplots(figsize=[12, 8])

# get state data
state_data = df.groupby(['date', 'lgd_state_name']).sum()[['total_vaccinated', 'lgd_pca_tot_p']].reset_index()

# get state total across all time
state_total = state_data.groupby(['lgd_state_name']).sum()[['total_vaccinated', 'lgd_pca_tot_p']].reset_index()

# calcualte vaccination rate
state_data['vac_rate'] = state_data['total_vaccinated'] / state_data['lgd_pca_tot_p']
state_total['vac_rate'] = state_total['total_vaccinated'] / state_total['lgd_pca_tot_p']

#sns.lineplot(data=state_data, x="date", y="vac_rate", hue="lgd_state_name")
state_total = state_total.sort_values(by='vac_rate', ascending=False)
state_total = state_total.set_index("lgd_state_name")

# drop infinite values (sikkim)
state_total = state_total.drop(state_total.loc[state_total["vac_rate"] == np.inf].index)

# drop 0 vlaues (lakshadweep)
state_total = state_total.drop(state_total.loc[state_total["vac_rate"] == 0].index)

state_total.plot.bar(y='vac_rate', ax=ax)
ax.set_ylabel("Vaccination Rate", fontsize=12)
ax.set_xlabel("State", fontsize=12)

plt.savefig(os.path.expanduser("~/public_html/png/state_vac_rate.png", bbox_inches="tight"))
