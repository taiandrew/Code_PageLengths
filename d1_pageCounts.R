

####Houskeeping#####
Sys.setlocale("LC_CTYPE", "English_United States.1258")

library(tidyverse)
library(readxl)
library(stringi)
library(stringr)
library(haven)

setwd('C:/Users/Andrew/Dropbox/journals/gender/')

rm(list=ls())
useful.vars = c('Title', 'year', 'pubdate', 'issue' ,'pubtitle', 'AccessionNumber', 'pages', 'Authors', 'subjectTerms')

files1 = list.files('Data/EconLit/Original', pattern = "\\.xls$", full.names=TRUE)
files2 = list.files('Data/EconLit/Updates_20150729/', pattern = "\\.xls$", full.names=TRUE)
files3 = list.files('Data/EconLit/Updates_20170614/', pattern = "\\.xls$", full.names=TRUE)
files4 = list.files('Data/EconLit/Updates_20170622/', pattern = "\\.xls$", full.names=TRUE)
files5 = list.files('Data/EconLit/Updates_20170706/', pattern = "\\.xls$", full.names=TRUE)
files6 = list.files('Data/EconLit/Updates_20170711/', pattern = "\\.xls$", full.names=TRUE)
files7 = list.files('Data/EconLit/Updates_20180226/', pattern = "\\.xls$", full.names=TRUE)
files8 = list.files('Data/EconLit/Updates_20180326/', pattern = "\\.xls$", full.names=TRUE)


##### Read in files #####

# Loop through files
EconLit <- data.frame()
for (f in c(files1, files2, files3, files4, files5, files6, files7, files8)) {
  print(f)
  thisFile <- read_excel(f)
  if (!'issue' %in% colnames(thisFile)) {
      thisFile['issue'] <- 99
  }
  EconLit <- rbind(thisFile[useful.vars], EconLit)
}

# Append missing JPE
JPE <- read_xlsx('Code_PageLengths/missingJPE.xlsx')
EconLit <- rbind(EconLit, JPE)


##### Create JEL codes #####

# Keep codes, (L##)
EconLit$JELs <- str_extract_all(EconLit$subjectTerms, "\\([A-z][0-9][0-9]?\\)")
EconLit$JELs <- sapply( EconLit$JELs, function(x) { gsub('[()]', '', x) } )



##### Misc cleaning #####

# Remove duplicate files 
#EconLit$Duplicated <- duplicated(EconLit[c('AccessionNumber', 'Title')])
EconLit <- EconLit[!duplicated(EconLit[c('AccessionNumber', 'Title')]),]


# Regularize Unicode characters to Latin-ASCII
#EconLit$pubtitle <- sapply( EconLit$pubtitle, function(x) { stri_trans_general(x, 'Latin-ASCII') } )
EconLit$pubtitle <- sapply( EconLit$pubtitle, function(x) { iconv(x, from='windows-1252', to='UTF-8') } )



##### Keep top 5 journals #####
EconLit <- EconLit[(EconLit$pubtitle=='American Economic Review' |
                    EconLit$pubtitle=='Quarterly Journal of Economics' |
                    EconLit$pubtitle=='Review of Economic Studies' |
                    EconLit$pubtitle=='Econometrica' |
                    EconLit$pubtitle=='Journal of Political Economy'),]


##### Obtain page length #####

EconLit$pgEnd <- as.numeric(sub("\\d+-", "\\1", EconLit$pages))
EconLit$pgStart <- as.numeric(sub("-\\d+", "", EconLit$pages))
EconLit$pgLen <- EconLit$pgEnd - EconLit$pgStart

# toss negatives and 1 pages
#EconLit <- EconLit[ EconLit$pgLen>2 & !is.na(EconLit$pgLen) ,]


##### Summarise #####
EconLit_Summary <- EconLit

EconLit_Summary<- EconLit_Summary %>%
  group_by(year, pubtitle) %>%
  summarise(pgLen = mean(pgLen), n = n())

##### Save RData and export #####

# Save .RData
EconLit = EconLit[EconLit$year>=1991,]
EconLit = select(EconLit, -subjectTerms)
save(EconLit, file='Code_PageLengths/temp/raw.RData')
