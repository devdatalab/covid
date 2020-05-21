# Covid-19 Data Resources

This repository aims to provide a backbone of high geographic
resolution administrative data to support analysis of and the policy response to the COVID-19
pandemic in India.

The current version includes estimates of hospital and clinic doctor
and bed capacity (district level, and soon subdistrict), CFR predictions
based on variation in local population age distribution (subdistrict
level), urbanization rates and population density (subdistrict level
and lower), as well as deaths and infections at the highest resolution
possible. Crucially, all of these are described with common
location identifiers, making it easy to link them together and to external data
sources. Data are disaggregated by urban/rural where possible.

We have phone surveys on economic conditions in the field, which we
will include here as they arrive. We will also harmonize and include
data from as many other teams' surveys as possible, given data
availability.

We are updating and adding to this repo as quickly as possible. *If you
are part of a team working with policymakers or researchers on
the COVID-19 response in India and need administrative data not in
this repository, please contact us (covid@devdatalab.org) and we will add it to our list if
we can obtain it.*

This is an effort by <a href="http://www.devdatalab.org" target="_blank">Development Data Lab</a>, led by Professors <a href="http://samuelasher.com" target="_blank">Sam Asher</a> (Johns Hopkins SAIS) and <a href="http://www.dartmouth.edu/~novosad/" target="_blank">Paul Novosad</a> (Dartmouth College).
If you use these data, please reference the source. This helps us
continue to provide and develop this service. If you are interested in
funding more rapid development of this data platform, please contact
us at covid@devdatalab.org.

<p align="center"><a target="_blank" href="https://www.dropbox.com/sh/y949ncp39towulf/AABs8_dECTzr38GdS7BneTH7a?dl=0"><img src="https://raw.githubusercontent.com/devdatalab/covid/master/assets/download_button.png"/></a></p>

## Data Folder Structure and Metadata

Relative paths here refer to paths in the data folder. CSV files are
in a csv/ subfolder in each path.

| Folder   | Description                                                                       | Data Files                             | Metadata                                                                                                                                         |
| ----------- | -----------                                                                       | ----------                             | --------                                                                                                                                         |
| covid/      | Number of confirmed cases and deaths by date, district                            | `covid/covid_cases_deaths_district`    | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vTKTuciRsUd6pk5kWhlMyhF85Iv5x04b0njSrWzCkaN5IeEZpBwwvmSdw-mUJOp215jBgv2NPMeTHXK/pubhtml)  |
|             | Case-level patient data with state/district ids                                   | `covid/covid_deaths_recoveries`        |                                                                                                                                                  |
| demography/ | Age pyramid of every district and subdistrict                                     | `demography/age_bins_(sub)district_t`  | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vSyQghmU8rKxC_1NWAUKMa1-DwjT95XmmmQO5b1nuzj48Tjmq8cDvZRaN1C59JgY7eRapMHtnmYY3_k/pubhtml)  |
|             | (Sub)district level slum populations, pop density, urbanization rates (PC)        | `demography/pc11_demographics_(sub)district`  | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vRX8_Qog9_KBasIRa6jjPoCPXJW5H-GHhJfCAXMotwcaAhbVQOWDxrjzBKY2m675keKVwK_2FQhTiKZ/pubhtml)  |
| estimates/  | Modeled district hospital/clinic bed and doctor counts (EC,PC,DLHS)               | `estimates/hospitals_dist`             | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vQL3zu-_LMCV3gIjk1NOGWJVwDwcspl2lI7lvvRUuUgRN3I-X9QFe9BUhdr3dhROpTItTiiUxP_-kU9/pubhtml)  |
|             | Modeled age-structured based fatality rate predictions                            | `estimates/(sub)district_age_dist_cfr` |                                                                                                                                                  |
| hospitals/  | District-level public hospital/clinic bed and doctor counts from DLHS             | `hospitals/dlhs4_hospitals_dist`       | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vR8pkaS86ZlwcSe0ljKyL6wR_YOGE380JrHgAhG5Z66Oq1WtD4xtsJCsdCt-yAv8Qw0X74twBeIQ9of/pubhtml#) |
|             | (Sub)district-level public hospital/clinic bed and doctor counts from Pop Census  | `hospitals/pc_hospitals_(sub)dist`     | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pubhtml)  |
|             | District- and town/village-level hospital public/private hospital employment (EC) | `hospitals/ec_hospitals_(dist,tv)`     | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pubhtml)  |
| migration/  | District-level temporary and permanent migration (LGD identified)            | `migration/district_migration`       | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vTu79uiVKSFv8c1oZvx7WARrWXSfbwfLakiukoezDaH0spMM_MQalkm5fr4bnkBQVNRs2aiU7x41oi3/pubhtml)|
|             | District-level temporary and permanent migration (PC11 identified)  | `migration/pc11/district_migration_pc11`     | [Link](https://docs.google.com/spreadsheets/d/e/2PACX-1vTu79uiVKSFv8c1oZvx7WARrWXSfbwfLakiukoezDaH0spMM_MQalkm5fr4bnkBQVNRs2aiU7x41oi3/pubhtml)  |
| keys/       | Correspondences to link different datasets                                        |                                        |                                                                                                                                                  |

## Data Identified for Inclusion

| Data              | Description | Geographic level | Scope |
| ----------- | ----------- | ----------- | ----------- |
| Comorbidity rates | Local mortality multipliers based on rates of common conditions known to correlate with Covid-19 morbidity, such as diabetes. Source: NSS | District | 
| Gender composition | Sex ratios in five year age bins | State/District/Subdistrict |
| Lockdown policies | Government-imposed restrictions/social distancing with details and dates | State/District |
| Slums | Slum populations, areas, proportions | State/District/Town |
| Poverty | Small area estimation consumption per capita and poverty rate estimates based on the Socioeconomic and Caste Census | State/District/Subdistrict | 
| Health staff | Number of doctors, nurses, employees of health centers, etc. | State/District/Subdistrict | Total/Urban/Rural | COVID testing and cases | Numbers tested and infected, date of first confirmed case, etc | State (potentially district) | 
| Sectoral composition | Share of employment in important sectors of the economy | State/District/Subdistrict | 

| <a href="http://www.devdatalab.org/covid_hospital_beds" target="_blank"><img src="https://raw.githubusercontent.com/devdatalab/covid/master/assets/hospital-beds.png" width="600" height="600"></a> | 
|:--:| 
| *Hospital Bed Availability by District* |

## Repo / Code Structure

| Directory   | Explanation |
| ----------- | ----------- |
| a/          | Analysis file with material used in the *current* version of the data build.
| b/          | Build folder.  |
| e/          | Explore folder. |
| assets/     | Various web assets, such as images embedded in `README.md`.  |

The root path of the folder only has one code file:
- `make_covid.do`, which runs the full build and the full analysis.

### Code Globals

This repository's build refers to locations of code and data using
Stata global variables. You will need to set the following globals to
run the code:

| Global      | Explanation                                           |
| ----------- | -----------                                           |
| `$tmp`      | A temporary folder for intermediate data and outputs. |
| `$ccode`    | Root folder for this repository.                      |
| `$covidpub` | Root data folder for this repo.                       |

A global can be set in Stata with e.g. `global tmp temporary/directory/location`.

### Build Diagram

The full build, including both code and data, is diagrammatically described [here](build.md).

## Downloading the Data

This repository is structured such that the first half runs on
DDL servers to produce datasets that serve as inputs
for the COVID-related analytics, like the EC microdata file, the DLHS
district-level aggregates, and a shortened VD/TD/PCA. The second half 
then needs to run on those files to produce the final
outputs, like the hospital bed estimates. 

You can download the data here:

[![Download Data](assets/download_button.png)](https://www.dropbox.com/sh/y949ncp39towulf/AABs8_dECTzr38GdS7BneTH7a?dl=0)

## Bugs / Requests

If you come across bugs in the data or have a specific data request
that we are likely to have, you can email covid@devdatalab.org or
email Paul, Sam or Toby directly.

## Contributing Data

We invite researchers and data asset holders to contribute data to the public good by adding it to this platform. 
To contribute your data, please [get in touch](mailto:covid@devdatalab.org). You can view the format requirements 
[here](https://docs.google.com/document/d/e/2PACX-1vSOF5vA0O-OEhPC598A3nIh-FcWCc-BvpzzcfY-snIEPsHYEQp8d_jYBeNmpS69sXylbMmVRb6NgArX/pub).

## The Team

This repo is a collaborative effort led by the Development Data Lab, co-founded by Sam Asher, Toby Lunt, and Paul Novosad. Additional contributors: Aditi Bhowmick, Ali Campion, Radhika Jain, Sam Besse, Kritarth Jha. 
