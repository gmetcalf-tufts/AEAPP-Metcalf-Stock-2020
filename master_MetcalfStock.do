/*******************************************************************************
* File Name: MASTER_Metcalf_Stock
* 
* Principal investigators: James Stock and Gilbert Metcalf
* Compiled by: Siddhi Doshi
*
* Last revised: Feb 20, 2022
*
* Description: Replicates the results for the Metcalf Stock (2020) AEAPP paper
********************************************************************************/
*** SET DIRECTORY HERE:
*local root "C:/Users/`c(username)'//Dropbox/Metcalf_Stock/stata/_Siddhi/AEA PandP Data Construction and Replication/Replication_AEAP" //for windows
*local root "/Users//`=c(username)'/Dropbox/Metcalf_Stock/stata/_Siddhi/AEA PandP Data Construction and Replication/Replication_AEAPP" //for mac
local root "C:/Users/`c(username)'//Dropbox/Metcalf_Stock/AER PP Submission Materials/Metcalf Stock Data Replication Public Folder"
cd "`root'"
clear all
cap log close
log using master.txt, text replace
set more off 
set scheme s1color
pause on


*******************************************************************************
		* 1. Setting up all the datasets
*******************************************************************************
* INSTALL the following package if not already installed:
net install tidy, from("https://raw.githubusercontent.com/matthieugomez/tidy.ado/master/") replace


************* Names ********************
include "`root'/do_files/names.do"

************* GDP data ********************
*This file compiles the GDP dataset 

include "`root'/do_files/gdp.do"

************* Carbon tax data ********************
/*Compiles carbon tax data from various sources, mainly the World Bank's carbon pricing dashboard.*/
include "`root'/do_files/ctax.do"


*************  Employment data ********************
*Total employment data
include "`root'/do_files/employment.do"

*******************************************************************************
* 2. Merging the datasets and running calculations to create the final dataset 
*******************************************************************************
include "`root'/do_files/merge and calculate 2018.do"

erase "`root'/stata/data/names.dta"
erase "`root'/stata/data/gdpdata.dta"
erase "`root'/stata/data/ctax_CTI.dta"
erase "`root'/stata/data/employment.dta"

*******************************************************************************
* 3. AERPP replication
*******************************************************************************
include "`root'/do_files/EUctax_IRF_AERPP.do"

*******************************************************************************
* 4. Appendix figure
*******************************************************************************
include "`root'/do_files/EUctax_IRF_5.do"

