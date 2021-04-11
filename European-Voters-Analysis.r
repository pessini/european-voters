

# Check if the packages that we need are installed
want = c("dplyr", "ggplot2", "ggthemes", "gghighlight", "foreign", "scales", "survey", "srvyr", "caret", 
         "ggpubr", "forcats")
have = want %in% rownames(installed.packages())
# Install the packages that we miss
if ( any(!have) ) { install.packages( want[!have] ) }
# Load the packages
junk <- lapply(want, library, character.only = T)
# Remove the objects we created
rm(have, want, junk)

survey_rawdata <- read.spss("ESS9e03_1.sav", use.value.labels=T, max.value.labels=Inf, to.data.frame=TRUE)

variables <- c("cntry", 
               "eduyrs", 
               "eisced",
               "uemp3m", 
               "mbtru", 
               "vteurmmb", 
               "yrbrn", 
               "agea", 
               "gndr", 
               "anweight", 
               "psu", 
               "stratum")

european_survey <- survey_rawdata[,variables]

head(european_survey)

paste0("Number of rows in the dataset: ", nrow(european_survey))

# Checking for NA's in the dataset
sapply(european_survey, function(x) sum(is.na(x)))

# For the purpose of this analysis, considering Vote as Leave or Remain
european_survey$vteurmmb <- as.character(european_survey$vteurmmb)
european_survey$vteurmmb[european_survey$vteurmmb == "Remain member of the European Union"] <- "Remain"
european_survey$vteurmmb[european_survey$vteurmmb == "Leave the European Union"] <- "Leave"
european_survey$vteurmmb[european_survey$vteurmmb == "Would submit a blank ballot paper"] <- NA
european_survey$vteurmmb[european_survey$vteurmmb == "Would spoil the ballot paper"] <- NA
european_survey$vteurmmb[european_survey$vteurmmb == "Would not vote"] <- NA
european_survey$vteurmmb[european_survey$vteurmmb == "Not eligible to vote"] <- NA
european_survey$vteurmmb <- as.factor(european_survey$vteurmmb)

# Cleaning responses that are not able to fit into ISCED
european_survey$eisced <- as.character(european_survey$eisced)
european_survey$eisced[european_survey$eisced == "Not possible to harmonise into ES-ISCED"] <- NA
european_survey$eisced[european_survey$eisced == "Other"] <- NA

# Cleaning NA values
df_european_survey <- european_survey[complete.cases(european_survey), ]
sapply(df_european_survey, function(x) sum(is.na(x)))

# Different way to clean the variable leaving as yes or no
df_european_survey$uemp3m <- as.character(df_european_survey$uemp3m)
df_european_survey$uemp3m <- as.factor(df_european_survey$uemp3m)

# Creating a new feature Education by aggregating the ISCED"s levels
# Low, Medium and High Education
df_european_survey <- df_european_survey %>% 
  mutate(Education = case_when(
      eisced == "ES-ISCED I , less than lower secondary" ~ "Low Education",
      eisced == "ES-ISCED II, lower secondary" ~ "Low Education",
      eisced == "ES-ISCED IIIb, lower tier upper secondary" ~ "Medium Education",
      eisced == "ES-ISCED IIIa, upper tier upper secondary" ~ "Medium Education",
      eisced == "ES-ISCED IV, advanced vocational, sub-degree" ~ "Medium Education",
      eisced == "ES-ISCED V1, lower tertiary education, BA level" ~ "High Education",
      eisced == "ES-ISCED V2, higher tertiary education, >= MA level" ~ "High Education",
      TRUE ~ eisced))
df_european_survey$Education <- as.factor(df_european_survey$Education)
df_european_survey$eisced <- as.factor(df_european_survey$eisced)

# For the purpose of this analysis, considering the answer if the respondent ever been a member 
# of a trade union or similar organisation - "Yes, currently" and "Yes, previously" as simple Yes
df_european_survey$mbtru <- as.character(df_european_survey$mbtru)
df_european_survey$mbtru[df_european_survey$mbtru == "Yes, currently"] <- "Yes"
df_european_survey$mbtru[df_european_survey$mbtru == "Yes, previously"] <- "Yes"
df_european_survey$mbtru <- as.factor(df_european_survey$mbtru)


# Transforming as numeric the variable Years of Education
df_european_survey$eduyrs <- as.numeric(df_european_survey$eduyrs)

# Creating a new feature as per age (eg. young, young adult, older adult, elderly)
df_european_survey$agea <- as.numeric(df_european_survey$agea)
df_european_survey <- df_european_survey %>% 
  mutate(Age_Band = case_when(
    agea < 20 ~ "<20",
    agea >= 20 & agea < 40 ~ "20-39",
    agea >= 40 & agea <= 65 ~ "40-65",
    agea > 65 ~ ">65"))
df_european_survey$Age_Band <- as.factor(df_european_survey$Age_Band)

northern <- c("Denmark","Finland","Ireland","Latvia","Lithuania","Sweden")
western <- c("Austria","Belgium","France","Germany","Netherlands")
eastern <- c("Bulgaria","Czechia","Hungary","Poland","Slovakia")
southern <- c("Slovenia","Cyprus","Spain","Croatia","Italy","Portugal")
df_european_survey <- df_european_survey %>% mutate(Region = case_when(cntry %in% northern ~ "Northern Europe",
                                                                      cntry %in% western ~ "Western Europe",
                                                                      cntry %in% eastern ~ "Eastern Europe",
                                                                      cntry %in% southern ~ "Southern Europe",
                                                                      TRUE ~ "Europe"))

weighted_df_ess <- df_european_survey %>% as_survey_design(ids=psu, strata=stratum, weights=anweight)

# Lonely PSUs - http://r-survey.r-forge.r-project.org/survey/exmample-lonely.html
options(survey.lonely.psu = "adjust")

weighted_df_ess

# Classifying happiness with EU by splitting countries with more than 15% of voting to Leave as Unfavorable
happiness_EU <- weighted_df_ess %>% 
                    group_by(cntry,vteurmmb) %>%
                    summarise(proportion = survey_mean()) %>%
                    filter(vteurmmb == "Leave") %>% 
                    mutate(EU_Opinion = ifelse(proportion < .16, "Favorable", "Unfavorable")) %>%
                    group_by(EU_Opinion) %>% summarise(total = n()) %>%
                    mutate(prop = total / sum(total), 
                           label = paste0(round(total / sum(total) * 100, 0), "%"), 
                           label_y = cumsum(prop) - 0.5 * prop)

happiness_overview <- happiness_EU %>%
    ggplot(aes(x = "", y = prop)) +
    geom_bar(aes(fill = fct_reorder(EU_Opinion, prop, .desc = FALSE)), lineend = 'round',
             stat = "identity", width = .5, alpha=.9) +
    coord_flip() +
    scale_fill_manual(values = c("#67a9cf", "#ef8a62")) +
    geom_text(aes(y = label_y, label = paste0(label, "\n", EU_Opinion)), size = 8, col = "white", fontface = "bold") +
    labs(x = "", y = "%",
        title = "How happy member nations are with European Union?",
        subtitle = "Considering more than 15% of votes to Leave the EU as Unfavorable view") + 
    theme_void() +
    theme(axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank()) +
    theme(legend.position = "none",
          plot.title=element_text(vjust=.8,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.8,family='', face='bold', colour='#636363', size=15))

#ef8a62 - Happy
#67a9cf - Not so Happy
happiness_overview

countries_by_Vote_Leave <- weighted_df_ess %>% group_by(cntry,vteurmmb) %>% 
    summarise(total = survey_total(), prop = survey_mean()) %>%
    filter(vteurmmb == "Leave") %>%
    arrange(desc(prop)) %>%
    head(15)

countries_by_Vote_Leave %>% 
mutate(factor(cntry, levels = .$cntry),
      label = paste0(round(prop * 100, 0), "%")) %>%
ggplot(aes(x=reorder(cntry,prop), y=prop)) + 
    geom_segment(aes(xend = cntry, yend = 0), color = "#67a9cf", size=1.2) +
    geom_point(size = 18, color="#67a9cf") +
    geom_text(face="bold", color = "white", size = 5, aes(label = label)) +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "", y = "",
         title = "Countries with the highest proportion of votes to Leave the EU",
        subtitle = "% is approximate") +
    theme_minimal() + coord_flip() +
    theme(axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          plot.title=element_text(vjust=1.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=1.5,family='', face='bold', colour='#636363', size=15))

countries_by_Vote_Remain <- weighted_df_ess %>% group_by(cntry,vteurmmb) %>% 
    summarise(total = survey_total(), prop = survey_mean()) %>%
    filter(vteurmmb == "Remain") %>%
    arrange(desc(prop)) %>%
    head(15)

countries_by_Vote_Remain %>% 
mutate(factor(cntry, levels = .$cntry),
      label = paste0(round(prop * 100, 0), "%")) %>%
ggplot(aes(x=reorder(cntry,prop), y=prop)) + 
    geom_segment(aes(xend = cntry, yend = 0), color = "#ef8a62", size=1.2) +
    geom_point(size = 18, color="#ef8a62") +
    geom_text(face="bold", color = "white", size = 5, aes(label = label)) +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "", y = "",
         title = "Countries with the highest proportion of votes to Remain member of the EU",
        subtitle = "% is approximate") +
    theme_minimal() + coord_flip() +
    theme(axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          plot.title=element_text(vjust=1.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=1.5,family='', face='bold', colour='#636363', size=15))

weighted_df_ess %>% 
    group_by(Region,vteurmmb) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    mutate(label = paste0(round(proportion * 100, 2), "%"), 
           label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= fct_reorder2(Region, vteurmmb, proportion, .desc = FALSE), y=proportion)) + 
    geom_bar(aes(fill=vteurmmb), position = position_stack(reverse = TRUE) ,stat="identity", width = .4) +
    scale_fill_manual(values = c("#67a9cf", "#ef8a62"))  +
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    geom_text(aes(y=label_y, label = paste0(label, "\n", vteurmmb)), 
              col = "white",
              size = 6,
              fontface = "bold") +
    labs(x = "", y = "", fill = "",
        title = "Voting intention on European Regions")+ 
    theme_minimal() + 
    theme(legend.position = "none",
          axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(),
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))

weighted_df_ess %>%
    group_by(gndr,Age_Band) %>%
    summarise(total = round(survey_total(),2), proportion = survey_mean()) %>%
    mutate(label = paste0(round(proportion * 100, 2), "%"), 
       label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= gndr, y=proportion)) + 
    geom_bar(aes(fill=factor(Age_Band,levels=c("<20","20-39","40-65",">65"))),
             stat="identity",
             position = position_stack(reverse = TRUE),
             width = .3) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_brewer(palette='Set2') +
    geom_text(aes(y=label_y, label = label), 
              col = "white",
              size = 6,
              fontface = "bold") +
    labs(x = "", y = "", fill = "Age Band", title = "Gender-Age Overview") +
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.direction = "horizontal",legend.title = element_text(size=15, face="bold"),
          legend.text = element_text(size=15, face="bold"),
          axis.text.x = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          plot.title=element_text(hjust = 0.5,vjust=1.5,family='', face='bold', colour='#636363', size=25))

weighted_df_ess %>%
    group_by(Age_Band,vteurmmb) %>%
    summarise(total = round(survey_total(),2), proportion = survey_mean()) %>%
    mutate(label = paste0(round(proportion * 100, 2), "%"), 
       label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= factor(Age_Band,levels=c("<20","20-39","40-65",">65")), y=proportion)) + 
    geom_bar(aes(fill=vteurmmb),
             stat="identity",
             position = position_stack(reverse = TRUE),
             width = .5) +
    scale_y_continuous(labels = scales::percent) +
    gghighlight(vteurmmb == "Leave", use_direct_label = TRUE) +
    scale_fill_manual(values = c("#67a9cf", "#ef8a62"))  +
    geom_text(aes(y=label_y, label = label), 
              col = "white",
              size = 6,
              fontface = "bold") +
    labs(x = "Age Band", y = "", fill = "Age Band", 
         title = "Young Europeans more keen on the EU",
        subtitle = "% of voting intention to Leave the EU: Age Overview") +
    theme_minimal()  +
    theme(legend.position = "none",
          axis.text.x = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          plot.title=element_text(hjust = 0.5,vjust=1.5,family='', face='bold', colour='#636363', size=25),
         plot.subtitle=element_text(hjust = 0.5,vjust=.5,family='', face='bold', colour='#636363', size=15))

weighted_df_ess %>% 
    group_by(vteurmmb,Education) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    ggplot(aes(x= vteurmmb, y=proportion, 
               fill=factor(Education,levels=c("Low Education","Medium Education","High Education")))) + 
    geom_bar(position="dodge",stat="identity", width = .6) +
    geom_hline(aes(yintercept = 0.25), colour = "#636363", linetype ="longdash", size = .8) +
    scale_fill_brewer(palette = "Pastel1") +
    scale_y_continuous(labels = scales::percent) +
    annotate("text", x = .5, y = .26, label = "paste(25, \"%\")", parse = TRUE, size=5) +
    labs(x = "Vote", y = "",fill = "", 
         title = "Education Overview on European Voters",
         subtitle = "% proportion of votes") + 
    theme_minimal() + 
    theme(legend.text = element_text(size=15, face="bold",colour='#636363'),
          axis.text.x = element_text(face="bold", color="#636363", size=18), 
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))

# Filtering the countries to use later on data viz
target_countries_l <- countries_by_Vote_Leave %>% arrange(desc(prop)) %>% head(5) %>% select(cntry)
target_countries_l$index <- seq.int(nrow(target_countries_l)) # adding an ordered index
target_countries_r <- countries_by_Vote_Remain %>% arrange(desc(prop)) %>% head(5) %>% select(cntry)
target_countries_r$index <- seq.int(nrow(target_countries_r))

countries_education_leave <- weighted_df_ess %>% 
    group_by(cntry,Education) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    filter(cntry %in% target_countries_l$cntry) %>% 
    arrange(desc(cntry,Education,proportion)) %>%
    ggplot(aes(x= factor(cntry, labels=target_countries_l$cntry), y=proportion)) + 
    geom_bar(aes(fill=factor(Education,levels=c("Low Education","Medium Education","High Education"))),
             position="dodge",stat="identity", width = .6) +
    geom_hline(aes(yintercept = 0.20), colour = "#8da0cb", linetype ="longdash", size = .8) +
    scale_fill_brewer(palette = "Pastel1") +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "",
        y = "",
        fill = "Education",
        title = "Countries with highest proportion of votes to Leave the EU",
        subtitle = "Educational overview") + 
    theme_minimal() + 
    theme(legend.text = element_text(size=12, face="bold", color="#636363"),
          axis.text.x = element_text(face="bold", color="#636363", size=12),
          legend.title = element_blank(), 
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=12))

countries_education_remain <- weighted_df_ess %>% 
    group_by(cntry,Education) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    filter(cntry %in% target_countries_r$cntry) %>% 
    arrange(desc(cntry,Education,proportion)) %>%
    ggplot(aes(x= factor(cntry, labels=target_countries_r$cntry), y=proportion)) + 
    geom_bar(aes(fill=factor(Education,levels=c("Low Education","Medium Education","High Education"))),
             position="dodge",stat="identity", width = .6) +
    geom_hline(aes(yintercept = 0.20), colour = "#8da0cb", linetype ="longdash", size = .8) +
   scale_fill_brewer(palette = "Pastel1") +
    scale_y_continuous(labels = scales::percent) +
    labs(x = "",
        y = "",
        fill = "Education",
        title = "Countries with highest proportion of votes to Remain member of EU",
        subtitle = "Educational overview") + 
    theme_minimal() +
    theme(axis.text.x = element_text(face="bold", color="#636363", size=12),legend.position = "none", 
          plot.title=element_text(vjust=.5, face='bold', colour='#636363', size=15),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=12))

ggarrange(countries_education_leave, countries_education_remain, ncol = 2, nrow = 1)

weighted_df_ess %>% 
    group_by(Region,uemp3m) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    mutate(label = paste0(round(proportion * 100, 2), "%"), 
           label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= fct_reorder2(Region, uemp3m, proportion, .desc = FALSE), y=proportion)) + 
    geom_bar(aes(fill=uemp3m), position = position_stack(reverse = TRUE) ,stat="identity", width = .4) +
    scale_fill_brewer(palette='Set1') +
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    geom_text(aes(y=label_y, label = label), 
              col = "white",
              size = 8,
              fontface = "bold") +
    labs(x = "", y = "", fill = "",
        title = "Unemployment overview on European Regions",
        subtitle = "% of respondents who ever were unemployed and seeking work for a period more than three months")+ 
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.direction = "horizontal",
          legend.text = element_text(size=15, face="bold"),
          axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(),
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))

weighted_df_ess %>% 
    group_by(cntry,uemp3m) %>%
    summarise(total = round(survey_total(),2), proportion = survey_mean()) %>%
    mutate(label = paste0(round(proportion * 100, 0), "%"), 
           label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= fct_reorder2(cntry, uemp3m, proportion, .desc = FALSE), y=proportion)) + 
    geom_bar(aes(fill=uemp3m), position = position_stack(reverse = TRUE) ,stat="identity", width = .7) +
    scale_fill_brewer(palette='Set1') +
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    geom_text(aes(y=label_y, label = label), 
              col = "white",
              size = 5,
              fontface = "bold") +
    labs(x = "", y = "", fill = "",
        title = "Unemployment overview by Countries",
        subtitle = "% of respondents who ever were unemployed and seeking work for a period more than three months")+ 
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.direction = "horizontal",
          legend.text = element_text(size=15, face="bold"),
          axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(),
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))

weighted_df_ess %>% 
    group_by(vteurmmb,uemp3m) %>%
    summarise(total = round(survey_total(),2), proportion = survey_mean()) %>%
    mutate(label = paste0(round(proportion * 100, 0), "%"), 
           label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= factor(vteurmmb), y=proportion)) + 
    geom_bar(aes(fill=uemp3m), position = position_stack(reverse = TRUE),
             stat="identity", width = .3) +
    scale_fill_brewer(palette='Set1') +
    scale_y_continuous(labels = scales::percent) +
    geom_text(aes(y=label_y, label = label), 
              col = "white",
              size = 8,
              fontface = "bold") +
    labs(x = "", y = "", fill = "",
        title = "Unemployment rate among European voters",
        subtitle = "% of respondents who ever were unemployed and seeking work for a period more than three months")+ 
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.direction = "horizontal",
          legend.text = element_text(size=15, face="bold"),
          axis.text.x = element_text(face="bold", color="#636363", size=18),
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))


weighted_df_ess %>% 
    group_by(Region,mbtru) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    mutate(label = paste0(round(proportion * 100, 2), "%"), 
           label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= fct_reorder2(Region, mbtru, proportion, .desc = TRUE), y=proportion)) + 
    geom_bar(aes(fill=mbtru), position = position_stack(reverse = TRUE) ,stat="identity", width = .4) +
    scale_fill_brewer(palette='Set2') +
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    geom_text(aes(y=label_y, label = label), 
              col = "white",
              size = 8,
              fontface = "bold") +
    labs(x = "", y = "", fill = "",
        title = "Union membership on European Regions",
        subtitle = "% of respondents that have been a member of a trade union or similar organisation")+ 
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.direction = "horizontal",
          legend.text = element_text(size=15, face="bold"),
          axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(),
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))

weighted_df_ess %>% 
    group_by(vteurmmb,mbtru) %>%
    summarise(total = round(survey_total(),2), proportion = round(survey_mean(),2)) %>%
    mutate(label = paste0(round(proportion * 100, 2), "%"), 
           label_y = cumsum(proportion) - 0.5 * proportion) %>%
    ggplot(aes(x= vteurmmb, y=proportion)) + 
    geom_bar(aes(fill=mbtru), position = position_stack(reverse = TRUE) ,stat="identity", width = .4) +
    scale_fill_brewer(palette='Set2') +
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    geom_text(aes(y=label_y, label = label), col = "white", size = 10, fontface = "bold") +
    labs(x = "", y = "", fill = "",
        title = "Union membership overview on european voters",
        subtitle = "% of respondents that have been a member of a trade union or similar organisation")+ 
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.direction = "horizontal",
          legend.text = element_text(size=15, face="bold"),
          axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.text.y = element_text(face="bold", color="#636363", size=18),
          axis.title.y = element_blank(),
          plot.title=element_text(vjust=.5,family='', face='bold', colour='#636363', size=25),
          plot.subtitle=element_text(vjust=.5,family='', face='bold', colour='#636363', size=15))

# Setting Remain in variable vteurmmb as the first factor level
# Applying this transformation in order to use 
weighted_df_ess$variables$vteurmmb <- relevel(weighted_df_ess$variables$vteurmmb, ref="Remain")

str(weighted_df_ess$variables)

glm_eduyears_vote <- svyglm(vteurmmb ~ eduyrs, design=weighted_df_ess, family=binomial(link="logit"))

# Creating a plot to check hyphotesis 3
educational_profile <- data.frame(eduyrs = seq(from = 0, to = 60, by = .5))

educational_profile$predicted_probs <- predict(glm_eduyears_vote, 
                                              newdata = educational_profile, 
                                              type = "response")

ggplot(data=educational_profile, aes(x= eduyrs, y=predicted_probs)) + 
geom_line(color="#67a9cf", linetype ="longdash", size = .8) +
scale_fill_brewer(palette='Set1') +
scale_y_continuous(labels = scales::percent) +
labs(x = "Years of Formal Education", y = "Probability to vote for Leave",
    title = "Relation between Education Level and Voting Intentions",
    subtitle = "% of probability to vote for Leave throughout the years")+ 
theme_minimal() + 
theme(axis.text.x = element_text(face="bold", color="#636363", size=18),
      axis.title.x = element_text(face="bold", color="#636363", size=18),
      axis.text.y = element_text(face="bold", color="#636363", size=18),
      axis.title.y = element_blank(),
      plot.title=element_text(vjust=.5,hjust=.5,family='', face='bold', colour='#67a9cf', size=25),
      plot.subtitle=element_text(vjust=.5,hjust=.5,family='', face='bold', colour='#67a9cf', size=18))

glm_voters <- svyglm(vteurmmb ~ uemp3m+mbtru+Education, design=weighted_df_ess, family=binomial(link="logit"))
summary(glm_voters, df.resid = degf(weighted_df_ess))

person1 <- predict(glm_voters,
                   newdata = data.frame(Education = "Medium Education", 
                                        uemp3m = "Yes", 
                                        mbtru = "Yes"),
                   type = "response")

paste0(round(person1*100,1), "%")

person2 <- predict(glm_voters,
                   newdata = data.frame(Education = "High Education", 
                                        uemp3m = "No", 
                                        mbtru = "No"),
                   type = "response")

paste0(round(person2*100,1), "%")

getRversion()
