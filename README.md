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

## Data Currently Available

| Data              | Description | Geographic level |
| ----------- | ----------- | ----------- |
| Public Hospital capacity | Facilities, doctors, and beds. Sources: 2011 Population Census and DLHS-4 (2012-14). | District, Subdistrict (PC only) |
| Private Hospitals | Public and private hospital employment from 2013 Economic Census. Can estimate private system beds based on public employment:bed ratios. | District |
| Predicted COVID-19 mortality rates | Predictions based strictly on local age distributions, which create substantial risk differences across locations. | Subdistrict |
|District correspondences | Keys linking current districts to 2011 Population Census districts, which are the basis of many datasets | District |
| Demographics | 2011 Population Census (most recent) population, density, literacy rate, urbanization | State/District/Subdistrict/Town/Village |


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

| ![Hospital Beds by District](assets/dlhs4_perk_beds_pubpriv.png?raw=true "Hospital Beds") | 
|:--:| 
| *Hospital Bed Availability by District* |

## Repo Structure

| Directory   | Explanation |
| ----------- | ----------- |
| a/          | Analysis file with material used in the *current* version of the data build.
| b/          | Build folder.  |
| e/          | Explore folder. |
| assets/     | Various web assets, such as images embedded in `README.md`.  |

The root path of the folder only has one code file:
- `make_covid.do`, which runs the full build and the full analysis.

## Data Folder Structure

| Directory   | Explanation |
| ----------- | ----------- |
| covid/      | Confirmed cases and deaths by date, state, district
| demography/ | Age structure of every district and subdistrict  |
| estimates/  | All estimates/outputs requiring assumption/imputation, e.g. district bed counts, case fatality rate predictions based on age structure |
| hospitals/  | Hospital and clinic bed and doctor counts (Population Census, Economic Census, DLHS4)  |
| keys/       | Correspondences to link different datasets  |

### Code Globals

This repository's build refers to locations of code and data using
Stata global variables. You will need to set the following globals to
run the code:

| Global   | Explanation |
| ----------- | ----------- |
| `$tmp`          | A temporary folder for intermediate data and outputs.
| `$ccode`          | Root folder for this repository.  |
| `$hosp`          | Output folder for hospital data. |

A global can be set in Stata with e.g. `global tmp temporary/directory/location`.

## Downloading the Data

This repository is structured such that the first half runs on
DDL servers to produce datasets that serve as inputs
for the COVID-related analytics, like the EC microdata file, the DLHS
district-level aggregates, and a shortened VD/TD/PCA. These files have
been compressed into a single archive available
[here](https://dl.dropboxusercontent.com/s/80igbve4f751rz1/ddl_covid_input_data.tar.gz?dl=0). 

The second half then needs to run on those files to produce the final
outputs, like the hospital bed estimates. If you are interested in
downloading those data without running any of the code, you can do so
[here](https://dl.dropboxusercontent.com/s/ig9u8ol45445vdl/ddl_covid_output_data.tar.gz?dl=0).

## Metadata

Metadata tables describing the datasets and variable specifications
for these data can be found
[here](https://github.com/devdatalab/covid/blob/master/assets/metadata.md).

## The Team

This repo is a collaborative effort led by the Development Data Lab, co-founded by Sam Asher, Toby Lunt, and Paul Novosad. Additional contributors: Aditi Bhowmick, Ali Campion, Radhika Jain, Sam Besse. 
