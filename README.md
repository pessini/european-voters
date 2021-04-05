## Leave or remain in the European Union? Examining the factors that influence in European voters.

<img src="https://github.com/pessini/european-voters/blob/main/img/ESS-logo.png" alt="European Social Survey" width="250"/><br>

This analysis will investigated a dataset provided by [European Social Survey](https://www.europeansocialsurvey.org/) (ESS) which is a cross-national survey of attitudes and behaviour from European citizens. The topics covered by ESS are very heterogeneous and include media and social trust, politics, immigration, citizen involvement, health and care, economic, work and well-being.

The analysis will focus on which aspects can influence a person vote for your country leave or remain a member of the European Union. 



### Software version

[R](https://www.r-project.org/foundation/) - version 4.0.2

To run R in [Jupyter Notebooks](https://jupyter.org/), check out the [IRKernel](https://irkernel.github.io/) project.

For a list of supported programming languages in Jupyter Notebooks, please refer to the [Jupyter kernels](https://github.com/jupyter/jupyter/wiki/Jupyter-kernels) page in GitHub.

## Dataset

The dataset used was [ESS9-2018 Edition 3.1](https://www.europeansocialsurvey.org/docs/round9/survey/ESS9_data_documentation_report_e03_1.pdf) released on 17th of February 2021 and it can be founded [here](https://github.com/pessini/european-voters/blob/main/ESS9e03_1.sav).

### Data Dictionary

- __CNTRY__ Country
- __EDUYRS__ Years of full-time education completed
- __EISCED__ Highest level of education, ES - ISCED
- __NETUSOFT__ Internet use, how often
- __UEMP3M__ Ever unemployed and seeking work for a period more than three months
- __MBTRU__ Member of trade union or similar organisation
- __GNDR__ Gender
- __YRBRN__  Year of birth
- __AGEA__ Age of respondent. Calculation based on year of birth and year of interview
- __VTEURMMB__ Would vote for your country to remain member of European Union or leave

## Survey Weights

The analysis of survey data often uses complex sample designs and __weighting adjustments__ in order to make the sample look more like the intended population of the survey. As ESS is a __cross-national survey__ and countries implement different sample designs, it is important to use weights in all analysis to take into consideration the country context, and therefore __avoid bias in the outcome__.

__Post-stratification weights__ intended purpose is to decrease the impact of coverage, sampling and nonresponse error. In ESS is based on gender, age, education and geographical region.

__Clustering__ produces more precise population estimates than a simple random design would achieve but this makes survey results appear more homogeneous. To address this problem ESS uses Clustering Adjustments.

According to ESS documentation:

> It is recommended that by default you should always use *anweight* (analysis 
> weight) as a weight in all analysis. This weight is suitable for all types of analysis, 
> including when you are studying just one country, when you compare across 
> countries, or when you are studying groups of countries. 

> *anweight* corrects for differential selection probabilities within each country as 
> specified by sample design, for nonresponse, for noncoverage, and for sampling 
> error related to the four post-stratification variables, and takes into account 
> differences in population size across countries. 

Details about how ESS weights the data can be found [here](https://www.europeansocialsurvey.org/docs/methodology/ESS_weighting_data_1_1.pdf).

## References

> Kaminska, O., & Lynn, P. (2017). Survey-Based Cross-Country Comparisons Where Countries Vary in Sample Design: Issues and Solutions. Retrieved March 31, 2021, from https://sciendo.com/article/10.1515/jos-2017-0007

> European Social Survey Cumulative File, ESS 1-9 (2020). Data file edition 1.1. NSD - Norwegian Centre for Research Data, Norway - Data Archive and distributor of ESS data for ESS ERIC.