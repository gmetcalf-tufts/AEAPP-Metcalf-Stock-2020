clear
cd "`root'/stata"
set more off 

*******************************************************************************
*
*     Create GDP data set 01/25/20 
*  Updated 03/14/22 by Siddhi D.
*
*******************************************************************************
*
* create index2016 tempfile - US GDP deflator
import excel using "raw_data\OECD_GDP.xlsx",sheet(US gdp deflator (FRED)) case(lower) first clear 
keep year index2016 index2015
rename index2016 igdp16
 label var igdp16 "US GDP deflator (2016=100)"
tempfile igdp16
save "`igdp16'", replace
*
* create OECD ppp tempfile
import excel using "raw_data\OECD_GDP.xlsx",sheet(OECD ppp) case(lower) first clear 
keep location time value
keep if location=="SWE"
replace location="LIE" if location=="SWE"
tempfile pppLIE
save "`pppLIE'", replace

import excel using "raw_data\OECD_GDP.xlsx",sheet(OECD ppp) case(lower) first clear 
keep location time value
drop if location=="LIE"
append using "`pppLIE'"
rename location ID
rename time year
rename value ppp
 label var ppp "Purchasing power parity (OECD)"
tempfile ppp
save "`ppp'", replace

import excel using "raw_data\OECD_GDP.xlsx",sheet(GDP constant LCU) cellrange(A4:BK268) first clear
drop CountryName IndicatorName IndicatorCode
reshape long _, i(CountryCode) j(year)
rename (CountryCode year _) (ID year rgdp)
 label var rgdp "Real GDP, local currency"
tempfile rgdp
save "`rgdp'", replace

* create gdp deflator local currency tempfile
import excel using "raw_data\OECD_GDP.xlsx",sheet(GDP deflator) cellrange(A4:BK268) first clear
drop CountryName IndicatorName IndicatorCode
reshape long _, i(CountryCode) j(year)
rename (CountryCode year _) (location time value)

preserve
keep if location=="SWE"
replace location="LIE" if location=="SWE"
tempfile pgdpLIE
save "`pgdpLIE'", replace
restore

*import excel using "raw_data\OECD_GDP.xlsx",sheet(GDP deflator LCU) case(lower) first clear 
*keep location time value
drop if location=="LIE"
append using "`pgdpLIE'"
rename location ID
rename time year
rename value pgdp
 label var pgdp "GDP deflator, local currency"
tempfile pgdp
save "`pgdp'", replace
*

* Modified Gross National Income and CPI for Ireland
import excel using "raw_data\Irish Modified GNI.xlsx",sheet(data) case(lower) first clear 
keep id year cpi_irl gnim_irl
rename id ID
tempfile gnim_irl
save "`gnim_irl'", replace

* Mainland GDP for Norway
import excel using "raw_data\Norway_mainland_gdp.xlsx",sheet(tostata) case(lower) first clear 
gen pgdp_nor = 100*ngdp_nor/rgdp_nor
rename id ID
tempfile gdpm_nor
save "`gdpm_nor'", replace

* merge 
use "`igdp16'"
merge 1:m year using "`ppp'" 
 drop _merge
merge 1:1 ID year using "`rgdp'" 
 drop _merge
merge 1:1 ID year using "`pgdp'" 
 drop _merge
merge 1:1 ID year using "`gnim_irl'" 
 drop _merge
merge 1:1 ID year using "`gdpm_nor'" 
 drop _merge
merge m:1 ID using "data/names" 
 drop if _merge==2
 drop _merge

 
* Ireland: eliminate for intellectual property investment boom
*     (1) splice GDP (<=1995) and modified GNI using 1995 splice year
*     (2) replace pgdp with cpi
gen rgdp_wb = rgdp
 label var rgdp_wb "Real GDP growth, World Bank, unadjusted"
gen rgdp_x99 = rgdp
gen pgdp_x99 = pgdp
gen rgnim_irl = gnim_irl/cpi_irl
su rgdp if (ID=="IRL")*(year==1995)
 sca mrgdp95 = r(mean)
su rgnim_irl if (ID=="IRL")*(year==1995)
 sca mrgni95 = r(mean)
replace rgdp = (mrgdp95/mrgni95)*rgnim_irl if (ID=="IRL")*(year>=1995)
replace pgdp = cpi_irl if (ID=="IRL")
list year ID cpi_irl pgdp_x99 pgdp gnim_irl rgdp_x99 rgnim_irl rgdp if (ID=="IRL")
list year ID pgdp rgdp if (ID=="IRL")
drop rgnim_irl gnim_irl cpi_irl rgdp_x99 pgdp_x99

* Norway: replace WB GDP with mainland GDP
list year ID rgdp rgdp_nor pgdp pgdp_nor if ID=="NOR"
replace rgdp = rgdp_nor if ID=="NOR"
replace pgdp = pgdp_nor if ID=="NOR"
drop rgdp_nor pgdp_nor ngdp_nor
cap drop cnum*
drop igdp16 rgdp_wb
sort ID year
save data/gdpdata, replace
*


