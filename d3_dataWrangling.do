
clear all
set more off

* Open data
use "temp/split.dta", clear

destring pg* Year Issue, replace

* Journal names
replace Journal = "AER" if Journal=="American Economic Review"
replace Journal = "EMA" if Journal=="Econometrica" 
replace Journal = "JPE" if Journal=="Journal of Political Economy"
replace Journal = "QJE" if Journal=="Quarterly Journal of Economics"
replace Journal = "RES" if Journal=="Review of Economic Studies"

* Author count; collapse back
bysort Year Journal Title : egen nAuthors = count(Year)



********************
* Lengths
********************

gen pgLen_norm = .

* QJE, JPE, EMA, and REStud
replace pgLen_norm = pgLen * (2700/2550) if Journal=="QJE"
replace pgLen_norm = pgLen * (3070/2550) if Journal=="JPE"
replace pgLen_norm = pgLen * (3300/2500) if Journal=="EMA"
replace pgLen_norm = pgLen * (4180/2500) if Journal=="RES"

* AER
replace pgLen_norm=pgLen*(4210/2550) if Journal=="AER" & Year>=1970 & Year<1980
replace pgLen_norm=pgLen*(4330/2550) if Journal=="AER" & Year>=1980 & Year<1990
replace pgLen_norm=pgLen*(4290/2550) if Journal=="AER" & Year>=1990 & Year<1995
replace pgLen_norm=pgLen*(4440/2550) if Journal=="AER" & Year>=1995 & Year<2000
replace pgLen_norm=pgLen*(4570/2550) if Journal=="AER" & Year>=2000 & Year<2008
replace pgLen_norm=pgLen*(4390/2550) if Journal=="AER" & Year>=2008 & Year<2011
replace pgLen_norm=pgLen*(3730/2550) if Journal=="AER" & Year>=2011



********************
* Flag non-papers
********************

* Label Papers and Proceedings issue of AER, and various notes and comments -- all excluded later
gen Flag_AERpp = (Journal=="AER" & ((Issue==2 & Year<=2010)|(Issue==3 & Year>=2011 & Year<=2013)|(Issue==5 & Year>=2014)) )

* create flags
foreach x in various comment reply errata discussion {
	gen Flag_`x'=0
}

* Various
foreach x in "Foreword" "Distinguished Fellow" "John Bates Clark" "Editorial" "American Economic Association" "Report of the Editor" "Report of the Director" "Report of the Secretary" "Report of the Treasurer" "Report of the Representative" "Committee on" "Editor's Note" "Editor's Introduction" "Editors' Introduction" "President's Address" "Search Committee" "Minutes of the" "Independent Auditors' Report" {
	replace Flag_various=1 if regexm(Title,"`x'")
}
replace Flag_various=1 if Name=="NA"

* Comments
foreach x in "Comment" {
	replace Flag_comment=1 if regexm(Title,"`x'")
}

* Replies
foreach x in "Reply" "Rejoinder" {
	replace Flag_reply=1 if regexm(Title,"`x'")
}

* Errata
foreach x in "Errata" "Erratum" "Corrigendum" ": Correction" ": A Correction" {
	replace Flag_errata=1 if regexm(Title,"`x'")
}

* Discussion
foreach x in "Discussion" {
	replace Flag_discussion=1 if regexm(Title,"`x'")
}

* Collective flags
egen Flags = rowtotal(Flag_*)

* Collapse back
bysort Year Journal Title: egen temp = max(Flag_various)
replace Flag_various = temp
drop temp

drop Name
duplicates drop



********************
* JELs
********************

******************************
* Program to match JEL codes
cap program drop JELMatch
program define JELMatch

local name "`1'"
local codes "`2'"
local exclude "`3'"

gen JEL_`name'=0

* Remove excluded JEL codes from consideration
gen JEL_ex = JELs
foreach s in `exclude' {
	replace JEL_ex = subinstr(JEL_ex, "`s'", "", .)
}

* Match desired JEL codes
foreach s in `codes' {
	replace JEL_`name' = 1 if regexm(JEL_ex, "`s'")
}

drop JEL_ex
end
******************************

* Call function
JELMatch "Micro" "D" "D11 D5 D21 D85 D86 D44 D71 D81 D82 D83 D9"
JELMatch "Theory" "C7 D11 D5 D21 D85 D86 D44 D71 D81 D82 D83"
JELMatch "Metrics" "C" "C7 C9"
JELMatch "Macro" "E O11 O4 O5 D9"
JELMatch "Intl" "F"
JELMatch "Fin" "G"
JELMatch "Public" "H"
JELMatch "Labor" "J I2"
JELMatch "HealthUrbanLaw" "I0 I1 R K"
JELMatch "Hist" "N"
JELMatch "IO" "L"
JELMatch "Dev" "O" "O4 O5"
JELMatch "Exp" "C9"
JELMatch "Other" "A B M P Q Y Z I3"

* Create missing flag
gen JEL_Missing = (missing(JELs))



********************
* Old data
********************

drop if Year<2010

preserve
use "data/top5clean.dta", clear

drop author subject volume pages pages1 pages2 author? maxjelnew sumfields nojel maxjelold flags


rename title Title
rename year Year 
rename issue Issue 
rename citations GScites 
rename length pgLen 
rename noauthors nAuthors 
rename journal Journal 
rename lengthnorm pgLen_norm 
rename AERpp Flag_AERpp
rename various Flag_various
rename comment Flag_comment
rename reply Flag_reply 
rename errata Flag_errata 
rename discussion Flag_discussion

rename micro JEL_Micro
rename theory JEL_Theory
rename metrics JEL_Metrics
rename macro JEL_Macro
rename internat JEL_Intl 
rename fin JEL_Fin 
rename pub JEL_Public 
rename labor JEL_Labor
rename healthurblaw JEL_HealthUrbanLaw 
rename hist JEL_Hist 
rename io JEL_IO 
rename dev JEL_Dev 
rename lab JEL_Exp 
rename other JEL_Other 

rename samplemain Flags
replace Flags=0

order Year Journal Title Issue pgLen nAuthors pgLen_norm Flag_AERpp Flag_various Flag_comment Flag_reply Flag_errata Flag_discussion Flags JEL_Micro JEL_Theory JEL_Metrics JEL_Macro JEL_Intl JEL_Fin JEL_Public JEL_Labor JEL_HealthUrbanLaw JEL_Hist JEL_IO JEL_Dev JEL_Exp JEL_Other

drop if Year>2009

tempfile temp1
save `temp1'

restore
append using `temp1'

* Save
compress
drop Pages pgStart pgEnd
save "Top5_Clean.dta", replace


