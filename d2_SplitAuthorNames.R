
##### Housekeeping #####
rm(list=ls())

#Sys.setlocale('LC_ALL','C') 
Sys.setlocale("LC_CTYPE", "English_United States.1258")
library(ggplot2)
library(zoo)
library(readxl)
library(stringi)
library(stringr)
library(haven)

setwd('C:/Users/Andrew/Dropbox/journals/gender/')



##### Cleaning #####

load('Code_PageLengths/temp/raw.RData')

# Keep lines with at least two line breaks
index = grep("\n.*\n", EconLit$Authors)
#EconLit = EconLit[,c('pubtitle','Authors','year', 'Title', 'JELs')]

AllNames = data.frame(Name = 'Name', Year = 'Year', Journal = 'Journal', 
                      Title='Title', JELs = 'JEL1', Date = 'pubdate', Issue = 'issue',
                      Pages='Pages', pgEnd='pgEnd', pgStart='pgStart', pgLen='pgLen',
                      stringsAsFactors = FALSE)

EconLit = EconLit[index,]
head(EconLit$Authors)

# Replace from line break to comma with semicolon
EconLit$Authors = gsub("\n.*?,", ";", EconLit$Authors)
# match between semicolons
index2 = grepl(";.*;", EconLit$Authors)

for(j in 1:length(EconLit$Authors)){
  if(j%%1000==0) print(j)
  if(!index2[j]) {
    EconLit$Authors[j] = gsub("(.*);.*", "\\1", EconLit$Authors[j])
    AllNames = rbind(AllNames, c(as.character(EconLit$Authors[j]), 
                                 as.character(EconLit$year[j]),
                                 as.character(EconLit$pubtitle[j]),
                                 as.character(EconLit$Title[j]),
                                 as.character(EconLit$JELs[j]),
                                 as.character(EconLit$pubdate[j]),
                                 as.character(EconLit$issue[j]),
                                 as.character(EconLit$pages[j]),
                                 as.character(EconLit$pgEnd[j]),
                                 as.character(EconLit$pgStart[j]),
                                 as.character(EconLit$pgLen[j]) ))
    
  } else {
    each = strsplit(EconLit$Authors[j], ";")[[1]]
    each = each[!grepl(" and ", each)]
    each = each[grep(",", each)]
    each = gsub(", III", "", each)
    if(length(each)>1){
      for(i in 2:(length(each))){
        each[i] = sub(",", ";", each[i])
        each[i] = sub(".*;", "", each[i])
        each[i] = sub("^[[:blank:]]?","", each[i])
      }
    }
    each = each[grep(",", each)]
    if(length(each)>0){
      for(i in 1:length(each)){
        AllNames = rbind(AllNames, c(as.character(each[i]), 
                                     as.character(EconLit$year[j]),
                                     as.character(EconLit$pubtitle[j]),
                                     as.character(EconLit$Title[j]),
                                     as.character(EconLit$JELs[j]), 
                                     as.character(EconLit$pubdate[j]),
                                     as.character(EconLit$issue[j]),
                                     as.character(EconLit$pages[j]),
                                     as.character(EconLit$pgEnd[j]),
                                     as.character(EconLit$pgStart[j]),
                                     as.character(EconLit$pgLen[j]) ))
      }
    }
  }
}

AllNames = AllNames[-1,]
AllNames = AllNames[!grepl("[[:digit:]]", AllNames$Name),]



##### Export #####
save(AllNames, file='Code_PageLengths/temp/split.RData')
write_dta(AllNames, 'Code_PageLengths/temp/split.dta', version=13)
