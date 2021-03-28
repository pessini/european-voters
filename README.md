## Leave or remain in the European Union? Examining the factors that influence in European voters.

This report will investigated a dataset provided by [European Social Survey](https://www.europeansocialsurvey.org/) (ESS) which is a biennial cross-national survey of attitudes and behaviour from European citizens. 

The study will focus on which aspects can influence for a person to vote for your country leave or remain a member of the European Union. After analyzing each variable individually I will build a model that after been trained can predict the probability on a person to vote for your country to Leave the European Union.

This paper will conduct all statistical relevant tests and will present a few insights after the model has been built in order to accept or reject the hyphotesis later described.

## Dataset

- The topics covered at least once by the ESS since its inception include media and social trust, politics, subjective well-being, gender, household, socio demographics, human values, immigration, citizen involvement, health and care, economic morality, family, work and well-being, timing of life, personal and social well-being, welfare attitudes, ageism, trust in justice, democracy, health inequalities, climate change and energy use, justice and fairness, and digital social contacts.
  
  The dataset has 572 variables and I will select a few relevant variables to build a Logistic Regression model to explain the target variable (*vteurmmb*) which is if the person would vote for your country to leave or remain a member of the European Union.
  
  I selected 4 variables in order to predict the vote. The country, number of education years, employed/unemployed and if the person has ever participated in a Labor Union.