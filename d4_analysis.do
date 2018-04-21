
clear all
set more off

use "Top5_Clean.dta", clear
gen N=1
drop if Flags!=0
drop if Year==2018

* Publications per year
preserve
collapse (count) N, by(Journal Year)
reshape wide N, i(Year) j(Journal) string
restore



* Length by year
preserve
collapse	(count) N ///
			(mean) nAuthors ///
			(mean) mean=pgLen_norm ///
			(median) med=pgLen_norm ///
			, by(Year)
tempfile allLength
save `allLength'
restore

* Length by year, journal
collapse	(count) N ///
			(mean) nAuthors ///
			(mean) mean=pgLen_norm ///
			(median) med=pgLen_norm ///
			, by(Journal Year)
			
reshape wide N nAuthors mean med, i(Year) j(Journal) string

merge 1:1 Year using `allLength', nogen


* Export 
foreach j in AER EMA JPE QJE RES {
foreach v of varlist *`j' {
	label var `v' "`j'"
}
}
foreach v of varlist N nAuthors mean med {
	label var `v' 
}

order N nAuthors mean med *AER *EMA *JPE *QJE *RES 
sort Year

export excel Year N* using "PageLengths2018.xlsx", sheet("d_N") sheetmodify firstrow(varlab)
export excel Year nAuthors* using "PageLengths2018.xlsx", sheet("d_nAuth") sheetmodify firstrow(varlab)
export excel Year mean* using "PageLengths2018.xlsx", sheet("d_Mean") sheetmodify firstrow(varlab)
export excel Year med* using "PageLengths2018.xlsx", sheet("d_Med") sheetmodify firstrow(varlab)
