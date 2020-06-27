import os
import getpass
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

mpl.rcParams['mathtext.fontset'] = 'custom'
mpl.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
mpl.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
mpl.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'

mpl.rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})
mpl.rc('text', usetex=True)

# get filepath names
username = getpass.getuser()
homedir = os.path.expanduser("~")

# read in the data
df = pd.read_stata(os.path.join("/scratch", username, "coefs_to_plot.dta"))

# drop gender from this plot of health conditions
df = df.drop(df.loc[df["variable"] == "male_ratio"].index)

# convert coefficients to numeric
df['coef'] = df['coef'].astype(float)

# define ordering of health conditions
sort_vars = {'male_ratio': 1,
 'diabetes_contr_ratio': 2,
 'diabetes_uncontr_ratio': 3,
 'bp_high_ratio': 4,
 'obese_1_2_ratio': 5,
 'obese_3_ratio': 6,
 'chronic_heart_dz_ratio': 7,
 'chronic_resp_dz_ratio': 8,
 'asthma_ocs_ratio': 9,
 'kidney_dz_ratio': 10,
 'liver_dz_ratio': 11,
 'haem_malig_1_ratio': 12,
 'cancer_non_haem_1_ratio': 13,
 'stroke_dementia_ratio': 14,
 'neuro_other_ratio': 15,
 'autoimmune_dz_ratio': 16,
 'immuno_other_dz_ratio': 17,
 'health_ratio': 18}

# sort health conditions
df['sort'] = df['variable'].apply(lambda x: sort_vars[x])
df = df.sort_values("sort", ascending=False)
df = df.drop("sort", axis=1)

# define label key 
label_key = {
 'health_ratio': "All Health Conditions",
 'male_ratio': "Male",
 'obese_1_2_ratio': "Obese (Class 1 \& 2)",
 'obese_3_ratio': "Obese (Class 3)",
 'bp_high_ratio': "Hypertension",
 'diabetes_uncontr_ratio': "Diabetes (Uncontrolled)",
 'diabetes_contr_ratio': "Diabetes (Controlled)",
 'asthma_ocs_ratio': "Asthma",
 'autoimmune_dz_ratio': "Psoriasis, Rheumatoid",
 'haem_malig_1_ratio': "Haematological Cancer",
 'cancer_non_haem_1_ratio': "Non-haematological Cancer",
 'chronic_heart_dz_ratio': "Chronic Heart Disease",
 'chronic_resp_dz_ratio': "Chronic Respiratory Disease",
 'immuno_other_dz_ratio': "Other Immunosuppressive Conditions",
 'kidney_dz_ratio': "Kidney Disease",
 'liver_dz_ratio': "Chronic Liver Disease",
 'neuro_other_ratio': "Other Neurological Condition",
 'stroke_dementia_ratio': "Stroke, Dementia"}

# define function to assign color based on sign of coefficient
def define_color(val):
    if val > 0:
        return "black"
    elif val <= 0:
        return "#e38800"

# define the color for each health condition
color=tuple([define_color(x) for x in list(df['coef'])])

# reassign color of last bar for total
color_list = list(color)
color_list[0] = "#ffbc21"
color = tuple(color_list)    

# define the figure
f, ax = plt.subplots(figsize=[6,10])

# make the horizontal bar chart of coefficients
df['coef'].plot(kind="barh", color=color)

# plot the 0 line
ax.plot([0,0], [-1,17.7], "k-", linewidth=0.75)

# plot the dashed line before total health
ax.plot([-13.5,13.5], [0.5,0.5], linestyle="-.", color="#989997", linewidth=0.5)

# overwrite yticklabels with proper labels
labs = ax.set_yticklabels([label_key[x] for x in list(df["variable"])], fontsize=14, color="#383838")

# add the annotation of the percentage for each bar
for p in ax.patches:
    note = "{:.2f}".format(p.get_width()) + "\%"
    if p.get_width() > 0:
        ax.annotate("+" + note, (p.get_width() + 0.28, p.get_y()+.1), fontsize=14, fontweight="bold", color="#383838")
    else:
        ax.annotate(note, (p.get_width() - 3.5, p.get_y()+.1), fontsize=14, fontweight="bold", color="#383838")

# format axes
ax.set_xlim([-13.5,13.5])
ax.set_ylim([-0.5,17.5])
ax.set_xlabel("Percent Change", color="#383838", fontsize=14)
ax.annotate("India", (5.5,17), color="Black", fontsize=14)
ax.annotate("England", (-9,17), color="#e38800", fontsize=14)
ax.set_title("Percent Change of Population Relative Risk for each \n Health Condition in India Relative to England", fontsize=16, color="#383838")

# save figure
plt.savefig(os.path.join(homedir, "iec", "output", "covid", "coefplot.pdf"), bbox_inches="tight", dpi=150)
# plt.savefig(os.path.join(homedir, "public_html", "png", "coefplot.png"), bbox_inches="tight", dpi=150)

plt.close("all")
