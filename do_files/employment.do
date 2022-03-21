clear
*local root "/Users//`=c(username)'/Dropbox/Metcalf_Stock/stata/_Siddhi/AEA PandP Data Construction and Replication/Replication_AEAPP_cleaning" //for mac
cd "`root'/stata"
set more off 

*******************************************************************************
*
*     Create employment data set 01/25/20 
*
*******************************************************************************
*
global country Austria Belgium Bulgaria Switzerland Cyprus Czechia Germanyuntil1990formerterri Denmark EuroareaEA112000EA122006 Euroarea12countries Euroarea19countries Estonia Greece Spain EuropeanUnion15countries1 EuropeanUnion27countriesf EuropeanUnion28countries Finland France Croatia Hungary Ireland Iceland Italy Liechtenstein Lithuania Luxembourg Latvia Montenegro NorthMacedonia Malta Netherlands Norway Poland Portugal Romania Serbia Sweden Slovenia Slovakia UnitedKingdom

***** Total Employment *****
import excel using "raw_data/Total employment domestic_Thousand persons", sheet(Data1) cellrange(A11:AP55) firstrow clear
foreach i in $country {
if "`i'" != "Denmark" & "`i'" != "France" & "`i'" != "Norway" {
qui replace `i' = "" if `i' == ":" 
qui destring `i', replace
}
}
gather $country, variable(country) value(total_employment) 

tempfile total_employment
save "`total_employment'", replace

/*
***** Manufacturing Employment *****
import excel using "raw_data/Total employment domestic_Thousand persons", sheet(Data4) cellrange(A11:AP55) firstrow clear
foreach i in $country {
if "`i'" != "Denmark" & "`i'" != "France" & "`i'" != "Norway" {
qui replace `i' = "" if `i' == ":" 
qui destring `i', replace
}
}
gather $country, variable(country) value(manufacturing_employment) 
*/

***** merge with Total Employment dataset *****
merge 1:1 country TIMEGEO using "`total_employment'"
drop _merge

*rename countries
replace country="Czech Republic" if country=="Czechia"
replace country="Germany" if country=="Germanyuntil1990formerterri"
replace country="United Kingdom" if country=="UnitedKingdom"
replace country="Slovak Republic" if country=="Slovakia"
rename TIMEGEO year

label var total_employment "Total employment domestic concept (thousand persons)"
*label var manufacturing_employment "Manufacturing employment domestic concept (thousand persons)"
label var country "Country name"

destring year,replace
merge m:1 country using "data/names"
tab country if _merge==1
drop if _merge!=3
drop _merge
desc
save "data/employment.dta",replace


