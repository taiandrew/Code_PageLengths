
##### Housekeeping #####
rm(list=ls())

#Sys.setlocale('LC_ALL','C') 
Sys.setlocale("LC_CTYPE", "English_United States.1258")

library(readr)
library(tidyr)
library(dplyr)
library(stringr)

setwd('C:/Users/Andrew/Dropbox/journals/gender/')



##### Clean names #####

# Load data
load("Temp/EconLit_Split.RData" )

# Trim Whitespace and title casing
AllNames$Name = sapply( AllNames$Name, function(x) {
  str_to_title(
  str_trim(x
           )) } )

# Remove Jr. and Sr.
AllNames$Name = sapply( AllNames$Name, function(x) {
  sub("([ ,.]|^)Jr([ .,]|$)", "", x)
} )
AllNames$Name = sapply( AllNames$Name, function(x) {
  sub("([ ,.]|^)Sr([ .,]|$)", "", x)
} )

# Remove excess commas
AllNames$Name <- str_replace_all(AllNames$Name, "\\,\\,", "")
AllNames$Name <- str_replace_all(AllNames$Name, "^\\,", "")

# Split names
AllNames = separate(AllNames, Name, c("LastName", "FirstName"), sep="\\,", remove=FALSE)
AllNames$FirstName = sapply(AllNames$FirstName, function(x) { str_trim(x) } )
AllNames$LastName = sapply(AllNames$LastName, function(x) { str_trim(x) } )

# Drop if first or last name missing
AllNames <- AllNames[nchar(AllNames$FirstName)>0 & nchar(AllNames$LastName)>0, ]
AllNames <- AllNames[!is.na(AllNames$Name), ]



##### Clean Initials #####

# Create Initial
AllNames$Initial1 = sapply(AllNames$FirstName, function(x) { substr(x, 1, 1) } )

# Order by name and year
AllNames = AllNames[order(AllNames$Name, AllNames$Year),]

# We repeat this up to 3 times in case there are multiple instances...
for (j in 1:3) {
  for (i in 1:(nrow(AllNames)-1)) {
    
    # Print a counter
    if (i%%5000==0) {
      print(paste(toString(i), "of", toString(nrow(AllNames)), "time", toString(j)))
    }
    
    # Replace first with name before if it is an initial and lines up with name before, up to 3 times
    if ((AllNames$LastName[i]==AllNames$LastName[i+1]) &
        (AllNames$Initial1[i]==AllNames$Initial1[i+1]) &
        (AllNames$FirstName[i]==AllNames$Initial1[i])) {
      
         AllNames$FirstName[i] = AllNames$FirstName[i+1]
    }
  }
}

for (s in c("FirstName", "LastName")) {

  # Remove initials: "A."
  AllNames[s] = sapply(AllNames[s], function(x) {
    gsub("[A-z]\\. ?", "", x ) } )
  # Remove initials: " A "
  AllNames[s] = sapply(AllNames[s], function(x) {
    gsub(" [A-Z] ", " ", x ) } )
  # Remove initials: "A "
  AllNames[s] = sapply(AllNames[s], function(x) {
    gsub("^[A-Z] ", "", x ) } )
  # Remove initials: "A.$" (end)
  AllNames[s] = sapply(AllNames[s], function(x) {
    gsub("[A-Z]\\.?$", "", x ) } )
  # Remove initials: "^A." (start)
  AllNames[s] = sapply(AllNames[s], function(x) {
    gsub("^[A-Z]\\.? {1,2}", "", x ) } )

  # Trim whitespace and title casing again
  AllNames[s] = sapply( AllNames[s], function(x) {
    str_to_title(
      str_trim(x
      )) } )
  
  # Remove special characters if they are at the beginning
  AllNames[s] = sapply( AllNames[s], function(x) {
    sub("^\\-", "", x)
  })
  AllNames[s] = sapply( AllNames[s], function(x) {
    sub("^\\.", "", x)
  })
  
}

# Create new author name
AllNames$AuthorOld = AllNames$Name
AllNames$Name = paste(AllNames$FirstName, AllNames$LastName)



##### Misc Cleaning #####

# Clean journal names
AllNames$Journal <- sapply( AllNames$Journal, function(x) { gsub("[\\.\\,\\:]", "" , x) } )
AllNames$Journal <- sapply( AllNames$Journal, function(x) { str_to_lower(x) } )


# Trim Whitespace and title casing again
AllNames$Name = sapply( AllNames$Name, function(x) {
  str_to_title(
    str_trim(x
    )) } )

# Remove if there is only one name left
AllNames$nWords = sapply(AllNames$Name, function(x) {
  str_count(x, pattern="\\s?[\\w]+\\s?") })

AllNames = AllNames[AllNames$nWords>1,]

# Remove if first name has 1 letter or less
AllNames$nCharFirst = sapply(AllNames$FirstName, function(x) {
  nchar(x, allowNA=TRUE) })

AllNames = AllNames[AllNames$nCharFirst>1,]

# Remove country and place names
AllNames$Country = sapply( AllNames$Name, function(x) {
  grepl( "Netherlands|United|Germany|Los Angeles|London|School|University|College", x, ignore.case=TRUE)
})

AllNames = AllNames[AllNames$Country==FALSE ,]



##### Save & Export #####

# Save list of unique names for matching
EconLit_UniqueNames = unique(AllNames[c('FirstName', 'LastName', 'Name')])
save(EconLit_UniqueNames, file='Data/Cleaned/EconLit_UniqueNames.RData')

# Save full data
AllNames = AllNames[c('Name', 'FirstName', 'LastName', 'Journal', 'Year', 'Title', 'JELs')]
save(AllNames, file="Data/Cleaned/EconLit_Full.RData")

# # Save data for EconLit
# AllNames = AllNames[c('Name', 'FirstName', 'LastName', 'Journal', 'Year')]
# save(AllNames, file="Temp/EconLit_Clean.RData")
# write.csv(AllNames, file="Output/EconLit_Clean.csv", row.names=FALSE)


