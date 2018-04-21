set more off

** Do file replicates the results in 
** David Card and Stefano DellaVigna
** Nine Facts about Top Journals in Economics
** Journal of Economic Literature 2013, 51:1, 1–18

use Top5JELPosting.dta, replace
log using top5_part1.log, replace


* Generate length normalized by page density -- renormilization is obtained
* by measures of page density for a given journal in different years
gen lengthnorm=length*(2700/2550) if journal=="QJE"
replace lengthnorm=length*(3070/2550) if journal=="JPE"
replace lengthnorm=length*(3300/2550) if journal=="EMA"
replace lengthnorm=length*(4180/2550) if journal=="RES"
* For the AER use a time-varying measure, since it is the only one which appears to have
* changed the font repeatedly over time
replace lengthnorm=length*(4210/2550) if journal=="AER" & year>=1970 & year<1980
replace lengthnorm=length*(4330/2550) if journal=="AER" & year>=1980 & year<1990
replace lengthnorm=length*(4290/2550) if journal=="AER" & year>=1990 & year<1995
replace lengthnorm=length*(4440/2550) if journal=="AER" & year>=1995 & year<2000
replace lengthnorm=length*(4570/2550) if journal=="AER" & year>=2000 & year<2008
replace lengthnorm=length*(4390/2550) if journal=="AER" & year>=2008 & year<2011
replace lengthnorm=length*(3730/2550) if journal=="AER" & year>=2011

* Replaced scraped citation measure with hand-checked one where appropriate
replace citations=citationsbyhand if flags==1 & citationsbyhand~=.
replace citations=0 if citations==.
drop citationsbyhand

* Label Papers and Proceedings issue of AER, and various notes and comments -- all excluded later
gen AERpp=journal=="AER" & ((issue==2 & year<=2010)|(issue==3 & year>=2011))
ta length AERpp
foreach x in various comment reply errata discussion {
	gen `x'=0
	}
foreach x in "Foreword" "Distinguished Fellow" "John Bates Clark" "Editorial" "American Economic Association" "Report of the Editor" "Report of the Director" "Report of the Secretary" "Report of the Treasurer" "Report of the Representative" "Committee on" "Editor's Note" "Editor's Introduction" "Editors' Introduction" "President's Address" "Search Committee" "Minutes of the" "Independent Auditors' Report" {
replace various=1 if regexm(title,"`x'")
}
replace various=1 if author=="NA"
foreach x in "Comment" {
replace comment=1 if regexm(title,"`x'")
}
foreach x in "Reply" "Rejoinder" {
replace reply=1 if regexm(title,"`x'")
}
foreach x in "Errata" "Erratum" "Corrigendum" ": Correction" ": A Correction" {
replace errata=1 if regexm(title,"`x'")
}
foreach x in "Discussion" {
replace discussion=1 if regexm(title,"`x'")
}

**** some checks -- omitted here
*list title if various==1
*ta length journal if various==1
*list if various==1 & length>6
*list title if comment==1
*list title if reply==1
*list title if errata==1
*list title if discussion==1
*ta journal various
*ta journal comment
*ta journal reply
*ta journal errata
*ta journal discussion

* Main sample used for all results below
gen samplemain=AERpp==0 & various==0 & comment==0 & reply==0 & errata==0 & discussion==0


* This is Appendix Table 1 and Figure 2 data
ta year journal if samplemain==1,m


*** check of issues and # articles per issue
*bys journal: ta year issue if samplemain==1,m
*bys journal: ta year issue,m
* QJE: It is correct that in 1980 there was double the number of issues -- CORRECT
* AER: Check year 1974, no issue 5, issue 6 instead -- CORRECT
* AER: Check year 1978, two articles in issue 6? -- CORRECT
* AER: Check year 1981, three articles in issue 6? -- CORRECT
* AER: Check year 1985, five articles in issue 6? -- CORRECT
* AER: Check year 1989, three articles in issue 6? -- CORRECT
* AER: Check year 1993, two articles in issue 6? -- CORRECT
* AER: Check year 1997, three articles in issue 6? -- CORRECT




* This is information for Figure 4 (contained in Oldappt4(length) sheet of .xls)
tabstat noauthors if samplemain==1, by(year) st(mean p25 p50 p75 p90 co)
tabstat lengthnorm if samplemain==1, by(year) st(mean p50 co)


* Comparison of percentiles in (normalized) length
tabstat lengthnorm if samplemain==1 & year<=1975, st(mean p10 p25 p50 p75 p90 co)
tabstat lengthnorm if samplemain==1 & year>=2012, st(mean p10 p25 p50 p75 p90 co)
* top 5% of citation
tabstat citation if samplemain==1, by(year) st(mean p95 p99 co)

* Extract fields from JEL codes
*Uses the package "moss" and regular expressions to extract all substrings from "subject" that have four numerals surrounded by parentheses (for old JEL codes) or that
*start with a capital letter and have one or more numerals following the letter (for new JEL codes). This generates variables for the number of JEL codes in the string, 
*the position of each JEL code in "subject," and the value of each JEL code.
*ssc install moss

*Extracts the old JEL codes
moss subject, match("(\([0-9][0-9][0-9][0-9]\))") regex prefix(jelold2)
ta year jelold2count

*Gets the maximum number of old JEL codes across observations (5)
egen maxjelold=max(jelold2count)
local maxjelold=maxjelold[1]+0

*Removes parentheses and last (unnecessary) digit of old JEL codes
forvalues x = 1/`maxjelold' {
	replace jelold2match`x'=substr(jelold2match`x',2,3)
}

*Convert jelold2match vars to numerics
forvalues x = 1/`maxjelold' {
	gen jeloldmatch`x'=real(jelold2match`x')
}
drop jelold2match*

rename jelold2count jeloldcount

*Extracts the new JEL codes
moss subject, match("([A-Z][0-9]+)") regex prefix(jelnew)
ta year jelnewcount
li if jelnewcount>0 & year==1971

*Puts papers into fields 
foreach x in micro theory metrics macro internat fin pub labor healthurblaw hist io dev lab other {
	gen `x'=0
	}

*Gets the maximum number of new JEL codes across observations (7)
egen maxjelnew=max(jelnewcount)
local maxjelnew=maxjelnew[1]+0

gen jeloldmatch6=.
gen jeloldmatch7=.

forvalues x = 1/`maxjelnew' {
	replace micro=1 if (substr(jelnewmatch`x',1,1)=="D" & substr(jelnewmatch`x',1,3)!="D11" & substr(jelnewmatch`x',1,2)!="D5" & substr(jelnewmatch`x',1,3)!="D21" & substr(jelnewmatch`x',1,3)!="D85" & substr(jelnewmatch`x',1,3)!="D86" & substr(jelnewmatch`x',1,3)!="D44" & substr(jelnewmatch`x',1,3)!="D71" & substr(jelnewmatch`x',1,3)!="D81" & substr(jelnewmatch`x',1,3)!="D82" & substr(jelnewmatch`x',1,3)!="D83" & substr(jelnewmatch`x',1,2)!="D9" | inlist(jeloldmatch`x',024,114,224,511,512,513,522,921,020))
}
forvalues x = 1/`maxjelnew' {
	replace theory=1 if (substr(jelnewmatch`x',1,2)=="C7" | substr(jelnewmatch`x',1,3)=="D11" | substr(jelnewmatch`x',1,2)=="D5" | substr(jelnewmatch`x',1,3)=="D21" | substr(jelnewmatch`x',1,3)=="D85" | substr(jelnewmatch`x',1,3)=="D86" | substr(jelnewmatch`x',1,3)=="D44" | substr(jelnewmatch`x',1,3)=="D71"  | substr(jelnewmatch`x',1,3)=="D81" | substr(jelnewmatch`x',1,3)=="D82"  | substr(jelnewmatch`x',1,3)=="D83" | inlist(jeloldmatch`x',021,022,025,026))
}

forvalues x = 1/`maxjelnew' {
	replace metrics=1 if ((substr(jelnewmatch`x',1,1)=="C" | inlist(jeloldmatch`x',211,212,213,214,220,222,229)) & substr(jelnewmatch`x',1,2)!="C7" & substr(jelnewmatch`x',1,2)!="C9")
}

forvalues x = 1/`maxjelnew' {
	replace macro=1 if (substr(jelnewmatch`x',1,1)=="E" | jelnewmatch`x'=="O11" | substr(jelnewmatch`x',1,2)=="O4" | substr(jelnewmatch`x',1,2)=="O5" | substr(jelnewmatch`x',1,2)=="D9" | inlist(jeloldmatch`x',023,112,120,121,122,123,124,131,132,133,134,221,223,226,311,227))
}

forvalues x = 1/`maxjelnew' {
	replace internat=1 if (substr(jelnewmatch`x',1,1)=="F" | inlist(jeloldmatch`x',111,400,411,421,422,423,431,432,433,441,442,443))
}
	
forvalues x = 1/`maxjelnew' {
	replace fin=1 if (substr(jelnewmatch`x',1,1)=="G" | inlist(jeloldmatch`x',310,312,313,314,315,521,520))
}

forvalues x = 1/`maxjelnew' {
	replace pub=1 if (substr(jelnewmatch`x',1,1)=="H" | inlist(jeloldmatch`x',320,321,322,323,324,325,641,915))
}

forvalues x = 1/`maxjelnew' {
	replace labor=1 if (substr(jelnewmatch`x',1,1)=="J" | substr(jelnewmatch`x',1,2)=="I2" | inlist(jeloldmatch`x',811,812,813,821,822,823,824,825,826,831,832,833,841,851,912,917,918))
}

forvalues x = 1/`maxjelnew' {
	replace healthurblaw=1 if (substr(jelnewmatch`x',1,2)=="I0" | substr(jelnewmatch`x',1,2)=="I1" | substr(jelnewmatch`x',1,1)=="R" | substr(jelnewmatch`x',1,1)=="K" | inlist(jeloldmatch`x',731,913,916,931,932,933,941,930))
}

forvalues x = 1/`maxjelnew' {
	replace hist=1 if (substr(jelnewmatch`x',1,1)=="N" | inlist(jeloldmatch`x',041,042,043,044,045,046,047,048,032))
}

forvalues x = 1/`maxjelnew' {
	replace io=1 if (substr(jelnewmatch`x',1,1)=="L" | inlist(jeloldmatch`x',514,611,612,613,614,615,616,619,631,632,633,634,635,636))
}

forvalues x = 1/`maxjelnew' {
	replace dev=1 if ((substr(jelnewmatch`x',1,1)=="O" | inlist(jeloldmatch`x',621)) & jelnewmatch`x'!="O11" & substr(jelnewmatch`x',1,2)!="O4" & substr(jelnewmatch`x',1,2)!="O5")
}
	 
forvalues x = 1/`maxjelnew' {
	replace lab=1 if (substr(jelnewmatch`x',1,2)=="C9" | inlist(jeloldmatch`x',215))
}

forvalues x = 1/`maxjelnew' {
	replace other=1 if (inlist(substr(jelnewmatch`x',1,1),"A","B","M","P","Q","Y","Z") | substr(jelnewmatch`x',1,2)=="I3" | inlist(jeloldmatch`x',011,012,027,031,036,050,051,052,053,113,531,541,710,711,713,714,715,716,717,718,721,722,723,911,914))
}
	 
gen sumfields=micro+theory+metrics+macro+internat+fin+pub+labor+healthurblaw+hist+io+dev+lab+other
li if sumfields==0 & jelnewcount>0 

li jeloldmatch* if sumfields==0 &  jeloldcount>0
*There were 58 papers with an old JEL code that are not in a field (JELs: 20, 32, 227, 520, 930) because the old-to-new JEL mapping did not
*list their JEL codes. We went back and added them to the right fields, so now every paper with at least one JEL code is in at least one field.

sum sumfields if jelnewcount>0 | jeloldcount>0
ta sumfields if jelnewcount>0 | jeloldcount>0
*The mean number of fields a paper is in (given it has at least one new JEL) is 1.5, and the mode is 1

*"Sum" gives the frequency for each field. I only consider papers with at least one new JEL code.
tabstat micro theory metrics macro internat fin pub labor healthurblaw hist io dev lab other if jelnewcount>0 | jeloldcount>0, stats(sum mean count)
*68 of the 91 papers without a JEL code were published in 1990 (year of the JEL change), and all 91 were published before 1991.
*I drop these 68 papers when I create the following field figures.
gen nojel=(jeloldmatch1==. & jelnewmatch1=="")

keep if samplemain==1
drop jel*





*save for conversion to sas
saveold top5clean, replace





