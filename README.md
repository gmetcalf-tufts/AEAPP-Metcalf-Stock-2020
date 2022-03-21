# AEAPP-Metcalf-Stock-2020
Data and code for: Measuring the Macroeconomic Impact of Carbon Taxes
### Overview
The code in this replication package constructs the tables and figures using Stata. The master file runs all of the code to generate two tables and two appendix figures.
### Description of files and code:
- master_MetcalfStock.do will run all the files to construct the final tables and figures.
- The "do_files" folder contains the do files run by the master file.
  - **Creating the dataset**: names.do, employment.do, GDP.do, ctax.do, and merge and calculate.do create the dataset for analysis
  - **Analysis**: EUctax_IRF_AERPP.do runs the analysis and creates the paper tables
  - **Appendix figures**: EUctax_IRF_5.do, EUctax_IRF_AERPP_out_r1.do, and EUctax_IRF_CIRF_lun_tabfig.do create the appendix figures
-  The stata folder contains the raw data, the dataset used for analysis, and the results
-  "Replication memo.docx" contains details on the sources of all raw data
### Instructions to Replicators
Edit master_MetcalfStock.do to change the default path
### Note
In March 2020 we found a data bug that makes minor changes to some EU2 results. So, the EU2 results in the out\AERPP_results.xlsx spreadsheet don't match Table 2 exactly for EU2, although they do match for the CT20 countries (countries with CT >= $20). There are no qualitative changes. For example, the upper left estimate in Table 2 is 0.10 (SE = 0.43). Using the corrected data, the result is (0.14) (SE = 0.41). 
Another bug causes small rounding discrepancies from the results in Table 2.
