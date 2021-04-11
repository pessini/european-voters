## Examining factors that influence EU acceptance among European voters

<img title="" src="img/ess_logo.png" alt="" align="center">

## Description

This analysis will investigate a dataset provided by [European Social Survey (ESS)](https://www.europeansocialsurvey.org/) which is a cross-national survey of attitudes and behaviour from European citizens. The topics covered by ESS are very heterogeneous and include media and social trust, politics, immigration, citizen involvement, health and care, economic, work and well-being.

The analysis will focus on which aspects can influence a person to vote for their country to leave or remain a member of the European Union. The variables selected are mostly socio-demographic such as education, employment status and Union membership status.

### Software version

[R](https://www.r-project.org/foundation/) - version 4.0.2

To run R in [Jupyter Notebooks](https://jupyter.org/), check out the [IRKernel](https://irkernel.github.io/) project.

For a list of supported programming languages in Jupyter Notebooks, please refer to the [Jupyter kernels](https://github.com/jupyter/jupyter/wiki/Jupyter-kernels) page in GitHub.

## Dataset

The dataset used was [ESS9-2018 Edition 3.1](https://www.europeansocialsurvey.org/docs/round9/survey/ESS9_data_documentation_report_e03_1.pdf) released on 17th of February 2021 and it can be found [here](https://github.com/pessini/european-voters/blob/main/ESS9e03_1.sav).

##### Data Dictionary

- **CNTRY** Country
- **EDUYRS** Years of full-time education completed
- **EISCED** Highest level of education, ES - ISCED
- **UEMP3M** Ever unemployed and seeking work for a period more than three months
- **MBTRU** Member of trade union or similar organisation
- **VTEURMMB** Would vote for your country to remain member of European Union or leave
- **GNDR** Gender
- **YRBRN** Year of birth
- **AGEA** Age of respondent. Calculation based on year of birth and year of interview

## Survey Weights

The analysis of survey data often uses complex sample designs and **weighting adjustments** in order to make the sample look more like the intended population of the survey. As ESS is a **cross-national survey** and countries implement different sample designs, it is important to use weights in all analyses to take into consideration the country context, and therefore **avoid bias in the outcome**.

## Data Storytelling

The Data Analysis can be visualized as a [Repository Page]([European-Voters-Analysis (pessini.github.io)](https://pessini.github.io/european-voters/).